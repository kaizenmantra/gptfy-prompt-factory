# Unified Strategy: The Decisive Analysis Assembler

## Executive Summary
This document synthesizes the architectural vision for the GPTfy Prompt Factory. We are pivoting from a "generic prompt generator" to a **"Decisive Analysis Assembler"**.
We stop asking users to "describe what they want" and instead **automatically assemble** a sophisticated "mini-analyst" based on hard data signals, verified customer context, and proven analytical patterns.

---

## 1. The Core Philosophy: "Assembly, Not Invention"

The key insight is that **great analysis is not invented from scratch** by an LLM each time. It is **assembled** from proven components.

*   **Old Way**: "Read this record and give advice." -> Result: Generic hallucinations.
*   **New Way**: "Apply the *Negotiation Pressure* pattern using *Cigna* terminology with evidence from *Record #1*." -> Result: Expert decision support.

## 2. The 4-Layer Architecture

We will implement this via four distinct layers of intelligence:

### Layer 1: The Foundation (Truth & Evidence)
Instead of relying on single records or scraped web data, we build on verified ground truth.
*   **Multi-Record Evidence**: We query 3 records (Recent, Oldest, Mid-stage) to detect variance and patterns. This prevents "n=1" bias.
*   **Customer Context File**: A single-tenant "Ground Truth" file (Markdown/JSON) containing verified industry terms, forbidden topics, and buying motions. This replaces generic industry guessing.
    *   *Example*: "At Cigna, we say 'Member', not 'Customer'."

### Layer 2: The Pattern Engine (Analytical Lenses)
We do not ask the LLM to "figure it out." We inject specific **Analytical Patterns** triggered by data signals.
*   **Pattern Library**: A catalog of 15-20 specific analysis modules (e.g., *Negotiation Pressure*, *Stalled Deal Revival*, *Executive Risk*).
*   **Deterministic Triggers**: Patterns are selected by hard logic, not AI vibes.
    *   *If `Stage` contains 'Quote' AND `Probability` > 50% -> Trigger 'Negotiation Pressure'.*

### Layer 3: The Assembly (Meta-Prompting)
The "Factory" becomes an assembly line that constructs the final prompt from the selected components.
*   **Archetypes**: The "container" for the output (e.g., *Deal Coach Brief*, *Executive Risk Memo*).
*   **Evidence Binding**: A strict system rule: "Every insight must cite specific evidence from Record 1/2/3 or state 'Data Missing'".
*   **Pattern Injection**: The meta-prompt explicitly instructs the AI: "Apply the *Negotiation Pressure* analysis rules."

### Layer 4: The Experience (User Control)
While the engine is decisive, the user experience builds trust through transparency and refinement.
*   **Interactive Preview**: Users see the prompt being assembled in real-time (Patterns selected -> Context loaded -> Prompt generated).
*   **Privacy Mode**: PII sanitization for sensitive fields before analysis.
*   **Deep Research**: Optional "live" web context for highly strategic accounts.

---

## 3. Implementation Priorities

To realize this vision, our roadmap focuses on **depth over breadth**.

### Phase 1: The "Analysis Assembler" Engine (Immediate)
*   **Meta-Prompt Generator**: Build the "Factory" prompt that creates the runtime analyst.
*   **Flagship Archetype**: Rewrite the "Deal Coach" use case to prove the model.
*   **Evidence Binding**: Implement the "Cite your sources" rule immediately.

### Phase 2: Knowledge Injection (Short Term)
*   **Customer Context**: Deploy the static context file structure.
*   **Pattern Library**: Extract the top 5 proven patterns from existing production prompts.

### Phase 3: Functional Scale (Medium Term)
*   **Multi-Record Querying**: Enable the 3-record evidence foundation.
*   **Full Pipeline Activation**: Enable Stages 9-12 (Validation/Quality) to guardrail the new powerful prompts.

---

## 4. Why This Wins

1.  **Trust**: By citing explicit evidence ("Record 2 shows..."), users trust the output.
2.  **Relevance**: By using the Customer Context file, we speak their language on Day 1.
3.  **Speed**: We stop asking users 20 questions. We look at the data and **decide** what analysis they need.

**Verdict**: The "Analysis Assembler" is not just a feature upgrade; it is a fundamental shift from *generative text* to *automated intelligence*.
