# Picklist Intelligence Architecture

**Version**: 1.0  
**Purpose**: Comprehensive architecture for extracting and enriching picklist metadata  
**Based On**: User technical guidance (Jan 22, 2026)  
**Status**: Implementation Blueprint

---

## Executive Summary

**Problem**: LLMs need context about picklist values (is "Needs Analysis" stage 2 of 6 or stage 5 of 6?)

**Solution**: Build a local cache of enriched picklist metadata using:
1. **Describe API** → Basic picklist shape (values, labels, active/default)
2. **Tooling API** → Special field attributes (probability, IsClosed, IsConverted)
3. **UI API** → Record-type-specific availability
4. **Custom Metadata** → Admin-defined annotations for custom picklists

**Key Principle**: **No runtime callouts**. Sync metadata via scheduled job, query via SOQL at runtime.

---

## Architecture Overview

### The Three-Layer Model

```
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 1: DISCOVERY                       │
│  (Describe API - Synchronous, Always Available)             │
│  • Field type, label, help text                             │
│  • Picklist values (value, label, active, default)          │
│  • Controlling/dependent relationships                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   LAYER 2: ENRICHMENT                       │
│  (Tooling API + UI API - Async Callouts, Cached)           │
│  • OpportunityStage → DefaultProbability                    │
│  • CaseStatus → IsClosed                                    │
│  • LeadStatus → IsConverted                                 │
│  • Record-type-specific picklist values                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  LAYER 3: ANNOTATION                        │
│  (Custom Metadata - Admin-Defined)                         │
│  • Custom picklist semantics (weight, meaning)              │
│  • AI hints (synonyms, canonicalization)                   │
│  • Business-specific probability mappings                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  LOCAL CACHE (Custom Object)                │
│  PicklistValueInfo__c - Queried at runtime via SOQL        │
└─────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Implementation Plan

### Step 1: Discover Picklist Fields (Describe API)

**Goal**: Identify all picklist fields on target objects and extract base metadata

**Implementation** (`PicklistIntelligenceService.cls`):

```apex
public class PicklistIntelligenceService {
    
    /**
     * @description Discover all picklist fields on an object
     * @param objectApiName API name of the object (e.g., 'Opportunity')
     * @return List of field metadata profiles
     */
    public static List<FieldMetadataProfile> discoverPicklistFields(String objectApiName) {
        List<FieldMetadataProfile> profiles = new List<FieldMetadataProfile>();
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            Schema.DisplayType fieldType = fieldDescribe.getType();
            
            // Check if picklist type
            if (fieldType == Schema.DisplayType.PICKLIST || 
                fieldType == Schema.DisplayType.MULTIPICKLIST) {
                
                FieldMetadataProfile profile = new FieldMetadataProfile();
                profile.objectApiName = objectApiName;
                profile.fieldApiName = fieldDescribe.getName();
                profile.fieldLabel = fieldDescribe.getLabel();
                profile.fieldType = fieldType.name();
                profile.helpText = fieldDescribe.getInlineHelpText();
                profile.isRequired = !fieldDescribe.isNillable();
                
                // Extract picklist values
                profile.picklistValues = extractPicklistValues(fieldDescribe);
                
                // Check for controlling/dependent relationships
                profile.isDependentPicklist = fieldDescribe.isDependentPicklist();
                if (profile.isDependentPicklist) {
                    Schema.SObjectField controller = fieldDescribe.getController();
                    if (controller != null) {
                        profile.controllerField = controller.getDescribe().getName();
                    }
                }
                
                profiles.add(profile);
            }
        }
        
        return profiles;
    }
    
    /**
     * @description Extract picklist values from field describe
     * @param fieldDescribe Field describe result
     * @return List of picklist value metadata
     */
    private static List<PicklistValueMetadata> extractPicklistValues(
        Schema.DescribeFieldResult fieldDescribe
    ) {
        List<PicklistValueMetadata> values = new List<PicklistValueMetadata>();
        List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
        
        Integer order = 1;
        for (Schema.PicklistEntry entry : entries) {
            PicklistValueMetadata valueMetadata = new PicklistValueMetadata();
            valueMetadata.value = entry.getValue();
            valueMetadata.label = entry.getLabel();
            valueMetadata.isActive = entry.isActive();
            valueMetadata.isDefault = entry.isDefaultValue();
            valueMetadata.sortOrder = order++;
            
            values.add(valueMetadata);
        }
        
        return values;
    }
}
```

**What You Get from Step 1**:
- Field basics: type, label, help text, required
- All picklist values: value, label, active, default, order
- Dependency relationships: controlling field reference

**What You DON'T Get** (needs Layer 2):
- OpportunityStage probability mapping
- CaseStatus IsClosed flag
- LeadStatus IsConverted flag
- Record-type-specific availability

---

### Step 2: Handle Record Types (UI API via Callout)

**Goal**: Get record-type-specific picklist values

**Why This Matters**:
- Some picklist values are only available for certain record types
- Describe API gives you "universe of values" but not per-record-type availability

**Implementation** (`RecordTypePicklistEnricher.cls`):

```apex
public class RecordTypePicklistEnricher {
    
    /**
     * @description Get record-type-specific picklist values via UI API
     * @param objectApiName Object API name
     * @param fieldApiName Field API name
     * @return Map of RecordTypeId to available values
     */
    public static Map<String, List<String>> getRecordTypePicklistValues(
        String objectApiName,
        String fieldApiName
    ) {
        Map<String, List<String>> recordTypeValues = new Map<String, List<String>>();
        
        // Query active record types
        List<RecordType> recordTypes = [
            SELECT Id, DeveloperName, Name
            FROM RecordType
            WHERE SObjectType = :objectApiName
            AND IsActive = true
        ];
        
        // For each record type, call UI API to get available values
        for (RecordType rt : recordTypes) {
            String endpoint = '/services/data/v60.0/ui-api/object-info/' + 
                            objectApiName + '/picklist-values/' + 
                            rt.Id + '/' + fieldApiName;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SalesforceOrgAPI' + endpoint);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = 
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                List<String> availableValues = parseUIAPIPicklistResponse(responseData);
                recordTypeValues.put(rt.Id, availableValues);
            }
        }
        
        return recordTypeValues;
    }
    
    private static List<String> parseUIAPIPicklistResponse(Map<String, Object> responseData) {
        List<String> values = new List<String>();
        Map<String, Object> picklistData = 
            (Map<String, Object>) responseData.get('values');
        
        if (picklistData != null) {
            for (String value : picklistData.keySet()) {
                Map<String, Object> valueData = 
                    (Map<String, Object>) picklistData.get(value);
                if ((Boolean) valueData.get('validFor') == true) {
                    values.add((String) valueData.get('value'));
                }
            }
        }
        
        return values;
    }
}
```

**Important**: This requires a **Named Credential** pointing to your own org:
- Name: `SalesforceOrgAPI`
- URL: `https://your-instance.salesforce.com`
- Identity Type: Named Principal (OAuth)
- Authentication: OAuth 2.0

---

### Step 3: Detect "Special Picklists" (Registry Pattern)

**Goal**: Identify fields that have extra attributes beyond basic picklist metadata

**Known Special Fields**:
- `Opportunity.StageName` → DefaultProbability, ForecastCategory, IsClosed
- `Case.Status` → IsClosed
- `Lead.Status` → IsConverted

**Implementation** (`SpecialPicklistRegistry.cls`):

```apex
public class SpecialPicklistRegistry {
    
    private static final Map<String, SpecialPicklistType> REGISTRY = 
        new Map<String, SpecialPicklistType>{
            'Opportunity.StageName' => SpecialPicklistType.OPPORTUNITY_STAGE,
            'Case.Status' => SpecialPicklistType.CASE_STATUS,
            'Lead.Status' => SpecialPicklistType.LEAD_STATUS
        };
    
    public enum SpecialPicklistType {
        OPPORTUNITY_STAGE,
        CASE_STATUS,
        LEAD_STATUS
    }
    
    /**
     * @description Check if a field is a "special picklist" with extra attributes
     * @param objectApiName Object API name
     * @param fieldApiName Field API name
     * @return SpecialPicklistType enum if special, null otherwise
     */
    public static SpecialPicklistType getSpecialType(
        String objectApiName,
        String fieldApiName
    ) {
        String key = objectApiName + '.' + fieldApiName;
        return REGISTRY.get(key);
    }
    
    /**
     * @description Check if a field is special
     */
    public static Boolean isSpecialPicklist(String objectApiName, String fieldApiName) {
        return getSpecialType(objectApiName, fieldApiName) != null;
    }
}
```

---

### Step 4: Fetch Special Attributes (Tooling API via Callout)

**Goal**: For special picklists, fetch extra attributes that Describe API doesn't provide

#### OpportunityStage Enricher

```apex
public class OpportunityStageEnricher implements ISpecialPicklistEnricher {
    
    /**
     * @description Fetch OpportunityStage metadata from Tooling API
     * @return Map of stage API name to extra attributes
     */
    public Map<String, Map<String, Object>> fetchExtraAttributes() {
        Map<String, Map<String, Object>> stageAttributes = 
            new Map<String, Map<String, Object>>();
        
        // Query OpportunityStage via SOQL (more reliable than Tooling API for this)
        List<OpportunityStage> stages = [
            SELECT ApiName, MasterLabel, DefaultProbability, 
                   IsActive, IsClosed, IsWon, ForecastCategoryName, SortOrder
            FROM OpportunityStage
            WHERE IsActive = true
            ORDER BY SortOrder ASC
        ];
        
        for (OpportunityStage stage : stages) {
            Map<String, Object> attrs = new Map<String, Object>();
            attrs.put('probability', stage.DefaultProbability);
            attrs.put('isClosed', stage.IsClosed);
            attrs.put('isWon', stage.IsWon);
            attrs.put('forecastCategory', stage.ForecastCategoryName);
            attrs.put('sortOrder', stage.SortOrder);
            
            // Use ApiName as key (matches picklist value)
            stageAttributes.put(stage.ApiName, attrs);
        }
        
        return stageAttributes;
    }
}
```

#### CaseStatus Enricher

```apex
public class CaseStatusEnricher implements ISpecialPicklistEnricher {
    
    /**
     * @description Fetch CaseStatus metadata from Tooling API
     * @return Map of status API name to extra attributes
     */
    public Map<String, Map<String, Object>> fetchExtraAttributes() {
        Map<String, Map<String, Object>> statusAttributes = 
            new Map<String, Map<String, Object>>();
        
        // Tooling API query for CaseStatus
        String query = 'SELECT ApiName, MasterLabel, IsClosed ' +
                      'FROM CaseStatus WHERE IsActive = true';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SalesforceOrgAPI/services/data/v60.0/tooling/query?q=' + 
                       EncodingUtil.urlEncode(query, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseData = 
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) responseData.get('records');
            
            for (Object record : records) {
                Map<String, Object> statusRecord = (Map<String, Object>) record;
                String apiName = (String) statusRecord.get('ApiName');
                
                Map<String, Object> attrs = new Map<String, Object>();
                attrs.put('isClosed', statusRecord.get('IsClosed'));
                
                statusAttributes.put(apiName, attrs);
            }
        }
        
        return statusAttributes;
    }
}
```

#### LeadStatus Enricher

```apex
public class LeadStatusEnricher implements ISpecialPicklistEnricher {
    
    /**
     * @description Fetch LeadStatus metadata from Tooling API
     * @return Map of status API name to extra attributes
     */
    public Map<String, Map<String, Object>> fetchExtraAttributes() {
        Map<String, Map<String, Object>> statusAttributes = 
            new Map<String, Map<String, Object>>();
        
        // Tooling API query for LeadStatus
        String query = 'SELECT ApiName, MasterLabel, IsConverted ' +
                      'FROM LeadStatus WHERE IsActive = true';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SalesforceOrgAPI/services/data/v60.0/tooling/query?q=' + 
                       EncodingUtil.urlEncode(query, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseData = 
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) responseData.get('records');
            
            for (Object record : records) {
                Map<String, Object> statusRecord = (Map<String, Object>) record;
                String apiName = (String) statusRecord.get('ApiName');
                
                Map<String, Object> attrs = new Map<String, Object>();
                attrs.put('isConverted', statusRecord.get('IsConverted'));
                
                statusAttributes.put(apiName, attrs);
            }
        }
        
        return statusAttributes;
    }
}
```

---

### Step 5: Custom Picklist Annotations (Custom Metadata)

**Goal**: Allow admins to define extra attributes for custom picklists

**Custom Metadata Type**: `Picklist_Annotation__mdt`

**Fields**:
- `Object_API_Name__c` (Text) - e.g., "CustomObject__c"
- `Field_API_Name__c` (Text) - e.g., "Stage__c"
- `Value__c` (Text) - e.g., "Prospecting"
- `Probability__c` (Number) - Admin-defined probability
- `Weight__c` (Number) - Relative importance
- `Semantic_Tag__c` (Text) - e.g., "early_pipeline", "closing"
- `Synonyms__c` (Long Text) - Comma-separated synonyms
- `AI_Hint__c` (Long Text) - Guidance for LLM interpretation

**Usage**:
```apex
public class CustomPicklistAnnotationLoader {
    
    public static Map<String, Map<String, Object>> loadAnnotations(
        String objectApiName,
        String fieldApiName
    ) {
        Map<String, Map<String, Object>> annotations = 
            new Map<String, Map<String, Object>>();
        
        List<Picklist_Annotation__mdt> mdtRecords = [
            SELECT Value__c, Probability__c, Weight__c, 
                   Semantic_Tag__c, Synonyms__c, AI_Hint__c
            FROM Picklist_Annotation__mdt
            WHERE Object_API_Name__c = :objectApiName
            AND Field_API_Name__c = :fieldApiName
        ];
        
        for (Picklist_Annotation__mdt mdt : mdtRecords) {
            Map<String, Object> attrs = new Map<String, Object>();
            attrs.put('probability', mdt.Probability__c);
            attrs.put('weight', mdt.Weight__c);
            attrs.put('semanticTag', mdt.Semantic_Tag__c);
            attrs.put('synonyms', mdt.Synonyms__c?.split(','));
            attrs.put('aiHint', mdt.AI_Hint__c);
            
            annotations.put(mdt.Value__c, attrs);
        }
        
        return annotations;
    }
}
```

---

### Step 6: Local Cache (Custom Object)

**Goal**: Store enriched picklist metadata for fast SOQL queries at runtime

**Custom Object**: `Picklist_Value_Info__c`

**Fields**:
- `Object_API_Name__c` (Text, External ID)
- `Field_API_Name__c` (Text, External ID)
- `Record_Type_Id__c` (Text, External ID) - nullable
- `Value__c` (Text, External ID)
- `Label__c` (Text)
- `Sort_Order__c` (Number)
- `Is_Active__c` (Checkbox)
- `Is_Default__c` (Checkbox)
- `Controller_Value__c` (Text) - for dependent picklists
- `Probability__c` (Number) - for stages or custom
- `Is_Closed__c` (Checkbox) - for Case/Opportunity stages
- `Is_Converted__c` (Checkbox) - for Lead status
- `Is_Won__c` (Checkbox) - for Opportunity stages
- `Forecast_Category__c` (Text) - for Opportunity stages
- `Semantic_Tag__c` (Text) - admin-defined or derived
- `Extra_Attributes__c` (Long Text) - JSON for extensibility

**Composite External ID**: `Unique_Key__c` = `{Object}.{Field}.{RecordType}.{Value}`

**Why Custom Object over Custom Metadata**:
- ✅ Can be refreshed programmatically via DML
- ✅ Can handle large datasets (thousands of values across hundreds of fields)
- ✅ Can query with complex filters at runtime
- ✅ Can be updated frequently without deployments

---

### Step 7: Sync Job (Scheduled/Queueable)

**Goal**: Periodically refresh the local cache from Salesforce metadata

**Implementation** (`PicklistMetadataSyncJob.cls`):

```apex
public class PicklistMetadataSyncJob implements Queueable, Database.AllowsCallouts {
    
    private List<String> objectsToSync;
    
    public PicklistMetadataSyncJob(List<String> objectsToSync) {
        this.objectsToSync = objectsToSync;
    }
    
    public void execute(QueueableContext context) {
        
        for (String objectApiName : objectsToSync) {
            syncObjectPicklists(objectApiName);
        }
        
        System.debug('Picklist metadata sync completed for: ' + objectsToSync);
    }
    
    private void syncObjectPicklists(String objectApiName) {
        
        // Step 1: Discover picklist fields via Describe
        List<FieldMetadataProfile> profiles = 
            PicklistIntelligenceService.discoverPicklistFields(objectApiName);
        
        List<Picklist_Value_Info__c> cacheRecords = new List<Picklist_Value_Info__c>();
        
        for (FieldMetadataProfile profile : profiles) {
            
            // Step 2: Check if special picklist
            SpecialPicklistRegistry.SpecialPicklistType specialType = 
                SpecialPicklistRegistry.getSpecialType(
                    profile.objectApiName, 
                    profile.fieldApiName
                );
            
            Map<String, Map<String, Object>> extraAttributes = null;
            
            // Step 3: Fetch extra attributes if special
            if (specialType != null) {
                ISpecialPicklistEnricher enricher = 
                    SpecialPicklistEnricherFactory.getEnricher(specialType);
                extraAttributes = enricher.fetchExtraAttributes();
            }
            
            // Step 4: Load custom annotations
            Map<String, Map<String, Object>> annotations = 
                CustomPicklistAnnotationLoader.loadAnnotations(
                    profile.objectApiName,
                    profile.fieldApiName
                );
            
            // Step 5: Merge and create cache records
            for (PicklistValueMetadata valueMetadata : profile.picklistValues) {
                Picklist_Value_Info__c cacheRecord = new Picklist_Value_Info__c();
                cacheRecord.Object_API_Name__c = profile.objectApiName;
                cacheRecord.Field_API_Name__c = profile.fieldApiName;
                cacheRecord.Value__c = valueMetadata.value;
                cacheRecord.Label__c = valueMetadata.label;
                cacheRecord.Sort_Order__c = valueMetadata.sortOrder;
                cacheRecord.Is_Active__c = valueMetadata.isActive;
                cacheRecord.Is_Default__c = valueMetadata.isDefault;
                
                // Merge extra attributes
                if (extraAttributes != null && extraAttributes.containsKey(valueMetadata.value)) {
                    Map<String, Object> attrs = extraAttributes.get(valueMetadata.value);
                    cacheRecord.Probability__c = (Decimal) attrs.get('probability');
                    cacheRecord.Is_Closed__c = (Boolean) attrs.get('isClosed');
                    cacheRecord.Is_Won__c = (Boolean) attrs.get('isWon');
                    cacheRecord.Is_Converted__c = (Boolean) attrs.get('isConverted');
                    cacheRecord.Forecast_Category__c = (String) attrs.get('forecastCategory');
                }
                
                // Merge custom annotations
                if (annotations != null && annotations.containsKey(valueMetadata.value)) {
                    Map<String, Object> annot = annotations.get(valueMetadata.value);
                    if (cacheRecord.Probability__c == null) {
                        cacheRecord.Probability__c = (Decimal) annot.get('probability');
                    }
                    cacheRecord.Semantic_Tag__c = (String) annot.get('semanticTag');
                    
                    // Store extra as JSON
                    cacheRecord.Extra_Attributes__c = JSON.serialize(annot);
                }
                
                // Generate unique key
                cacheRecord.Unique_Key__c = profile.objectApiName + '.' + 
                                           profile.fieldApiName + '.null.' + 
                                           valueMetadata.value;
                
                cacheRecords.add(cacheRecord);
            }
        }
        
        // Upsert to cache (using unique key as external ID)
        if (!cacheRecords.isEmpty()) {
            Database.upsert(cacheRecords, 
                          Picklist_Value_Info__c.Unique_Key__c, 
                          false);
        }
    }
}
```

**Schedule this job**:
```apex
// Run nightly at 2 AM
String cronExp = '0 0 2 * * ?';
System.schedule(
    'Picklist Metadata Sync - Nightly',
    cronExp,
    new PicklistMetadataSyncSchedulable()
);
```

---

### Step 8: Runtime API (What Stage08 Calls)

**Goal**: Fast SOQL query to get enriched picklist metadata for prompt assembly

**Implementation** (`PicklistIntelligenceAPI.cls`):

```apex
public class PicklistIntelligenceAPI {
    
    /**
     * @description Get enriched picklist metadata for a field
     * @param objectApiName Object API name
     * @param fieldApiName Field API name
     * @param recordTypeId Optional record type filter
     * @return Enriched field metadata profile
     */
    public static EnrichedFieldProfile getFieldProfile(
        String objectApiName,
        String fieldApiName,
        String recordTypeId
    ) {
        EnrichedFieldProfile profile = new EnrichedFieldProfile();
        profile.objectApiName = objectApiName;
        profile.fieldApiName = fieldApiName;
        
        // Query cached values
        List<Picklist_Value_Info__c> cachedValues = [
            SELECT Value__c, Label__c, Sort_Order__c, 
                   Is_Active__c, Is_Default__c,
                   Probability__c, Is_Closed__c, Is_Won__c, Is_Converted__c,
                   Forecast_Category__c, Semantic_Tag__c, Extra_Attributes__c
            FROM Picklist_Value_Info__c
            WHERE Object_API_Name__c = :objectApiName
            AND Field_API_Name__c = :fieldApiName
            AND (Record_Type_Id__c = :recordTypeId OR Record_Type_Id__c = NULL)
            AND Is_Active__c = true
            ORDER BY Sort_Order__c ASC
        ];
        
        profile.values = new List<EnrichedPicklistValue>();
        
        for (Picklist_Value_Info__c cached : cachedValues) {
            EnrichedPicklistValue value = new EnrichedPicklistValue();
            value.value = cached.Value__c;
            value.label = cached.Label__c;
            value.sortOrder = Integer.valueOf(cached.Sort_Order__c);
            value.isDefault = cached.Is_Default__c;
            value.probability = cached.Probability__c;
            value.isClosed = cached.Is_Closed__c;
            value.isWon = cached.Is_Won__c;
            value.isConverted = cached.Is_Converted__c;
            value.forecastCategory = cached.Forecast_Category__c;
            value.semanticTag = cached.Semantic_Tag__c;
            
            // Parse extra attributes if present
            if (String.isNotBlank(cached.Extra_Attributes__c)) {
                value.extraAttributes = 
                    (Map<String, Object>) JSON.deserializeUntyped(cached.Extra_Attributes__c);
            }
            
            profile.values.add(value);
        }
        
        profile.totalValues = profile.values.size();
        
        return profile;
    }
    
    /**
     * @description Get context for current value (position in list, stage analysis)
     * @param profile Enriched field profile
     * @param currentValue Current field value
     * @return Context analysis string
     */
    public static String getValueContext(
        EnrichedFieldProfile profile,
        String currentValue
    ) {
        Integer currentPosition = null;
        EnrichedPicklistValue currentValueData = null;
        
        for (Integer i = 0; i < profile.values.size(); i++) {
            if (profile.values[i].value == currentValue) {
                currentPosition = i + 1;
                currentValueData = profile.values[i];
                break;
            }
        }
        
        if (currentPosition == null) {
            return 'Value not found in picklist';
        }
        
        // Build context
        String context = 'Position ' + currentPosition + ' of ' + profile.totalValues;
        
        // Stage analysis
        if (currentPosition <= profile.totalValues / 3) {
            context += ' (EARLY stage)';
        } else if (currentPosition <= 2 * profile.totalValues / 3) {
            context += ' (MID stage)';
        } else {
            context += ' (LATE stage)';
        }
        
        // Add probability if available
        if (currentValueData.probability != null) {
            context += '. Expected probability: ' + currentValueData.probability + '%';
        }
        
        // Add semantic tag if available
        if (String.isNotBlank(currentValueData.semanticTag)) {
            context += '. Semantic: ' + currentValueData.semanticTag;
        }
        
        return context;
    }
}
```

**Usage in Stage08**:
```apex
// In buildFieldContextSection()
EnrichedFieldProfile profile = PicklistIntelligenceAPI.getFieldProfile(
    'Opportunity',
    'StageName',
    null
);

String currentStage = (String) dataPayload.get('StageName');
String context = PicklistIntelligenceAPI.getValueContext(profile, currentStage);

// Build prompt section
contextBlock.append('FIELD: Opportunity.StageName\n');
contextBlock.append('Current Value: "' + currentStage + '"\n');
contextBlock.append('Context: ' + context + '\n\n');

contextBlock.append('Available Values (' + profile.totalValues + ' total):\n');
for (EnrichedPicklistValue value : profile.values) {
    String marker = (value.value == currentStage) ? ' ← CURRENT' : '';
    contextBlock.append('  ' + value.sortOrder + '. ' + value.value);
    if (value.probability != null) {
        contextBlock.append(' (' + value.probability + '% probability)');
    }
    contextBlock.append(marker + '\n');
}
```

---

## Common Gotchas & Solutions

### Gotcha 1: Global Value Sets

**Problem**: Some picklists use Global Value Sets (shared across fields)

**Solution**: Cache still keys by `{Object}.{Field}`, but you can optimize sync by detecting Global Value Set usage via Describe and caching the value set separately

---

### Gotcha 2: Inactive Values

**Problem**: Records may have inactive picklist values that don't show in Describe for new records

**Solution**: Store inactive values in cache with `Is_Active__c = false`, but filter them out in runtime queries unless specifically requested

---

### Gotcha 3: Labels vs Values

**Problem**: Labels can be translated/changed, but values are stable

**Solution**: Always use **API Value** as the join key, not Label

---

### Gotcha 4: Probability Override

**Problem**: Opportunity.Probability on records can differ from stage default

**Solution**: Your AI needs both:
- Default probability (from cache/OpportunityStage)
- Actual probability (from SOQL on Opportunity record)

Include both in prompt:
```
Stage: Negotiation (80% default probability)
Actual Probability: 65% (15 points below stage default - concern)
```

---

### Gotcha 5: Dependent Picklists

**Problem**: Dependent picklists have complex controller→valid dependents logic

**Solution**: 
- Store `Controller_Value__c` on cache records
- UI API provides this data cleanly during sync
- For runtime, query cache with controller value filter

---

## Integration with Stage05 & Stage08

### Stage05: Field Selection

**Update**: After selecting fields, flag which are picklists and trigger sync if needed

```apex
// In Stage05_FieldSelection.cls
public StageResult execute(Id runId, Map<String, Object> inputs) {
    // ... existing field selection logic ...
    
    // NEW: Identify picklist fields
    Set<String> objectsNeedingSync = new Set<String>();
    for (String objectName : selectedFields.keySet()) {
        List<String> fields = selectedFields.get(objectName);
        
        for (String fieldName : fields) {
            if (isPicklistField(objectName, fieldName)) {
                objectsNeedingSync.add(objectName);
            }
        }
    }
    
    // Trigger sync if cache is stale or missing
    if (!objectsNeedingSync.isEmpty()) {
        System.enqueueJob(new PicklistMetadataSyncJob(
            new List<String>(objectsNeedingSync)
        ));
    }
    
    // ... rest of logic ...
}
```

---

### Stage08: Prompt Assembly

**Update**: Query enriched picklist metadata and inject as field context

```apex
// In Stage08_PromptAssembly.cls
private String buildFieldContextSection(
    Map<String, List<String>> selectedFields,
    Map<String, Object> dataPayload
) {
    StringBuilder context = new StringBuilder();
    context.append('=== FIELD CONTEXT ===\n\n');
    
    for (String objectName : selectedFields.keySet()) {
        for (String fieldName : selectedFields.get(objectName)) {
            
            // Check if field is picklist
            if (isPicklistField(objectName, fieldName)) {
                
                // Get enriched metadata
                EnrichedFieldProfile profile = 
                    PicklistIntelligenceAPI.getFieldProfile(
                        objectName,
                        fieldName,
                        null
                    );
                
                // Get current value from data
                String currentValue = (String) dataPayload.get(fieldName);
                
                // Build context block
                context.append('FIELD: ' + objectName + '.' + fieldName + '\n');
                context.append('Current Value: "' + currentValue + '"\n');
                context.append('Context: ' + 
                    PicklistIntelligenceAPI.getValueContext(profile, currentValue) + '\n\n');
                
                context.append('Available Values (' + profile.totalValues + ' total):\n');
                for (EnrichedPicklistValue value : profile.values) {
                    String marker = (value.value == currentValue) ? ' ← CURRENT' : '';
                    context.append('  ' + value.sortOrder + '. ' + value.value);
                    if (value.probability != null) {
                        context.append(' (' + value.probability + '%)');
                    }
                    context.append(marker + '\n');
                }
                context.append('\n---\n\n');
            }
        }
    }
    
    return context.toString();
}
```

---

## Testing Strategy

### Unit Tests

```apex
@IsTest
private class PicklistIntelligenceArchitecture_Test {
    
    @TestSetup
    static void setup() {
        // Create test cache records
        List<Picklist_Value_Info__c> testData = new List<Picklist_Value_Info__c>();
        
        // Opportunity stages
        testData.add(createCacheRecord('Opportunity', 'StageName', 'Qualification', 1, 10));
        testData.add(createCacheRecord('Opportunity', 'StageName', 'Needs Analysis', 2, 20));
        testData.add(createCacheRecord('Opportunity', 'StageName', 'Negotiation', 3, 80));
        
        insert testData;
    }
    
    @IsTest
    static void testGetFieldProfile() {
        EnrichedFieldProfile profile = PicklistIntelligenceAPI.getFieldProfile(
            'Opportunity',
            'StageName',
            null
        );
        
        Assert.areEqual(3, profile.totalValues);
        Assert.areEqual('Qualification', profile.values[0].value);
        Assert.areEqual(10, profile.values[0].probability);
    }
    
    @IsTest
    static void testGetValueContext() {
        EnrichedFieldProfile profile = PicklistIntelligenceAPI.getFieldProfile(
            'Opportunity',
            'StageName',
            null
        );
        
        String context = PicklistIntelligenceAPI.getValueContext(profile, 'Needs Analysis');
        
        Assert.isTrue(context.contains('Position 2 of 3'));
        Assert.isTrue(context.contains('MID stage'));
        Assert.isTrue(context.contains('20%'));
    }
    
    private static Picklist_Value_Info__c createCacheRecord(
        String obj, String field, String value, Integer order, Decimal prob
    ) {
        return new Picklist_Value_Info__c(
            Object_API_Name__c = obj,
            Field_API_Name__c = field,
            Value__c = value,
            Label__c = value,
            Sort_Order__c = order,
            Is_Active__c = true,
            Probability__c = prob,
            Unique_Key__c = obj + '.' + field + '.null.' + value
        );
    }
}
```

---

## Deployment Checklist

**1. Create Custom Object**:
- [ ] `Picklist_Value_Info__c` with all fields
- [ ] External ID on `Unique_Key__c`

**2. Create Custom Metadata Type**:
- [ ] `Picklist_Annotation__mdt` for admin annotations

**3. Create Named Credential**:
- [ ] `SalesforceOrgAPI` pointing to your org
- [ ] OAuth setup with API access

**4. Deploy Apex Classes**:
- [ ] `PicklistIntelligenceService`
- [ ] `SpecialPicklistRegistry`
- [ ] `OpportunityStageEnricher`, `CaseStatusEnricher`, `LeadStatusEnricher`
- [ ] `CustomPicklistAnnotationLoader`
- [ ] `PicklistMetadataSyncJob`
- [ ] `PicklistIntelligenceAPI`

**5. Schedule Sync Job**:
- [ ] Schedule nightly refresh
- [ ] Run initial sync manually

**6. Update Stage05 & Stage08**:
- [ ] Integrate picklist detection in Stage05
- [ ] Integrate field context building in Stage08

**7. Test**:
- [ ] Unit tests for all components
- [ ] Integration test with real Opportunity
- [ ] Validate prompt output contains enriched context

---

**Document Created**: January 22, 2026  
**Based On**: User technical guidance on Salesforce metadata extraction  
**Status**: Implementation Blueprint Ready  
**Estimated Implementation Effort**: 16-20 hours
