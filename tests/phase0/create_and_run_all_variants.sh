#!/bin/bash
# Phase 0 Test - Create all variants and execute them
# This script will:
# 1. Create all 5 prompt variant files
# 2. Execute each variant via Prompt Factory API
# 3. Capture responses
# 4. Log everything

set -e

PROMPT_ID="a0DQH00000KYLsv2AH"
OPP_ID="006QH00000HjgvlYAB"
ORG_ALIAS="agentictso"
TEST_DIR="tests/phase0"

echo "🚀 Phase 0 Quality Test - Starting..."
echo "Test Opportunity: $OPP_ID"
echo "Prompt ID: $PROMPT_ID"
echo ""

# Create Evidence Binding instruction block file
cat > "${TEST_DIR}/instruction_evidence.txt" << 'EOF'

=== EVIDENCE BINDING RULES (PHASE 0 TEST - VARIANT 1) ===

CRITICAL: Every insight, recommendation, or analysis MUST be grounded in specific data from the Salesforce record.

REQUIRED FORMAT FOR ALL RECOMMENDATIONS:
"[Recommendation] (Evidence: [Field] = [Value])"

EXAMPLES:
❌ BAD: "Consider following up with the decision maker."
✅ GOOD: "CRITICAL: Follow up immediately with CFO Sarah Johnson (Evidence: Contact.Name = 'Sarah Johnson', Contact.Title = 'Chief Financial Officer', OpportunityContactRole.Role = 'Economic Buyer', OpportunityContactRole.IsPrimary = true)"

❌ BAD: "There are overdue tasks that need attention."
✅ GOOD: "HIGH RISK: Task 'Send ROI Analysis to CFO' is 7 days overdue (Evidence: Task.Subject = 'Send ROI Analysis to CFO', Task.ActivityDate = '2026-01-15', Task.Status = 'Not Started', Task.Priority = 'High', TODAY = '2026-01-22')"

EVIDENCE BINDING CHECKLIST (MANDATORY):
1. Every claim must cite at least one field name and its actual value
2. Use actual field values from merge fields - never invent data
3. For people references, ALWAYS cite: Contact.Name, Contact.Title, and OpportunityContactRole.Role
4. For date-based insights, cite the date field and calculate days elapsed/remaining
5. If data is missing, state explicitly: "MISSING DATA: [Field Name] - recommend updating before proceeding"

MANDATORY EVIDENCE FIELDS TO CITE (when relevant):
- Opportunity: Amount, Probability, StageName, CloseDate, Description, NextStep, HasOverdueTask, HasOpenActivity
- Tasks: Subject, Status, Priority, ActivityDate (calculate overdue days if past today)
- Events: Subject, StartDateTime, Description, Contact.Name (who attended)
- Contacts: Contact.Name, Contact.Title, Contact.Department, OpportunityContactRole.Role, OpportunityContactRole.IsPrimary

NO GENERIC RECOMMENDATIONS. Every sentence analyzing data must include specific evidence citations.
If you cannot find evidence for a recommendation, do NOT make that recommendation.
EOF

# Create Diagnostic Language instruction block file
cat > "${TEST_DIR}/instruction_diagnostic.txt" << 'EOF'

=== DIAGNOSTIC LANGUAGE RULES (PHASE 0 TEST - VARIANT 2) ===

Replace ALL descriptive language with diagnostic assessments. Act as a Deal Doctor, not a reporter.

FORBIDDEN PHRASES (NEVER USE):
- "Consider following up"
- "Reach out to"
- "Touch base with"
- "Circle back"
- "Ensure alignment"
- "Maintain momentum"
- "Engage stakeholders"
- "Reinforce value proposition"
- "There is", "There are"
- "Shows", "Displays", "Contains"

REQUIRED DIAGNOSTIC LANGUAGE:

1. SEVERITY LABELS (use for every issue):
   - CRITICAL: Deal-killing risk, requires immediate action
   - HIGH RISK: Significant threat to close probability
   - WARNING: Issue that could escalate
   - GAP: Missing information needed for analysis
   - OPPORTUNITY: Unexploited advantage

2. CAUSAL ANALYSIS (always explain WHY):
   ❌ BAD: "The deal has low probability."
   ✅ GOOD: "20% probability indicates weak buyer commitment. LIKELY CAUSE: Missing economic buyer engagement (last contact: 15+ days ago) + competing offer from Aetna (15% cheaper)."

3. PRESCRIPTIVE ACTIONS (specific, time-bound):
   ❌ BAD: "Follow up with the CFO."
   ✅ GOOD: "IMMEDIATE ACTION (within 24 hours): Call CFO Sarah Johnson to address 7-day-overdue ROI analysis. Script: 'I know you're evaluating budget approval by Feb 15. Here's the TCO comparison you requested...'"

4. SIGNAL INTERPRETATION:
   - Don't just list data - interpret what it MEANS
   ❌ BAD: "There is 1 overdue task."
   ✅ GOOD: "CRITICAL SIGNAL: Overdue task 'Send ROI Analysis to CFO' (7 days late) indicates we're failing to meet Economic Buyer's information needs. This will delay budget approval and give Aetna time to counter."

STRUCTURE EVERY INSIGHT AS:
[SEVERITY LABEL]: [Diagnostic finding] (Evidence: [data]) → [Causal explanation] → [Prescriptive action with timeline]

NO GENERIC ADVICE. Every sentence must diagnose, prescribe, or explain causality.
EOF

# Create Context Application instruction block file
cat > "${TEST_DIR}/instruction_context.txt" << 'EOF'

=== HEALTHCARE PAYER CONTEXT APPLICATION (PHASE 0 TEST - VARIANT 3) ===

This is a HEALTHCARE PAYER deal. Apply these industry-specific heuristics to your analysis:

BUYING MOTION ASSUMPTIONS:
- Decision process: Committee-driven, requires CFO budget approval + Legal compliance review + Executive sponsor
- Timeline: Long sales cycles (3-6 months), procurement-heavy with RFP process
- Proof requirements: Security architecture docs, HIPAA compliance evidence, customer references from similar organizations
- Risk sensitivity: Extremely high - any compliance gaps or security concerns are deal-killers

RED FLAGS FOR HEALTHCARE PAYER DEALS:
1. Missing HIPAA compliance discussion → Indicates we haven't addressed their #1 concern
2. CFO pushing for discounts → Means we haven't proven ROI/value over cost
3. No Legal/Compliance contact in deal → They WILL get involved, better to engage early
4. Competitor emphasizing "brand trust" → We must counter with proof points, not claims
5. Delay in security review → Often hides internal budget or priority issues

DEAL COACHING FOR HEALTHCARE PAYER:
- Economic Buyer (CFO): Speaks language of TCO, risk mitigation, budget predictability
  → Frame solution in financial terms: "3-year TCO vs. status quo", "cost per employee", "ROI timeline"
  
- Compliance Stakeholder: HIPAA compliance is non-negotiable, requires documentation
  → Proactively provide: Security architecture, data encryption methods, audit trails, breach notification procedures
  
- HR/Benefits: Cares about employee satisfaction, ease of administration, wellness programs
  → Emphasize: Digital member experience, wellness tools, modern UX, employee engagement metrics

COMPETITOR CONTEXT:
- If competing with Aetna/UnitedHealthcare/Cigna (established players):
  → They'll lead with brand trust and network size
  → Counter with: Modern technology, better member experience, superior digital tools, customer service NPS
  → Don't compete on price alone - emphasize value and employee satisfaction

APPLY THESE HEURISTICS:
- Interpret all signals through healthcare payer lens
- Use industry-specific terminology (TCO, HIPAA, member experience, wellness programs)
- Recognize industry-standard buying patterns
- Anticipate regulatory/compliance concerns before they're raised
- Frame recommendations in terms of healthcare payer decision criteria

When analyzing this deal, ask:
1. Have we addressed HIPAA compliance? (If no → CRITICAL GAP)
2. Do we have CFO buy-in on TCO? (If no → HIGH RISK)
3. Is there a compliance/legal contact? (If no → ADD TO OPPORTUNITY)
4. How are we positioned vs. incumbent/competitor on value (not just price)?
5. Does our champion have influence with Economic Buyer?
EOF

echo "✅ Instruction blocks created"
echo ""

# Variant 2: Baseline + Diagnostic Language
echo "📝 Creating Variant 2 (Diagnostic Language)..."
cat "${TEST_DIR}/variants/variant_0_baseline.txt" "${TEST_DIR}/instruction_diagnostic.txt" > "${TEST_DIR}/variants/variant_2_diagnostic.txt"
echo "✅ Variant 2 created ($(wc -c < ${TEST_DIR}/variants/variant_2_diagnostic.txt) bytes)"

# Variant 3: Baseline + Context Application
echo "📝 Creating Variant 3 (Context Application)..."
cat "${TEST_DIR}/variants/variant_0_baseline.txt" "${TEST_DIR}/instruction_context.txt" > "${TEST_DIR}/variants/variant_3_context.txt"
echo "✅ Variant 3 created ($(wc -c < ${TEST_DIR}/variants/variant_3_context.txt) bytes)"

# Variant 4: Baseline + All Three
echo "📝 Creating Variant 4 (All Three Combined)..."
cat "${TEST_DIR}/variants/variant_0_baseline.txt" "${TEST_DIR}/instruction_evidence.txt" "${TEST_DIR}/instruction_diagnostic.txt" "${TEST_DIR}/instruction_context.txt" > "${TEST_DIR}/variants/variant_4_all.txt"
echo "✅ Variant 4 created ($(wc -c < ${TEST_DIR}/variants/variant_4_all.txt) bytes)"

echo ""
echo "✅ All 5 variants created successfully!"
echo ""
ls -lh "${TEST_DIR}/variants/"
echo ""

echo "📊 Variant Summary:"
echo "  - Variant 0: Baseline ($(wc -c < ${TEST_DIR}/variants/variant_0_baseline.txt) bytes)"
echo "  - Variant 1: +Evidence Binding ($(wc -c < ${TEST_DIR}/variants/variant_1_evidence.txt) bytes)"
echo "  - Variant 2: +Diagnostic Language ($(wc -c < ${TEST_DIR}/variants/variant_2_diagnostic.txt) bytes)"
echo "  - Variant 3: +Context Application ($(wc -c < ${TEST_DIR}/variants/variant_3_context.txt) bytes)"
echo "  - Variant 4: +All Three ($(wc -c < ${TEST_DIR}/variants/variant_4_all.txt) bytes)"
echo ""

echo "🎯 Ready to execute! Run the test_execution script next."
