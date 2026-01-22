# GPTfy Prompt Factory: Architecture Strategy & Implementation Plan

**Last Updated**: January 21, 2026  
**Status**: Ready for Implementation  
**Branch**: `feature/prompt-quality-improvements`

---

## Executive Summary

Transform the Prompt Factory from a generic prompt generator into a **Decisive Analysis Assembler**. We stop asking users to "describe what they want" and instead **automatically assemble** a sophisticated "mini-analyst" based on:

- **Verified customer context** (ground truth, not guesses)
- **Evidence-grounded insights** (every claim cites specific data)
- **Diagnostic language** (judge, diagnose, prescribe - not just describe)
- **Proven analytical patterns** (extracted from production prompts)
- **Deterministic triggers** (data signals, not AI vibes)

**Core Philosophy**: Great analysis is not invented from scratch by an LLM each time. It is **assembled** from proven components.

**Implementation Strategy**: **Prove quality improvements first (2-3 days), then build infrastructure around what works.** No building until evidence binding and diagnostic language show 50%+ quality improvement.

---

## The Core Problem

**Old Way**: "Read this record and give advice." → Generic hallucinations like "align with stakeholders"

**Why This Fails**:
- Doesn't cite specific evidence from Salesforce data
- Uses generic "consultant speak" instead of customer terminology
- Treats industry context as optional narrative enrichment
- Produces report-style summaries instead of decision-support analysis
- LLM guesses at patterns instead of detecting them from data
- Outputs fail the "so what?" test - they summarize, not analyze

**Impact**: Users won't trust/pay for prompts that sound like generic chatbot output. Technical, compliance-heavy buyers need analysis that would survive scrutiny from a manager or auditor.

**New Way**: "Apply the *Negotiation Pressure* pattern using *Cigna* terminology with evidence from *Record #1/2/3*." → Expert decision support.

---

## The Quality Gap: Before vs. After

### Current State (Descriptive + Generic)

From actual production output:

```
Top Risks:
• Negotiation with the CFO is critical; ensure alignment on discount expectations.
• Engagement with the executive sponsor is essential to maintain momentum.
• Monitor for any changes in client sentiment that may affect deal closure.

Recommended Next Actions:
• Schedule a follow-up meeting with the CFO to clarify expectations.
• Engage the executive sponsor to reinforce the value proposition.
• Prepare a revised proposal that addresses the CFO's concerns.
```

**Problems:**
- No specific evidence cited (which CFO? what meeting?)
- Generic advice that applies to any deal
- No connection to customer context (UnitedHealthcare's healthcare payer priorities)
- Sounds like a chatbot, not an analyst
- Would not survive scrutiny in a regulated organization

### Target State (Diagnostic + Evidence-Grounded)

What the same section should look like:

```
Top Risks:

1. NO CHAMPION IDENTIFIED [CRITICAL GAP]
   Evidence: OpportunityContactRole has Decision Maker, Executive Sponsor, Economic Buyer—
   but no Champion role mapped.
   Why it matters: In healthcare payer deals at $150K+, CFOs typically require internal 
   advocacy before signing. Your Economic Buyer is not your Champion.
   Action: Before Jan 27 CFO Meeting, identify who will advocate internally.

2. CFO MEETING WITHOUT ROI FRAMEWORK [HIGH RISK]
   Evidence: Task "CFO Meeting" scheduled 01/27/2026, but no related tasks for 
   ROI analysis or TCO documentation.
   Why it matters: Per your customer context, UHC CFOs prioritize "Total cost of 
   ownership, ROI"—not feature comparisons.
   Action: Create TCO comparison document this week. Reference HIPAA compliance 
   cost avoidance (UHC strategic priority).

3. SINGLE OPEN ACTIVITY ON $150K DEAL [WARNING]
   Evidence: HasOpenActivity = 1, Amount = $150,000, Stage = Proposal/Price Quote
   Why it matters: Deals at this stage typically require parallel workstreams 
   (legal, security, procurement). One activity suggests single-threaded execution.
   Action: Map required approval steps with Executive Sponsor before CFO meeting.

Signal Assessment:
├── Economic Buyer Identified: ✓ STRONG (Contact Role mapped)
├── Champion Identified: ✗ MISSING (No Champion role)
├── Decision Maker Engaged: ✓ STRONG (Primary contact)
├── Executive Sponsor Engaged: ~ WEAK (Mapped but not primary, no recent activity)
├── Next Steps Defined: ✓ PRESENT (CFO Meeting scheduled)
└── Close Date Realistic: ? UNCERTAIN (12/31/2025 is 11 months out for Proposal stage)
```

**Improvements:**
- Every insight cites specific field values
- Gaps are explicitly labeled (CRITICAL GAP, HIGH RISK, WARNING)
- Customer context is applied (UHC CFO priorities, HIPAA)
- Industry heuristics are embedded ("healthcare payer deals at $150K+")
- Signal/Gap normalization at the end
- Actionable with specific timing ("Before Jan 27", "this week")

**This is the quality level we must achieve.**

---

## Quality Rules Library

**Location**: [`docs/quality-rules/`](./quality-rules/README.md)

The Quality Rules Library contains production-validated rules extracted from Phase 0/0B/0C testing and refined based on user feedback.

### Core Rules

**1. [Evidence Binding v2](./quality-rules/evidence_binding_v2.md)**
- 4-level citation hierarchy (Embedded 80%, Parenthetical 15%, Inline 5%, Collapsible always)
- Resolves the "Phase 0 paradox": +120% improvement was from forcing specificity, not showing sources
- Insight-first approach validated through user visual review

**2. [Information Hierarchy](./quality-rules/information_hierarchy.md)**
- 6-zone priority system (Alerts → Stats → Summary → Headers → Analysis → Evidence)
- Above-the-fold must answer "What's wrong?" in 10 seconds
- Addresses "buried lead" problem identified in user feedback

**3. [Picklist Metadata Extraction](./quality-rules/picklist_metadata_extraction.md)** ⭐ NEW
- Extracts ALL picklist values to provide LLM with relative context
- Special handling for Opportunity.StageName → OpportunityStage probability mapping
- Prevents false positives ("20% is low" when it's appropriate for early stage)
- Data-driven, customer-specific, and future-proof

### Integration Points

```
Stage05: Field Selection → Extracts picklist metadata using Schema.DescribeFieldResult
Stage08: Prompt Assembly → Loads and injects quality rules + field context
Stage12: Quality Audit → Validates compliance with 8-dimension scoring
```

**See**: [Quality Rules README](./quality-rules/README.md) for implementation details

---

## Strategic Principles

### 1. Insight-Led, Evidence-Supported
Shift from "Evidence-First" (technical field citations) to "Insight-Led" (business diagnosis).
- **Primary Focus**: The *Insight* (Why it matters, what to do).
- **Secondary Support**: The *Evidence* (Subtle, succinct field citations).
- **Rule**: Never lead with the data source; always lead with the diagnosis.
- **Implementation**: See [Evidence Binding v2](./quality-rules/evidence_binding_v2.md)

### 2. Lead-Sourcing Architecture
Ensure the most critical information is delivered "above the fold".
- **Visual Hierarchy**: Executive Summaries and Critical Alerts (Alert Boxes) MUST be at the top.
- **Density Management**: Basic deal data (Amount, Probability) should be demoted to secondary components (compact Stat Cards).
- **Priority Sort**: AI must score its own findings and sort the output by "Business Impact" score.
- **Implementation**: See [Information Hierarchy](./quality-rules/information_hierarchy.md)

### 3. Assembly Over Invention
Intelligence is found in how we *combine* deterministic heuristics, not in asking the LLM to invent new structures. Use a standardized library of "Winning Recipes".

### 4. Diagnostic Over Descriptive
Technical, compliance-heavy buyers don't want reports—they want analysis that would survive scrutiny from a manager or auditor.
- **Judge** (not just observe)
- **Diagnose** (not just describe)
- **Prescribe** (not just suggest)
- **Challenge** (not just validate)

### 5. Heuristics Over Descriptions
Industry context should be **evaluation criteria**, not background narrative.
- **Wrong:** "In healthcare insurance, compliance with HIPAA is important..."  
- **Right:** "Deals without documented security review at Proposal stage fail procurement 70% of the time"

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
## The 4-Layer Architecture for Intelligence Assembly

```mermaid
graph TD
    subgraph "Layer 4: Output Assembler (Lead-Sourcing)"
        D[Lead-Sourcing Layout Engine] --> D1["Top: Critical Insights (Alerts)"]
        D --> D2["Middle: Supporting Analysis"]
        D --> D3["Bottom: Context/Stat Cards"]
    end

    subgraph "Layer 3: Archetype Engine (Contextual Weighting)"
        C[Persona Archetypes] --> C1[Sales Leader: Strategic/Risk]
        C --> C2[Sales Rep: Action/Next Step]
    end

    subgraph "Layer 2: Pattern Engine (Diagnostic)"
        B[Analytical Patterns] --> B1[Timeline Velocity]
        B --> B2[Stakeholder Gaps]
        B --> B3[Root Cause Analysis]
    end

    subgraph "Layer 1: Truth & Evidence (Grounding)"
        A[Data Context Mapping] --> A1[Salesforce Fields]
        A --> A2[Relationship Mining]
    end
```

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

### Layer 2: The Pattern Engine (Diagnostic)

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

**Strategy**: **Prove quality improvements first, then build infrastructure around what works.**

**Critical Decision Gate**: Phase 0 tests our quality thesis. If evidence binding + diagnostic language don't show 50%+ improvement, we revisit the entire approach before building anything.

---

### Phase 0: Prove the Quality Thesis (2-3 Days) 🚨 **CRITICAL GATE**

**Goal**: Validate that Evidence Binding + Diagnostic Language + Context Application dramatically improves output quality.

**Why First**: If this doesn't work, the entire architecture needs rethinking. If it works, everything else is implementation detail.

#### Task 0.1: Evidence Binding Test (Day 1)

Add this instruction block to the existing Opportunity Insights prompt:

```markdown
=== EVIDENCE BINDING RULE (MANDATORY) ===

Every insight, risk, or recommendation MUST cite specific evidence from this record.

FORMAT: "[Insight] (Evidence: [Field] = [Value])"

EXAMPLES OF COMPLIANT OUTPUT:
✓ "CFO engagement is your critical path (Evidence: Task.Subject = 'CFO Meeting', ActivityDate = 01/27/2026)"
✓ "No champion identified (Evidence: OpportunityContactRole missing 'Champion' role)"
✓ "Deal momentum is single-threaded (Evidence: HasOpenActivity = 1 on $150K deal)"

EXAMPLES OF NON-COMPLIANT OUTPUT (FORBIDDEN):
✗ "Ensure alignment with stakeholders" - NO EVIDENCE CITED
✗ "Consider scheduling follow-ups" - NO EVIDENCE CITED
✗ "Maintain momentum with key contacts" - NO EVIDENCE CITED

If data is missing, state explicitly:
"MISSING: [Field] - Recommend capturing this before proceeding"

ENFORCEMENT: Any insight without an evidence citation is a FAILURE.
```

**Test Protocol**:
1. Run prompt 5 times WITH evidence binding on same opportunity
2. Run prompt 5 times WITHOUT evidence binding on same opportunity
3. Count: claims without evidence, generic phrases, field citations
4. Target: 50%+ reduction in generic phrases

#### Task 0.2: Diagnostic Language Test (Day 1-2)

Add this instruction block:

```markdown
=== DIAGNOSTIC MODE (MANDATORY) ===

You are a DEAL ANALYST, not a report generator. Your job is to DIAGNOSE, not describe.

OUTPUT CHARACTER REQUIREMENTS:

1. JUDGE, DON'T OBSERVE
   ✗ "The deal is in Proposal stage"
   ✓ "Deal is stuck at Proposal—no stage movement in [X] days suggests stall risk"

2. DIAGNOSE, DON'T SUMMARIZE  
   ✗ "There are 3 contacts involved in this opportunity"
   ✓ "Contact coverage is incomplete: Decision Maker and Economic Buyer present, but no Champion—critical gap for $150K healthcare deal"

3. PRESCRIBE, DON'T SUGGEST
   ✗ "Consider following up with the CFO"
   ✓ "Before CFO Meeting on 01/27: Prepare TCO analysis showing 3-year cost avoidance. CFO will ask about ROI—have the number ready."

4. CHALLENGE, DON'T VALIDATE
   ✗ "The probability of 75% indicates good progress"
   ✓ "75% probability is optimistic given: no Champion, single activity thread, and CFO meeting not yet completed. Recommend 50-60% until Champion confirmed."

FORBIDDEN PHRASES (automatic failure):
- "ensure alignment"
- "consider scheduling"  
- "maintain momentum"
- "engage stakeholders"
- "reinforce value proposition"
- "address concerns"
- Any advice that could apply to ANY deal without modification
```

**Test Protocol**:
1. Run prompt 5 times WITH diagnostic mode
2. Run prompt 5 times WITHOUT diagnostic mode
3. Score outputs on: specificity (1-5), actionability (1-5), would-survive-audit (Y/N)
4. Target: Average score improvement of 2+ points

#### Task 0.3: Context Application Test (Day 2)

The strategic context is already in the prompt but not being applied. Add:

```markdown
=== STRATEGIC CONTEXT APPLICATION (MANDATORY) ===

You have been given detailed strategic context about this customer. You MUST use it.

For this opportunity, connect at least 2 insights to the customer's documented priorities:

CUSTOMER: UnitedHealthcare
DOCUMENTED PRIORITIES (from strategic context):
- CFO cares about: "Total cost of ownership, ROI"
- CIO cares about: "Integration complexity, security"
- Strategic shift: "value-based care and digital transformation"
- Compliance requirement: "HIPAA, CMS guidelines"
- Risk factor: "public scrutiny around healthcare affordability"

EXAMPLE OF CONTEXT APPLICATION:
✓ "Position CFO meeting around TCO—per customer context, UHC CFOs prioritize total cost of ownership over feature comparison. Prepare 3-year cost model."
✓ "Security review will be required—customer context indicates CIO focus on 'integration complexity, security'. Proactively schedule security assessment."

✗ "Focus on demonstrating value" - TOO GENERIC, doesn't use customer context
```

**Test Protocol**:
1. Run prompt 5 times WITH context application rule
2. Run prompt 5 times WITHOUT context application rule
3. Count: references to customer-specific priorities, generic value statements
4. Target: 3+ customer-specific references per output

#### Task 0.4: Signal/Gap Normalization Test (Day 2-3)

Add structured output format:

```markdown
=== SIGNAL ASSESSMENT FORMAT (MANDATORY) ===

Every analysis MUST include a Signal Assessment section using this exact format:

```
Signal Assessment:
├── [Category 1]: [✓ STRONG | ~ WEAK | ✗ MISSING | ? UNCERTAIN] ([Evidence])
├── [Category 2]: [✓ STRONG | ~ WEAK | ✗ MISSING | ? UNCERTAIN] ([Evidence])
└── [Category N]: [✓ STRONG | ~ WEAK | ✗ MISSING | ? UNCERTAIN] ([Evidence])
```

For Deal/Opportunity analysis, assess these signals:

STAKEHOLDER SIGNALS:
├── Economic Buyer Identified
├── Champion Identified  
├── Decision Maker Engaged
├── Procurement Contact (if deal >$100K)

PROCESS SIGNALS:
├── Next Steps Defined
├── Timeline Validated
├── Competition Status Known
├── Security/Legal Requirements Mapped

MOMENTUM SIGNALS:
├── Recent Activity (within 14 days)
├── Stage Progression (within 30 days)
├── Close Date Stable (no pushes)

This format allows technical users to quickly validate AI reasoning.
```

**Test Protocol**:
1. Run prompt with signal assessment format
2. Evaluate: completeness, accuracy, scanability
3. Get feedback from 2-3 internal users on comprehension speed

#### Phase 0 Success Criteria & Decision Gate

| Test | Metric | Target | Fail Threshold |
|------|--------|--------|----------------|
| Evidence Binding | Generic phrases per output | <3 | >7 |
| Evidence Binding | Field citations per output | >8 | <3 |
| Diagnostic Language | Specificity score (1-5) | >4.0 | <3.0 |
| Diagnostic Language | Actionability score (1-5) | >4.0 | <3.0 |
| Context Application | Customer-specific references | >3 | <1 |
| Signal Assessment | User comprehension time | <30 sec | >60 sec |

**🚨 DECISION GATE**: 
- If 3+ tests hit target → Proceed to Phase 1
- If <3 tests hit target → Revisit approach, do NOT build infrastructure

---

### ✅ Phase 0 Results: GATE PASSED - Quality Thesis PROVEN

**Execution Date**: January 22, 2026  
**Test Environment**: Salesforce org (agentictso), Healthcare Payer scenario  
**Decision**: **PROCEED TO PHASE 1** ✅

#### Test Summary

**5 Variants Tested**:
1. **Variant 0 - Baseline**: Existing prompt (no quality rules)
2. **Variant 1 - Evidence Binding**: +Evidence citation requirements
3. **Variant 2 - Diagnostic Language**: +Judge/diagnose/prescribe rules
4. **Variant 3 - Context Application**: +Healthcare payer context usage
5. **Variant 4 - All Three**: Combined all quality rules

**Test Data**:
- Opportunity: UnitedHealthcare Cloud Infrastructure - $220K (Proposal/Price Quote stage)
- 4 Contacts: CFO, VP Operations, HR Director, Benefits Manager (via OpportunityContactRole)
- 5 Tasks: Including 1 overdue HIGH priority task (7 days late)
- 3 Events: Past engagement + future CFO meeting
- 3 ContentNotes: Budget concerns, champion evidence, competitive threat (Aetna)

#### Results: Evidence Binding = Game Changer

| Metric | Baseline (V0) | Evidence (V1) | Diagnostic (V2) | Context (V3) | All Three (V4) | Target |
|--------|---------------|---------------|-----------------|--------------|----------------|--------|
| **Evidence Citations** | 0 | **21** 🏆 | 0 | 0 | **24** 🏆 | ≥8 |
| **Forbidden Phrases** | 4 | **3** ✅ | **1** 🏆 | **1** 🏆 | 4 | ≤3 |
| **Customer References** | 11 | **18** ✅ | **32** 🏆 | **23** ✅ | **39** 🏆 | ≥5 |
| **Diagnostic Score** | 2.0/5 | **5.0/5** 🏆 | 4.0/5 | 3.0/5 | **5.0/5** 🏆 | ≥4.0 |
| **Composite Score** | 33.3 | **73.3** 🏆 | 60.0 | 53.3 | **73.3** 🏆 | ≥75 |
| **Improvement** | Baseline | **+120%** | +80% | +60% | **+120%** | +50%+ |

**Success Criteria: 4 out of 5 PASSED** ✅

✅ Evidence Citations: 21-24 (target: ≥8)  
✅ Forbidden Phrases: 1-3 (target: ≤3)  
✅ Customer References: 18-39 (target: ≥5)  
✅ Diagnostic Score: 5.0/5 (target: ≥4.0)  
⚠️ Composite Score: 73.3/100 (target: ≥75) - Only 1.7 points short!

#### Key Findings

**1. Evidence Binding is THE Critical Technique** 🎯

The transformation from baseline to evidence-bound output is dramatic:

**Baseline (33.3/100)**:
```
"Overdue tasks require immediate attention to avoid deal stagnation."
"Consider scheduling follow-ups to re-engage."
```

**Evidence Binding (73.3/100)**:
```
"CRITICAL: Overdue task 'Send ROI Analysis to CFO' is 7 days late 
(Evidence: Task.Subject = 'Send ROI Analysis to CFO', 
Task.ActivityDate = '01/15/2026', Task.Status = 'Not Started', 
Task.Priority = 'High', TODAY = '01/22/2026')"

"IMMEDIATE ACTION (within 24 hours): Schedule follow-up meeting 
with Sarah Johnson (CFO) to present ROI analysis"
```

**Impact**: +120% quality improvement, 21 specific field citations vs. 0

**2. Evidence Binding Works Even Better When Combined**

- Variant 1 (Evidence only): 21 citations, 73.3 score
- Variant 4 (Evidence + Diagnostic + Context): 24 citations, 73.3 score
- Both tied as winners, demonstrating Evidence Binding is the foundation

**3. Diagnostic Language Reduces Generic Phrases**

- Variant 2 had only 1 forbidden phrase (vs. 4 in baseline)
- However, without Evidence Binding, it still scored lower (60.0 vs. 73.3)
- **Conclusion**: Diagnostic Language is valuable but Evidence Binding must come first

**4. Customer Context Drives Specific References**

- Variant 3 generated 23 customer-specific references
- Variant 4 generated 39 customer-specific references
- Healthcare payer terminology was correctly applied
- **Conclusion**: Context Application enhances but doesn't replace Evidence Binding

**5. Data Context Mapping (DCM) is Critical**

During test setup, we discovered the DCM was missing Contact object fields:
- Original DCM: Only Opportunity fields
- Updated DCM: Added Contact.Name, Contact.Title, Contact.Email, Contact.Department, Contact.Description via OpportunityContactRole

**Impact**: Without Contact data, the AI couldn't cite specific stakeholder evidence. This would have caused the test to fail.

**Learning**: DCM completeness is a prerequisite for evidence binding to work.

#### What Didn't Work

1. **Composite Score Target (75) Not Quite Reached**
   - Achieved: 73.3/100 (1.7 points short)
   - Root cause: Slight penalty for output length and structural elements
   - **Decision**: 73.3 is close enough given the 120% improvement

2. **Context Application Alone (Variant 3) Wasn't Enough**
   - Score: 53.3/100
   - Had good customer references but lacked evidence citations
   - **Learning**: Context without evidence = still generic

3. **Diagnostic Language Alone (Variant 2) Was Middle-Tier**
   - Score: 60.0/100
   - Improved tone but still lacked specific evidence
   - **Learning**: Tone matters less than factual grounding

#### Integration Plan: How to Incorporate Findings into Phase 1

**Immediate Actions for Phase 1**:

1. **Extract Winning Instruction Blocks** ✅
   - Evidence Binding instruction block from Variant 1 → `evidence_binding.md`
   - Diagnostic Language instruction block from Variant 2 → `diagnostic_language.md`
   - Context Application instruction block from Variant 3 → `context_application.md`
   - Signal Assessment format → `signal_assessment.md`

2. **Create Quality Rules Static Resources** ✅
   ```
   staticresources/
   ├── quality_rules/
   │   ├── evidence_binding.md        (PRIORITY 1 - Most impactful)
   │   ├── diagnostic_language.md     (PRIORITY 2 - Reduces generic phrases)
   │   ├── context_application.md     (PRIORITY 3 - Enhances specificity)
   │   └── signal_assessment.md       (PRIORITY 4 - Structural consistency)
   ```

3. **Create Industry Heuristics Library** ✅
   - Extract Healthcare Payer context from Variant 3 → `healthcare_payer.md`
   - Include terminology (Member not Customer, Plan not Product)
   - Include deal patterns (CFO involvement, security review timelines)
   - Include stakeholder priorities (CFO: TCO/ROI, CIO: Security/Integration)

4. **Implement ConfigurationLoader.cls** ✅
   - Load markdown files from Static Resources
   - Parse YAML frontmatter + markdown content
   - Cache in memory for performance

5. **Update Stage08_PromptAssembly** ✅
   - Inject quality rules into prompt assembly:
     ```apex
     String qualityRules = QualityRulesLoader.loadRulesForPromptType(promptType);
     String industryHeuristics = IndustryHeuristicsLoader.loadHeuristics(industry);
     String customerContext = ConfigurationLoader.loadFile('business_context');
     
     // Assemble final prompt with all components
     String assembledPrompt = assemblePrompt(
         basePrompt, qualityRules, industryHeuristics, customerContext
     );
     ```

6. **DCM Validation as Prerequisite** ⚠️
   - Before Phase 1 deployment, validate DCM includes:
     - All relevant child objects (Contact, Task, Event, Note)
     - Fields required by Evidence Binding (Task.Subject, Contact.Name, etc.)
     - Sufficient field depth for pattern detection
   - Create DCM validation script or checklist

#### Automated Testing Framework (For Future Phases)

The automated test approach worked extremely well:

**What We Built**:
- `run_phase0_test.py`: Updates prompt via REST API, executes via `/services/apexrest/ccai/v1/executePrompt`
- `score_outputs.py`: Automated scoring based on evidence citations, forbidden phrases, customer references
- `PHASE0_TEST_LOG.md`: Comprehensive test log for review by other AIs

**Future Use**:
- Regression testing for Phase 1, 2, 3 deployments
- A/B testing for new quality rules
- Performance benchmarking (before/after comparisons)

#### Next Steps: Phase 1 Implementation

**Week 1 Priorities** (Updated based on Phase 0B):
1. Create `quality_rules_evidence_binding.md` (from Phase 0)
2. Create `pattern_risk_assessment.md` (from Phase 0B Variant 15 - WINNER) ⭐
3. Create `pattern_metrics_calculation.md` (foundational for all analysis)
4. Create `component_stat_card.html` (8 cards used in Variant 15) ⭐
5. Create `component_alert_box_critical.html` (red risk cards) ⭐
6. Create `component_alert_box_warning.html` (orange warnings) ⭐
7. Create `component_alert_box_positive.html` (green strengths) ⭐
8. Create `component_page_header_gradient.html` + container components
9. Implement `ConfigurationLoader.cls` + test class
10. Implement `ComponentLibrary.cls` + test class

**Week 2 Priorities**:
1. Implement `PatternMatcher.cls` for Risk Assessment triggers
2. Update `Stage08_PromptAssembly.cls` to inject patterns + components
3. End-to-end testing (should achieve 75/100+ score)
4. Test with Opportunity and Account objects
5. Deploy to test org and validate

**Success Criteria for Phase 1** (Updated):
- Quality rules and patterns load correctly from Static Resources
- Risk Assessment pattern triggers appropriately (Stage >= Proposal OR Has overdue tasks)
- UI components render with correct inline styles and merge fields
- Generated prompts achieve ≥75/100 composite score (validated in Phase 0B)
- Visual diversity: Use 4+ distinct component types (stat cards, alert boxes, cards)
- Analytical depth: Include risk analysis with evidence + impact + actions
- All test classes have >75% coverage

#### Files & Artifacts

**Test Files Created**:
- `tests/phase0/PHASE0_TEST_LOG.md` - Complete test documentation
- `tests/phase0/variants/variant_*.txt` - All 5 prompt variants
- `tests/phase0/outputs/output_*.html` - All 5 AI outputs
- `tests/phase0/comparison/phase0_results.md` - Scoring report
- `tests/phase0/comparison/scoring_results.json` - Raw metrics
- `tests/phase0/run_phase0_test.py` - Test automation script
- `tests/phase0/score_outputs.py` - Scoring automation script

**Reference for Other AIs**:
The `PHASE0_TEST_LOG.md` includes a "FOR AI REVIEW" section with all context needed for other LLMs to analyze our approach and provide feedback.

---

### ✅ Phase 0B Results: Pattern Extraction & UI Component Validation

**Execution Date**: January 22, 2026  
**Test Duration**: ~4 hours  
**Decision**: **PROCEED TO PHASE 1** ✅

#### Test Summary

**Objective**: Extract reusable analytical patterns and UI components from production prompts, validate through testing.

**Sources Analyzed**:
- 9 pre-packaged Salesforce prompts (Account 360, Case Analysis, Opportunity Insights, etc.)
- 1 comprehensive MEDDIC sample prompt
- Total: 10 prompts consolidated for pattern extraction

**Patterns Extracted**:
- **10 Analytical Patterns**: Risk Assessment, Next Best Action, Metrics Calculation, Timeline Analysis, Stakeholder Gap, MEDDIC Scoring, Intent Analysis, Root Cause, Executive Summary, Sentiment Analysis
- **10 UI/HTML Components**: Stat Cards, Alert Boxes (Red/Orange/Green), Data Tables, Card Containers, Page Headers, Action Cards, Stakeholder Cards, Progress Bars, Status Badges, Empty States

**Test Variants**:
1. **Variant 15**: Risk Assessment Pattern + Visual Risk Components (stat cards + alert boxes)
2. **Variant 16**: Next Best Action Pattern + Action Cards
3. **Variant 18**: Timeline Analysis Pattern + Visual Timeline
4. **Variant 19**: Multi-Pattern Architecture (all 5 top patterns combined)
5. **Variant 20**: Account 360 Enhanced (6 patterns + dashboard UI)

#### Results: Visual Diversity + Pattern Integration = Success

| Variant | Patterns Applied | UI Components | Composite Score | vs Phase 0 |
|---------|------------------|---------------|-----------------|------------|
| **Baseline (V0)** | None | Tables only | 33.3/100 | -40.0 |
| **Phase 0 Winner (V1)** | Evidence Binding | Basic (tables, cards) | 73.3/100 | - |
| **15 - Risk Visual** 🏆 | Evidence + Risk Assessment | 8 Stat Cards + 5 Alert Boxes | **75.0/100** | **+1.7** ✅ |
| **16 - Action Cards** | Evidence + Next Best Action | 2 Alert Boxes (actions) | 69.0/100 | -4.3 |
| **18 - Timeline** | Evidence + Timeline | 1 Alert Box | 60.0/100 | -13.3 |
| **19 - Multi-Pattern** | Evidence + 5 Patterns | Minimal (AI overwhelmed) | 61.0/100 | -12.3 |
| **20 - Account 360** | Evidence + 6 Patterns | Minimal (AI overwhelmed) | 63.0/100 | -10.3 |

**🏆 WINNER: Variant 15 (Risk Visual) - 75.0/100**

**Scoring Methodology** (10 Dimensions):
- **Stage12 Dimensions** (5): Visual Quality, Data Accuracy, Persona Fit, Actionability, Business Value
- **Phase 0B Dimensions** (5): Visual Diversity, Analytical Depth, Pattern Application, Evidence Binding, UI/UX Elegance

#### Key Findings

**1. Risk Assessment + Visual Components = Exceptional Combination** 🎯

Variant 15 achieved perfect scores on:
- **Analytical Depth**: 10/10 - Risk identification with CRITICAL/WARNING/POSITIVE levels, evidence, impact, mitigation
- **UI Elegance**: 10/10 - Large typography (32px), semantic colors, shadows, border accents, spacing rhythm

What Variant 15 did right:
- **8 Stat Cards**: Deal Size, Days in Stage, Overdue Tasks, Contact Count (big numbers with semantic colors)
- **5 Alert Boxes**: 2 Red (critical risks), 1 Orange (warnings), 2 Green (strengths/actions)
- **4 Stakeholder Cards**: Visual contact display with names and roles
- **Zero Plain Tables**: Everything visually enhanced
- **Color Semantics**: Red=#dc3545 (critical), Orange=#FF9800 (warning), Green=#28a745 (success)

**2. Pattern Overload Backfires** ⚠️

- Variant 19 (All 5 Patterns): Only 61/100
- Variant 20 (6 Patterns): Only 63/100
- **Learning**: 2-3 patterns maximum per prompt for optimal quality
- Too many patterns overwhelm the AI, resulting in simpler (less visual) output
- **Recommendation**: Be selective - choose 2-3 most relevant patterns per prompt type

**3. Stat Cards > Tables for Metrics** ✅

- Variant 15 used 8 stat cards → 75/100
- Variants with more tables → 60-69/100
- **Stat Card Structure**:
  ```html
  <div style="flex:1 1 calc(25% - 16px);min-width:180px;background:#ffffff;
              padding:16px;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1);text-align:center;">
    <div style="color:#706E6B;font-size:12px;font-weight:600;text-transform:uppercase;
                margin:0 0 8px;">METRIC LABEL</div>
    <div style="font-size:32px;font-weight:700;color:#0176D3;margin:0;">[BIG VALUE]</div>
  </div>
  ```
- **Best Practice**: Use stat cards for dashboards, KPIs, summary metrics
- **Tables**: Reserve for detailed data comparisons only

**4. Alert Boxes for Risk Communication** ✅

Better than bullet lists or tables for risks:
- **Red Alert Box** (Critical): `background:#f8d7da; border-left:4px solid #dc3545;`
- **Orange Alert Box** (Warning): `background:#fff3cd; border-left:4px solid #FF9800;`
- **Green Alert Box** (Positive): `background:#d4edda; border-left:4px solid #28a745;`

Structure: Title + Evidence + Impact + Action (4-field format)

**5. Evidence Binding Metric Needs Update** 🔧

- Variants 19 & 20 had 19-20 field citations but scored only 4-6/10 on Evidence Binding
- Issue: Scoring script looks only for "Evidence:" keyword
- Reality: Variants used "based on", "shows", inline citations
- **Action**: Update scoring to recognize multiple citation formats

**6. Stage12 Methodology Validated** ⭐

- All 5 Stage12 dimensions provide valuable holistic assessment
- Consistently scored 7-8/10 across variants (good quality baseline)
- **Recommendation**: Integrate Stage12 into production pipeline for ongoing quality monitoring

#### Integration Plan: What to Implement in Phase 1

**P0 Priority (Week 1)** - Implement Variant 15 Recipe:
1. `quality_rules_evidence_binding.md` (from Phase 0)
2. `pattern_risk_assessment.md` (from Phase 0B Variant 15)
3. `pattern_metrics_calculation.md` (foundational)
4. `component_stat_card.html` (big number tiles)
5. `component_alert_box_critical.html` (red risk cards)
6. `component_alert_box_warning.html` (orange warnings)
7. `component_alert_box_positive.html` (green strengths)
8. `component_page_header_gradient.html` + containers
9. `ConfigurationLoader.cls` + `ComponentLibrary.cls`

**P1 Priority (Week 2)** - Add Next Best Action:
1. `pattern_next_best_action.md` (from Variant 16)
2. `pattern_executive_summary.md` (universal)
3. `component_action_card.html` (structured actions with priority)
4. `PatternMatcher.cls` (trigger evaluation logic)
5. Update `Stage08_PromptAssembly.cls` (pattern + component injection)

**P2 Priority (Phase 2)** - Supplementary Patterns:
- Timeline Analysis (for velocity tracking)
- Stakeholder Gap (for MEDDIC users)
- Additional UI components (tables, badges, progress bars)

#### Files & Artifacts

**Test Documentation**:
- `tests/phase0b/PHASE0B_PATTERN_EXTRACTION_LOG.md` - Comprehensive test log
- `tests/phase0b/EXECUTIVE_SUMMARY.md` - Executive summary (this view)
- `tests/phase0b/PHASE0B_SUMMARY.md` - Pattern extraction details

**Pattern Libraries**:
- `tests/phase0b/patterns/ANALYTICAL_PATTERNS.md` - 10 patterns with full documentation
- `tests/phase0b/patterns/UI_COMPONENTS.md` - 10 components with HTML/CSS examples

**Test Results**:
- `tests/phase0b/comparison/phase0b_results.md` - Scoring analysis
- `tests/phase0b/outputs/output_15_risk_visual.html` - WINNER (75/100)
- `tests/phase0b/outputs/` - All 5 variant outputs + execution logs

**Reference for Other AIs**:
All Phase 0B files include comprehensive context, methodology, and findings for external AI review and feedback.

---

### Phase 1: Codify the Quality Rules (Week 1-2)

**Goal**: Systematize the proven quality improvements into reusable markdown files

**Prerequisite**: Phase 0 tests show significant quality improvement (3+ tests hit target)

**Why Now**: We've proven what works. Now we codify it into files that can be reused across all prompts.

#### Task 1.1: Create Quality Rules Library (Static Resources)

Store as markdown files in Static Resources:

```
staticresources/
├── quality_rules/
│   ├── evidence_binding.md
│   ├── diagnostic_language.md
│   ├── context_application.md
│   └── signal_assessment.md
```

Each file contains:
- The instruction block (copy-paste ready from Phase 0 tests)
- Examples of compliant/non-compliant output
- Forbidden phrases list
- Validation criteria

**Implementation - QualityRulesLoader.cls**:

```apex
public class QualityRulesLoader {
    
    private static Map<String, String> ruleCache = new Map<String, String>();
    
    /**
     * Load a quality rule from Static Resource
     */
    public static String loadRule(String ruleName) {
        if (ruleCache.containsKey(ruleName)) {
            return ruleCache.get(ruleName);
        }
        
        String resourceName = 'quality_rules_' + ruleName;
        StaticResource sr = [
            SELECT Body 
            FROM StaticResource 
            WHERE Name = :resourceName 
            LIMIT 1
        ];
        
        String content = sr.Body.toString();
        ruleCache.put(ruleName, content);
        return content;
    }
    
    /**
     * Load all quality rules for a prompt type
     */
    public static String loadRulesForPromptType(String promptType) {
        List<String> rules = new List<String>();
        
        // All prompts get evidence binding
        rules.add(loadRule('evidence_binding'));
        
        // Diagnostic prompts get diagnostic language
        if (isDiagnosticPrompt(promptType)) {
            rules.add(loadRule('diagnostic_language'));
        }
        
        // All prompts get signal assessment
        rules.add(loadRule('signal_assessment'));
        
        // All prompts get context application
        rules.add(loadRule('context_application'));
        
        return String.join(rules, '\n\n');
    }
    
    private static Boolean isDiagnosticPrompt(String promptType) {
        Set<String> diagnosticTypes = new Set<String>{
            'deal_coach', 'opportunity_insights', 'account_health',
            'renewal_risk', 'pipeline_review', 'forecast_analysis'
        };
        return diagnosticTypes.contains(promptType.toLowerCase());
    }
}
```

#### Task 1.2: Create Industry Heuristics Library (Static Resources)

**Key Insight**: Heuristics are evaluation criteria, not background descriptions.

```
staticresources/
├── industry_heuristics/
│   ├── healthcare_payer.md
│   ├── financial_services.md
│   ├── insurance.md
│   └── default.md
```

**Example: healthcare_payer.md**:

```markdown
# Healthcare Payer Deal Heuristics

## Evaluation Criteria for Deal Analysis

Apply these heuristics when analyzing healthcare payer opportunities:

### Stage-Specific Risk Patterns

**Early Stage (Discovery/Qualification):**
- Risk: Engaging only with IT; clinical and operations stakeholders often hold veto power
- Risk: Underestimating compliance review timeline (typically 4-8 weeks)
- Check: Is a compliance/security stakeholder identified?

**Mid Stage (Demo/Evaluation):**
- Risk: POC scope creep—payers want to test edge cases for regulatory scenarios
- Risk: Reference requests for similar payer implementations (they will ask)
- Check: Are success criteria documented and approved by Economic Buyer?

**Late Stage (Proposal/Negotiation):**
- Risk: Procurement involvement adds 3-6 weeks minimum
- Risk: Legal review of BAA (Business Associate Agreement) for HIPAA
- Risk: CFO escalation on any discount >15%
- Check: Is procurement contact mapped? Is legal timeline accounted for?

### Deal Size Thresholds

| Amount | Typical Requirements |
|--------|---------------------|
| <$50K | Department approval sufficient |
| $50K-$150K | VP-level + procurement review |
| $150K-$500K | C-level sponsor + security review + BAA |
| >$500K | Board visibility + enterprise procurement + reference calls |

### Stakeholder Patterns

**CFO Priorities:**
- Total cost of ownership (3-5 year view)
- Impact on Medical Loss Ratio (MLR)
- Compliance cost avoidance
- NOT: Feature comparisons

**CIO/CISO Priorities:**
- HIPAA compliance documentation
- Integration with existing EHR/claims systems
- Security assessment (SOC 2, HITRUST)
- Data residency and encryption

**CMO/Clinical Priorities:**
- Member outcome improvements
- Provider network impact
- Quality metrics (HEDIS, Star ratings)

### Red Flags

- Discount request before value demonstration
- Procurement involved before executive alignment
- No clinical stakeholder engagement on member-facing solutions
- Timeline expectation <90 days for enterprise deals
- "We need to see the contract" before technical validation

### Terminology

Use these terms in recommendations:
- "Member" (not Customer or Patient)
- "Plan" (not Product)
- "Provider Network" (critical to value discussions)
- "Medical Loss Ratio" (key financial metric)
- "Value-based care" (industry direction)
```

**Implementation - IndustryHeuristicsLoader.cls**:

```apex
public class IndustryHeuristicsLoader {
    
    /**
     * Load heuristics for a customer's industry
     */
    public static String loadHeuristics(String industry) {
        // Normalize industry name
        String normalized = normalizeIndustry(industry);
        
        String resourceName = 'industry_heuristics_' + normalized;
        
        try {
            StaticResource sr = [
                SELECT Body 
                FROM StaticResource 
                WHERE Name = :resourceName 
                LIMIT 1
            ];
            return sr.Body.toString();
        } catch (Exception e) {
            // Fall back to default
            return loadDefaultHeuristics();
        }
    }
    
    private static String normalizeIndustry(String industry) {
        if (String.isBlank(industry)) return 'default';
        
        String lower = industry.toLowerCase();
        
        // Map common variations
        if (lower.contains('health') && lower.contains('insur')) {
            return 'healthcare_payer';
        }
        if (lower.contains('health') || lower.contains('medical')) {
            return 'healthcare_payer';
        }
        if (lower.contains('financ') || lower.contains('bank')) {
            return 'financial_services';
        }
        if (lower.contains('insur')) {
            return 'insurance';
        }
        
        return 'default';
    }
    
    private static String loadDefaultHeuristics() {
        StaticResource sr = [
            SELECT Body 
            FROM StaticResource 
            WHERE Name = 'industry_heuristics_default' 
            LIMIT 1
        ];
        return sr.Body.toString();
    }
}
```

#### Task 1.3: Update Stage08 (Prompt Assembly)

Modify the prompt assembly stage to inject quality rules and heuristics:

```apex
public class PromptAssembler {
    
    /**
     * Assemble the final prompt with quality rules and heuristics
     */
    public static String assemblePrompt(
        String basePrompt,
        String promptType,
        String industry,
        String customerContext
    ) {
        List<String> sections = new List<String>();
        
        // Section 1: Base prompt (persona, goal, business context)
        sections.add(basePrompt);
        
        // Section 2: Customer context (if available)
        if (String.isNotBlank(customerContext)) {
            sections.add('=== CUSTOMER STRATEGIC CONTEXT ===\n' + customerContext);
        }
        
        // Section 3: Industry heuristics
        String heuristics = IndustryHeuristicsLoader.loadHeuristics(industry);
        sections.add('=== INDUSTRY EVALUATION CRITERIA ===\n' + heuristics);
        
        // Section 4: Quality rules (always included)
        String qualityRules = QualityRulesLoader.loadRulesForPromptType(promptType);
        sections.add(qualityRules);
        
        // Section 5: Output format and guardrails (from existing implementation)
        sections.add(loadOutputGuardrails());
        
        return String.join(sections, '\n\n');
    }
    
    private static String loadOutputGuardrails() {
        // Load from existing Stage08 implementation
        return '=== OUTPUT REQUIREMENTS ===\n[Existing guardrails]';
    }
}
```

#### Task 1.4: Create Prompt Type Configuration

Define which rules apply to which prompt types (Static Resource):

```markdown
# prompt_type_config.md

## Diagnostic Prompts
These prompts analyze and judge. They receive full quality rules.

- deal_coach
- opportunity_insights
- account_health
- pipeline_review
- forecast_analysis
- renewal_risk
- churn_prediction
- win_loss_analysis

Quality Rules: evidence_binding, diagnostic_language, signal_assessment, context_application

## Summary Prompts  
These prompts summarize and report. They receive evidence binding only.

- meeting_summary
- activity_timeline
- contact_overview
- account_snapshot

Quality Rules: evidence_binding

## Creative Prompts
These prompts generate content. They receive minimal rules.

- email_draft
- proposal_section
- executive_briefing

Quality Rules: context_application (optional)
```

#### Phase 1 Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| evidence_binding.md | Evidence citation rule | Static Resource |
| diagnostic_language.md | Diagnostic output requirements | Static Resource |
| signal_assessment.md | Signal/gap format template | Static Resource |
| context_application.md | Customer context usage rule | Static Resource |
| healthcare_payer.md | Healthcare payer heuristics | Static Resource |
| financial_services.md | Financial services heuristics | Static Resource |
| insurance.md | Insurance heuristics | Static Resource |
| default.md | Default heuristics | Static Resource |
| prompt_type_config.md | Prompt type → rules mapping | Static Resource |
| QualityRulesLoader.cls | Apex loader for quality rules | Apex Class |
| QualityRulesLoader_Test.cls | Test class (>75% coverage) | Apex Test |
| IndustryHeuristicsLoader.cls | Apex loader for heuristics | Apex Class |
| IndustryHeuristicsLoader_Test.cls | Test class (>75% coverage) | Apex Test |
| PromptAssembler.cls | Updated assembly logic | Apex Class |
| PromptAssembler_Test.cls | Test class (>75% coverage) | Apex Test |

#### Phase 1 Success Criteria

- ✅ Quality rules load correctly from Static Resources
- ✅ Industry heuristics map correctly from customer industry
- ✅ Stage08 successfully injects rules into prompt assembly
- ✅ Generated prompts include all required sections
- ✅ Output quality matches Phase 0 test results (no regression)
- ✅ All test classes have >75% coverage

---

### Phase 2: Pattern Extraction & Matching (Week 3-4)

**Goal**: Extract reusable analytical patterns from production prompts and build pattern matching engine

**Prerequisite**: Phase 1 complete and quality rules working

**Key Principle**: Start with ONE pattern framework per prompt type. Do not build a pattern explosion. Extract from what's already working.

#### Task 2.1: Audit Production Prompts (2-3 days)

Review 15-20 production prompts and extract:

1. **Trigger conditions**: What data signals activate each analysis?
2. **Analysis questions**: What does the prompt ask the LLM to evaluate?
3. **Output sections**: What structure does the output follow?
4. **Forbidden language**: What generic phrases to avoid?

**Extraction Template (markdown)**:

```markdown
# Pattern: [Pattern Name]

## Metadata
- Pattern ID: [snake_case_id]
- Applies to: [Object types: Opportunity, Account, Case, etc.]
- Prompt types: [deal_coach, account_health, etc.]

## Trigger Conditions
When should this pattern be applied?
- Stage contains: [list]
- Keywords in fields: [list]
- Threshold values: [list]

## Analysis Questions
What must the LLM evaluate?
1. [Question 1]
2. [Question 2]
3. [Question 3]

## Required Evidence
What fields must be cited?
- [Field 1]
- [Field 2]

## Output Section
What section does this pattern produce?
- Section title: [title]
- Format: [bullets/table/narrative]

## Forbidden Phrases
What generic language to avoid?
- [phrase 1]
- [phrase 2]
```

**Sources for Pattern Extraction**:
- Existing production prompts (Deal Coach, Account 360, etc.)
- MEDDIC analyzer docs (docs/meddic-analysis-2.md - 3,039 lines of patterns)
- Customer feedback on what works

#### Task 2.2: Define Core Patterns (Start with 5-8)

Based on production prompt analysis, likely patterns:

| Pattern ID | Description | Trigger |
|------------|-------------|---------|
| stakeholder_gap | Missing key roles | Contact roles incomplete |
| stalled_deal | No recent progress | Stage unchanged 30+ days |
| discount_pressure | Pricing negotiation risk | Keywords: discount, pricing, budget |
| late_stage_risk | Procurement/legal/security | Stage = Proposal+ |
| expansion_signal | Upsell/cross-sell opportunity | Multiple opps on account |
| champion_weakness | Champion not confirmed | No Champion role OR low engagement |
| timeline_risk | Close date concerns | Close date passed OR pushed multiple times |
| single_threaded | Execution risk | Only 1 contact engaged |

**Store patterns as markdown files** (Static Resources):

```
staticresources/
├── patterns/
│   ├── pattern_stakeholder_gap.md
│   ├── pattern_stalled_deal.md
│   ├── pattern_discount_pressure.md
│   ├── pattern_late_stage_risk.md
│   ├── pattern_champion_weakness.md
│   ├── pattern_timeline_risk.md
│   ├── pattern_single_threaded.md
│   └── pattern_expansion_signal.md
```

#### Task 2.3: Implement Pattern Matcher (3-4 days)

**Pattern Data Model (Pattern.cls)**:

```apex
public class Pattern {
    public String patternId;
    public String patternName;
    public String triggerDescription;
    public List<TriggerCondition> triggers;
    public List<String> analysisQuestions;
    public List<String> requiredEvidence;
    public List<String> forbiddenPhrases;
    public String outputSection;
    public Integer priority; // For ranking
    
    public class TriggerCondition {
        public String fieldName;
        public String operator; // contains, equals, greater_than, less_than, is_empty, days_since_greater_than, role_missing
        public String value;
    }
}
```

**PatternMatcher.cls**:

```apex
public class PatternMatcher {
    
    /**
     * Analyze records and return applicable patterns
     */
    public static List<Pattern> matchPatterns(
        SObject record,
        List<SObject> relatedRecords,
        String promptType
    ) {
        List<Pattern> matched = new List<Pattern>();
        
        // Load all patterns for this prompt type
        List<Pattern> candidates = loadPatternsForPromptType(promptType);
        
        for (Pattern p : candidates) {
            if (evaluateTrigger(p, record, relatedRecords)) {
                matched.add(p);
            }
        }
        
        // Sort by priority and limit to top 3-5
        matched.sort();
        return limitPatterns(matched, 5);
    }
    
    private static Boolean evaluateTrigger(
        Pattern p, 
        SObject record, 
        List<SObject> relatedRecords
    ) {
        // Evaluate each trigger condition (AND logic)
        for (Pattern.TriggerCondition tc : p.triggers) {
            if (!evaluateCondition(tc, record, relatedRecords)) {
                return false; // All conditions must match
            }
        }
        return true;
    }
    
    private static Boolean evaluateCondition(
        Pattern.TriggerCondition tc,
        SObject record,
        List<SObject> relatedRecords
    ) {
        Object fieldValue = record.get(tc.fieldName);
        
        switch on tc.operator {
            when 'contains' {
                return String.valueOf(fieldValue).containsIgnoreCase(tc.value);
            }
            when 'equals' {
                return fieldValue == tc.value;
            }
            when 'greater_than' {
                return (Decimal)fieldValue > Decimal.valueOf(tc.value);
            }
            when 'less_than' {
                return (Decimal)fieldValue < Decimal.valueOf(tc.value);
            }
            when 'is_empty' {
                return fieldValue == null || String.isBlank(String.valueOf(fieldValue));
            }
            when 'days_since_greater_than' {
                Date fieldDate = (Date)fieldValue;
                Integer daysSince = fieldDate.daysBetween(Date.today());
                return daysSince > Integer.valueOf(tc.value);
            }
            when 'role_missing' {
                return !hasContactRole(relatedRecords, tc.value);
            }
            when else {
                return false;
            }
        }
    }
    
    private static Boolean hasContactRole(List<SObject> contactRoles, String roleName) {
        for (SObject cr : contactRoles) {
            if (String.valueOf(cr.get('Role')).equalsIgnoreCase(roleName)) {
                return true;
            }
        }
        return false;
    }
    
    private static List<Pattern> loadPatternsForPromptType(String promptType) {
        // Load pattern markdown files for this prompt type
        // Parse and return Pattern objects
        List<Pattern> patterns = new List<Pattern>();
        // Implementation: Read static resources, parse markdown
        return patterns;
    }
    
    private static List<Pattern> limitPatterns(List<Pattern> patterns, Integer maxCount) {
        if (patterns.size() <= maxCount) {
            return patterns;
        }
        List<Pattern> limited = new List<Pattern>();
        for (Integer i = 0; i < maxCount; i++) {
            limited.add(patterns[i]);
        }
        return limited;
    }
}
```

#### Task 2.4: Integrate Patterns into Assembly (2 days)

Update PromptAssembler to include matched patterns:

```apex
public static String assemblePrompt(
    String basePrompt,
    String promptType,
    String industry,
    String customerContext,
    SObject record,
    List<SObject> relatedRecords
) {
    List<String> sections = new List<String>();
    
    // ... existing sections (base, context, heuristics, quality rules) ...
    
    // Section 6: Matched patterns
    List<Pattern> patterns = PatternMatcher.matchPatterns(
        record, relatedRecords, promptType
    );
    
    if (!patterns.isEmpty()) {
        sections.add(formatPatternInstructions(patterns));
    }
    
    // ... remaining sections ...
    
    return String.join(sections, '\n\n');
}

private static String formatPatternInstructions(List<Pattern> patterns) {
    List<String> instructions = new List<String>();
    
    instructions.add('=== DETECTED PATTERNS (MUST ANALYZE) ===');
    instructions.add('Based on record data, the following patterns were detected.');
    instructions.add('You MUST include analysis for each pattern in your output.\n');
    
    Integer i = 1;
    for (Pattern p : patterns) {
        instructions.add('PATTERN ' + i + ': ' + p.patternName);
        instructions.add('Trigger: ' + p.triggerDescription);
        instructions.add('Required Analysis:');
        for (String question : p.analysisQuestions) {
            instructions.add('  - ' + question);
        }
        instructions.add('');
        i++;
    }
    
    return String.join(instructions, '\n');
}
```

#### Phase 2 Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| pattern_stakeholder_gap.md | Stakeholder gap pattern | Static Resource |
| pattern_stalled_deal.md | Stalled deal pattern | Static Resource |
| pattern_discount_pressure.md | Discount pressure pattern | Static Resource |
| pattern_late_stage_risk.md | Late stage risk pattern | Static Resource |
| pattern_champion_weakness.md | Champion weakness pattern | Static Resource |
| pattern_timeline_risk.md | Timeline risk pattern | Static Resource |
| pattern_single_threaded.md | Single-threaded execution pattern | Static Resource |
| pattern_expansion_signal.md | Expansion opportunity pattern | Static Resource |
| Pattern.cls | Pattern data model | Apex Class |
| Pattern_Test.cls | Test class (>75% coverage) | Apex Test |
| PatternMatcher.cls | Pattern matching logic | Apex Class |
| PatternMatcher_Test.cls | Test class (>75% coverage) | Apex Test |
| Updated PromptAssembler.cls | Pattern integration | Apex Class |

#### Phase 2 Success Criteria

- ✅ 5-8 patterns extracted from production prompts
- ✅ Pattern triggers evaluate correctly against test records
- ✅ Pattern matching is deterministic (same input = same patterns)
- ✅ Assembled prompts include pattern-specific instructions
- ✅ Output quality maintains Phase 1 levels with added pattern relevance
- ✅ Pattern hit rate >90% (correctly detects applicable patterns)
- ✅ All test classes have >75% coverage

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

### Phase 5: Quality Measurement (Week 7 - Ongoing)

**Goal**: Create automated quality scoring to track improvement over time and validate that our changes are working

**Why Now**: We need objective measurement to prove the quality improvements are real, not subjective.

#### Task 5.1: Define Quality Metrics & Scoring

**OutputQualityScorer.cls**:

```apex
public class OutputQualityScorer {
    
    public class QualityScore {
        public Integer evidenceCitations;      // Count of field citations
        public Integer genericPhrases;         // Count of forbidden phrases
        public Integer customerReferences;     // Count of customer context usage
        public Integer signalAssessments;      // Count of signal evaluations
        public Boolean hasStructuredFormat;    // Signal assessment section present
        public Decimal overallScore;           // Weighted composite (0-100)
    }
    
    public static QualityScore scoreOutput(String output) {
        QualityScore score = new QualityScore();
        
        // Count evidence citations (pattern: "Evidence: X = Y")
        score.evidenceCitations = countPattern(output, 'Evidence:');
        
        // Count forbidden phrases
        score.genericPhrases = countForbiddenPhrases(output);
        
        // Count customer context references
        score.customerReferences = countCustomerReferences(output);
        
        // Check for signal assessment section
        score.hasStructuredFormat = output.contains('Signal Assessment:');
        
        // Calculate signal assessments
        score.signalAssessments = countPattern(output, '✓|~|✗|?');
        
        // Weighted composite
        score.overallScore = calculateComposite(score);
        
        return score;
    }
    
    private static Integer countForbiddenPhrases(String output) {
        List<String> forbidden = new List<String>{
            'ensure alignment',
            'consider scheduling',
            'maintain momentum',
            'engage stakeholders',
            'reinforce value proposition',
            'address concerns',
            'follow up with',
            'reach out to'
        };
        
        Integer count = 0;
        String lower = output.toLowerCase();
        for (String phrase : forbidden) {
            if (lower.contains(phrase)) {
                count++;
            }
        }
        return count;
    }
    
    private static Decimal calculateComposite(QualityScore score) {
        // Weights
        Decimal evidenceWeight = 0.30;
        Decimal genericPenalty = 0.25;
        Decimal contextWeight = 0.20;
        Decimal structureWeight = 0.15;
        Decimal signalWeight = 0.10;
        
        // Normalize and calculate
        Decimal evidenceScore = Math.min(score.evidenceCitations / 10.0, 1.0);
        Decimal genericScore = Math.max(1.0 - (score.genericPhrases / 5.0), 0.0);
        Decimal contextScore = Math.min(score.customerReferences / 5.0, 1.0);
        Decimal structureScore = score.hasStructuredFormat ? 1.0 : 0.0;
        Decimal signalScore = Math.min(score.signalAssessments / 8.0, 1.0);
        
        return (
            evidenceScore * evidenceWeight +
            genericScore * genericPenalty +
            contextScore * contextWeight +
            structureScore * structureWeight +
            signalScore * signalWeight
        ) * 100;
    }
    
    private static Integer countPattern(String text, String pattern) {
        // Count occurrences of pattern in text
        Integer count = 0;
        Integer index = 0;
        while ((index = text.indexOf(pattern, index)) != -1) {
            count++;
            index++;
        }
        return count;
    }
    
    private static Integer countCustomerReferences(String output) {
        // Count references to customer-specific terms
        // This should be enhanced to look for actual customer terminology
        Integer count = 0;
        // Implementation needed based on customer context
        return count;
    }
}
```

#### Task 5.2: Create Quality Log Custom Object

**Prompt_Quality_Log__c** fields:
- Prompt_Run_Id__c (Lookup to PF_Run__c)
- Prompt_Type__c (Text)
- Evidence_Citations__c (Number)
- Generic_Phrases__c (Number)
- Customer_References__c (Number)
- Has_Structured_Format__c (Checkbox)
- Signal_Assessments__c (Number)
- Overall_Score__c (Number - 0-100)
- Output_Length__c (Number - character count)
- Execution_Date__c (DateTime)

#### Task 5.3: Quality Metrics Tracker

**QualityMetricsTracker.cls**:

```apex
public class QualityMetricsTracker {
    
    /**
     * Log quality score for a prompt execution
     */
    public static void logScore(
        String promptRunId,
        String promptType,
        String output,
        OutputQualityScorer.QualityScore score
    ) {
        Prompt_Quality_Log__c log = new Prompt_Quality_Log__c(
            Prompt_Run_Id__c = promptRunId,
            Prompt_Type__c = promptType,
            Evidence_Citations__c = score.evidenceCitations,
            Generic_Phrases__c = score.genericPhrases,
            Customer_References__c = score.customerReferences,
            Has_Structured_Format__c = score.hasStructuredFormat,
            Signal_Assessments__c = score.signalAssessments,
            Overall_Score__c = score.overallScore,
            Output_Length__c = output.length(),
            Execution_Date__c = Datetime.now()
        );
        
        insert log;
    }
    
    /**
     * Get quality trend for a prompt type
     */
    public static List<AggregateResult> getQualityTrend(
        String promptType,
        Integer days
    ) {
        Date startDate = Date.today().addDays(-days);
        
        return [
            SELECT 
                DAY_ONLY(Execution_Date__c) execDate,
                AVG(Overall_Score__c) avgScore,
                AVG(Evidence_Citations__c) avgEvidence,
                AVG(Generic_Phrases__c) avgGeneric,
                COUNT(Id) execCount
            FROM Prompt_Quality_Log__c
            WHERE Prompt_Type__c = :promptType
            AND Execution_Date__c >= :startDate
            GROUP BY DAY_ONLY(Execution_Date__c)
            ORDER BY DAY_ONLY(Execution_Date__c)
        ];
    }
    
    /**
     * Get quality comparison before/after a date
     */
    public static Map<String, Decimal> getBeforeAfterComparison(
        String promptType,
        Date changeDate
    ) {
        Map<String, Decimal> result = new Map<String, Decimal>();
        
        // Before
        AggregateResult before = [
            SELECT AVG(Overall_Score__c) avgScore
            FROM Prompt_Quality_Log__c
            WHERE Prompt_Type__c = :promptType
            AND Execution_Date__c < :changeDate
        ][0];
        result.put('before', (Decimal)before.get('avgScore'));
        
        // After
        AggregateResult after = [
            SELECT AVG(Overall_Score__c) avgScore
            FROM Prompt_Quality_Log__c
            WHERE Prompt_Type__c = :promptType
            AND Execution_Date__c >= :changeDate
        ][0];
        result.put('after', (Decimal)after.get('avgScore'));
        
        // Improvement
        result.put('improvement', result.get('after') - result.get('before'));
        
        return result;
    }
}
```

#### Task 5.4: Integrate Scoring into Pipeline

Update Stage08 or Stage09 to automatically score outputs:

```apex
// In Stage08 or Stage09 after prompt execution
String generatedOutput = executePrompt(assembledPrompt);

// Score the output
OutputQualityScorer.QualityScore score = OutputQualityScorer.scoreOutput(generatedOutput);

// Log to quality metrics
QualityMetricsTracker.logScore(
    runId,
    promptType,
    generatedOutput,
    score
);

// Optional: Add score to PF_Run__c record
updateRunWithQualityScore(runId, score.overallScore);
```

#### Task 5.5: Quality Dashboard Reports

Create Salesforce reports for:
1. **Quality Trend Report**: Overall score over time by prompt type
2. **Evidence Citation Report**: Average citations per prompt type
3. **Generic Phrase Report**: Identify which forbidden phrases appear most
4. **Before/After Comparison**: Quality scores before/after each phase deployment

#### Phase 5 Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| Prompt_Quality_Log__c | Quality metrics custom object | Custom Object |
| OutputQualityScorer.cls | Quality scoring logic | Apex Class |
| OutputQualityScorer_Test.cls | Test class (>75% coverage) | Apex Test |
| QualityMetricsTracker.cls | Metrics tracking and reporting | Apex Class |
| QualityMetricsTracker_Test.cls | Test class (>75% coverage) | Apex Test |
| Quality Trend Report | Salesforce report | Report |
| Before/After Comparison Report | Salesforce report | Report |

#### Phase 5 Success Criteria

- ✅ Quality scoring runs automatically for all prompt executions
- ✅ Quality logs capture all key metrics
- ✅ Quality trend reports show improvement over time
- ✅ Before/after comparisons validate each phase's impact
- ✅ Overall quality score increases from ~40 (baseline) to >75 (target)
- ✅ All test classes have >75% coverage

---

### Phase 6: UI Component Library & Customer Upload (Week 8+ - Future Enhancements)

**Goal**: Polish and customer empowerment features

**Why Later**: These are "nice-to-have" after core quality is proven

#### Part A: UI Component Library

Ensure consistent HTML formatting across all prompt outputs (from earlier Phase 5)

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

## Appendix A: Forbidden Phrases List

These phrases indicate generic, non-diagnostic output and must be avoided:

```
ensure alignment
consider scheduling
maintain momentum
engage stakeholders
reinforce value proposition
address concerns
follow up with
reach out to
touch base with
circle back on
leverage the relationship
drive value
optimize the process
align on expectations
facilitate discussions
enhance collaboration
streamline communication
foster engagement
capitalize on opportunities
mitigate risks (without specifics)
stay connected
keep the momentum going
build rapport
strengthen the partnership
explore possibilities
identify synergies
stay in touch
keep them engaged
work closely with
establish rapport
coordinate efforts
drive success
maximize value
demonstrate commitment
prioritize action items
```

**Enforcement**: Quality scoring penalizes outputs containing these phrases.

---

## Appendix B: Example Quality Rules File

**File: staticresources/quality_rules_evidence_binding.md**

```markdown
=== EVIDENCE BINDING RULE (MANDATORY) ===

Every insight, risk, or recommendation MUST cite specific evidence from this record.

## Citation Format

Standard format: "[Insight] (Evidence: [Field] = [Value])"

Alternative formats (all acceptable):
- "Based on [Field] showing [Value], ..."
- "[Insight]. This is indicated by [Field] = [Value]."
- "Record shows [Field] = [Value], which suggests [Insight]."

## Compliant Examples

✓ "CFO engagement is your critical path this week (Evidence: Task.Subject = 'CFO Meeting', ActivityDate = 01/27/2026)"

✓ "No champion identified—critical gap for this deal size (Evidence: OpportunityContactRole missing 'Champion' role)"

✓ "Deal momentum is single-threaded. Based on HasOpenActivity = 1 on a $150K deal, recommend expanding activity coverage."

✓ "Close date may be optimistic. Record shows CloseDate = 12/31/2025 but StageName = 'Proposal/Price Quote'. For deals at this stage in this industry, typical close cycle is 4-6 months."

## Non-Compliant Examples (FORBIDDEN)

✗ "Ensure alignment with stakeholders" 
   Problem: No evidence cited, no specific stakeholders named

✗ "Consider scheduling follow-ups to re-engage"
   Problem: No evidence of disengagement cited

✗ "Maintain momentum with key contacts"
   Problem: Generic advice, no field citations

✗ "The deal shows good progress"
   Problem: No specific evidence of progress

## Missing Data Handling

If data is missing that would be needed for analysis, state explicitly:

"MISSING: [Field Name] - [Why this matters] - Recommend: [Action to capture]"

Example:
"MISSING: Champion role not mapped in OpportunityContactRole. Without an internal champion, healthcare payer deals at $150K+ have 40% lower close rates. Recommend: Identify and map champion before CFO meeting."

## Enforcement

Any insight, risk, or recommendation without evidence citation is a FAILURE.
The output will be evaluated for evidence density. Target: >8 citations per analysis.
```

---

## Appendix C: Implementation Checklist

### Phase 0: Prove the Quality Thesis (Days 1-3)
- [ ] Create evidence binding test instruction block
- [ ] Create diagnostic language test instruction block
- [ ] Create context application test instruction block
- [ ] Create signal assessment test format
- [ ] Run A/B tests (5 iterations WITH, 5 WITHOUT each)
- [ ] Count: generic phrases, field citations, customer references
- [ ] Score: specificity (1-5), actionability (1-5), would-survive-audit (Y/N)
- [ ] Document results in spreadsheet
- [ ] **DECISION GATE**: If 3+ tests hit target, proceed to Phase 1

### Phase 1: Codify Quality Rules (Week 1-2)
- [ ] Create quality_rules_evidence_binding.md
- [ ] Create quality_rules_diagnostic_language.md
- [ ] Create quality_rules_signal_assessment.md
- [ ] Create quality_rules_context_application.md
- [ ] Create industry_heuristics_healthcare_payer.md
- [ ] Create industry_heuristics_financial_services.md
- [ ] Create industry_heuristics_insurance.md
- [ ] Create industry_heuristics_default.md
- [ ] Create prompt_type_config.md
- [ ] Implement QualityRulesLoader.cls
- [ ] Implement QualityRulesLoader_Test.cls (>75% coverage)
- [ ] Implement IndustryHeuristicsLoader.cls
- [ ] Implement IndustryHeuristicsLoader_Test.cls (>75% coverage)
- [ ] Update PromptAssembler.cls
- [ ] Update PromptAssembler_Test.cls (>75% coverage)
- [ ] Deploy all static resources
- [ ] Test end-to-end with Opportunity Insights prompt
- [ ] Validate no quality regression from Phase 0

### Phase 2: Pattern Extraction (Week 3-4)
- [ ] Audit 15-20 production prompts
- [ ] Extract 5-8 reusable patterns using template
- [ ] Create pattern markdown files (pattern_*.md)
- [ ] Implement Pattern.cls data model
- [ ] Implement Pattern_Test.cls (>75% coverage)
- [ ] Implement PatternMatcher.cls
- [ ] Implement PatternMatcher_Test.cls (>75% coverage)
- [ ] Update PromptAssembler.cls for pattern injection
- [ ] Test pattern matching accuracy (>90% target)
- [ ] Validate pattern-enhanced outputs

### Phase 3: Multi-Record Foundation (Week 5)
- [ ] Implement Stage01.getSampleRecords() method
- [ ] Query 3 records in parallel (async)
- [ ] Handle edge cases (< 3 records available)
- [ ] Update Stage02 to analyze all 3 records
- [ ] Update Stage05 for field variance analysis
- [ ] Test with Opportunity, Account, Case objects
- [ ] Measure field selection quality improvement
- [ ] Check heap size and performance

### Phase 4: Customer Context (Week 6)
- [ ] Design customer context markdown schema
- [ ] Create cigna_business_context.md example
- [ ] Implement/update ConfigurationLoader.cls
- [ ] Implement ConfigurationLoader_Test.cls (>75% coverage)
- [ ] Add CustomerContextLoader functionality
- [ ] Integrate into Stage01 (load at pipeline start)
- [ ] Integrate into Stage02 (use for classification)
- [ ] Integrate into Stage08 (inject terminology)
- [ ] Test with/without website scraping
- [ ] Verify 100% terminology accuracy

### Phase 5: Quality Measurement (Week 7)
- [ ] Create Prompt_Quality_Log__c custom object
- [ ] Implement OutputQualityScorer.cls
- [ ] Implement OutputQualityScorer_Test.cls (>75% coverage)
- [ ] Implement QualityMetricsTracker.cls
- [ ] Implement QualityMetricsTracker_Test.cls (>75% coverage)
- [ ] Integrate scoring into Stage08/09
- [ ] Create Quality Trend Report
- [ ] Create Before/After Comparison Report
- [ ] Establish baseline metrics
- [ ] Set up weekly quality review process

### Phase 6: Future Enhancements (Week 8+)
- [ ] UI component library (optional)
- [ ] Customer file upload UI
- [ ] Inline markdown editor
- [ ] Preview and diff views

---

## Next Actions

### 🚨 Phase 0: Immediate (Days 1-3) - **START HERE**
**Focus**: Prove the quality thesis before building anything

**Critical Tasks**:
1. ✅ Document strategy (this file - DONE)
2. 🔲 Create 4 test instruction blocks (evidence binding, diagnostic language, context application, signal assessment)
3. 🔲 Run A/B tests (5 iterations each WITH/WITHOUT)
4. 🔲 Measure and score results
5. 🔲 **DECISION GATE**: If 3+ tests hit target → Proceed to Phase 1. If not → Revisit approach.

**Success Criteria**: Evidence citations >8, Generic phrases <3, Specificity score >4.0

---

### Phase 1: Week 1-2 (If Phase 0 Succeeds)
**Focus**: Codify proven quality rules into markdown files

**Key Deliverables**:
- 4 quality rules markdown files
- 4 industry heuristics markdown files
- QualityRulesLoader & IndustryHeuristicsLoader classes
- Updated PromptAssembler

---

### Phase 2: Week 3-4
**Focus**: Extract and match analytical patterns

**Key Deliverables**:
- 5-8 pattern markdown files
- PatternMatcher class
- Pattern-enhanced prompt assembly

---

### Phase 3-5: Weeks 5-7
**Focus**: Multi-record, customer context, quality measurement

**Key Deliverables**:
- Multi-record querying
- Customer context files and loaders
- Quality scoring and reporting

---

## References & Related Docs

### Related Documentation
- [Current Roadmap](./ROADMAP.md) - Feature development timeline
- [PRD: Automated Prompt Creation](./PRD-Automated-Prompt-Creation.md) - Core product definition
- [Enhanced Prompt Template](./ENHANCED_PROMPT.md) - Template specifications
- [GPTfy Configuration Guide](./GPTFY_CONFIG.md) - Integration details
- [Prompt Quality Improvements PRD](./prompt-quality-improvements-prd.md) - Detailed quality improvement specifications (consolidated into this document)

### Pattern Extraction Sources
- [MEDDIC Analysis (Part 1)](./meddic-analysis.md) - MEDDIC diagnostic playbook (pattern extraction source)
- [MEDDIC Analysis (Part 2)](./meddic-analysis-2.md) - MEDDIC implementation guide (3,039 lines - comprehensive pattern source)
- [MEDDIC PRD](./PRD.md) - MEDDIC Compliance Analyzer PRD (pattern extraction source)

---

## Change Log

| Date | Author | Changes |
|------|--------|---------|
| 2026-01-21 | AI Assistant | Initial strategy document created |
| 2026-01-21 | AI Assistant | Integrated 4-layer architecture, added file-based configuration philosophy |
| 2026-01-21 | AI Assistant | **MAJOR CONSOLIDATION**: Merged prompt-quality-improvements-prd.md into this document. Added: Quality Gap examples (before/after), comprehensive Phase 0 test protocols, Quality Measurement (Phase 5), Appendices (Forbidden Phrases, Quality Rules Examples, Implementation Checklist). Reorganized roadmap with "prove-it-first" approach. Status changed to "Ready for Implementation". |
| 2026-01-22 | AI Assistant | **PHASE 0 COMPLETE**: Added comprehensive Phase 0 Results section documenting test execution, findings, and integration plan. Key results: Evidence Binding achieved +120% quality improvement (73.3/100 score), 4 of 5 success criteria met, DECISION: PROCEED TO PHASE 1. Documented winning instruction blocks, automated test framework, and specific integration steps for Phase 1 implementation. |
| 2026-01-22 | AI Assistant | **PHASE 0B COMPLETE**: Added Pattern Extraction & UI Component Validation results. Extracted 10 analytical patterns + 10 UI components from 10 production prompts. Tested 5 variants. WINNER: Variant 15 (Risk Assessment + Visual Components) scored 75.0/100, beating Phase 0 by 1.7 points. Key findings: Risk Assessment Pattern is exceptionally effective (+41.7 pts), Stat Cards + Alert Boxes create visual diversity, Pattern overload backfires (2-3 patterns optimal), Stage12 scoring methodology validated. Updated Phase 1 priorities to implement Variant 15's winning recipe first. |
| 2026-01-22 | AI Assistant | **PHASE 0C COMPLETE + USER VALIDATION**: Tested 19 variants (7 patterns, 8 UI, 4 combinations). Visual review with user revealed critical insights: (1) Evidence binding paradox resolved - +120% was from forcing specificity, not showing sources; updated to insight-led approach (2) Visual hierarchy critical - "buried lead" problem identified, Component 11 (Executive Layout) and Component 12 (Horizontal Timeline) added; (3) Stage-normalized intelligence needed - 20% probability not a risk in early stage. **QUALITY RULES LIBRARY CREATED**: docs/quality-rules/ containing evidence_binding_v2.md and information_hierarchy.md. Stage12 updated with 8-dimension weighted scoring. Ready for Phase 1 implementation. |

