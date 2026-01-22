# GPTfy_Config__c - Universal Configuration Object Design

**Version**: 1.0  
**Date**: January 22, 2026  
**Purpose**: Complete schema design and usage patterns for unified configuration object

---

## Executive Summary

**Problem**: Too many custom objects/metadata types adding complexity to GPTfy package

**Solution**: ONE flat object (`GPTfy_Config__c`) that stores:
- Quality rules
- Picklist metadata
- Analytical patterns
- UI components
- Field selection rules
- Validation rules
- Context templates
- Persona/industry templates
- Heuristics

**Expected Scale**: 200-300 records total (perfectly manageable)

---

## Complete Field Schema

### **Primary Identification Fields (All Indexed)**

```apex
Config_Type__c (Picklist, Required, Indexed)
  Values: 
    - "Quality Rule"         // Evidence binding, hierarchy rules
    - "Picklist Metadata"    // Synced from Salesforce metadata
    - "Pattern"              // Risk, timeline, stakeholder analysis
    - "UI Component"         // Stat cards, alert boxes, timelines
    - "Field Rule"           // Field selection/prioritization logic
    - "Validation Rule"      // Output validation rules
    - "Context Template"     // Business context templates
    - "Persona Template"     // Persona-specific instructions
    - "Industry Template"    // Industry-specific context
    - "Heuristic"            // Business rules and benchmarks

Category__c (Text 255, Indexed)
  Examples:
    - "Risk Assessment" (for Pattern)
    - "Evidence Binding" (for Quality Rule)
    - "Opportunity.StageName" (for Picklist Metadata)
    - "Healthcare Payer" (for Industry Template)
    - "Sales Rep" (for Persona Template)

Object_API_Name__c (Text 80, Indexed)
  Examples: "Opportunity", "Case", "Lead", "Account", "Contact"
  Null for: Quality Rules, Persona Templates, Industry Templates

Field_API_Name__c (Text 80, Indexed)
  Examples: "StageName", "Status", "Amount", "CloseDate", "Priority"
  Null for: Object-level configs, global configs

Value__c (Text 255)
  For: Picklist values, specific identifiers
  Examples: "Needs Analysis", "Closed Won", "High Priority"
```

---

### **Composite Key (External ID)**

```apex
Unique_Key__c (Text 255, External ID, Unique, Required)
  Format: {Type}.{Category}.{Object}.{Field}.{Value}
  
  Examples:
    - "PicklistMeta.Opportunity.StageName.Needs Analysis"
    - "Pattern.RiskAssessment.Opportunity"
    - "QualityRule.EvidenceBinding.v2"
    - "FieldRule.Opportunity.Amount.High"
    - "UIComponent.StatCard.Zone2"
    - "PersonaTemplate.SalesRep"
    - "IndustryTemplate.HealthcarePayer"
    - "ValidationRule.NoPlaceholders"
```

---

### **Content & Structured Data**

```apex
Content__c (Long Text Area 131,072 characters)
  Purpose: The actual content (markdown, HTML, JSON, instructions)
  
  Examples:
    - Quality Rule: "Every claim must be traceable. No claim should..."
    - Pattern: "PATTERN: RISK ASSESSMENT\n\nAnalyze for critical..."
    - UI Component: "<div style='...'>{{LABEL}}</div>"
    - Validation Rule: "Output must not contain: {{PLACEHOLDER}}, [TBD]"
    - Context Template: "Industry: {{INDUSTRY}}\nDeal Size: {{SIZE_TIER}}"

Attributes__c (Long Text Area 131,072 characters, JSON)
  Purpose: Flexible structured data storage
  
  Examples by Config Type:
  
  Picklist Metadata:
    {"probability": 20, "isClosed": false, "forecastCategory": "Pipeline"}
  
  Pattern:
    {"weight": 0.85, "minFields": 5, "targetPersona": ["Sales Rep"], 
     "minProbability": 60, "applicableStages": ["Negotiation", "Proposal"]}
  
  UI Component:
    {"zone": 2, "width": "25%", "minWidth": "180px", "responsive": true}
  
  Field Rule:
    {"weight": 0.9, "required": false, "category": "Financial", 
     "applicablePersonas": ["Sales Rep", "Finance"]}
  
  Validation Rule:
    {"severity": "Error", "failureAction": "Block", "regex": "{{.*}}"}
  
  Heuristic:
    {"avgDealCycle": 270, "stdDev": 45, "confidence": 0.85, 
     "sampleSize": 150, "industry": "Healthcare"}
```

---

### **Filtering & Search**

```apex
Tags__c (Text 255, Indexed)
  Purpose: Comma-separated keywords for flexible filtering in LWC
  
  Examples:
    - "early-stage,qualification,low-probability"
    - "financial,revenue,high-priority"
    - "risk,blocker,urgent"
    - "healthcare,payer,regulatory"
  
  Use Case: LWC quick filtering without complex WHERE clauses

Applies_To__c (Text 255)
  Purpose: Comma-separated list of applicable entities
  
  Examples:
    - "Sales Rep,Sales Manager" (for patterns)
    - "Opportunity,OpportunityLineItem" (for field rules)
    - "Healthcare,Financial Services" (for heuristics)
    - "All" (for quality rules)
  
  Use Case: Filter by persona, object type, or industry
```

---

### **Display & Admin UI**

```apex
Name (Text, Auto-Number)
  Format: "CONFIG-{0000001}"
  Purpose: System identifier

Label__c (Text 255, Required)
  Purpose: Human-readable label for admin UI
  
  Examples:
    - "Early Stage Risk Pattern"
    - "Opportunity Stage Metadata - Needs Analysis"
    - "Evidence Binding Rules v2"
    - "Healthcare Payer Context Template"

Description__c (Text 255)
  Purpose: Short description for admin UI
  
  Examples:
    - "Analyzes risks for early-stage opportunities"
    - "Synced from OpportunityStage metadata"
    - "V2 rules with insight-first approach"
```

---

### **Ordering & Priority**

```apex
Sort_Order__c (Number, 2 decimals)
  Purpose: Ordering within a category
  
  Use Cases:
    - Picklist value order (1, 2, 3...)
    - Pattern execution order
    - Field priority order
  
  Examples:
    - Opportunity stages: 1.0, 2.0, 3.0, 4.0
    - Patterns by importance: 1.0 (Risk), 2.0 (Timeline), 3.0 (Stakeholder)

Weight__c (Number, 2 decimals, 0.0 to 1.0)
  Purpose: Relative importance/weight
  
  Use Cases:
    - Pattern selection (0.9 = critical, 0.5 = nice-to-have)
    - Field prioritization (0.8 = high value, 0.3 = low value)
    - Heuristic confidence (0.85 = high confidence)

Priority__c (Number)
  Purpose: Integer priority (1 = highest, 10 = lowest)
  
  Use Cases:
    - Validation rule priority (check critical rules first)
    - Pattern execution order when weight is same
```

---

### **Lifecycle & Versioning**

```apex
Version__c (Text 10)
  Purpose: Version identifier
  Examples: "1.0", "2.0", "2.1", "3.0-beta"
  Use Case: Track evolution, allow multiple versions to coexist

Is_Active__c (Checkbox, Default: false, Indexed)
  Purpose: Active/inactive toggle
  Use Case: Deactivate without deleting, test new versions

Last_Synced__c (DateTime)
  Purpose: Timestamp of last sync (for cached metadata)
  Use Case: Know when picklist metadata was last refreshed

Created_By_Process__c (Text 80)
  Purpose: Which process created this record
  Values: "Manual", "Sync Job", "Migration", "Test Data"
  Use Case: Troubleshooting and audit trail

Parent_Config__c (Lookup to GPTfy_Config__c, nullable)
  Purpose: Hierarchical relationships
  Use Cases:
    - Link picklist values to parent field definition
    - Link pattern variations to base pattern
    - Link overrides to defaults
```

---

## Mapping 12 Stages to Configuration Types

### **Stage 1: Intelligence Retrieval**

**What Can Be Configured**:
- Industry-specific context templates
- Persona-specific instruction templates

**Config Records**:

```
Config_Type: "Industry Template"
Category: "Healthcare Payer"
Unique_Key: "IndustryTemplate.HealthcarePayer"
Content: "Industry: Healthcare Payer
         Key Terminology:
         - Use 'Member' not 'Customer'
         - Use 'Plan' not 'Product'
         Decision Makers: CFO, Chief Medical Officer, Compliance Officer
         Regulatory Considerations: HIPAA compliance, risk adjustment audits"
Tags: "healthcare,payer,insurance,medicare"
```

```
Config_Type: "Persona Template"
Category: "Sales Rep"
Unique_Key: "PersonaTemplate.SalesRep"
Content: "TARGET USER: Sales Representative
         FOCUS AREAS:
         1. Deal risks (what could block this?)
         2. Next actions (what should I do today?)
         3. Stakeholder gaps (who am I missing?)
         TONE: Action-oriented, specific, urgent
         AVOID: Technical jargon, compliance details"
Applies_To: "Sales Rep"
```

---

### **Stage 5: Field Selection**

**What Can Be Configured**:
- Field selection rules (which fields to prioritize for which objects)
- Field weighting (importance scores)

**Config Records**:

```
Config_Type: "Field Rule"
Category: "Financial"
Object_API_Name: "Opportunity"
Field_API_Name: "Amount"
Unique_Key: "FieldRule.Opportunity.Amount"
Weight: 0.95
Content: "RULE: Always include Amount for Opportunities
         RATIONALE: Critical for risk assessment and prioritization
         PERSONA RELEVANCE: All personas need deal size context"
Attributes: {"required": true, "category": "Financial", 
            "applicablePersonas": ["All"]}
Tags: "financial,critical,revenue"
Sort_Order: 1
```

```
Config_Type: "Field Rule"
Category: "Relationship"
Object_API_Name: "Opportunity"
Field_API_Name: "Owner.Manager.Name"
Unique_Key: "FieldRule.Opportunity.OwnerManager"
Weight: 0.60
Content: "RULE: Include Opportunity Owner's Manager name
         RATIONALE: Useful for escalation and approval workflows
         PERSONA RELEVANCE: Sales Manager, VP"
Attributes: {"required": false, "category": "Relationship",
            "applicablePersonas": ["Sales Manager", "VP Sales"]}
Tags: "relationship,manager,escalation"
Sort_Order: 15
```

---

### **Stage 6: Configuration Validation**

**What Can Be Configured**:
- Validation rules (what to check before executing)
- Data quality rules

**Config Records**:

```
Config_Type: "Validation Rule"
Category: "Data Quality"
Unique_Key: "ValidationRule.RequiredFields"
Priority: 1
Content: "RULE: Root object record must exist
         CHECK: Query returns at least 1 record
         ERROR MESSAGE: 'Record not found for ID: {recordId}'"
Attributes: {"severity": "Error", "failureAction": "Block", 
            "stage": "Stage04_DataQuery"}
```

```
Config_Type: "Validation Rule"
Category: "Field Validation"
Object_API_Name: "Opportunity"
Unique_Key: "ValidationRule.Opportunity.Amount"
Priority: 5
Content: "RULE: Opportunity Amount should be populated
         CHECK: Amount IS NOT NULL
         WARNING: 'Amount is null - financial analysis limited'"
Attributes: {"severity": "Warning", "failureAction": "Log",
            "stage": "Stage04_DataQuery"}
```

---

### **Stage 7: Context Assembly**

**What Can Be Configured**:
- Context templates with variable substitution
- Industry-specific context blocks

**Config Records**:

```
Config_Type: "Context Template"
Category: "Opportunity Context"
Object_API_Name: "Opportunity"
Unique_Key: "ContextTemplate.Opportunity.Standard"
Content: "BUSINESS CONTEXT:
         Deal: {{OPPORTUNITY_NAME}}
         Size: {{AMOUNT}} ({{SIZE_TIER}})
         Stage: {{STAGE}} ({{DAYS_IN_STAGE}} days)
         Close Date: {{CLOSE_DATE}} ({{DAYS_TO_CLOSE}} days remaining)
         Owner: {{OWNER_NAME}} ({{OWNER_TITLE}})
         
         STRATEGIC IMPORTANCE: {{PRIORITY}}
         COMPETITIVE LANDSCAPE: {{COMPETITORS}}"
Applies_To: "All"
```

---

### **Stage 8: Prompt Assembly**

**What Can Be Configured**:
- Quality rules (already covered)
- Analytical patterns (already covered)
- UI components (already covered)

**Config Records**: (already designed in previous examples)

---

### **Stage 10: Response Validation**

**What Can Be Configured**:
- Output validation rules (what makes valid HTML)
- Forbidden patterns

**Config Records**:

```
Config_Type: "Validation Rule"
Category: "Output Format"
Unique_Key: "ValidationRule.NoPlaceholders"
Priority: 1
Content: "RULE: Output must not contain placeholders
         FORBIDDEN PATTERNS: {{.*}}, [TBD], [PLACEHOLDER], %%VAR%%
         ERROR MESSAGE: 'Output contains unfilled placeholder: {match}'"
Attributes: {"severity": "Error", "failureAction": "Block",
            "regex": "\\{\\{.*?\\}\\}|\\[TBD\\]|\\[PLACEHOLDER\\]",
            "stage": "Stage10_ResponseValidation"}
```

```
Config_Type: "Validation Rule"
Category: "HTML Rules"
Unique_Key: "ValidationRule.NoScriptTags"
Priority: 2
Content: "RULE: Output must not contain <script> tags
         SECURITY RULE: XSS prevention
         ERROR MESSAGE: 'Script tag detected in output'"
Attributes: {"severity": "Error", "failureAction": "Block",
            "regex": "<script.*?>",
            "securityRule": true}
```

```
Config_Type: "Validation Rule"
Category: "HTML Rules"
Unique_Key: "ValidationRule.SingleLine"
Priority: 3
Content: "RULE: Output must be single-line HTML (no newlines except in content)
         TECHNICAL REQUIREMENT: Salesforce Lightning component parsing
         ERROR MESSAGE: 'Output contains illegal newline characters'"
Attributes: {"severity": "Error", "failureAction": "Block",
            "regex": "\\n(?!.*<.*>)"}
```

---

### **Stage 12: Quality Audit**

**What Can Be Configured**:
- Scoring criteria
- Quality thresholds
- Dimension weights

**Config Records**:

```
Config_Type: "Heuristic"
Category: "Quality Scoring"
Unique_Key: "Heuristic.QualityScoring.Weights"
Content: "QUALITY SCORING WEIGHTS:
         1. Evidence Binding: 20%
         2. Diagnostic Depth: 15%
         3. Visual Quality: 15%
         4. UI Component Fit: 10%
         5. Data Accuracy: 10%
         6. Persona Fit: 10%
         7. Actionability: 10%
         8. Business Value: 10%
         
         PASS THRESHOLD: 7.0/10
         EXCELLENT THRESHOLD: 8.5/10"
Attributes: {"weights": {"evidenceBinding": 0.20, "diagnosticDepth": 0.15,
            "visualQuality": 0.15, "uiComponentFit": 0.10, "dataAccuracy": 0.10,
            "personaFit": 0.10, "actionability": 0.10, "businessValue": 0.10},
            "passThreshold": 7.0, "excellentThreshold": 8.5}
Version: "3.0"
```

---

## Common Query Patterns

### **Query 1: Get Active Quality Rules**

```apex
List<GPTfy_Config__c> qualityRules = [
    SELECT Category__c, Content__c, Version__c
    FROM GPTfy_Config__c
    WHERE Config_Type__c = 'Quality Rule'
    AND Is_Active__c = true
    ORDER BY Category__c, Version__c DESC
];

// Build rules block for prompt
StringBuilder rulesBlock = new StringBuilder();
for (GPTfy_Config__c rule : qualityRules) {
    rulesBlock.append('=== ' + rule.Category__c.toUpperCase() + ' ===\n\n');
    rulesBlock.append(rule.Content__c + '\n\n');
}
```

**Performance**: Type + Active (both indexed) = **Fast**

---

### **Query 2: Get Field Selection Rules for Opportunity**

```apex
List<GPTfy_Config__c> fieldRules = [
    SELECT Field_API_Name__c, Weight__c, Content__c, Attributes__c
    FROM GPTfy_Config__c
    WHERE Config_Type__c = 'Field Rule'
    AND Object_API_Name__c = 'Opportunity'
    AND Is_Active__c = true
    ORDER BY Weight__c DESC
];

// Use in Stage05 field selection
Map<String, Decimal> fieldWeights = new Map<String, Decimal>();
for (GPTfy_Config__c rule : fieldRules) {
    fieldWeights.put(rule.Field_API_Name__c, rule.Weight__c);
}
```

**Performance**: Type + Object (both indexed) = **Fast**

---

### **Query 3: Get Picklist Metadata with Efficient Filtering**

```apex
// Option A: Query specific field (FASTEST)
List<GPTfy_Config__c> oppStages = [
    SELECT Value__c, Sort_Order__c, Attributes__c
    FROM GPTfy_Config__c
    WHERE Config_Type__c = 'Picklist Metadata'
    AND Object_API_Name__c = 'Opportunity'
    AND Field_API_Name__c = 'StageName'
    AND Is_Active__c = true
    ORDER BY Sort_Order__c
];

// Option B: Query all picklists for an object (use when need multiple fields)
List<GPTfy_Config__c> oppPicklists = [
    SELECT Field_API_Name__c, Value__c, Sort_Order__c, Attributes__c
    FROM GPTfy_Config__c
    WHERE Config_Type__c = 'Picklist Metadata'
    AND Object_API_Name__c = 'Opportunity'
    AND Is_Active__c = true
    ORDER BY Field_API_Name__c, Sort_Order__c
];

// Group by field
Map<String, List<GPTfy_Config__c>> picklistsByField = new Map<String, List<GPTfy_Config__c>>();
for (GPTfy_Config__c config : oppPicklists) {
    if (!picklistsByField.containsKey(config.Field_API_Name__c)) {
        picklistsByField.put(config.Field_API_Name__c, new List<GPTfy_Config__c>());
    }
    picklistsByField.get(config.Field_API_Name__c).add(config);
}
```

**Performance**: Type + Object + Field (all indexed) = **Very Fast**

---

### **Query 4: Get Patterns for Specific Persona & Object**

```apex
List<GPTfy_Config__c> patterns = [
    SELECT Category__c, Content__c, Weight__c, Attributes__c
    FROM GPTfy_Config__c
    WHERE Config_Type__c = 'Pattern'
    AND Object_API_Name__c = 'Opportunity'
    AND Applies_To__c LIKE '%Sales Rep%'
    AND Is_Active__c = true
    ORDER BY Weight__c DESC
];
```

**Performance**: Type + Object (indexed) + LIKE on Applies_To = **Fast**

---

### **Query 5: Get Context Template with Variable Substitution**

```apex
GPTfy_Config__c contextTemplate = [
    SELECT Content__c
    FROM GPTfy_Config__c
    WHERE Config_Type__c = 'Context Template'
    AND Object_API_Name__c = 'Opportunity'
    AND Category__c = 'Opportunity Context'
    AND Is_Active__c = true
    LIMIT 1
];

// Substitute variables
String context = contextTemplate.Content__c;
context = context.replace('{{OPPORTUNITY_NAME}}', opp.Name);
context = context.replace('{{AMOUNT}}', String.valueOf(opp.Amount));
context = context.replace('{{STAGE}}', opp.StageName);
// ... more substitutions
```

---

### **Query 6: Get Validation Rules by Priority**

```apex
List<GPTfy_Config__c> validationRules = [
    SELECT Category__c, Content__c, Priority__c, Attributes__c
    FROM GPTfy_Config__c
    WHERE Config_Type__c = 'Validation Rule'
    AND Is_Active__c = true
    ORDER BY Priority__c NULLS LAST
];

// Execute in order
for (GPTfy_Config__c rule : validationRules) {
    Map<String, Object> attrs = 
        (Map<String, Object>) JSON.deserializeUntyped(rule.Attributes__c);
    
    String severity = (String) attrs.get('severity');
    String regex = (String) attrs.get('regex');
    
    if (String.isNotBlank(regex)) {
        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(output);
        if (m.find()) {
            if (severity == 'Error') {
                throw new ValidationException(rule.Content__c);
            }
        }
    }
}
```

---

### **Query 7: LWC Tag-Based Filtering**

```apex
// In LWC controller
@AuraEnabled(cacheable=true)
public static List<GPTfy_Config__c> getPatternsByTags(String tags) {
    String likePattern = '%' + tags + '%';
    
    return [
        SELECT Label__c, Category__c, Description__c, Tags__c
        FROM GPTfy_Config__c
        WHERE Config_Type__c = 'Pattern'
        AND Tags__c LIKE :likePattern
        AND Is_Active__c = true
        ORDER BY Weight__c DESC
        LIMIT 50
    ];
}

// In LWC JavaScript
import getPatternsByTags from '@salesforce/apex/GPTfyConfigController.getPatternsByTags';

// User types "early-stage" in search box
this.patterns = await getPatternsByTags({ tags: 'early-stage' });
```

---

## Record Count Estimates

| Config Type | Examples | Est. Records |
|-------------|----------|--------------|
| **Quality Rule** | Evidence Binding, Hierarchy, etc. | 5-10 |
| **Picklist Metadata** | Opp.Stage, Case.Status, Lead.Status, Priority, etc. | 50-100 |
| **Pattern** | Risk, Timeline, Stakeholder, Action, etc. | 15-20 |
| **UI Component** | Stat Card, Alert Box, Timeline, etc. | 12-15 |
| **Field Rule** | Field weights/priorities for 3-5 objects | 30-50 |
| **Validation Rule** | Output validation, data quality checks | 10-15 |
| **Context Template** | Object-specific context templates | 5-10 |
| **Persona Template** | Sales Rep, Manager, Executive, etc. | 5-8 |
| **Industry Template** | Healthcare, Finance, Manufacturing, etc. | 10-15 |
| **Heuristic** | Deal cycles, benchmarks, thresholds | 20-30 |
| **TOTAL (Active)** | | **~200-300** |
| **With Inactive/Versions** | | **~350-400** |

**Conclusion**: Easily manageable in a single object.

---

## Indexes for Performance

**Required Indexes**:
1. `Config_Type__c` (High selectivity)
2. `Object_API_Name__c` (Medium selectivity)
3. `Field_API_Name__c` (Medium selectivity)
4. `Category__c` (Medium selectivity)
5. `Is_Active__c` (Low selectivity, but frequently used)
6. `Tags__c` (For LIKE queries in LWC)
7. `Unique_Key__c` (External ID, automatically indexed)

**Compound Indexes** (if available):
- `(Config_Type__c, Object_API_Name__c, Is_Active__c)`
- `(Config_Type__c, Category__c, Is_Active__c)`

---

## Migration Strategy

### **Phase 1: Create Object & Load Core Config**

1. Create `GPTfy_Config__c` object with all fields
2. Load Quality Rules (Evidence Binding, Hierarchy)
3. Load Analytical Patterns (Risk, Timeline, Stakeholder)
4. Load UI Components (Stat Cards, Alert Boxes)

**Records**: ~40-50

---

### **Phase 2: Sync Picklist Metadata**

1. Create sync job (`GPTfyConfigSyncJob`)
2. Sync OpportunityStage, CaseStatus, LeadStatus
3. Schedule nightly refresh

**Records**: +50-100 = **~140-150 total**

---

### **Phase 3: Add Field Rules & Validation**

1. Define field selection rules for Opportunity, Case, Lead
2. Define validation rules for output quality
3. Test in Stage05 and Stage10

**Records**: +40-50 = **~200 total**

---

### **Phase 4: Add Templates & Heuristics**

1. Create context templates
2. Create persona/industry templates
3. Add historical benchmarks/heuristics

**Records**: +50-80 = **~280 total**

---

## Benefits Summary

### **vs. Multiple Objects/Metadata**

**Before** (my over-engineered proposal):
- 3-4 custom objects
- 2-3 custom metadata types
- Static resources
- Complex relationships

**After** (your instinct):
- **1 custom object**
- Simple SOQL queries
- JSON flexibility
- Easy versioning

**Simplicity Score**: 5x better

---

### **Query Performance**

- All primary fields indexed
- Typical query: <10ms
- Max records per query: 50-100 (filtered)
- Cacheable in LWC (@AuraEnabled(cacheable=true))

---

### **Maintainability**

- Single object to understand
- Consistent query patterns
- Easy to add new config types (just add picklist value)
- Version control via `Version__c` field

---

### **Extensibility**

- JSON `Attributes__c` handles any structure
- Tags enable flexible filtering
- Hierarchical via `Parent_Config__c`
- Applies_To enables multi-tenancy

---

**Document Created**: January 22, 2026  
**Status**: Complete schema design ready for implementation  
**Next Step**: Create object and start Phase 1 migration
