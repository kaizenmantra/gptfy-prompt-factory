// Phase 3: Create Context Template Builder
// Healthcare Payer Context

System.debug('=== PHASE 3: CONTEXT TEMPLATE BUILDER ===');

// Get Builder record type
Id builderRtId = [SELECT Id FROM RecordType 
                   WHERE SobjectType = 'ccai__AI_Prompt__c' 
                   AND DeveloperName = 'Builder' 
                   LIMIT 1].Id;

// Get topic IDs
Map<String, Id> topicMap = new Map<String, Id>();
for (Topic t : [SELECT Id, Name FROM Topic 
                WHERE Name IN ('Healthcare', 'Context Template', 'P1')]) {
    topicMap.put(t.Name, t.Id);
}

System.debug('✅ Builder RecordType: ' + builderRtId);
System.debug('✅ Topics found: ' + topicMap.size());

// Create Healthcare Context Template
String healthcareContext = 
'=== CONTEXT TEMPLATE: HEALTHCARE PAYER ===\n\n' +
'PURPOSE: Provide industry-specific context, terminology, and heuristics for healthcare payer/insurance organizations.\n\n' +
'WHEN TO USE:\n' +
'- Opportunities or accounts in Healthcare/Insurance industry\n' +
'- When analyzing deals with payer organizations (Anthem, UnitedHealth, Cigna, Aetna, etc.)\n' +
'- B2B software sales to healthcare administrators or benefits teams\n' +
'- Compliance-heavy regulatory environments\n\n' +
'INDUSTRY TERMINOLOGY:\n' +
'- Member: Healthcare plan enrollee/beneficiary (not "customer")\n' +
'- Provider: Doctor, hospital, clinic (not "vendor")\n' +
'- Network: In-network vs. out-of-network care\n' +
'- Claims: Medical billing transactions\n' +
'- Utilization: Healthcare service usage rates\n' +
'- Care Management: Programs to improve health outcomes\n' +
'- Value-Based Care: Payment models tied to quality/outcomes (vs. fee-for-service)\n' +
'- Prior Authorization: Pre-approval for procedures/medications\n' +
'- Formulary: List of covered prescription drugs\n' +
'- Star Ratings: CMS quality ratings for Medicare Advantage plans\n\n' +
'KEY STAKEHOLDER ROLES:\n' +
'- Chief Medical Officer (CMO): Clinical decision-maker, quality focus\n' +
'- Chief Information Officer (CIO): Technology infrastructure, integration concerns\n' +
'- VP of Operations: Process efficiency, cost reduction\n' +
'- Director of Care Management: Member outcomes, care coordination\n' +
'- Compliance Officer: HIPAA, state/federal regulations\n' +
'- CFO: Financial impact, ROI, budget authority\n' +
'- Actuaries: Risk modeling, pricing analysis\n\n' +
'BUYING PATTERNS & HEURISTICS:\n\n' +
'1. LONG SALES CYCLES (9-18 months typical):\n' +
'   - Multiple stakeholders across clinical + operational + IT\n' +
'   - Regulatory/legal review adds 2-3 months\n' +
'   - Budget cycles tied to fiscal year (often July 1 or Jan 1)\n' +
'   - Early stage deals (Discovery/Qualification) in Q1-Q2 may not close until next fiscal year\n\n' +
'2. COMPLIANCE IS PARAMOUNT:\n' +
'   - HIPAA compliance is non-negotiable (security, privacy, breach notification)\n' +
'   - BAA (Business Associate Agreement) required for any PHI access\n' +
'   - State-specific insurance regulations (varies by market)\n' +
'   - SOC 2 Type II certification often expected\n' +
'   - Missing compliance documentation = deal-killer\n\n' +
'3. PROOF OF CONCEPT (POC) EXPECTATIONS:\n' +
'   - Pilot with limited member population (500-5,000 members)\n' +
'   - Success metrics: Cost savings, quality improvement, member satisfaction\n' +
'   - Timeline: 3-6 months minimum\n' +
'   - Champion risk: If pilot fails, deal dies\n\n' +
'4. INTEGRATION COMPLEXITY:\n' +
'   - Legacy systems: Mainframe claims systems, fragmented data\n' +
'   - HL7/FHIR standards for health data exchange\n' +
'   - Integration with EHRs (Epic, Cerner), pharmacy systems, lab systems\n' +
'   - Data quality concerns (incomplete, inconsistent member data)\n' +
'   - IT team involvement from Day 1 is critical\n\n' +
'5. VALUE PROPOSITION FOCUS:\n' +
'   - Cost reduction: Lower admin costs, reduce unnecessary utilization\n' +
'   - Quality improvement: Better health outcomes, preventive care\n' +
'   - Member satisfaction: NPS scores, retention, engagement\n' +
'   - Regulatory compliance: Avoid fines, meet CMS requirements\n' +
'   - Quantify impact: "Save $2M annually" beats "Improve efficiency"\n\n' +
'RISK FACTORS SPECIFIC TO HEALTHCARE PAYERS:\n\n' +
'⚠️ HIGH RISK:\n' +
'- No CMO or CIO engagement (clinical + IT buy-in both required)\n' +
'- No compliance documentation shared/reviewed\n' +
'- Integration requirements undefined (IT team not engaged)\n' +
'- Late-stage deal without BAA in place\n' +
'- Budget not confirmed in Q3-Q4 (likely pushed to next fiscal year)\n\n' +
'✅ POSITIVE SIGNALS:\n' +
'- CMO + CIO + CFO all engaged\n' +
'- Active POC with defined success metrics\n' +
'- Compliance team already reviewed documentation\n' +
'- Integration architecture workshop completed\n' +
'- Reference customer from similar payer organization\n\n' +
'RECOMMENDED ACTIONS FOR HEALTHCARE DEALS:\n\n' +
'Early Stage (Discovery/Qualification):\n' +
'- Map stakeholders: Ensure CMO, CIO, Operations lead, Compliance all identified\n' +
'- Schedule compliance review: Share SOC 2, HIPAA documentation early\n' +
'- Understand integration landscape: What systems must connect?\n' +
'- Quantify value: Work with champion to model ROI (cost savings, quality metrics)\n\n' +
'Mid Stage (Proposal/Negotiation):\n' +
'- BAA negotiation: Start early, legal review takes 4-6 weeks\n' +
'- POC scope: Define pilot size, success metrics, timeline, exit criteria\n' +
'- Executive sponsor: Secure C-level champion to drive internal approvals\n' +
'- Budget timing: Confirm fiscal year alignment\n\n' +
'Late Stage (Contract/Closed Won):\n' +
'- Implementation plan: Detailed integration roadmap with IT team\n' +
'- Change management: Training for care managers, clinical staff\n' +
'- Success metrics: Agree on KPIs, reporting cadence\n\n' +
'ALERT TRIGGERS:\n' +
'- If deal > $500K and no CMO engagement → CRITICAL RISK\n' +
'- If in Proposal stage and no BAA discussions → WARNING\n' +
'- If Q4 close target and budget not approved → HIGH RISK (likely slip to next year)\n' +
'- If "integration concerns" mentioned but no IT stakeholder → WARNING\n' +
'- If no reference customer from healthcare → Moderate risk\n\n' +
'LANGUAGE & FRAMING:\n' +
'- Use healthcare terminology (members, not customers; providers, not vendors)\n' +
'- Frame value in healthcare outcomes (quality, cost, satisfaction)\n' +
'- Acknowledge compliance complexity ("We understand HIPAA requirements...")\n' +
'- Reference similar healthcare customers by name (with permission)\n' +
'- Demonstrate understanding of payer business model (risk, utilization, value-based care)\n\n' +
'BENCHMARKS (Healthcare Payer Deals):\n' +
'- Average deal size: $300K-$2M\n' +
'- Average sales cycle: 12 months\n' +
'- Close rate: 25-35% (lower than other industries due to complexity)\n' +
'- Stage velocity: Discovery 2-3 months, Qualification 3-4 months, Proposal 4-5 months, Negotiation 2-3 months\n' +
'- Champion loss risk: High (turnover in healthcare IT leadership)\n\n' +
'USE THIS CONTEXT TO:\n' +
'1. Interpret deal data through healthcare lens\n' +
'2. Flag risks specific to payer organizations\n' +
'3. Recommend actions aligned with healthcare buying patterns\n' +
'4. Use appropriate terminology and framing\n' +
'5. Set realistic expectations for timeline and complexity';

ccai__AI_Prompt__c healthcareBuilder = new ccai__AI_Prompt__c(
    Name = 'Healthcare Payer Context',
    RecordTypeId = builderRtId,
    Category__c = 'Context Template',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = 'a01gD000003okzEQAQ',
    ccai__AI_Data_Extraction_Mapping__c = 'a05QH000008Olh8YAC',
    ccai__Prompt_Command__c = healthcareContext
);

insert healthcareBuilder;
System.debug('✅ Created Healthcare Context Builder: ' + healthcareBuilder.Id);

// Create topic assignments
List<TopicAssignment> assignments = new List<TopicAssignment>();

if (topicMap.containsKey('Healthcare')) {
    assignments.add(new TopicAssignment(EntityId = healthcareBuilder.Id, TopicId = topicMap.get('Healthcare')));
}
if (topicMap.containsKey('Context Template')) {
    assignments.add(new TopicAssignment(EntityId = healthcareBuilder.Id, TopicId = topicMap.get('Context Template')));
}
if (topicMap.containsKey('P1')) {
    assignments.add(new TopicAssignment(EntityId = healthcareBuilder.Id, TopicId = topicMap.get('P1')));
}

if (!assignments.isEmpty()) {
    insert assignments;
    System.debug('✅ Created ' + assignments.size() + ' topic assignments');
}

// Verification
ccai__AI_Prompt__c builder = [
    SELECT Id, Name, Category__c, ccai__Status__c
    FROM ccai__AI_Prompt__c
    WHERE Id = :healthcareBuilder.Id
];

System.debug('\n=== VERIFICATION ===');
System.debug('📦 ' + builder.Name + ' (' + builder.Category__c + ') - ' + builder.ccai__Status__c);
System.debug('\n✅ PHASE 3 COMPLETE');
System.debug('Healthcare Context ID: ' + healthcareBuilder.Id);
