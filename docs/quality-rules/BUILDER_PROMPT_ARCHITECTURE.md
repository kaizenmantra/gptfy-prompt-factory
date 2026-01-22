# Builder Prompt Architecture

**Purpose**: Define the production architecture for prompt factory using ccai__AI_Prompt__c record types  
**Status**: Finalized Design  
**Last Updated**: January 22, 2026

---

## Executive Summary

The GPTfy Prompt Factory leverages the existing `ccai__AI_Prompt__c` object instead of creating new custom objects. This approach uses:

1. **Record Types**: Builder Prompt (infrastructure) vs Executable Prompt (applications)
2. **Standard Features**: Topics for tagging, Files for long content, Canvas for composition
3. **Minimal Schema**: Only 2 new fields (Category__c, Weight__c)
4. **Zero New Objects**: No configuration objects, no metadata types, no bloat

**Benefits**:
- Leverages existing infrastructure (versioning, status, files)
- Minimal package complexity
- Standard Salesforce UI components
- Extensible via Topics and Canvas composition

---

## Record Type Architecture

### Record Type 1: Builder Prompt

**Purpose**: Reusable building blocks for prompt assembly

**API Name**: `Builder_Prompt`

**Types of Builders**:
- Quality Rules (Evidence Binding, Information Hierarchy)
- Analytical Patterns (Risk Assessment, Timeline Analysis, Metrics Calculation)
- UI Components (Stat Cards, Alert Boxes, Progress Bars)
- Context Templates (Industry-specific guidance, terminology)
- Field Services (Apex classes for live metadata queries)

**Page Layout**:
```
Section 1: Classification
├── Category__c (Picklist) - Required
├── Topics (Standard - via TopicAssignment)
└── Weight__c (Number 0.0-1.0)

Section 2: Content
├── Name (Standard)
├── Status__c (Active/Inactive/Draft)
├── Prompt_Command__c (Long Text - markdown-friendly)
└── Apex_Class__c (Text - conditional on Category)

Section 3: Metadata
├── Version__c
├── Created By / Date
└── Modified By / Date

Section 4: Usage Analytics (Read-only)
├── Used In Canvas Prompts (Related List)
└── Last Used Date
```

**Lightning Page Components**:
- Content Preview (render markdown)
- Topic Cloud (clickable filter)
- Impact Analysis (how many prompts use this?)
- Version History

**Required Fields**:
- Category__c
- Prompt_Command__c (or Apex_Class__c for Field Service builders)

---

### Record Type 2: Executable Prompt

**Purpose**: Prompts that run against live data

**API Name**: `Executable_Prompt`

**Types of Executables**:
- Text (standard prompt)
- JSON (structured output)
- Canvas (container for builders)
- Agent (Apex-driven prompt)

**Page Layout**:
```
Section 1: Execution Settings
├── Type__c (Text/JSON/Canvas/Agent) - Required
├── Connection__c (Lookup to AI provider)
├── Temperature__c, Max_Tokens__c
└── Object__c (Opportunity, Case, Account)

Section 2: Business Context
├── Purpose__c (Multi-select: Optimize Renewals, Improve Services, etc.)
├── Description__c
└── Prompt_Command__c (Long Text)

Section 3: Data Source
├── Data_Extraction_Mapping__c (Lookup)
└── Additional context...

Section 4: Canvas Composition (if Type = Canvas)
├── Prompt Elements (Related List)
└── Layout Configuration

Section 5: Testing
├── Test Execution Panel
└── Response History
```

**Lightning Page Components**:
- Test Execution Panel
- Response Preview
- Prompt Elements (if Canvas)
- Response History
- Files

**Required Fields**:
- Type__c
- Connection__c
- Object__c
- Prompt_Command__c

---

## Field Schema

### New Fields on ccai__AI_Prompt__c

#### Category__c (Picklist)

**Label**: Category  
**API Name**: `Category__c`  
**Type**: Picklist  
**Required**: Only for Builder Prompt record type  
**Description**: Classifies builder prompts by technical function

**Picklist Values**:
```
Quality Rule - Evidence binding, information hierarchy, citation policies
Pattern - Risk Assessment, Timeline Analysis, Stakeholder Mapping, etc.
UI Component - Stat Cards, Alert Boxes, Progress Bars, Timeline Visuals
Context Template - Industry guidance, terminology, personas
Field Service - Apex classes for metadata queries, calculations
```

**Usage**:
```apex
// Query all quality rules
List<ccai__AI_Prompt__c> rules = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder_Prompt'
      AND Category__c = 'Quality Rule'
      AND ccai__Status__c = 'Active'
];
```

**Validation Rules**:
- Required if RecordType = Builder_Prompt
- Hidden if RecordType = Executable_Prompt

---

#### Weight__c (Number)

**Label**: Weight  
**API Name**: `Weight__c`  
**Type**: Number(2, 1)  
**Range**: 0.0 to 1.0  
**Required**: No  
**Default**: null (no priority)  
**Description**: Priority weight for builder prompts (higher = more important)

**Usage Examples**:
- Evidence Binding (Quality Rule): 1.0 (always include)
- Risk Assessment (Pattern): 0.9 (high priority)
- Stakeholder Mapping (Pattern): 0.7 (medium priority)
- Root Cause Analysis (Pattern): 0.5 (low priority, situational)
- Alert Box (UI Component): 0.8 (high visibility)

**Usage in Code**:
```apex
// Get top 3 patterns by weight
List<ccai__AI_Prompt__c> topPatterns = [
    SELECT Id, Name, ccai__Prompt_Command__c, Weight__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder_Prompt'
      AND Category__c = 'Pattern'
      AND ccai__Status__c = 'Active'
    ORDER BY Weight__c DESC NULLS LAST, Name
    LIMIT 3
];
```

**Validation Rules**: None (null is valid = no priority)

---

### Existing Fields (Reused)

#### ccai__Prompt_Command__c (Long Text)

**For Builder Prompts**:
- Stores rule content, pattern instructions, UI templates
- Markdown-friendly formatting
- Can be truncated if file attached

**For Executable Prompts**:
- Stores main prompt logic
- Can reference builders via merge fields
- Example: `{!QualityRules.EvidenceBinding} + {!Patterns.RiskAssessment}`

---

#### ccai__Type__c (Picklist)

**For Builder Prompts**:
- Not used (Category__c replaces it)
- Hidden on Builder page layout

**For Executable Prompts**:
- Text, JSON, Canvas, Agent
- Determines execution mode

---

#### ccai__Purpose__c (Multi-Select Picklist)

**For Builder Prompts**:
- Not used (Topics replace semantic tagging)
- Hidden on Builder page layout

**For Executable Prompts**:
- Business outcome tagging (Optimize Renewals, Improve Services, etc.)
- Helps admins discover prompts by business goal

**Separation of Concerns**:
- Purpose__c = Business goals (for end-user prompts)
- Topics = Technical classification (for builders)

---

#### Apex_Class__c (Text)

**For Builder Prompts with Category = "Field Service"**:
- Stores Apex class name to invoke
- Example: `FieldMetadataService`, `PicklistIntelligenceService`
- Conditional visibility on page layout

**For Other Builders**:
- Hidden

---

## Topics Architecture

### Why Topics Instead of Tags__c?

**Topics** (Standard Salesforce):
- Standard `Topic` object + `TopicAssignment` junction
- Many-to-many (up to 100 topics per record)
- Built-in UI components (picker, badges, cloud)
- Indexed queries (fast filtering)
- Cross-object (can tag prompts, responses, files)
- Clickable navigation (click topic → see all records)

**Custom Tags__c Field** (What we're NOT doing):
- Text field with comma-separated values
- Requires string parsing in Apex
- No built-in UI components
- LIKE queries (slow, inefficient)
- Limited to 255 characters
- No clickable discovery

**Winner**: Topics (standard, faster, better UX)

---

### Topic Taxonomy

**Pattern Types**:
- Risk Assessment
- Timeline Analysis
- Metrics Calculation
- Stakeholder Mapping
- Root Cause Analysis
- Executive Summary
- Next Action Recommendation

**UI Types**:
- Stat Card
- Alert Box
- Progress Bar
- Timeline Visual
- Table
- Card Layout

**Quality Rules**:
- Evidence Binding
- Information Hierarchy
- Insight-Led Design
- Priority Scoring

**Maturity Levels**:
- Production-Ready
- Phase-1-Ready
- Experimental
- Deprecated

**Priority Levels**:
- P0 (always include)
- P1 (high value)
- P2 (situational)

**Object Context**:
- Opportunity
- Case
- Account
- Contact
- Lead
- Multi-Object

**Industry Context** (for Context Templates):
- Financial Services
- Healthcare
- Manufacturing
- Technology
- Retail

---

### Topic Usage Examples

#### Example 1: P0 Risk Assessment Patterns

```apex
// Get all P0 Risk Assessment builder prompts
List<String> topics = new List<String>{'Risk Assessment', 'P0'};
List<ccai__AI_Prompt__c> prompts = PromptTopicService.getPromptsByTopics(
    topics, 
    'AND' // Must have ALL topics
);
```

**Result**: Returns builders tagged with BOTH "Risk Assessment" AND "P0"

---

#### Example 2: UI Components for Opportunity

```apex
// Get all UI components for Opportunity object
List<String> topics = new List<String>{'Stat Card', 'Alert Box', 'Opportunity'};
List<ccai__AI_Prompt__c> prompts = PromptTopicService.getPromptsByTopics(
    topics, 
    'OR' // Must have ANY of these topics
);
```

**Result**: Returns Stat Card OR Alert Box builders tagged with "Opportunity"

---

#### Example 3: Experimental Patterns

```apex
// Get all experimental patterns for testing
List<String> topics = new List<String>{'Pattern', 'Experimental'};
List<ccai__AI_Prompt__c> prompts = PromptTopicService.getPromptsByTopics(
    topics, 
    'AND'
);
```

**Result**: Returns experimental analytical patterns (not for production)

---

### Topic Management

**Admin Workflow**:
1. Create builder prompt record (Record Type = Builder Prompt)
2. Fill Category__c (e.g., "Pattern")
3. Add Topics via standard UI (e.g., "Risk Assessment", "Opportunity", "P0")
4. Set Weight__c (e.g., 0.9)
5. Activate (Status = Active)

**LWC Prompt Factory**:
- Filter by Topics (multi-select)
- Filter by Category (picklist)
- Sort by Weight (descending)
- Drag & drop to Canvas prompt

**Topics Component on Record Page**:
- Shows existing topics as clickable badges
- Click badge → filter to other records with same topic
- Add new topics via auto-suggest

---

## Canvas Prompt Composition

### How Canvas Prompts Work

**Canvas Prompt** (Type = Canvas):
- Container for other prompts (building blocks)
- Uses `ccai__AI_Prompt_Element__c` junction object
- Controls sequence, layout, and width

**Example Structure**:
```
Canvas: "Opportunity Deal Coach"
├── Element 1 (Sequence: 1, Width: Full)
│   └── Builder: Evidence Binding Rules (Quality Rule)
├── Element 2 (Sequence: 2, Width: Full)
│   └── Builder: Information Hierarchy Rules (Quality Rule)
├── Element 3 (Sequence: 3, Width: 1/2)
│   └── Builder: Risk Assessment Pattern (Pattern)
├── Element 4 (Sequence: 4, Width: 1/2)
│   └── Builder: Timeline Analysis Pattern (Pattern)
├── Element 5 (Sequence: 5, Width: Full)
│   └── Builder: Stat Card UI Component (UI Component)
└── Element 6 (Sequence: 6, Width: Full)
    └── Builder: Field Metadata Service (Field Service - Apex)
```

---

### Junction Object: ccai__AI_Prompt_Element__c

**Fields** (Existing):
```
Parent_Prompt__c (Lookup to Canvas prompt)
Child_Prompt__c (Lookup to Builder prompt)
Sequence__c (Number - order of inclusion)
Width__c (Picklist: Full, 1/2, 1/3, 2/3)
```

**Query Example**:
```apex
// Get all builders in a canvas prompt
List<ccai__AI_Prompt_Element__c> elements = [
    SELECT Child_Prompt__c, Child_Prompt__r.Name, 
           Child_Prompt__r.Category__c,
           Child_Prompt__r.ccai__Prompt_Command__c,
           Sequence__c, Width__c
    FROM ccai__AI_Prompt_Element__c
    WHERE Parent_Prompt__c = :canvasPromptId
    ORDER BY Sequence__c
];
```

---

### Stage08 Assembly with Canvas

**Process**:
1. Stage08 receives Canvas prompt ID
2. Query all prompt elements (ordered by sequence)
3. For each element:
   - If Category = "Field Service" → Invoke Apex class
   - If Category = "Quality Rule" → Load rule content
   - If Category = "Pattern" → Load pattern instructions
   - If Category = "UI Component" → Load HTML template
   - If Category = "Context Template" → Load contextual guidance
4. Merge all builders into final prompt
5. Inject data payload at end

**Code Example**:
```apex
public class Stage08_PromptAssembly {
    
    public String assembleCanvasPrompt(Id canvasPromptId, Map<String, Object> data) {
        StringBuilder finalPrompt = new StringBuilder();
        
        // Get canvas prompt
        ccai__AI_Prompt__c canvas = [
            SELECT Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE Id = :canvasPromptId
        ];
        
        // Add canvas header
        finalPrompt.append(canvas.ccai__Prompt_Command__c + '\n\n');
        
        // Get all builders in sequence
        List<ccai__AI_Prompt_Element__c> elements = [
            SELECT Child_Prompt__r.Category__c,
                   Child_Prompt__r.ccai__Prompt_Command__c,
                   Child_Prompt__r.Apex_Class__c,
                   Sequence__c
            FROM ccai__AI_Prompt_Element__c
            WHERE Parent_Prompt__c = :canvasPromptId
            ORDER BY Sequence__c
        ];
        
        // Assemble each builder
        for (ccai__AI_Prompt_Element__c element : elements) {
            String category = element.Child_Prompt__r.Category__c;
            
            if (category == 'Field Service') {
                // Invoke Apex class
                String apexClass = element.Child_Prompt__r.Apex_Class__c;
                String result = invokeFieldService(apexClass, data);
                finalPrompt.append(result + '\n\n');
                
            } else if (category == 'Quality Rule') {
                // Load rule content
                finalPrompt.append('=== QUALITY RULE ===\n');
                finalPrompt.append(element.Child_Prompt__r.ccai__Prompt_Command__c);
                finalPrompt.append('\n\n');
                
            } else if (category == 'Pattern') {
                // Load pattern
                finalPrompt.append('=== ANALYTICAL PATTERN ===\n');
                finalPrompt.append(element.Child_Prompt__r.ccai__Prompt_Command__c);
                finalPrompt.append('\n\n');
                
            } else if (category == 'UI Component') {
                // Load UI template
                finalPrompt.append('=== UI COMPONENT ===\n');
                finalPrompt.append(element.Child_Prompt__r.ccai__Prompt_Command__c);
                finalPrompt.append('\n\n');
            }
        }
        
        // Add data payload
        finalPrompt.append('=== DATA ===\n');
        finalPrompt.append(JSON.serializePretty(data));
        
        return finalPrompt.toString();
    }
    
    private String invokeFieldService(String apexClassName, Map<String, Object> data) {
        // Dynamic Apex invocation
        Type serviceType = Type.forName(apexClassName);
        if (serviceType == null) {
            return '// Error: Apex class not found: ' + apexClassName;
        }
        
        // Assume all field services implement IFieldService interface
        IFieldService service = (IFieldService) serviceType.newInstance();
        return service.execute(data);
    }
}
```

---

## Example: Building "Opportunity Deal Coach" Canvas

### Step 1: Create Builder Prompts

**Quality Rule: Evidence Binding**
```
Record Type: Builder Prompt
Category: Quality Rule
Topics: Evidence Binding, Insight-Led Design, P0
Weight: 1.0
Status: Active
Prompt Command: [Full evidence binding rules from evidence_binding_v2.md]
```

**Quality Rule: Information Hierarchy**
```
Record Type: Builder Prompt
Category: Quality Rule
Topics: Information Hierarchy, Above-the-Fold, P0
Weight: 1.0
Status: Active
Prompt Command: [Full hierarchy rules from information_hierarchy.md]
```

**Pattern: Risk Assessment**
```
Record Type: Builder Prompt
Category: Pattern
Topics: Risk Assessment, Opportunity, P0
Weight: 0.9
Status: Active
Prompt Command: [Risk assessment pattern instructions]
```

**Pattern: Timeline Analysis**
```
Record Type: Builder Prompt
Category: Pattern
Topics: Timeline Analysis, Opportunity, P1
Weight: 0.8
Status: Active
Prompt Command: [Timeline pattern instructions]
```

**UI Component: Stat Card**
```
Record Type: Builder Prompt
Category: UI Component
Topics: Stat Card, Above-the-Fold, P0
Weight: 0.9
Status: Active
Prompt Command: [Stat card HTML template]
```

**Field Service: Opportunity Stage Context**
```
Record Type: Builder Prompt
Category: Field Service
Topics: Picklist Metadata, Opportunity, P0
Weight: 1.0
Status: Active
Apex Class: FieldMetadataService
Prompt Command: Extracts OpportunityStage picklist values and probabilities
```

---

### Step 2: Create Canvas Prompt

**Canvas: Opportunity Deal Coach**
```
Record Type: Executable Prompt
Type: Canvas
Object: Opportunity
Purpose: Manage Stakeholders, Optimize Renewals
Status: Active
Prompt Command: 
You are a Salesforce AI Deal Coach generating HTML content for an Opportunity analysis.
Your goal is to identify risks, provide metrics, and recommend actions.
```

---

### Step 3: Link Builders to Canvas

**Via ccai__AI_Prompt_Element__c**:
```
Element 1: Evidence Binding (Sequence: 1, Width: Full)
Element 2: Information Hierarchy (Sequence: 2, Width: Full)
Element 3: Opportunity Stage Context (Sequence: 3, Width: Full)
Element 4: Risk Assessment (Sequence: 4, Width: Full)
Element 5: Timeline Analysis (Sequence: 5, Width: Full)
Element 6: Stat Card (Sequence: 6, Width: Full)
```

---

### Step 4: Execute Canvas Prompt

**Stage08 Output**:
```
You are a Salesforce AI Deal Coach generating HTML content for an Opportunity analysis.
Your goal is to identify risks, provide metrics, and recommend actions.

=== QUALITY RULE ===
[Evidence Binding Rules v2 content]

=== QUALITY RULE ===
[Information Hierarchy content]

=== FIELD SERVICE RESULT ===
FIELD CONTEXT: Opportunity.StageName
Current Value: "Needs Analysis"
Available Values (6 total):
  1. Prospecting (10% probability)
  2. Needs Analysis (20% probability) ← CURRENT
  3. Value Proposition (40% probability)
  4. Negotiation (70% probability)
  5. Closed Won (100% probability)
  6. Closed Lost (0% probability)

Analysis: This is an EARLY stage (position 2 of 6).
IMPORTANT: When evaluating probability, consider this is an early stage.
A 20% probability is NORMAL for this stage.

=== ANALYTICAL PATTERN ===
[Risk Assessment pattern instructions]

=== ANALYTICAL PATTERN ===
[Timeline Analysis pattern instructions]

=== UI COMPONENT ===
[Stat Card HTML template]

=== DATA ===
{
  "Opportunity": {
    "Name": "Acme Corp - Enterprise Deal",
    "Amount": 150000,
    "StageName": "Needs Analysis",
    "Probability": 20,
    "CloseDate": "2026-03-30",
    ...
  }
}
```

**Result**: LLM receives comprehensive prompt with all quality rules, field context, patterns, and UI guidance, then generates HTML output.

---

## Implementation Checklist

### Schema Setup (1 hour)

- [ ] Create Record Type: Builder_Prompt
- [ ] Create Record Type: Executable_Prompt
- [ ] Create Field: Category__c (Picklist, required for Builder)
- [ ] Create Field: Weight__c (Number 2,1, optional)
- [ ] Update Page Layout: Builder Prompt Layout
  - [ ] Show: Category, Topics, Weight, Prompt Command, Apex Class (conditional)
  - [ ] Hide: Type, Purpose, Connection, Data Extraction Mapping
- [ ] Update Page Layout: Executable Prompt Layout
  - [ ] Show: Type, Purpose, Connection, Object, Prompt Command
  - [ ] Hide: Category, Weight
- [ ] Create Lightning Page: Builder Prompt Record Page
  - [ ] Add component: Topics
  - [ ] Add component: Content Preview
  - [ ] Add component: Used In Canvas Prompts (related list)
- [ ] Enable Topics on ccai__AI_Prompt__c object

---

### Apex Services (4-6 hours)

- [ ] Create Interface: IFieldService
  ```apex
  public interface IFieldService {
      String execute(Map<String, Object> data);
  }
  ```
- [ ] Create Class: PromptTopicService
  - [ ] Method: getPromptsByTopics(List<String>, String logic)
  - [ ] Method: getTopicsForPrompt(Id)
- [ ] Create Class: FieldMetadataService (implements IFieldService)
  - [ ] Method: execute() - returns picklist context
  - [ ] Method: getPicklistValues(String objectName, String fieldName)
- [ ] Update Class: Stage08_PromptAssembly
  - [ ] Method: assembleCanvasPrompt(Id canvasId, Map<String, Object> data)
  - [ ] Method: invokeFieldService(String className, Map<String, Object> data)

---

### Seed Data (2-3 hours)

- [ ] Create Topics (via Data Loader or Setup)
  - [ ] Pattern types (Risk Assessment, Timeline Analysis, etc.)
  - [ ] UI types (Stat Card, Alert Box, etc.)
  - [ ] Maturity levels (Production-Ready, Experimental)
  - [ ] Priority levels (P0, P1, P2)
  - [ ] Object context (Opportunity, Case, Account)
- [ ] Create Builder Prompts (20-30 records)
  - [ ] Quality Rules: Evidence Binding, Information Hierarchy
  - [ ] Patterns: Risk Assessment, Timeline, Metrics, Stakeholder, Root Cause, Executive, Next Action
  - [ ] UI Components: Stat Card, Alert Box, Progress Bar, Timeline Visual, Table
  - [ ] Field Services: FieldMetadataService, PicklistIntelligenceService
- [ ] Create Canvas Prompt: "Opportunity Deal Coach"
- [ ] Link builders to canvas via Prompt Elements

---

### Testing (2 hours)

- [ ] Unit Tests: PromptTopicService
- [ ] Unit Tests: FieldMetadataService
- [ ] Integration Test: Stage08 Canvas Assembly
- [ ] End-to-End Test: Execute canvas prompt for test opportunity
- [ ] Validate: Output contains quality rules, field context, patterns, UI templates

---

## Migration from Previous Approaches

### What We're NOT Building

**Custom Object: GPTfy_Config__c**
- Reason: Adds package bloat, unnecessary complexity
- Replaced By: Builder Prompt record type + Topics

**Custom Metadata Type: Picklist_Annotation__mdt**
- Reason: Overkill for initial implementation
- Replaced By: Standard Topics for classification

**Static Resources for Rules**
- Reason: Less flexible than records, harder to version
- Replaced By: Builder prompts with Status and Version fields

**Custom Tags__c Field**
- Reason: No standard UI, requires parsing logic
- Replaced By: Standard Topics

---

### What We're Leveraging

**Existing Features**:
- ccai__AI_Prompt__c object (already exists)
- ccai__AI_Prompt_Element__c junction (already exists)
- Topics (standard Salesforce)
- ContentDocument (file attachments)
- Record Types (standard Salesforce)
- Status and Version fields (already exist)

**Result**: Minimal new schema, maximum leverage of existing infrastructure

---

## Success Metrics

**Schema Complexity**:
- Target: <5 new fields (achieved: 2 fields)
- Target: 0 new objects (achieved: 0)
- Target: 0 new metadata types (achieved: 0)

**Admin Experience**:
- Target: <5 minutes to create new builder prompt (achievable with form auto-fill)
- Target: <2 minutes to add builder to canvas (drag & drop UI)
- Target: <10 clicks to discover prompts by topic (topic filter)

**Developer Experience**:
- Target: <100 lines of code to assemble canvas prompt (achieved in example)
- Target: <50ms query time for builders by topic (indexed joins)
- Target: Extensible via Topics and Apex interface (achieved)

**User Experience**:
- Target: Visual discovery via topic clouds (standard component)
- Target: Clickable navigation (standard Topics behavior)
- Target: Version control and rollback (existing Status/Version fields)

---

## Document Created

**Date**: January 22, 2026  
**Finalized After**: 3 architectural iterations  
**Based On**: User feedback on package complexity, leveraging existing infrastructure, and UX needs  
**Status**: Ready for Implementation

---

## Related Documents

- [Implementation Roadmap](./IMPLEMENTATION_ROADMAP.md) - Sprint breakdown
- [Quality Rules README](./README.md) - Master index
- [Picklist Metadata Extraction](./picklist_metadata_extraction.md) - Field context strategy
- [Architecture Strategy](../ARCHITECTURE_STRATEGY.md) - Overall system design
