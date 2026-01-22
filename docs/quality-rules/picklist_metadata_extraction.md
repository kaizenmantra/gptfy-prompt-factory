# Picklist Metadata Extraction

**Version**: 1.0  
**Purpose**: Extract picklist metadata to provide LLM with relative context  
**Priority**: HIGH (replaces stage_normalization approach)  
**Author**: Based on user insight (Jan 22, 2026)  
**Implementation Details**: See [`picklist_intelligence_architecture.md`](./picklist_intelligence_architecture.md)

---

## Document Purpose

This document explains **WHY** picklist metadata extraction is valuable and **WHAT** benefits it provides.

For **HOW** to implement it (detailed architecture, code samples, sync jobs), see:
**→ [`picklist_intelligence_architecture.md`](./picklist_intelligence_architecture.md)**

---

## The Problem

**Current State (Blind LLM)**:
```
Data sent to LLM:
- Opportunity.StageName = "Needs Analysis"
- Opportunity.Probability = 20%

LLM reasoning:
"Is 20% probability low? Let me guess based on the English meaning 
of 'Needs Analysis'... sounds early? Maybe it's a risk?"
```

**What's Missing**: The LLM has **zero context** about:
- Is "Needs Analysis" stage 2 of 6 or stage 5 of 6?
- What probability is *normal* for this stage?
- Is this customer's first stage or middle stage?

**Result**: False positives ("20% is too low!") when it's actually appropriate for the stage.

---

## The Solution: Send Picklist Metadata

**New Approach**:
```
Data sent to LLM:
{
  "currentData": {
    "StageName": "Needs Analysis",
    "Probability": 20
  },
  "fieldMetadata": {
    "StageName": {
      "type": "picklist",
      "currentValue": "Needs Analysis",
      "allValues": [
        {"value": "Qualification", "probability": 10, "order": 1},
        {"value": "Needs Analysis", "probability": 20, "order": 2},  ← YOU ARE HERE
        {"value": "Value Proposition", "probability": 40, "order": 3},
        {"value": "Decision Making", "probability": 60, "order": 4},
        {"value": "Negotiation", "probability": 80, "order": 5},
        {"value": "Closed Won", "probability": 100, "order": 6}
      ],
      "analysis": "Stage 2 of 6 (early stage). Expected probability: 20%. NORMAL."
    }
  }
}
```

**LLM reasoning**:
"This is stage 2 of 6 (early qualification). The 20% probability matches 
the expected value for this stage. ✓ NORMAL - not a risk indicator."

---

## Why This Approach Is Superior

### 1. Data-Driven (Not Hardcoded)

**Old Approach** (what we considered):
```markdown
# stage_normalization.md

HARDCODED RULES:
- Qualification: 10-25% is normal
- Needs Analysis: 15-30% is normal
- Proposal: 40-60% is normal
```

**Problems**:
- ❌ Assumes everyone uses standard stage names
- ❌ Breaks if customer renames "Qualification" to "Discovery"
- ❌ Requires maintenance when stages change
- ❌ Doesn't respect customer-specific configurations

**New Approach** (picklist metadata):
```apex
// Extract actual picklist values from THIS org
List<Schema.PicklistEntry> stages = 
    Opportunity.StageName.getDescribe().getPicklistValues();

// Query OpportunityStage for probability mapping
List<OpportunityStage> stageConfig = [
    SELECT ApiName, DefaultProbability, SortOrder 
    FROM OpportunityStage 
    WHERE IsActive = true 
    ORDER BY SortOrder
];
```

**Benefits**:
- ✅ Respects customer's actual stage names
- ✅ Uses customer's actual probability mapping
- ✅ Works with custom stages (e.g., "Technical Validation", "Legal Review")
- ✅ Self-maintaining (updates when customer changes stages)

---

### 2. Customer-Specific Configuration

**Example**: Healthcare Payer vs Enterprise Software

**Healthcare Payer Opportunity Stages**:
```
1. Initial Contact (5%)
2. Needs Assessment (10%)
3. Stakeholder Alignment (20%)
4. Technical Review (40%)
5. Legal & Compliance (60%)
6. Contract Negotiation (80%)
7. Signature (95%)
8. Closed Won (100%)
```

**Enterprise Software Opportunity Stages**:
```
1. Qualification (20%)
2. Discovery (30%)
3. Proposal (50%)
4. Negotiation (75%)
5. Closed Won (100%)
```

**With Hardcoded Rules**: LLM doesn't understand "Stakeholder Alignment" or "Legal & Compliance"

**With Picklist Metadata**: LLM sees these are stages 3 and 5 of 8, with expected probabilities

---

### 3. Works for ANY Picklist Field

This pattern isn't just for `Opportunity.StageName`—it works for **all picklist fields**:

**Priority Field**:
```
Priority: "High" (current)
Available values: ["Low", "Medium", "High", "Critical"]
Analysis: "High" is 3rd of 4 severity levels - significant but not maximum
```

**Lead Status**:
```
Status: "Qualified" (current)
Available values: ["New", "Working", "Qualified", "Unqualified", "Nurturing"]
Analysis: "Qualified" is a positive progression state - ready for conversion
```

**Case Status**:
```
Status: "In Progress" (current)
Available values: ["New", "In Progress", "Escalated", "Resolved", "Closed"]
Analysis: "In Progress" is active work state - not yet escalated or resolved
```

---

## Implementation Plan

### Stage 1: Enhance Stage05 (Field Selection)

**Goal**: When selecting fields, also extract picklist metadata

**Location**: `Stage05_FieldSelection.cls`

**New Method**:
```apex
/**
 * @description Extract picklist metadata for a field
 * @param objectName API name of the object
 * @param fieldName API name of the field
 * @return Map<String, Object> containing picklist metadata
 */
private Map<String, Object> extractPicklistMetadata(String objectName, String fieldName) {
    Map<String, Object> metadata = new Map<String, Object>();
    
    try {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.SObjectField field = objDescribe.fields.getMap().get(fieldName);
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        
        // Check if field is a picklist
        Schema.DisplayType fieldType = fieldDescribe.getType();
        if (fieldType == Schema.DisplayType.PICKLIST || 
            fieldType == Schema.DisplayType.MULTIPICKLIST) {
            
            metadata.put('type', 'picklist');
            metadata.put('fieldName', fieldName);
            
            // Extract picklist values
            List<Map<String, Object>> picklistValues = new List<Map<String, Object>>();
            List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
            
            Integer order = 1;
            for (Schema.PicklistEntry entry : entries) {
                if (entry.isActive()) {
                    Map<String, Object> valueMap = new Map<String, Object>();
                    valueMap.put('value', entry.getValue());
                    valueMap.put('label', entry.getLabel());
                    valueMap.put('order', order);
                    valueMap.put('isDefault', entry.isDefaultValue());
                    picklistValues.add(valueMap);
                    order++;
                }
            }
            
            metadata.put('values', picklistValues);
            metadata.put('totalValues', picklistValues.size());
            
            // Special handling for Opportunity.StageName
            if (objectName == 'Opportunity' && fieldName == 'StageName') {
                metadata.put('probabilityMapping', getOpportunityStageMapping());
            }
        }
        
    } catch (Exception e) {
        System.debug('Error extracting picklist metadata: ' + e.getMessage());
    }
    
    return metadata;
}
```

**Helper Method for OpportunityStage Mapping**:
```apex
/**
 * @description Get Opportunity Stage to Probability mapping
 * @return List<Map<String, Object>> with stage details
 */
private List<Map<String, Object>> getOpportunityStageMapping() {
    List<Map<String, Object>> stageMapping = new List<Map<String, Object>>();
    
    try {
        // Query OpportunityStage object for probability mapping
        List<OpportunityStage> stages = [
            SELECT ApiName, MasterLabel, DefaultProbability, 
                   IsActive, IsClosed, IsWon, SortOrder
            FROM OpportunityStage
            WHERE IsActive = true
            ORDER BY SortOrder ASC
        ];
        
        for (OpportunityStage stage : stages) {
            Map<String, Object> stageData = new Map<String, Object>();
            stageData.put('stageName', stage.MasterLabel);
            stageData.put('apiName', stage.ApiName);
            stageData.put('probability', stage.DefaultProbability);
            stageData.put('sortOrder', stage.SortOrder);
            stageData.put('isClosed', stage.IsClosed);
            stageData.put('isWon', stage.IsWon);
            stageMapping.add(stageData);
        }
        
    } catch (Exception e) {
        System.debug('Error querying OpportunityStage: ' + e.getMessage());
    }
    
    return stageMapping;
}
```

**Integration into Field Selection**:
```apex
// After selecting fields, extract picklist metadata
Map<String, List<String>> selectedFields = /* field selection logic */;
Map<String, Map<String, Object>> fieldMetadata = new Map<String, Map<String, Object>>();

for (String objectName : selectedFields.keySet()) {
    for (String fieldName : selectedFields.get(objectName)) {
        String metadataKey = objectName + '.' + fieldName;
        Map<String, Object> metadata = extractPicklistMetadata(objectName, fieldName);
        
        if (!metadata.isEmpty()) {
            fieldMetadata.put(metadataKey, metadata);
        }
    }
}

// Store in outputs
result.outputs.put('selectedFields', selectedFields);
result.outputs.put('fieldMetadata', fieldMetadata);  // NEW
```

---

### Stage 2: Update Stage08 (Prompt Assembly)

**Goal**: Inject picklist metadata into the prompt as context

**Location**: `Stage08_PromptAssembly.cls`

**New Section in Prompt**:
```apex
/**
 * @description Build field context section with picklist metadata
 * @param fieldMetadata Map of field metadata from Stage05
 * @param dataPayload Current record data
 * @return String formatted field context block
 */
private String buildFieldContextSection(
    Map<String, Map<String, Object>> fieldMetadata, 
    Map<String, Object> dataPayload
) {
    StringBuilder contextBlock = new StringBuilder();
    contextBlock.append('=== FIELD CONTEXT ===\n\n');
    contextBlock.append('The following fields are picklists. You have the full list of ');
    contextBlock.append('available values to understand relative positioning and meaning.\n\n');
    
    for (String fieldKey : fieldMetadata.keySet()) {
        Map<String, Object> metadata = fieldMetadata.get(fieldKey);
        
        if (metadata.get('type') == 'picklist') {
            String fieldName = (String) metadata.get('fieldName');
            List<Map<String, Object>> values = 
                (List<Map<String, Object>>) metadata.get('values');
            Integer totalValues = (Integer) metadata.get('totalValues');
            
            // Get current value from data payload
            String currentValue = (String) dataPayload.get(fieldName);
            
            contextBlock.append('FIELD: ' + fieldKey + '\n');
            contextBlock.append('Current Value: "' + currentValue + '"\n');
            contextBlock.append('Available Values (' + totalValues + ' total):\n');
            
            // List all values with special handling for Opportunity.StageName
            Integer currentPosition = 0;
            for (Integer i = 0; i < values.size(); i++) {
                Map<String, Object> valueMap = values[i];
                String value = (String) valueMap.get('value');
                Integer order = (Integer) valueMap.get('order');
                
                String marker = '';
                if (value == currentValue) {
                    marker = ' ← CURRENT';
                    currentPosition = order;
                }
                
                // Check for probability mapping (OpportunityStage)
                if (fieldKey == 'Opportunity.StageName' && 
                    metadata.containsKey('probabilityMapping')) {
                    
                    List<Map<String, Object>> probMapping = 
                        (List<Map<String, Object>>) metadata.get('probabilityMapping');
                    
                    for (Map<String, Object> stage : probMapping) {
                        if (stage.get('stageName') == value) {
                            Decimal prob = (Decimal) stage.get('probability');
                            Boolean isClosed = (Boolean) stage.get('isClosed');
                            contextBlock.append('  ' + order + '. ' + value + 
                                              ' (' + prob + '% probability)');
                            if (isClosed) contextBlock.append(' [CLOSED STAGE]');
                            contextBlock.append(marker + '\n');
                            break;
                        }
                    }
                } else {
                    contextBlock.append('  ' + order + '. ' + value + marker + '\n');
                }
            }
            
            // Add analysis for current position
            if (currentPosition > 0) {
                contextBlock.append('\nAnalysis: ');
                if (currentPosition <= totalValues / 3) {
                    contextBlock.append('This is an EARLY stage ');
                } else if (currentPosition <= 2 * totalValues / 3) {
                    contextBlock.append('This is a MID stage ');
                } else {
                    contextBlock.append('This is a LATE stage ');
                }
                contextBlock.append('(position ' + currentPosition + ' of ' + 
                                  totalValues + ').\n');
                
                // Special note for Opportunity.StageName
                if (fieldKey == 'Opportunity.StageName') {
                    contextBlock.append('IMPORTANT: When evaluating probability, ');
                    contextBlock.append('consider the expected probability for this stage. ');
                    contextBlock.append('A "low" probability may be NORMAL for an early stage.\n');
                }
            }
            
            contextBlock.append('\n---\n\n');
        }
    }
    
    return contextBlock.toString();
}
```

**Integration into Final Prompt**:
```apex
String finalPrompt = 
    businessContext +
    '\n\n' + buildFieldContextSection(fieldMetadata, dataPayload) +  // NEW
    '\n\n' + evidenceBindingRules +
    '\n\n' + informationHierarchyRules +
    '\n\n' + analyticalPatterns +
    '\n\n' + dataPayload;
```

---

### Example Output in Prompt

**For a Healthcare Payer Opportunity**:

```
=== FIELD CONTEXT ===

The following fields are picklists. You have the full list of available 
values to understand relative positioning and meaning.

FIELD: Opportunity.StageName
Current Value: "Needs Assessment"
Available Values (7 total):
  1. Initial Contact (5% probability)
  2. Needs Assessment (10% probability) ← CURRENT
  3. Stakeholder Alignment (20% probability)
  4. Technical Review (40% probability)
  5. Legal & Compliance (60% probability)
  6. Contract Negotiation (80% probability)
  7. Closed Won (100% probability) [CLOSED STAGE]

Analysis: This is an EARLY stage (position 2 of 7).
IMPORTANT: When evaluating probability, consider the expected probability 
for this stage. A "low" probability may be NORMAL for an early stage.

---

FIELD: Opportunity.Priority__c
Current Value: "High"
Available Values (4 total):
  1. Low
  2. Medium
  3. High ← CURRENT
  4. Critical

Analysis: This is a LATE stage (position 3 of 4).

---
```

**LLM Reasoning with This Context**:
```
"I see this opportunity is in 'Needs Assessment', which is stage 2 of 7 
(early qualification). The probability is 10%, which matches the expected 
probability for this stage. This is NORMAL. 

However, I also notice the Priority is 'High' (3 of 4), which suggests 
strategic importance. And the CloseDate is 67 days away—that's aggressive 
for an early-stage deal with 6 more stages to progress through.

DIAGNOSIS: Timeline risk due to ambitious close date, NOT probability risk."
```

---

## Benefits Summary

### 1. Eliminates False Positives

**Before** (no context):
```
❌ "20% probability is concerningly low"
```

**After** (with picklist context):
```
✅ "20% probability is appropriate for stage 2 of 6 (early qualification)"
```

---

### 2. Enables Stage-Aware Analysis

**Timeline Analysis**:
```
"With 67 days to close and currently in stage 2 of 6, this deal would 
need to progress through 4 remaining stages averaging 17 days each. 
Stage 5 (Legal & Compliance) typically takes 30+ days alone. 
RECOMMENDATION: Extend close date or identify critical path shortcuts."
```

**Velocity Analysis**:
```
"Opportunity has been in 'Technical Review' (stage 4 of 7) for 45 days. 
Expected duration for this stage is 21 days based on historical data. 
This is 2x the normal velocity. RECOMMENDATION: Identify blockers."
```

---

### 3. Customer-Specific Intelligence

**Standard Org** (5 stages):
```
Stage 3 of 5 = "mid-stage"
```

**Complex Enterprise Org** (10 stages):
```
Stage 3 of 10 = "early-stage"
```

Same stage name, different meaning. Picklist metadata provides the truth.

---

### 4. Future-Proof

When customers add/remove/rename stages, the system automatically adapts:

**Customer Action**: Adds new stage "Security Review" between "Technical Review" and "Legal & Compliance"

**System Response**: 
- Next prompt automatically includes new stage in context
- LLM understands this is now stage 5 of 8 (not stage 4 of 7)
- No code changes required

---

## Implementation Checklist

### Phase 1: Core Infrastructure (Sprint 1)

- [ ] Update `Stage05_FieldSelection.cls`:
  - [ ] Add `extractPicklistMetadata()` method
  - [ ] Add `getOpportunityStageMapping()` method
  - [ ] Store `fieldMetadata` in outputs alongside `selectedFields`

- [ ] Update `Stage08_PromptAssembly.cls`:
  - [ ] Add `buildFieldContextSection()` method
  - [ ] Inject field context block into final prompt
  - [ ] Position after business context, before analytical patterns

- [ ] Write Tests:
  - [ ] Test picklist metadata extraction (standard picklist)
  - [ ] Test OpportunityStage mapping extraction
  - [ ] Test prompt assembly with field context
  - [ ] Test with custom picklist fields

---

### Phase 2: Enhanced Features (Sprint 2)

- [ ] **Historical Velocity Benchmarking**:
  - Query closed-won opportunities
  - Calculate average days-in-stage for each stage
  - Include in field context: "Typical duration: 21 days"

- [ ] **Stage Progression Validation**:
  - Detect if stages were skipped (e.g., went from stage 2 to stage 5)
  - Flag as anomaly in field context

- [ ] **Multi-Picklist Support**:
  - Handle fields like `Industry__c` (multi-select)
  - Show selected values + available options

---

### Phase 3: Advanced Intelligence (Future)

- [ ] **Win Rate by Stage**:
  - Calculate: "Opportunities at this stage have 65% win rate"
  - Include in field context

- [ ] **Stage Duration Alerts**:
  - "This opportunity has been in 'Negotiation' for 45 days, 
     which is 2x the average duration for this stage"

- [ ] **Picklist Value Sentiment Analysis**:
  - Detect negative values: "Unqualified", "Lost", "Rejected"
  - Positive values: "Qualified", "Won", "Approved"
  - Include sentiment hint in context

---

## Testing Strategy

### Unit Tests

```apex
@IsTest
private class PicklistMetadataExtraction_Test {
    
    @IsTest
    static void testExtractOpportunityStageMetadata() {
        // Test extracting StageName picklist
        Map<String, Object> metadata = 
            Stage05_FieldSelection.extractPicklistMetadata('Opportunity', 'StageName');
        
        Assert.areEqual('picklist', metadata.get('type'));
        Assert.isTrue(metadata.containsKey('probabilityMapping'));
        
        List<Map<String, Object>> values = 
            (List<Map<String, Object>>) metadata.get('values');
        Assert.isTrue(values.size() > 0);
    }
    
    @IsTest
    static void testOpportunityStageProbabilityMapping() {
        // Test OpportunityStage query
        List<Map<String, Object>> mapping = 
            Stage05_FieldSelection.getOpportunityStageMapping();
        
        Assert.isTrue(mapping.size() > 0);
        
        // Verify structure
        Map<String, Object> firstStage = mapping[0];
        Assert.isTrue(firstStage.containsKey('stageName'));
        Assert.isTrue(firstStage.containsKey('probability'));
        Assert.isTrue(firstStage.containsKey('sortOrder'));
    }
    
    @IsTest
    static void testFieldContextPromptGeneration() {
        // Create test metadata
        Map<String, Map<String, Object>> fieldMetadata = new Map<String, Map<String, Object>>();
        // ... populate test data ...
        
        // Create test data payload
        Map<String, Object> dataPayload = new Map<String, Object>();
        dataPayload.put('StageName', 'Negotiation');
        
        // Generate field context block
        String contextBlock = Stage08_PromptAssembly.buildFieldContextSection(
            fieldMetadata, dataPayload
        );
        
        Assert.isTrue(contextBlock.contains('FIELD CONTEXT'));
        Assert.isTrue(contextBlock.contains('Negotiation'));
        Assert.isTrue(contextBlock.contains('CURRENT'));
    }
}
```

---

## Success Metrics

### Before Implementation (Current State)

**False Positive Rate**: ~30% (probability flagged as risk when it's stage-appropriate)

**User Feedback**: "Why is the AI saying 20% is low when this is an early-stage deal?"

**LLM Reasoning**: Guessing based on English semantics

---

### After Implementation (Expected)

**False Positive Rate**: <5% (only flag if probability diverges from stage default)

**User Feedback**: "AI correctly understands this is normal for early stage"

**LLM Reasoning**: Data-driven analysis based on actual org configuration

---

## Conclusion

This picklist metadata extraction approach is **superior** to hardcoded stage normalization rules because:

1. ✅ **Data-Driven**: Uses actual org configuration, not assumptions
2. ✅ **Customer-Specific**: Respects custom stage names and mappings
3. ✅ **Future-Proof**: Automatically adapts when stages change
4. ✅ **Generalizable**: Works for ANY picklist field, not just stages
5. ✅ **Low Maintenance**: No hardcoded rules to update

**Recommendation**: Implement in Sprint 1 alongside evidence binding and information hierarchy rules.

---

**Document Created**: January 22, 2026  
**Based On**: User insight about picklist context  
**Priority**: HIGH  
**Status**: Ready for Implementation
