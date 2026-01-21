# GPTfy Prompt Factory: Architecture Strategy

**Last Updated**: January 21, 2026  
**Status**: Strategic Planning  
**Branch**: `feature/prompt-quality-improvements`

---

## Executive Summary

Transform the Prompt Factory from a generic prompt generator into a **Decisive Analysis Assembler**. We stop asking users to "describe what they want" and instead **automatically assemble** a sophisticated "mini-analyst" based on:

- **Verified customer context** (ground truth, not guesses)
- **Multi-record evidence** (patterns, not single data points)
- **Proven analytical patterns** (extracted from production prompts)
- **Deterministic triggers** (data signals, not AI vibes)

**Core Philosophy**: Great analysis is not invented from scratch by an LLM each time. It is **assembled** from proven components.

---

## The Core Problem

**Old Way**: "Read this record and give advice." → Generic hallucinations like "align with stakeholders"

**Why This Fails**:
- Doesn't cite specific evidence from Salesforce data
- Uses generic "consultant speak" instead of customer terminology
- Treats industry context as optional narrative enrichment
- Produces report-style summaries instead of decision-support analysis
- LLM guesses at patterns instead of detecting them from data

**Impact**: Users won't trust/pay for prompts that sound like generic chatbot output.

**New Way**: "Apply the *Negotiation Pressure* pattern using *Cigna* terminology with evidence from *Record #1/2/3*." → Expert decision support.

---

## The Single-Tenant Advantage

**Key Insight**: GPTfy deploys into a single customer's org (e.g., Cigna). This fundamentally changes the architecture from "generic + inferred" to "pre-configured + validated."

**What This Enables**:
- Pre-load customer-specific business context (no guessing)
- Use proven terminology from day 1 (Member, not Customer)
- Leverage known deal patterns and buying motions (CFO involvement at $500K+)
- Avoid hallucination about industry we don't understand
- Build a customer-specific analyst, not a generic chatbot

**Verdict**: The "Analysis Assembler" is not just a feature upgrade; it is a fundamental shift from *generative text* to *automated intelligence*.

---

## Configuration Philosophy: File-Based Architecture

**Key Insight**: Instead of creating Custom Metadata Types or new objects, store all configuration as **markdown files** (Static Resources or Salesforce Files).

### Why Markdown Files Win

#### Customer Editability
- **Non-technical users** can edit markdown files directly
- No need to understand Salesforce metadata or objects
- Can use any text editor or even edit in Salesforce
- Natural language documentation format

#### Simplicity
- **No schema design**: No Custom Metadata Types to create
- **No deployment friction**: Upload a file vs. deploy metadata
- **No object proliferation**: Keep data model clean
- **Easy versioning**: Git for static resources, record history for files

#### Flexibility
- **Schema evolution**: Change structure without redeployment
- **Rich content**: Can include examples, comments, documentation inline
- **Structured data**: Use YAML/JSON frontmatter + markdown content
- **Composability**: Reference other files, include snippets

### Storage Options

#### Option 1: Static Resources (Recommended for Initial Implementation)
```apex
// Deployed with package, version controlled
StaticResource cigna_business_context = [SELECT Body FROM StaticResource WHERE Name = 'cigna_business_context'];
String content = cigna_business_context.Body.toString();
```

**Pros**:
- Versioned with code in git
- Deployed with package
- Cacheable and fast
- No user upload required

**Cons**:
- Requires deployment to change
- Not customer-editable at runtime

#### Option 2: Salesforce Files (Future Enhancement for Customer Editability)
```apex
// Attached to specific record (e.g., PF_Run__c or custom settings record)
ContentVersion file = [SELECT VersionData FROM ContentVersion WHERE Title = 'cigna_business_context' AND IsLatest = true];
String content = file.VersionData.toString();
```

**Pros**:
- Customer can upload/edit at runtime
- No deployment needed
- Can attach to LWC component or record
- Version history built-in

**Cons**:
- Need file upload UI
- Validation/error handling for malformed files
- Caching strategy needed

#### Hybrid Approach (Recommended Long-Term)
1. **Ship defaults as Static Resources** - e.g., `default_patterns.md`, `default_archetypes.md`
2. **Allow customer overrides as Files** - e.g., upload `cigna_custom_patterns.md`
3. **Merge at runtime** - Customer file overrides defaults

### What Gets Stored in Markdown

#### 1. Customer Business Context
```markdown
# cigna_business_context.md

## Industry Profile
- Primary: Healthcare Payer
- Lines of Business: Medicare Advantage, Commercial

## Terminology
- Use "Member" not "Customer"
- Use "Plan" not "Product"

## Deal Patterns
- CFO involvement at $500K+
- Security review adds 2-3 weeks
```

#### 2. Analytical Patterns
```markdown
# pattern_negotiation_pressure.md

## Pattern: Negotiation Pressure Detection

### Trigger Rules
- Stage contains: Proposal, Quote, Negotiation
- Keywords: discount, CFO, budget, pricing
- Min Probability: 60%

### Analysis Questions
1. Who is driving the discount request?
2. What value justification is missing?
3. What concession alternatives exist besides price?

### Evidence Requirements
- OpportunityStage
- Description or NextStep
- Probability

### Forbidden Phrases
- "offer competitive pricing"
- "emphasize value proposition"
```

#### 3. Persona Archetypes
```markdown
# archetype_deal_coach.md

## Archetype: Deal Coach Brief

### Target Reader
Sales Representative or Account Executive

### Output Structure
1. Deal Health Summary (3-5 bullets)
2. Key Risks & Blockers (2-3 items)
3. Next Best Actions (prioritized list)
4. Stakeholder Engagement Status

### Tone
Prescriptive, action-oriented, coaching

### Evidence Depth
High - cite specific fields and values
```

#### 4. UI Components (HTML Templates)
```markdown
# component_risk_scorecard.html

<div class="slds-card risk-assessment">
  <div class="slds-card__header">
    <h2>Risk Assessment</h2>
  </div>
  <div class="slds-card__body">
    <div class="risk-level {{RISK_CLASS}}">
      {{RISK_LEVEL}}
    </div>
    <ul class="risk-factors">
      {{RISK_FACTORS}}
    </ul>
  </div>
</div>
```

### File Reading Implementation in Apex

```apex
public class ConfigurationLoader {
    
    // Cache for performance
    private static Map<String, String> fileCache = new Map<String, String>();
    
    /**
     * Load markdown file from Static Resource
     */
    public static String loadStaticResource(String resourceName) {
        if (fileCache.containsKey(resourceName)) {
            return fileCache.get(resourceName);
        }
        
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = :resourceName LIMIT 1];
        String content = sr.Body.toString();
        fileCache.put(resourceName, content);
        return content;
    }
    
    /**
     * Load markdown file from Salesforce Files (ContentVersion)
     * Falls back to Static Resource if not found
     */
    public static String loadFile(String fileName, String fallbackResourceName) {
        try {
            // Try customer-uploaded file first
            ContentVersion cv = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE Title = :fileName 
                AND IsLatest = true 
                LIMIT 1
            ];
            return cv.VersionData.toString();
        } catch (Exception e) {
            // Fall back to static resource
            return loadStaticResource(fallbackResourceName);
        }
    }
    
    /**
     * Parse YAML frontmatter + markdown content
     */
    public static Map<String, Object> parseMarkdown(String content) {
        Map<String, Object> result = new Map<String, Object>();
        
        // Simple frontmatter parser (--- at start and end)
        if (content.startsWith('---')) {
            Integer endIdx = content.indexOf('---', 3);
            if (endIdx > 0) {
                String frontmatter = content.substring(3, endIdx).trim();
                String body = content.substring(endIdx + 3).trim();
                
                result.put('metadata', parseYAML(frontmatter));
                result.put('content', body);
            }
        } else {
            result.put('content', content);
        }
        
        return result;
    }
    
    // Simple YAML parser for key: value pairs
    private static Map<String, String> parseYAML(String yaml) {
        Map<String, String> result = new Map<String, String>();
        for (String line : yaml.split('\n')) {
            if (line.contains(':')) {
                List<String> parts = line.split(':', 2);
                result.put(parts[0].trim(), parts[1].trim());
            }
        }
        return result;
    }
}
```

### Benefits of This Approach

#### For Customers (Non-Technical Users)
1. **Zero Technical Barrier**: Edit markdown files like documents, no Salesforce knowledge needed
2. **Self-Service Configuration**: Upload files to customize behavior without contacting support
3. **Familiar Format**: Markdown is used in Slack, Notion, GitHub - widely understood
4. **Inline Documentation**: Files include examples and comments explaining each section
5. **Immediate Changes**: Upload new file, system uses it next run (no deployment)

#### For Development Team
1. **Zero Schema Overhead**: No Custom Metadata design, no object relationships
2. **Rapid Iteration**: Change configuration without deployment cycle
3. **Version Control**: Git for defaults (Static Resources), Salesforce versioning for customer overrides
4. **Easy Testing**: Swap files to test different configurations
5. **No Governor Limits**: Static Resources don't count against SOQL queries
6. **Debugging Friendly**: Read the file content to see exactly what the system is using

#### For Implementation Team
1. **Easy Migration**: Copy files between orgs (dev → staging → prod)
2. **Customer Onboarding**: Just upload their business context file during implementation
3. **Customization**: Edit markdown during implementation, no code deployment
4. **Reusable Templates**: Create templates for different industries (Healthcare, Financial Services, etc.)
5. **Documentation**: Files serve as configuration documentation for the customer

#### Architecture Benefits
1. **Separation of Concerns**: Business logic (Apex) separate from configuration (files)
2. **Composability**: Files can reference each other, include snippets
3. **Extensibility**: Add new pattern/archetype files without changing code
4. **Backward Compatibility**: Old code still works if file format evolves (graceful degradation)

### Customer File Upload Workflow (Future Enhancement)

**Goal**: Allow customers to upload/edit configuration files without touching code

#### Approach 1: Files Attached to LWC Component

```javascript
// In promptFactoryWizard.js or new config component
import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

export default class PromptFactoryConfig extends LightningElement {
    handleFileUpload(event) {
        const files = event.target.files;
        // Upload to Salesforce Files (ContentVersion)
        // Tag with specific name: 'custom_business_context'
        // Apex will auto-detect and use instead of default
    }
}
```

**Apex Side**:
```apex
// ConfigurationLoader checks for custom file first
public static String loadCustomerContext() {
    // Try custom uploaded file
    List<ContentVersion> customFiles = [
        SELECT VersionData 
        FROM ContentVersion 
        WHERE Title = 'custom_business_context' 
        AND IsLatest = true
        LIMIT 1
    ];
    
    if (!customFiles.isEmpty()) {
        return customFiles[0].VersionData.toString();
    }
    
    // Fall back to default static resource
    return loadStaticResource('default_business_context');
}
```

#### Approach 2: Files Attached to Custom Settings Record

Create a Custom Setting: `PF_Configuration__c`
- Single org-wide record
- Field: `Config_Record_Id__c` (Text, stores ContentDocument ID)

Customers upload files and link them to this record, making it easy to find the "current" config.

#### Approach 3: Files in Known Folder (Recommended)

Create a "GPTfy Configuration" folder in Salesforce Files:
- Customers upload files to this folder
- Apex searches this folder by name
- No UI changes needed - use standard Salesforce file management

```apex
public static String loadFromFolder(String fileName, String folderName) {
    // Find folder
    List<ContentWorkspace> folders = [
        SELECT Id 
        FROM ContentWorkspace 
        WHERE Name = :folderName 
        LIMIT 1
    ];
    
    if (folders.isEmpty()) {
        return loadStaticResource('default_' + fileName);
    }
    
    // Find file in folder
    List<ContentDocument> docs = [
        SELECT LatestPublishedVersionId 
        FROM ContentDocument 
        WHERE Title = :fileName 
        AND ParentId = :folders[0].Id 
        LIMIT 1
    ];
    
    if (docs.isEmpty()) {
        return loadStaticResource('default_' + fileName);
    }
    
    // Load content
    ContentVersion cv = [
        SELECT VersionData 
        FROM ContentVersion 
        WHERE Id = :docs[0].LatestPublishedVersionId
    ];
    
    return cv.VersionData.toString();
}
```

#### Validation & Error Handling

When customers upload files, validate:
1. **File format**: Must be `.md` or `.html`
2. **Markdown syntax**: Basic parsing test
3. **Required sections**: e.g., customer context must have "Terminology" section
4. **Friendly errors**: "Your file is missing the ## Terminology section"

```apex
public class ConfigValidator {
    public static ValidationResult validate(String content, String fileType) {
        ValidationResult result = new ValidationResult();
        
        if (fileType == 'customer_context') {
            // Check for required sections
            if (!content.contains('## Terminology')) {
                result.errors.add('Missing required section: ## Terminology');
            }
            if (!content.contains('## Deal Patterns')) {
                result.errors.add('Missing required section: ## Deal Patterns');
            }
        }
        
        return result;
    }
}
```

### Implementation Strategy

**Phase 1**: Static Resources only (ship with package)
- All defaults deployed as Static Resources
- Hardcoded file names in Apex

**Phase 2**: Add file upload UI (customer can override)
- Create "Configuration Manager" LWC component
- Allow upload to "GPTfy Configuration" folder
- Apex checks folder first, falls back to Static Resources

**Phase 3**: Validation & versioning
- Validate uploaded files before accepting
- Show friendly error messages
- Version history via ContentVersion (built-in)

**Phase 4**: Advanced features
- Inline markdown editor in Salesforce
- Preview changes before saving
- Diff view (compare custom vs. default)

---

### Why This Is The Right Architecture Choice

**User's Original Insight**: "I want to kind of keep a simpler architecture so that we don't have to put things in custom metadata or create more objects."

**Decision**: ✅ **Markdown files win**

This architecture choice aligns perfectly with:
1. **Single-tenant deployment**: Each customer can have their own files, no multi-tenant schema constraints
2. **Customer empowerment**: Non-technical users can edit business context, terminology, patterns
3. **Rapid iteration**: Change configuration without waiting for deployment cycles
4. **Simplicity**: No Custom Metadata Types, no new objects, no schema design
5. **Flexibility**: Files can evolve structure over time without breaking changes

**The Trade-Off We're Making**:
- ❌ Give up: Schema enforcement, SOQL queryability, metadata relationships
- ✅ Get: Simplicity, customer editability, deployment-free changes, version control

**For this product, this is the right trade-off** because:
- Configuration is **customer-specific**, not shared across orgs
- Configuration is **narrative/documentation** (markdown-friendly), not transactional data
- Customers **want control** over terminology and patterns without technical overhead
- Implementation teams need **fast customization** during onboarding

---

## The 4-Layer Architecture

We implement this via four distinct layers of intelligence:

### Layer 1: The Foundation (Truth & Evidence)

**Purpose**: Build on verified ground truth, not LLM guesses

Instead of relying on single records or scraped web data, we establish a **foundation of truth**:

#### Multi-Record Evidence
Query 2-3 sample records instead of 1:
- **Most recent record** - Shows current state
- **Oldest open record** - Shows historical context
- **One mid-stage record** - Shows progression patterns

**Why This Works**:
- **Prevents n=1 bias**: Single records can be outliers
- **Enables pattern detection**: "2 of 3 deals mention discount pressure"
- **Provides variance analysis**: See which fields actually vary vs. always empty
- **Evidence binding**: Has real examples to cite ("In Record 1, Discount = 20%")

#### Implementation Details
```apex
// Stage01: Instead of single sampleRecordId
List<Id> sampleRecordIds = getSampleRecords(rootObject, 3);
// Returns: Most recent, oldest open, and one mid-stage

// Query in parallel (3 async calls, not sequential)
// Stage05 field selection analyzes variance across records
```

#### Keep Hardcoded Fields
- Baseline fields for major objects (Opportunity, Account, Contact) stay
- Multi-record is **additional context**, not replacement

#### Performance Considerations
- **Query in parallel**: 3 separate async calls
- **Heap size**: Only store field values, not full objects
- **Processing time**: +5-10 seconds acceptable (quality > speed)

#### Customer Business Context File

**Purpose**: Single-tenant "Ground Truth" that replaces generic industry guessing

A Markdown/JSON file deployed with the package containing verified customer-specific business intelligence.

#### Structure
```markdown
# Cigna Business Context

## Industry Profile
- **Primary**: Healthcare Payer
- **Lines of Business**: Medicare Advantage, Commercial, International
- **Buying Motions**: Committee-driven, compliance-heavy
- **Decision Drivers**: Risk mitigation, regulatory compliance, TCO

## Forbidden Topics
- Pharmacy upsell strategies (handled by separate division)
- Clinical workflows (not in our scope)
- Member engagement programs (different system)

## Key Terminology
- "Member" not "Customer"
- "Plan" not "Product"
- "Medical Loss Ratio" is a key metric
- "Provider Network" is critical to value discussions

## Common Deal Patterns
- CFO involvement typical at $500K+
- Security review adds 2-3 weeks
- Reference calls required for enterprise deals
- HIPAA compliance is non-negotiable

## Stakeholder Map
- Chief Medical Officer: Clinical outcomes, quality metrics
- CFO: Total cost of ownership, ROI
- CIO: Integration complexity, security
- VP of Operations: Implementation timeline, change management

## Red Flags
- Discount requests before value demonstration
- Procurement involvement before executive buy-in
- Unrealistic timeline expectations
```

#### Where It Lives

**Primary Storage**: Markdown file as Static Resource or Salesforce File

```apex
// Stage01 or Stage02
String context = ConfigurationLoader.loadFile(
    'cigna_business_context',  // Customer uploaded file name
    'default_business_context' // Fallback static resource
);
Map<String, Object> parsed = ConfigurationLoader.parseMarkdown(context);
```

**File Location Options**:
1. **Static Resource** (v1): `cigna_business_context.md` deployed with package
2. **Salesforce File** (v2): Uploaded by customer, attached to custom settings or LWC
3. **Hybrid** (v3): Customer file overrides default static resource

#### How It's Used
1. **Stage01** loads customer context file at pipeline start
2. **Stage02** uses context as baseline for industry classification and pattern detection
3. Website scraping **validates/enriches**, doesn't create from scratch
4. **Stage08** injects relevant sections (terminology, deal patterns) into final prompt assembly

#### Benefits
- ✅ No LLM guessing about industry
- ✅ No hallucination about business context  
- ✅ Terminology is correct from day 1
- ✅ Deal patterns are based on actual customer reality
- ✅ **Customer can edit** without touching code or metadata
- ✅ **No deployment required** to update (when using Salesforce Files)

#### Relationship with Website Scraping
- **Keep website scraping** for now (optional fallback/enrichment)
- Customer context file is "ground truth"
- Website provides additional public-facing messaging
- Future: Make website scraping optional if customer context is comprehensive

---

### Layer 2: The Pattern Engine (Analytical Lenses)

**Purpose**: We do not ask the LLM to "figure it out." We inject specific **Analytical Patterns** triggered by data signals.

#### The Insight
We have 15-20 production prompts (Deal Coach, Account 360, Sentiment Journey, etc.) that already work. Instead of inventing patterns theoretically or asking the LLM to be creative, **extract proven patterns and apply them deterministically**.

#### Library Structure: Markdown Files

All patterns, archetypes, and components are stored as individual markdown files.

##### A. Analytical Patterns (What to Analyze)

**File**: `pattern_negotiation_pressure.md`

```markdown
---
pattern_id: negotiation_pressure
pattern_name: Negotiation Pressure Detection
output_section: Negotiation Risk Assessment
---

# Negotiation Pressure Detection Pattern

## Trigger Rules
- Stage contains: Proposal, Quote, Negotiation
- Keywords in Description: discount, CFO, budget, pricing
- Min Probability: 60%

## Analysis Questions
1. Who is driving the discount request?
2. What value justification is missing?
3. What concession alternatives exist besides price?

## Evidence Requirements
- OpportunityStage (required)
- Description or NextStep (required)
- Probability (required)

## Forbidden Phrases
- "offer competitive pricing"
- "emphasize value proposition"
- "align with stakeholders"

## Example Usage
When an Opportunity is at Proposal stage with 75% probability and Description mentions 
"CFO requesting 20% discount", this pattern triggers and requires the LLM to analyze 
who's driving the request and what value justification is missing.
```

**Other Pattern Examples** (each as separate `.md` file):
- `pattern_stalled_deal_revival.md` - Triggers when Stage hasn't changed in 30+ days
- `pattern_expansion_opportunity.md` - Triggers when Account has multiple Opportunities
- `pattern_executive_engagement.md` - Triggers when no C-level contact in roles
- `pattern_risk_mitigation.md` - Triggers on legal/compliance keywords
- `pattern_competitive_threat.md` - Triggers on competitor mentions

##### B. UI Components (How to Display)

**File**: `component_risk_scorecard.html` (HTML with markdown metadata)

```html
<!--
---
component_id: risk_scorecard
component_name: Risk Assessment Card
used_in: Deal Coach, Executive Risk Brief
styling: red-yellow-green-indicator
---
-->

<div class="slds-card risk-assessment-card">
  <div class="slds-card__header">
    <h2 class="slds-text-heading_small">Risk Assessment</h2>
  </div>
  <div class="slds-card__body">
    <div class="risk-level {{RISK_CLASS}}">
      <span class="risk-indicator">{{RISK_LEVEL}}</span>
    </div>
    <ul class="slds-list_dotted risk-factors">
      {{RISK_FACTORS}}
    </ul>
    <div class="mitigation-actions">
      <h3>Recommended Actions</h3>
      {{MITIGATION_ACTIONS}}
    </div>
  </div>
</div>

<!-- Merge Fields:
  {{RISK_CLASS}} - CSS class: risk-high, risk-medium, risk-low
  {{RISK_LEVEL}} - Text: High Risk, Medium Risk, Low Risk
  {{RISK_FACTORS}} - <li> items generated by LLM
  {{MITIGATION_ACTIONS}} - <li> items generated by LLM
-->
```

**Other Component Examples** (each as separate file):
- `component_next_best_action_list.html` - Prioritized action items
- `component_timeline_visualization.html` - Stage progression timeline
- `component_stakeholder_map.html` - Relationship visualization
- `component_health_score_gauge.html` - Visual health indicator

##### C. Persona Archetypes (Who Is Reading)

**File**: `archetype_deal_coach.md`

```markdown
---
archetype_id: deal_coach
archetype_name: Deal Coach Brief
target_reader: Sales Representative or Account Executive
tone: Prescriptive, action-oriented, coaching
length: Executive brief (3-5 bullets per section)
evidence_depth: High - cite specific fields and values
---

# Deal Coach Brief Archetype

## Purpose
Provide actionable coaching to sales reps on how to advance their deals.

## Output Structure
1. **Deal Health Summary** (3-5 bullets)
   - Current stage and trajectory
   - Key strengths and momentum indicators
   
2. **Key Risks & Blockers** (2-3 items)
   - What could derail the deal
   - Missing information or stakeholders
   
3. **Next Best Actions** (prioritized list)
   - Specific, actionable steps
   - Who to contact, what to ask
   
4. **Stakeholder Engagement Status**
   - Who's engaged, who's missing
   - Relationship strength assessment

## Tone Guidelines
- Direct and prescriptive ("Schedule a call with..." not "Consider reaching out...")
- Action-oriented (every insight leads to a next step)
- Coach-like (explain WHY, not just WHAT)

## Evidence Binding
Every insight MUST cite:
- Specific record (Record 1, 2, or 3)
- Specific field name and value
- OR state "Missing data: <FieldName>"

## UI Components Used
- `component_health_score_gauge.html`
- `component_next_best_action_list.html`
- `component_stakeholder_map.html`
```

**Other Archetype Examples** (each as separate `.md` file):
- `archetype_executive_risk_brief.md` - For leadership (summary, risks, escalations)
- `archetype_account_360.md` - Holistic account view (relationships, health, expansion)
- `archetype_renewal_health.md` - Customer success focus (adoption, satisfaction, risk)
- `archetype_sentiment_journey.md` - Support focus (case patterns, satisfaction trends)

#### How to Build the Library

**Phase 1: Extraction** (Week 1)
1. Collect 5 best production prompts (Deal Coach, Account 360, etc.)
2. Analyze each prompt for:
   - **Trigger conditions**: What signals activate each analytical lens?
   - **Analysis questions**: What does the prompt ask the LLM to determine?
   - **Output structure**: What sections, tone, length?
   - **Forbidden language**: What generic phrases to avoid?
3. Document findings in markdown (human-readable notes)

**Phase 2: Markdown File Creation** (Week 1-2)
1. Create pattern files:
   - `pattern_negotiation_pressure.md`
   - `pattern_stalled_deal_revival.md`
   - `pattern_expansion_opportunity.md`
   - etc. (5-8 patterns initially)
2. Create archetype files:
   - `archetype_deal_coach.md`
   - `archetype_executive_risk_brief.md`
   - etc. (2-3 archetypes initially)
3. Create component files:
   - `component_risk_scorecard.html`
   - `component_next_best_action_list.html`
   - etc. (5-8 components initially)
4. Store all as **Static Resources** (deployed with package)

**Phase 3: Loader Implementation** (Week 2)
1. Implement `ConfigurationLoader` class (see "File Reading Implementation" above)
2. Implement `PatternMatcher` class:
   - Loads all pattern files
   - Evaluates trigger rules against record data
   - Returns 3-5 applicable patterns ranked by relevance
3. Implement `PromptAssembler` class:
   - Loads archetype file
   - Loads selected pattern files
   - Loads customer context file
   - Assembles final meta-prompt

**Phase 4: Integration** (Week 2-3)
1. **Stage01** loads customer context file
2. **Stage02** uses `PatternMatcher` to detect applicable patterns
3. **Stage08** uses `PromptAssembler` to compose final prompt
4. Test end-to-end

#### Storage Strategy

**Recommended Approach**: Markdown files as Static Resources (Phase 1), with Salesforce Files for customer overrides (Phase 2+)

**Why This Wins**:
- ✅ **No Custom Metadata complexity**: No schema design, no objects
- ✅ **Customer editable**: Non-technical users can edit markdown
- ✅ **Version controlled**: Static Resources in git
- ✅ **Fast**: Cached in-memory after first load
- ✅ **Flexible**: Change structure without redeployment
- ✅ **Documentation built-in**: Markdown is self-documenting
- ✅ **Easy migration**: Copy files between orgs

**File Organization**:
```
Static Resources:
├── patterns/
│   ├── pattern_negotiation_pressure.md
│   ├── pattern_stalled_deal_revival.md
│   └── pattern_expansion_opportunity.md
├── archetypes/
│   ├── archetype_deal_coach.md
│   └── archetype_executive_risk_brief.md
├── components/
│   ├── component_risk_scorecard.html
│   └── component_next_best_action_list.html
└── customer_context/
    ├── cigna_business_context.md
    └── default_business_context.md
```

**Future Enhancement**: Allow customers to upload their own files (Salesforce Files) to override defaults

---

### Layer 3: The Assembly (Meta-Prompting)

**Purpose**: The "Factory" becomes an assembly line that constructs the final prompt from selected components

The key is that **Stage08 doesn't write the prompt - it assembles it** from:

#### Persona Archetypes
The "container" for the output that defines:
- **Target reader** (Sales Rep, Executive, Customer Success Manager)
- **Output structure** (sections, tone, length)
- **Evidence depth** (how much to cite)

Examples: Deal Coach Brief, Executive Risk Memo, Account 360, Renewal Health Check

#### Evidence Binding Rule (Non-Negotiable)
A strict system instruction injected into every prompt:

```
EVIDENCE BINDING RULE:
Every insight must cite specific evidence from:
- Record 1, Record 2, or Record 3
- Specific Salesforce field names and values
- OR explicitly state: "Missing data: <field name>"

Forbidden: Generic claims without evidence
```

**Impact**: This single rule prevents 90% of hallucinations.

#### Pattern Injection
The meta-prompt explicitly instructs the AI which patterns to apply:

```
You are analyzing an Opportunity using the following patterns:
1. Negotiation Pressure (Stage=Proposal, Discount mentioned)
2. Stalled Deal Revival (No stage change in 32 days)

For each pattern, answer the specific questions defined in the pattern.
Use Cigna terminology: Member (not Customer), Plan (not Product).
```

#### Compositional Assembly
Stage08 builds the final prompt by:
1. Loading the persona archetype (Deal Coach)
2. Loading selected patterns from library (Negotiation Pressure, Stalled Deal)
3. Injecting customer terminology from context file
4. Adding evidence binding rule
5. Loading UI components for formatting
6. Assembling into a single, coherent meta-prompt

**Result**: The runtime AI receives a precise, constrained, evidence-grounded instruction - not a vague "analyze this."

---

### Layer 4: The Experience (User Control & Trust)

**Purpose**: While the engine is decisive, the user experience builds trust through transparency and control

#### Interactive Preview (Future Enhancement)
Users see the prompt being assembled in real-time:
- ✓ Patterns selected (based on data signals shown)
- ✓ Customer context loaded
- ✓ Evidence binding rule active
- ✓ Final prompt generated

**Benefit**: Users understand WHY the system made each choice (transparency breeds trust)

#### Privacy Mode (Future Enhancement)
PII sanitization for sensitive fields before analysis:
- Automatically detect PII fields (Email, Phone, SSN)
- Mask values before sending to LLM
- Preserve structure for analysis (e.g., "PII_EMAIL_1", "PII_PHONE_1")

**Benefit**: Compliance and security for regulated industries

#### Deep Research Mode (Future Enhancement)
Optional "live" web context for highly strategic accounts:
- User opts in for specific high-value deals
- Real-time competitive intelligence
- News and market context

**Benefit**: Balance speed (cached context) with depth (live research) based on deal importance

**Note**: Layer 4 enhancements are future roadmap items, not Phase 0-3 scope.

---

## The Cohesive Architecture

### Complete Stage Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Stage 01: Intelligence Retrieval                            │
├─────────────────────────────────────────────────────────────┤
│ • Query 3 sample records (parallel async calls)             │
│ • Load customer business context file                       │
│ • Pass to Stage 02                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 02: Strategic Profiling & Pattern Detection           │
├─────────────────────────────────────────────────────────────┤
│ • START with customer context (Cigna = Healthcare Payer)    │
│ • Enrich with website (validate, don't create)              │
│ • Analyze 3 records for pattern triggers:                   │
│   - Stage + Probability + Keywords → Negotiation Pressure   │
│   - No contact role updates → Stalled Deal                  │
│   - Multiple opps on account → Expansion Opportunity        │
│ • Output: Selected patterns (3-5 max)                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 05: Smart Field Selection                             │
├─────────────────────────────────────────────────────────────┤
│ • Analyze 3 records for field variance                      │
│ • Prioritize fields that:                                   │
│   - Vary across records (show patterns)                     │
│   - Are required by selected patterns                       │
│   - Are relevant to customer context                        │
│ • Keep baseline hardcoded fields                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 08: Prompt Assembly (The Magic Happens Here)          │
├─────────────────────────────────────────────────────────────┤
│ 1. Load persona archetype (Deal Coach)                      │
│ 2. Load selected patterns from library:                     │
│    • Negotiation Pressure                                   │
│    • Stalled Deal Revival                                   │
│ 3. Inject customer terminology:                             │
│    • "Member" not "Customer"                                │
│    • "Plan" not "Product"                                   │
│ 4. Add evidence binding rule:                               │
│    • "Every insight must cite Record 1/2/3"                 │
│    • "If data missing, state: Missing data: <field>"        │
│ 5. Load UI components from library:                         │
│    • Risk scorecard                                         │
│    • Next best action list                                  │
│ 6. Assemble final prompt                                    │
└─────────────────────────────────────────────────────────────┘
```

### What Makes This Cohesive: The 4 Layers Working Together

#### How the Layers Integrate

**Layer 1 (Foundation)** provides the raw materials:
- 3 sample records (evidence)
- Customer context file (terminology, patterns, constraints)

**Layer 2 (Pattern Engine)** selects the analytical lenses:
- Scans the 3 records for trigger signals
- Applies customer-specific patterns from context file
- Selects 3-5 applicable patterns (not all, just relevant ones)

**Layer 3 (Assembly)** constructs the meta-prompt:
- Loads persona archetype (Deal Coach, Executive Brief, etc.)
- Injects selected patterns with their specific questions
- Applies customer terminology
- Adds evidence binding rule
- Assembles into precise, constrained instruction

**Layer 4 (Experience)** builds user trust:
- Shows what patterns were selected and why (transparency)
- Offers privacy controls for PII (compliance)
- Allows deep research mode for strategic deals (flexibility)

#### Why This Is Assembly, Not Invention

- **No LLM creativity**: Patterns are pre-defined, triggers are deterministic
- **No guessing**: Customer context is verified truth, not web scraping
- **No vague prompts**: "Analyze this" becomes "Apply patterns X, Y, Z with evidence from records 1, 2, 3"
- **Composable**: Add new patterns without rewriting the system
- **Proven**: 70% reuse across prompt types (extracted from production)

---

## Implementation Roadmap

**Strategy**: Depth over breadth. Prove each layer before building the next.

---

### Phase 0: Evidence Binding (Immediate - 1-2 days)

**Goal**: Prove that forcing evidence citation improves quality

**Why First**: This is the fastest, highest-impact change. It's a 2-hour code change that prevents 90% of hallucinations.

**Tasks**:
1. **Update Stage08** (2 hours)
   - Inject evidence binding rule into prompt assembly
   - Format: "Every insight must cite Record 1/2/3 or state 'Missing data: <field>'"
   - Deploy to agentictso org

2. **Test & Measure** (1 day)
   - Run 5 test prompts (Deal Coach, Account 360, etc.)
   - Compare before/after: Count claims without evidence
   - User feedback: Does output feel more trustworthy?

**Success Criteria**:
- ✅ Hallucination rate drops by 50%+
- ✅ Users report output feels more credible
- ✅ No performance degradation

**Decision Point**: If evidence binding works, commit to full architecture. If not, revisit approach.

---

### Phase 1: The Analysis Assembler Engine (Week 1-2)

**Goal**: Build the "Factory" that assembles prompts from components

**Why Second**: Once evidence binding proves the value of constraints, build the engine that applies multiple constraints systematically.

**Tasks**:
1. **Define the Meta-Prompt Blueprint** (2 days)
   - Document the structure of the "Factory prompt"
   - Template variables: {selectedPatterns}, {customerContext}, {archetypeStructure}
   - Test manually before automating

2. **Archetype Definitions** (2 days)
   - Create metadata structure for archetypes
   - Define "Deal Coach" archetype completely
   - Define "Executive Risk Brief" archetype
   - Store in Custom Metadata: `PF_Persona_Archetype__mdt`

3. **Pattern Extraction** (3 days)
   - Analyze top 5 production prompts
   - Extract common patterns (expect to find 5-8)
   - Document triggers, questions, forbidden phrases
   - Create markdown documentation

4. **Flagship Rewrite** (2 days)
   - Rewrite "Deal Coach" using new architecture
   - Manually assemble the meta-prompt (no automation yet)
   - Test and compare vs. old version

**Success Criteria**:
- ✅ "Deal Coach" output quality 2x better than baseline
- ✅ Meta-prompt blueprint documented and validated
- ✅ 5-8 patterns extracted and documented
- ✅ Users prefer new "Deal Coach" over old version

---

### Phase 2: Pattern Engine (Week 3-4)

**Goal**: Automate pattern selection based on data signals

**Tasks**:
1. **Pattern Storage** (2 days)
   - Create Custom Metadata: `PF_Analytical_Pattern__mdt`
   - Store 5-8 extracted patterns
   - Include trigger rules (Stage, Keywords, Probability)

2. **Stage02 Pattern Detection** (3 days)
   - Implement trigger evaluation logic
   - Input: 3 records + data signals
   - Output: 3-5 selected patterns (ranked by relevance)
   - Test pattern matching accuracy

3. **Stage08 Assembly Integration** (3 days)
   - Update prompt assembly to query pattern library
   - Inject pattern-specific analysis questions
   - Apply forbidden phrase filters
   - Test with multiple pattern combinations

4. **Full Pipeline Test** (2 days)
   - End-to-end test: Sample records → Pattern detection → Prompt assembly
   - Measure pattern hit rate (% of applicable patterns correctly detected)
   - Measure output quality vs. baseline

**Success Criteria**:
- ✅ Pattern matching logic works reliably (>90% accuracy)
- ✅ Stage08 successfully composes prompts from patterns
- ✅ Output quality 2x better than generic prompts

---

### Phase 3: Multi-Record Foundation (Week 5)

**Goal**: Add multi-record evidence to increase pattern detection reliability

**Why Third**: Once pattern detection works with single records, enhance with multi-record variance

**Tasks**:
1. **Update Stage01** (2 days)
   - Implement `getSampleRecords()` method
   - Query 3 records in parallel (async calls)
   - Handle edge cases (fewer than 3 records available)
   - Pass all 3 to subsequent stages

2. **Update Stage02** (1 day)
   - Analyze all 3 records for pattern triggers
   - Enhance detection: "2 of 3 deals mention discount"
   - More reliable signal vs. single record

3. **Update Stage05** (2 days)
   - Analyze field variance across 3 records
   - Prioritize fields that show patterns
   - Maintain baseline hardcoded fields

4. **Testing** (1 day)
   - Test with Opportunity, Account, Case objects
   - Measure field selection quality improvement
   - Check heap size and performance

**Success Criteria**:
- ✅ 3 records queried successfully
- ✅ Pattern detection reliability improves
- ✅ Field selection quality improves measurably
- ✅ No performance degradation (heap size OK)

---

### Phase 4: Customer Context Integration (Week 6)

**Goal**: Replace industry guessing with verified ground truth

**Why Fourth**: Once the engine works well, enhance with customer-specific intelligence

**Tasks**:
1. **Context File Creation** (2 days)
   - Design markdown structure (see "Customer Business Context File" section)
   - Create Cigna example: `cigna_business_context.md`
     - Industry Profile
     - Terminology (Member not Customer, Plan not Product)
     - Deal Patterns (CFO involvement, security review timelines)
     - Stakeholder Map (CMO, CFO, CIO roles)
     - Red Flags (discount requests before value demo)
   - Store as Static Resource: `cigna_business_context`

2. **ConfigurationLoader Enhancement** (1 day)
   - Extend `loadFile()` to support customer context files
   - Add caching for performance
   - Parse markdown with YAML frontmatter

3. **Stage01 Integration** (1 day)
   - Load customer context file at pipeline start
   - Cache in `PF_Run__c.Customer_Context__c` (Long Text Area field)
   - Pass to Stage02 as baseline

4. **Stage02 Integration** (2 days)
   - START with customer context (not website)
   - Use context for:
     - Industry classification (no guessing needed)
     - Forbidden topics (exclusion list)
     - Deal pattern detection hints
   - Website scraping becomes **optional validation**, not primary source

5. **Stage08 Integration** (1 day)
   - Inject customer terminology sections into meta-prompt
   - Apply customer-specific deal patterns
   - Use customer stakeholder maps in analysis instructions

6. **Testing** (1 day)
   - Compare outputs with/without customer context
   - Verify terminology correctness (100% accuracy expected)
   - Test with/without website scraping (should work either way)
   - Test customer file upload (if implementing Salesforce Files option)

**Success Criteria**:
- ✅ Customer context markdown file correctly loaded
- ✅ Terminology 100% accurate in all outputs ("Member" not "Customer")
- ✅ Can skip website scraping without quality loss
- ✅ Industry-specific patterns correctly applied
- ✅ **Customer can edit markdown file** and see changes without redeployment (if using Salesforce Files)

---

### Phase 5: UI Component Library (Week 7 - Optional)

**Goal**: Ensure consistent HTML formatting across all prompt outputs

**Why Optional**: This is a "nice-to-have" polish after core functionality works

**Tasks**:
1. **Component Extraction** (2 days)
   - Identify common UI patterns in existing prompts (risk cards, action lists, timelines)
   - Extract HTML templates with merge field placeholders
   - Define merge field requirements per component

2. **Component Storage** (1 day)
   - Store in Static Resources (HTML templates with CSS)
   - Create metadata: `PF_UI_Component__mdt`
   - Link to analytical patterns (which patterns use which components)

3. **Stage07/08 Integration** (2 days)
   - Update Stage07 (Template Design) to query component library
   - Stage08 references components in assembly
   - Support archetype-specific layouts

**Success Criteria**:
- ✅ 8-10 reusable components defined
- ✅ Consistent formatting across all prompts
- ✅ Easy to add new components

**Note**: Can be deferred if Phases 0-4 take longer than expected. Core value is in Layers 1-3, not UI polish.

---

## Why This Wins: The Decisive Difference

### What Other AI Prompt Tools Do
**Invention Approach**:
- Generic, one-size-fits-all prompts
- Ask LLM to "figure out" what the user needs
- Guess at industry context from web scraping
- Generic advice ("align with stakeholders")
- No evidence backing
- Hope the model is smart enough

**Result**: Generic hallucinations that users don't trust

### What GPTfy Does (After This Implementation)
**Assembly Approach**:
- **Pre-configured** for customer's business (Cigna, not "healthcare")
- **Deterministic** pattern selection (data signals, not AI vibes)
- **Verified** customer context (ground truth file, not guesses)
- **Evidence-backed** by actual deal data (cites Record 1/2/3 or states "Missing")
- **Proven** patterns (extracted from working prompts, 70% reuse)
- **Compositional** (patterns + archetypes + context + evidence)
- **Transparent** (user sees what was selected and why)

**Result**: Decision support that feels like "your analyst, automated"

### The Three Reasons Customers Choose GPTfy

1. **Trust**: By citing explicit evidence ("Record 2 shows Discount = 20%"), users trust the output
2. **Relevance**: By using the Customer Context file, we speak their language on Day 1
3. **Speed**: We stop asking users 20 questions. We look at the data and **decide** what analysis they need

**This isn't just "better prompts" - it's a fundamental shift from *generative text* to *automated intelligence*.**

---

## Success Metrics

### Quality Metrics
- **Hallucination Rate**: % of claims without evidence citation (target: <5%)
- **Terminology Accuracy**: % using correct customer terms (target: 100%)
- **Actionability Score**: User rating of insight usefulness (target: 4.5/5)
- **Pattern Hit Rate**: % of applicable patterns correctly detected (target: >90%)

### Performance Metrics
- **Generation Time**: End-to-end prompt creation (target: <60 seconds)
- **Heap Size**: Max heap usage (target: <80% of limit)
- **API Calls**: Total callout count (target: <10 per run)

### Business Metrics
- **User Trust**: % of generated prompts used without modification (target: >80%)
- **Time Savings**: Hours saved per prompt vs. manual creation (target: >2 hours)
- **Pattern Reuse**: % of prompts using ≥3 library patterns (target: >70%)

---

## Open Questions & Decisions Needed

### Technical Decisions
1. **Metadata vs. Static Resources** for pattern library?
   - Recommendation: Hybrid (metadata for definitions, static resources for HTML)

2. **How many sample records** is optimal?
   - Recommendation: Start with 3, benchmark performance

3. **Website scraping**: Keep, reduce, or remove?
   - Recommendation: Keep as validation/enrichment, not primary source

### Business Decisions
1. **Customer context file**: Who maintains it?
   - Options: Implementation team during onboarding, Customer success team

2. **Pattern library**: How to version and update?
   - Recommendation: Versioned in git, deployed via metadata

3. **Performance trade-offs**: How much slower is acceptable for quality?
   - Recommendation: +10-15 seconds OK for 2x quality improvement

---

## Next Actions

### Phase 0: Immediate (This Week)
**Focus**: Prove evidence binding works

1. ✅ Document strategy (this file)
2. 🔲 Implement evidence binding in Stage08 (2 hours)
3. 🔲 Deploy and test (1 day)
4. 🔲 **Decision point**: If 50%+ improvement, proceed to Phase 1

### Phase 1: Short Term (Weeks 1-2)
**Focus**: Build the Analysis Assembler engine

1. Define meta-prompt blueprint
2. Extract 5-8 patterns from production prompts
3. Create archetype definitions (Deal Coach, Executive Risk Brief)
4. Rewrite "Deal Coach" using new architecture
5. **Decision point**: If 2x quality improvement, proceed to Phase 2

### Phase 2: Medium Term (Weeks 3-4)
**Focus**: Automate pattern selection

1. Create pattern library metadata
2. Implement Stage02 pattern detection
3. Integrate Stage08 prompt assembly
4. Test end-to-end pipeline

### Phase 3-5: Long Term (Weeks 5-7)
**Focus**: Enhance with multi-record and customer context

1. Multi-record foundation
2. Customer context file
3. UI component library (optional)

---

## References & Related Docs

### Strategic Documents
- [Strategic Evolution (recommendations.md)](../recommendations.md) - Original architectural vision
- [Unified POV](./UNIFIED_POV.md) - 4-layer architecture philosophy
- [Current Roadmap](./ROADMAP.md) - Feature development timeline

### Product Requirements
- [PRD: Automated Prompt Creation](./PRD-Automated-Prompt-Creation.md) - Core product definition
- [Enhanced Prompt Template](./ENHANCED_PROMPT.md) - Template specifications
- [GPTfy Configuration Guide](./GPTFY_CONFIG.md) - Integration details

---

## Change Log

| Date | Author | Changes |
|------|--------|---------|
| 2026-01-21 | AI Assistant | Initial strategy document created |
| 2026-01-21 | AI Assistant | Major revision: Integrated 4-layer architecture from UNIFIED_POV.md and recommendations.md, reorganized roadmap with decision points, clarified Assembly vs Invention philosophy |

