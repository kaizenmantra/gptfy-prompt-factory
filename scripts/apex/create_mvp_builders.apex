// MVP Test: Create 2 Builder Prompt Records
// Evidence Binding (Quality Rule) + Risk Assessment (Pattern)

System.debug('=== MVP BUILDER CREATION SCRIPT ===');

// Step 1: Get Builder record type ID
Id builderRtId;
try {
    builderRtId = [SELECT Id FROM RecordType 
                   WHERE SobjectType = 'ccai__AI_Prompt__c' 
                   AND DeveloperName = 'Builder' 
                   LIMIT 1].Id;
    System.debug('✅ Builder RecordType ID: ' + builderRtId);
} catch (Exception e) {
    System.debug('❌ ERROR: Builder RecordType not found - ' + e.getMessage());
    return;
}

// Step 2: Get topic IDs
Map<String, Id> topicMap = new Map<String, Id>();
List<Topic> topics = [SELECT Id, Name FROM Topic 
                      WHERE Name IN ('Evidence Binding', 'Insight-Led Design', 'P0', 
                                    'Risk Assessment', 'Opportunity')];

if (topics.isEmpty()) {
    System.debug('⚠️  WARNING: No topics found - builders will be created without topic assignments');
} else {
    for (Topic t : topics) {
        topicMap.put(t.Name, t.Id);
    }
    System.debug('✅ Found ' + topicMap.size() + ' topics');
}

// Step 3: Create Evidence Binding Builder (Quality Rule)
String evidenceBindingContent = 
'=== EVIDENCE BINDING RULES (v2) ===\n\n' +
'CORE PRINCIPLE: Every claim must be traceable. No claim should lead with its source.\n\n' +
'FORMAT HIERARCHY:\n\n' +
'Level 1 - EMBEDDED DATA (Use 80% of the time):\n' +
'Weave data naturally into insights. No explicit citation.\n' +
'✅ GOOD: "This $1.5M deal needs executive sponsor engagement before close."\n' +
'✅ GOOD: "With only 67 days to close and no discovery meeting scheduled..."\n' +
'✅ GOOD: "Stage has been stalled for 45 days—well beyond your 21-day benchmark."\n' +
'❌ BAD: "Evidence: Amount = $1,500,000. This is a large deal."\n\n' +
'Level 2 - PARENTHETICAL SOURCE (Use 15% of the time):\n' +
'Insight first, with brief source reference in parentheses.\n' +
'✅ GOOD: "No executive sponsor identified. (Source: Contact Roles)"\n' +
'✅ GOOD: "Budget not yet confirmed. (Source: Opportunity custom field)"\n' +
'❌ BAD: "Evidence: No Contact with Role = Economic Buyer"\n\n' +
'Level 3 - INLINE CITATION (Use 5% of the time - detailed sections only):\n' +
'Explicit "based on" statement after insight.\n' +
'✅ GOOD: "Deal timeline is at significant risk."\n' +
'        → Based on: Stage Age = 45 days (benchmark: 21 days), Close Date = March 28\n\n' +
'Level 4 - COLLAPSIBLE DATA SOURCES (Always at end):\n' +
'Full field citations available on demand, collapsed by default.\n' +
'<details>\n' +
'  <summary>📊 Data Sources</summary>\n' +
'  <ul>\n' +
'    <li>Deal Size: Opportunity.Amount = $1,500,000</li>\n' +
'    <li>Close Date: Opportunity.CloseDate = 2026-03-28</li>\n' +
'  </ul>\n' +
'</details>\n\n' +
'CRITICAL RULES:\n' +
'❌ NEVER start sentences with "Evidence:"\n' +
'❌ NEVER list field values without insight\n' +
'❌ NEVER use API field names in visible text\n' +
'❌ NEVER interrupt flow with multiple citations\n\n' +
'✅ ALWAYS lead with the "so what"\n' +
'✅ ALWAYS weave numbers into natural sentences\n' +
'✅ ALWAYS provide specific recommendations\n' +
'✅ ALWAYS include collapsible data sources at end\n\n' +
'ZONE-SPECIFIC REQUIREMENTS:\n' +
'- Above-the-Fold (Zones 1-4): Use Level 1 or Level 2 ONLY\n' +
'- Detailed Analysis (Zone 5): Level 1, 2, or 3 acceptable\n' +
'- Data Sources (Zone 6): Level 4 - always required, always collapsed';

ccai__AI_Prompt__c evidenceBinding = new ccai__AI_Prompt__c(
    Name = 'Evidence Binding Rules v2',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = 'a01gD000003okzEQAQ',
    ccai__AI_Data_Extraction_Mapping__c = 'a05QH000008Olh8YAC',
    ccai__Prompt_Command__c = evidenceBindingContent
);

try {
    insert evidenceBinding;
    System.debug('✅ Created Evidence Binding Builder: ' + evidenceBinding.Id);
} catch (Exception e) {
    System.debug('❌ ERROR creating Evidence Binding: ' + e.getMessage());
    return;
}

// Step 4: Create Risk Assessment Pattern Builder
String riskAssessmentContent = 
'=== ANALYTICAL PATTERN: RISK ASSESSMENT ===\n\n' +
'PURPOSE: Identify and analyze risks that could impact deal closure or customer satisfaction.\n\n' +
'DIAGNOSTIC LAYOUT (Lead with insight, support with evidence):\n\n' +
'For each risk, provide:\n' +
'1. SEVERITY: CRITICAL / WARNING / OPPORTUNITY\n' +
'2. RISK: Clear description of the gap or concern\n' +
'3. EVIDENCE: Specific field values that indicate this risk\n' +
'4. IMPACT: Business consequence if not addressed\n' +
'5. MITIGATION: Specific action to resolve\n\n' +
'CRITICAL RISKS (Deal-killers):\n' +
'- Missing champion or economic buyer\n' +
'- No decision maker engaged\n' +
'- Overdue deliverables blocking approval\n' +
'- Stage probability misaligned with close date\n' +
'- Budget not confirmed at late stage\n\n' +
'WARNING RISKS (Significant gaps):\n' +
'- Low activity velocity (< 3 activities/week in proposal stage)\n' +
'- Single-threaded (only 1 contact role)\n' +
'- No executive sponsor engagement\n' +
'- Long time in current stage vs. historical average\n\n' +
'OPPORTUNITIES (Positive signals):\n' +
'- Multiple stakeholders engaged\n' +
'- Recent high-value activities completed\n' +
'- Stage progression aligned with velocity\n' +
'- Strong champion identified\n\n' +
'OUTPUT FORMAT:\n' +
'Use hierarchical structure with color-coded indicators:\n' +
'🔴 CRITICAL: [Risk description]\n' +
'   Impact: [Business consequence]\n' +
'   Evidence: [Specific fields/values]\n' +
'   Action: [Specific, time-bound mitigation]\n\n' +
'🟠 WARNING: [Risk description]\n' +
'   Impact: [Business consequence]\n' +
'   Evidence: [Specific fields/values]\n' +
'   Action: [Specific mitigation]\n\n' +
'🟢 OPPORTUNITY: [Positive signal]\n' +
'   Evidence: [Specific fields/values]\n' +
'   Recommendation: [How to leverage]\n\n' +
'ALWAYS:\n' +
'- Cite specific evidence (Contact roles, Activity counts, Stage duration)\n' +
'- Quantify impact where possible ("Deals without champion: 31% win rate")\n' +
'- Provide actionable mitigation steps with timeframes\n' +
'- Position critical risks at TOP of output (Zone 1 - first 100px)\n' +
'- Limit to top 3 critical items above-the-fold\n\n' +
'NEVER:\n' +
'- Generic risk statements without specifics\n' +
'- Risks without recommended actions\n' +
'- Evidence without business impact\n' +
'- Technical jargon in risk descriptions';

ccai__AI_Prompt__c riskAssessment = new ccai__AI_Prompt__c(
    Name = 'Risk Assessment Pattern',
    RecordTypeId = builderRtId,
    Category__c = 'Pattern',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = 'a01gD000003okzEQAQ',
    ccai__AI_Data_Extraction_Mapping__c = 'a05QH000008Olh8YAC',
    ccai__Prompt_Command__c = riskAssessmentContent
);

try {
    insert riskAssessment;
    System.debug('✅ Created Risk Assessment Pattern: ' + riskAssessment.Id);
} catch (Exception e) {
    System.debug('❌ ERROR creating Risk Assessment: ' + e.getMessage());
    return;
}

// Step 5: Create topic assignments (if topics exist)
if (!topicMap.isEmpty()) {
    List<TopicAssignment> assignments = new List<TopicAssignment>();
    
    // Evidence Binding topics
    if (topicMap.containsKey('Evidence Binding')) {
        assignments.add(new TopicAssignment(EntityId = evidenceBinding.Id, TopicId = topicMap.get('Evidence Binding')));
    }
    if (topicMap.containsKey('Insight-Led Design')) {
        assignments.add(new TopicAssignment(EntityId = evidenceBinding.Id, TopicId = topicMap.get('Insight-Led Design')));
    }
    if (topicMap.containsKey('P0')) {
        assignments.add(new TopicAssignment(EntityId = evidenceBinding.Id, TopicId = topicMap.get('P0')));
    }
    
    // Risk Assessment topics
    if (topicMap.containsKey('Risk Assessment')) {
        assignments.add(new TopicAssignment(EntityId = riskAssessment.Id, TopicId = topicMap.get('Risk Assessment')));
    }
    if (topicMap.containsKey('Opportunity')) {
        assignments.add(new TopicAssignment(EntityId = riskAssessment.Id, TopicId = topicMap.get('Opportunity')));
    }
    if (topicMap.containsKey('P0')) {
        assignments.add(new TopicAssignment(EntityId = riskAssessment.Id, TopicId = topicMap.get('P0')));
    }
    
    if (!assignments.isEmpty()) {
        try {
            insert assignments;
            System.debug('✅ Created ' + assignments.size() + ' topic assignments');
        } catch (Exception e) {
            System.debug('⚠️  WARNING: Topic assignments failed - ' + e.getMessage());
        }
    }
}

// Step 6: Verification query
System.debug('\n=== VERIFICATION ===');
List<ccai__AI_Prompt__c> builders = [
    SELECT Id, Name, RecordType.Name, Category__c, ccai__Status__c,
           (SELECT Id, Topic.Name FROM TopicAssignments)
    FROM ccai__AI_Prompt__c
    WHERE Id IN (:evidenceBinding.Id, :riskAssessment.Id)
];

for (ccai__AI_Prompt__c b : builders) {
    System.debug('\n📦 Builder: ' + b.Name);
    System.debug('   ID: ' + b.Id);
    System.debug('   RecordType: ' + b.RecordType.Name);
    System.debug('   Category: ' + b.Category__c);
    System.debug('   Status: ' + b.ccai__Status__c);
    System.debug('   Topics: ' + b.TopicAssignments.size());
    for (TopicAssignment ta : b.TopicAssignments) {
        System.debug('      - ' + ta.Topic.Name);
    }
}

System.debug('\n✅ MVP BUILDER CREATION COMPLETE');
System.debug('Evidence Binding ID: ' + evidenceBinding.Id);
System.debug('Risk Assessment ID: ' + riskAssessment.Id);
