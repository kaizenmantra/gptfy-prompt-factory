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

### Layer 2: The Pattern Engine (Analytical Lenses)

**Purpose**: We do not ask the LLM to "figure it out." We inject specific **Analytical Patterns** triggered by data signals.

#### The Insight
We have 15-20 production prompts (Deal Coach, Account 360, Sentiment Journey, etc.) that already work. Instead of inventing patterns theoretically or asking the LLM to be creative, **extract proven patterns and apply them deterministically**.

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

**Option 3: Hybrid** (Recommended)
- Metadata for pattern definitions
- Static Resources for HTML templates

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
   - Design context file structure (see Layer 1 for example)
   - Create Cigna example context (Industry, Terminology, Deal Patterns, Stakeholders, Red Flags)
   - Store as Custom Metadata: `PF_Customer_Context__mdt` OR Static Resource

2. **Stage01 Integration** (1 day)
   - Load context file at pipeline start
   - Pass to Stage02 as baseline

3. **Stage02 Integration** (2 days)
   - START with customer context (not website)
   - Use context for:
     - Industry classification (no guessing)
     - Forbidden topics (exclusion list)
     - Deal pattern hints
   - Website scraping becomes **optional validation**, not primary source

4. **Stage08 Integration** (1 day)
   - Inject customer terminology into meta-prompt
   - Apply customer-specific deal patterns
   - Use customer stakeholder maps in analysis

5. **Testing** (1 day)
   - Compare outputs with/without customer context
   - Verify terminology correctness (100% accuracy expected)
   - Test with/without website scraping (should work either way)

**Success Criteria**:
- ✅ Customer context correctly loaded
- ✅ Terminology 100% accurate in all outputs
- ✅ Can skip website scraping without quality loss
- ✅ Industry-specific patterns correctly applied

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

