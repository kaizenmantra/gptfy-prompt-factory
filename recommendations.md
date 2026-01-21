# Strategic Evolution: GPTfy Analysis Assembler

## Vision
Transform the Prompt Factory from a generic prompt generator into a Decisive Analysis Assembler. Instead of asking the user for complexity, the system will automatically assemble a "mini analyst" based on lightweight industry detection, trigger-based pattern selection, and strict evidence-binding rules.

---

## Core Architectural Shifts

### 1. From Description to Decision
Insights will move away from generic "advice" to decision-support signals triggered by real data evidence.

- **Evidence Binding**: Every claim must cite a Salesforce field or log entry.
- **Forbidden Language**: Ban generic "consultant speak" like "Align with stakeholders."

### 2. Industry Behavior Profiles (Lightweight)
Replace deep scraping with deterministic industry classification.

- **Classification Pass**: Identify industry bucket (e.g., Healthcare Payer) and exclude irrelevant topics.
- **Static Assumptions**: Inject buying motions and sales cycle bias directly into the meta-prompt.

### 3. Pattern Library (The Analytical Lenses)
Implement a library of "patterns" (e.g., Negotiation Pressure) that include:

- **Trigger Logic**: Pure data-driven rules (Stage, Probability, Keywords).
- **Hard Constraints**: Specific questions the AI must answer.

### 4. Multi-Record Data Foundation

- **Purpose**: Evidence Quality & Pattern Detection
- Query 2-3 sample records instead of 1:
  - Most recent record
  - Oldest open record
  - One mid-stage record
- **Why It Works**:
  - Field Selection: Sees variance (empty vs populated fields across records)
  - Evidence Binding: Has real examples to cite (e.g., "In Record 1, Discount = 20%")
  - Pattern Detection: More reliable (e.g., "2 of 3 deals mention discount pressure")
- **Implementation Details**:
  - Query in parallel (3 async calls, not sequential)
  - Stage05 field selection analyzes variance across records

### 5. Customer Business Context File

- **Purpose**: Industry Intelligence Without Hallucination
- **Structure**:
  - Markdown/JSON file deployed with the package containing customer-specific business intelligence.
  - Example:
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
- **How It's Used**:
  - Stage02 loads this FIRST (before website scraping)
  - Website scraping validates/enriches, doesn't create from scratch
  - Stage08 injects relevant sections into final prompt based on detected patterns

---

## Proposed Roadmap

### Phase 1: The "Analysis Assembler" Engine
1. **Define the Meta-Prompt Blueprint**: Create the foundational prompt for the generator that produces the final runtime prompt.
2. **Industry Behavior Schema**: Define the static mappings for industry-specific buying motions.
3. **Archetype Definition**: Implement the "Deal Coach" and "Executive Risk" brief structures.

### Phase 2: Refactoring the Pipeline
1. **Stage 02 Rewrite**: Pivot from "Deep Research" to "Decisive Classification."
2. **Stage 08 Rewrite**: Implementation of the "Assembly" logic—injecting selected patterns and industry profiles.
3. **Evidence Binding Enforcement**: Add system-level instructions that force "Cite evidence or state 'Missing data'."

### Phase 3: Foundation & Cleanup (Technical)
1. Uncomment and activate Stages 9-12 with new validation rules.
2. Sanitize and externalize configuration (Custom Metadata).

### Phase 4: Pattern Library Implementation
1. Extract patterns from existing production prompts.
2. Build trigger evaluation in Stage02.
3. Store patterns in Custom Metadata or Static Resources.
4. Update Stage08 to use pattern library for prompt assembly.

### Phase 5: Customer Context Integration
1. Create customer business context structure.
2. Integrate into Stage02 and Stage08.
3. Replace/reduce website scraping dependency.

---

## Next Immediate Steps
1. **Design the Meta-Prompt Generator**: Draft the prompt that the "Factory" uses to build the "Analyst."
2. **"Deal Coach" Rewrite**: Apply this new architecture to the flagship use case to prove the model.
3. **Implement Evidence Binding**: Add system-level instructions to enforce evidence citation.

---

## IMPORTANT
This strategy prioritizes Decision Support over Description. We win by not asking the user questions and being decisive about the analysis.