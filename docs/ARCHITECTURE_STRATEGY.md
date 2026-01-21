# GPTfy Prompt Factory: Architecture Strategy

**Last Updated**: January 21, 2026  
**Status**: Strategic Planning  
**Branch**: `feature/prompt-quality-improvements`

---

## Executive Summary

Transform the Prompt Factory from a generic prompt generator into a **Decisive Analysis Assembler**. Instead of asking the user for complexity, the system will automatically assemble a "mini analyst" based on:

1. **Multi-record data foundation** for evidence quality
2. **Customer business context file** for industry intelligence (single-tenant advantage)
3. **Pattern library** extracted from existing production prompts

---

## The Core Problem

Current system generates generic advice like "align with stakeholders" that:
- Doesn't cite specific evidence from Salesforce data
- Uses generic "consultant speak" instead of customer terminology
- Treats industry context as optional narrative enrichment
- Produces report-style summaries instead of decision-support analysis

**Impact**: Users won't trust/pay for prompts that sound like generic chatbot output.

---

## The Single-Tenant Game Changer

**Key Insight**: GPTfy deploys into a single customer's org (e.g., Cigna). This fundamentally changes the architecture from "generic + inferred" to "pre-configured + validated."

Instead of guessing at industry context, we can:
- Pre-load customer-specific business context
- Use proven terminology from day 1
- Leverage known deal patterns and buying motions
- Avoid hallucination about industry that we don't understand

---

## The Three Pillars Strategy

### Pillar 1: Multi-Record Data Foundation

**Purpose**: Evidence Quality & Pattern Detection

#### What Changes
Query 2-3 sample records instead of 1:
- Most recent record
- Oldest open record  
- One mid-stage record

#### Why It Works
- **Field Selection**: Sees variance (empty vs populated fields across records)
- **Evidence Binding**: Has real examples to cite ("In Record 1, Discount = 20%")
- **Pattern Detection**: More reliable ("2 of 3 deals mention discount pressure")

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

---

### Pillar 2: Customer Business Context File

**Purpose**: Industry Intelligence Without Hallucination

#### What It Is
Markdown/JSON file deployed with the package containing customer-specific business intelligence.

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
**Option 1**: Custom Metadata Type
```apex
PF_Customer_Context__mdt record with Long Text fields
```

**Option 2**: Static Resource
```
StaticResource: customer_business_context.md
```

#### How It's Used
1. **Stage02** loads this FIRST (before website scraping)
2. Website scraping **validates/enriches**, doesn't create from scratch
3. **Stage08** injects relevant sections into final prompt based on detected patterns

#### Benefits
- ✅ No LLM guessing about industry
- ✅ No hallucination about business context
- ✅ Terminology is correct from day 1
- ✅ Deal patterns are based on actual customer reality

#### Relationship with Website Scraping
- **Keep website scraping** for now
- Use it to validate/enrich, not create from scratch
- Customer context file is "ground truth"
- Website provides additional public-facing messaging

---

### Pillar 3: Pattern Library from Existing Prompts

**Purpose**: Reusable Components, Proven Quality

#### The Insight
We have 15-20 production prompts (Deal Coach, Account 360, Sentiment Journey, etc.) that already work. Instead of inventing patterns theoretically, **extract them from what's proven**.

#### Library Structure

##### A. Analytical Patterns (What to Analyze)
```json
{
  "pattern_id": "negotiation_pressure",
  "pattern_name": "Negotiation Pressure Detection",
  "trigger": {
    "stage_contains": ["Proposal", "Quote", "Negotiation"],
    "description_keywords": ["discount", "CFO", "budget", "pricing"],
    "min_probability": 60
  },
  "analysis_questions": [
    "Who is driving the discount request?",
    "What value justification is missing?",
    "What concession alternatives exist besides price?"
  ],
  "output_section": "Negotiation Risk Assessment",
  "forbidden_phrases": [
    "offer competitive pricing",
    "emphasize value proposition",
    "align with stakeholders"
  ],
  "evidence_requirements": [
    "OpportunityStage",
    "Description or NextStep",
    "Probability"
  ]
}
```

**Other Pattern Examples**:
- `stalled_deal_revival` - Triggers when Stage hasn't changed in 30+ days
- `expansion_opportunity` - Triggers when Account has multiple Opportunities
- `executive_engagement` - Triggers when no C-level contact in roles
- `risk_mitigation` - Triggers on legal/compliance keywords
- `competitive_threat` - Triggers on competitor mentions

##### B. UI Components (How to Display)
```json
{
  "component_id": "risk_scorecard",
  "component_name": "Risk Assessment Card",
  "html_template": "<div class='risk-card'>...</div>",
  "merge_fields": [
    "{{RiskLevel}}",
    "{{RiskFactors}}",
    "{{MitigationActions}}"
  ],
  "used_in": ["Deal Coach", "Executive Risk Brief"],
  "styling": "red-yellow-green-indicator"
}
```

**Other Component Examples**:
- `next_best_action_list` - Prioritized action items
- `timeline_visualization` - Stage progression timeline
- `stakeholder_map` - Relationship visualization
- `health_score_gauge` - Visual health indicator

##### C. Persona Archetypes (Who Is Reading)
```json
{
  "archetype_id": "deal_coach",
  "archetype_name": "Deal Coach Brief",
  "target_reader": "Sales Representative or Account Executive",
  "sections": [
    "Deal Health Summary",
    "Key Risks & Blockers",
    "Next Best Actions",
    "Stakeholder Engagement Status"
  ],
  "tone": "Prescriptive, action-oriented, coaching",
  "length": "Executive brief (3-5 bullets per section)",
  "evidence_depth": "High - cite specific fields and values"
}
```

**Other Archetype Examples**:
- `executive_risk_brief` - For leadership (summary, risks, escalations)
- `account_360` - Holistic account view (relationships, health, expansion)
- `renewal_health` - Customer success focus (adoption, satisfaction, risk)
- `sentiment_journey` - Support focus (case patterns, satisfaction trends)

#### How to Build the Library

**Phase 1: Analysis** (Week 1)
1. Collect 5 best production prompts (Deal Coach, Account 360, etc.)
2. Analyze for common patterns (expect 70% overlap)
3. Extract:
   - Trigger conditions (what signals activate each pattern)
   - Analysis questions (what the prompt asks the LLM to determine)
   - Output structure (sections, tone, length)
   - Forbidden language (generic phrases to avoid)

**Phase 2: Structuring** (Week 1-2)
1. Create Custom Metadata Types:
   - `PF_Analytical_Pattern__mdt`
   - `PF_UI_Component__mdt`
   - `PF_Persona_Archetype__mdt`
2. Store in metadata or Static Resources (JSON files)
3. Build query/matching logic in Apex

**Phase 3: Integration** (Week 2-3)
1. **Stage02** detects applicable patterns based on triggers
2. **Stage08** queries library for selected patterns + archetype
3. Compose final prompt by assembling pieces

#### Storage Options

**Option 1: Custom Metadata** (Recommended)
- Easy to modify without deployment
- Version controlled
- Can be packaged
- Query in Apex easily

**Option 2: Static Resources**
- JSON files
- More flexible structure
- Requires parsing
- Good for complex nested data

**Option 3: Hybrid**
- Metadata for pattern definitions
- Static Resources for HTML templates

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

### What Makes This Cohesive

#### 1. Single Source of Truth (Customer Context File)
- Replaces guessing with facts
- Website scraping becomes validation, not discovery
- Terminology is correct from the start
- Deal patterns reflect customer reality

#### 2. Evidence Richness (Multi-Record)
- More data = better pattern detection
- Citations reference specific examples ("Record 2 shows...")
- Field selection is smarter (sees variance)

#### 3. Proven Patterns (From Existing Prompts)
- Not theoretical - extracted from what already works
- Easy to expand (add new patterns as you build new prompts)
- Consistent quality across all generated prompts
- 70% reuse across prompt types

#### 4. Compositional Architecture
- **Patterns** are Lego blocks (Negotiation Pressure, Stalled Deal)
- **Archetypes** define the shape (Deal Coach, Executive Brief)
- **Customer context** defines the language (Member, Plan, MLR)
- **Multi-record** provides the evidence (cite specific records)
- **UI components** ensure consistent formatting

---

## Implementation Roadmap

### Phase 0: Foundation & Proof of Concept (Week 1)

**Goals**: 
- Prove evidence binding improves quality
- Extract initial patterns from existing prompts
- Define metadata structure

**Tasks**:
1. **Evidence Binding** (1-2 hours)
   - Update Stage08 to inject evidence rules
   - Deploy and test with existing prompts
   - Measure hallucination reduction

2. **Pattern Extraction** (2-3 days)
   - Analyze top 5 existing prompts
   - Extract common patterns
   - Document in markdown

3. **Metadata Design** (1 day)
   - Design Custom Metadata structure
   - Create initial pattern definitions
   - Create initial archetype definitions

**Success Criteria**:
- Evidence binding reduces hallucination by 50%+
- Identified 5-8 reusable patterns
- Metadata structure approved

---

### Phase 1: Multi-Record Foundation (Week 2)

**Goals**: 
- Implement multi-record querying
- Improve field selection with variance analysis
- Test impact on evidence quality

**Tasks**:
1. **Update Stage01** (2 days)
   - Implement `getSampleRecords()` method
   - Query 3 records in parallel
   - Handle edge cases (fewer than 3 records available)

2. **Update Stage05** (2 days)
   - Analyze field variance across 3 records
   - Prioritize fields that show patterns
   - Maintain baseline hardcoded fields

3. **Testing** (1 day)
   - Test with Opportunity, Account, Case objects
   - Measure field selection quality improvement
   - Check heap size and performance

**Success Criteria**:
- 3 records queried successfully
- Field selection quality improves measurably
- No performance degradation (heap size OK)

---

### Phase 2: Pattern Library Implementation (Weeks 3-4)

**Goals**: 
- Build pattern matching logic
- Create pattern library from remaining prompts
- Integrate into Stage02 and Stage08

**Tasks**:
1. **Pattern Matching Logic** (3 days)
   - Build trigger evaluation in Stage02
   - Match patterns based on data signals
   - Limit to 3-5 patterns max per run

2. **Pattern Library Creation** (3 days)
   - Extract patterns from remaining 10-15 prompts
   - Store in Custom Metadata
   - Document each pattern

3. **Stage08 Composition** (3 days)
   - Update prompt assembly to use pattern library
   - Inject pattern-specific analysis questions
   - Apply forbidden phrase filters
   - Test with multiple pattern combinations

4. **Testing & Refinement** (2 days)
   - Test each pattern individually
   - Test pattern combinations
   - Measure output quality vs. baseline

**Success Criteria**:
- 10-15 patterns defined and stored
- Pattern matching logic works reliably
- Output quality improves 2x vs. generic prompts

---

### Phase 3: Customer Context Integration (Week 5)

**Goals**: 
- Create customer business context structure
- Integrate into Stage02
- Replace/reduce website scraping dependency

**Tasks**:
1. **Context File Creation** (2 days)
   - Design context file structure
   - Create Cigna example context
   - Store as Custom Metadata or Static Resource

2. **Stage02 Integration** (2 days)
   - Load context file first
   - Use as baseline for industry classification
   - Website scraping becomes validation/enrichment

3. **Stage08 Integration** (1 day)
   - Inject customer terminology
   - Apply customer-specific deal patterns
   - Use customer stakeholder maps

4. **Testing** (1 day)
   - Test with/without website scraping
   - Verify terminology correctness
   - Measure accuracy improvement

**Success Criteria**:
- Customer context correctly loaded
- Terminology accurate in all outputs
- Can optionally skip website scraping

---

### Phase 4: UI Component Library (Week 6)

**Goals**: 
- Extract reusable UI components
- Ensure consistent formatting
- Enable mix-and-match composition

**Tasks**:
1. **Component Extraction** (2 days)
   - Identify common UI patterns in existing prompts
   - Extract HTML templates
   - Define merge field requirements

2. **Component Storage** (1 day)
   - Store in Static Resources (HTML templates)
   - Link to analytical patterns in metadata
   - Document usage

3. **Stage08 Integration** (2 days)
   - Update template assembly to use components
   - Support archetype-specific layouts
   - Test rendering

**Success Criteria**:
- 8-10 reusable components defined
- Consistent formatting across all prompts
- Easy to add new components

---

## The Killer Advantage

### What Other AI Tools Do
- Generic, one-size-fits-all prompts
- Guess at industry context
- Generic advice ("align with stakeholders")
- No evidence backing

### What GPTfy Does (After This)
- **Pre-configured** for customer's business (Cigna, not "healthcare")
- **Built from proven patterns** (extracted from working prompts)
- **Evidence-backed** by actual deal data (cites Record 1/2/3)
- **Speaks customer's language** natively (Member, Plan, MLR)
- **Compositional** (patterns + archetypes + context + evidence)

**This isn't just "better prompts" - it's "your analyst, automated."**

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

### Immediate (This Week)
1. ✅ Document strategy (this file)
2. 🔲 Implement evidence binding in Stage08
3. 🔲 Extract patterns from 3-5 existing prompts
4. 🔲 Test evidence binding impact

### Short Term (Weeks 2-3)
1. Multi-record implementation
2. Initial pattern library (5-8 patterns)
3. Pattern matching logic in Stage02

### Medium Term (Weeks 4-6)
1. Full pattern library (10-15 patterns)
2. Customer context file integration
3. UI component library

---

## References & Related Docs

- [PRD: Automated Prompt Creation](./PRD-Automated-Prompt-Creation.md)
- [Enhanced Prompt Template](./ENHANCED_PROMPT.md)
- [GPTfy Configuration Guide](./GPTFY_CONFIG.md)
- [Current Roadmap](./ROADMAP.md)

---

## Change Log

| Date | Author | Changes |
|------|--------|---------|
| 2026-01-21 | AI Assistant | Initial strategy document created |

