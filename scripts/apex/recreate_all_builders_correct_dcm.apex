// Delete and recreate ALL builders with CORRECT Opportunity DCM
// Correct DCM: a05QH000008PLavYAG (from Deal Coach 05-05PM prompt)

System.debug('=== RECREATING ALL BUILDERS WITH CORRECT DCM ===');

String correctDCM = 'a05QH000008PLavYAG';
String correctAIConnection = 'a01gD000003okzEQAQ';

// Step 1: Delete existing builders (wrong DCM)
List<ccai__AI_Prompt__c> oldBuilders = [
    SELECT Id, Name
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND Name IN ('Evidence Binding Rules v2', 'Risk Assessment Pattern', 
                   'Stat Card Component', 'Alert Box Component', 
                   'Healthcare Payer Context')
];

System.debug('Found ' + oldBuilders.size() + ' builders to delete');
for (ccai__AI_Prompt__c b : oldBuilders) {
    System.debug('  - Deleting: ' + b.Name + ' (' + b.Id + ')');
}

delete oldBuilders;
System.debug('✅ Deleted ' + oldBuilders.size() + ' old builders');

// Step 2: Get Builder record type and topics
Id builderRtId = [SELECT Id FROM RecordType 
                   WHERE SobjectType = 'ccai__AI_Prompt__c' 
                   AND DeveloperName = 'Builder' 
                   LIMIT 1].Id;

Map<String, Id> topicMap = new Map<String, Id>();
for (Topic t : [SELECT Id, Name FROM Topic 
                WHERE Name IN ('Evidence Binding', 'Insight-Led Design', 'P0', 
                              'Risk Assessment', 'Opportunity', 'Stat Card', 
                              'Alert Box', 'Above-the-Fold', 'Healthcare', 
                              'Context Template', 'P1')]) {
    topicMap.put(t.Name, t.Id);
}

System.debug('\n=== RECREATING BUILDERS WITH CORRECT DCM ===');

// Recreate all 5 builders with correct DCM
List<ccai__AI_Prompt__c> newBuilders = new List<ccai__AI_Prompt__c>();

// 1. Evidence Binding
String evidenceBindingContent = 
'=== EVIDENCE BINDING RULES (v2) ===\n\n' +
'CORE PRINCIPLE: Every claim must be traceable. No claim should lead with its source.\n\n' +
'FORMAT HIERARCHY:\n\n' +
'Level 1 - EMBEDDED DATA (Use 80% of the time):\n' +
'Weave data naturally into insights. No explicit citation.\n' +
'✅ GOOD: "This $1.5M deal needs executive sponsor engagement before close."\n' +
'❌ BAD: "Evidence: Amount = $1,500,000. This is a large deal."\n\n' +
'Level 2 - PARENTHETICAL SOURCE (Use 15% of the time):\n' +
'✅ GOOD: "No executive sponsor identified. (Source: Contact Roles)"\n\n' +
'Level 3 - INLINE CITATION (Use 5% - detailed sections only):\n' +
'✅ GOOD: "Deal timeline at risk." → Based on: Stage Age = 45 days\n\n' +
'Level 4 - COLLAPSIBLE DATA SOURCES (Always at end):\n' +
'<details><summary>Data Sources</summary>...</details>\n\n' +
'CRITICAL RULES:\n' +
'❌ NEVER start with "Evidence:"\n' +
'✅ ALWAYS lead with insight\n' +
'✅ ALWAYS include collapsible data sources';

newBuilders.add(new ccai__AI_Prompt__c(
    Name = 'Evidence Binding Rules v2',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = correctAIConnection,
    ccai__AI_Data_Extraction_Mapping__c = correctDCM,
    ccai__Prompt_Command__c = evidenceBindingContent
));

// 2. Risk Assessment
String riskContent = 
'=== ANALYTICAL PATTERN: RISK ASSESSMENT ===\n\n' +
'PURPOSE: Identify risks that could impact deal closure.\n\n' +
'For each risk:\n' +
'1. SEVERITY: CRITICAL/WARNING/OPPORTUNITY\n' +
'2. RISK: Clear description\n' +
'3. EVIDENCE: Specific field values\n' +
'4. IMPACT: Business consequence\n' +
'5. MITIGATION: Specific action\n\n' +
'CRITICAL RISKS: Missing champion, No decision maker, Overdue deliverables\n' +
'WARNING RISKS: Low velocity, Single-threaded, No exec sponsor\n' +
'OPPORTUNITIES: Multiple stakeholders, Recent activities, Strong champion';

newBuilders.add(new ccai__AI_Prompt__c(
    Name = 'Risk Assessment Pattern',
    RecordTypeId = builderRtId,
    Category__c = 'Pattern',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = correctAIConnection,
    ccai__AI_Data_Extraction_Mapping__c = correctDCM,
    ccai__Prompt_Command__c = riskContent
));

// 3. Stat Card
String statCardContent = 
'=== UI COMPONENT: STAT CARD ===\n\n' +
'Display key metrics in scannable card format.\n' +
'Use 4-6 cards above-the-fold.\n' +
'Large value (28-32px), small label, color-coded by sentiment.';

newBuilders.add(new ccai__AI_Prompt__c(
    Name = 'Stat Card Component',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = correctAIConnection,
    ccai__AI_Data_Extraction_Mapping__c = correctDCM,
    ccai__Prompt_Command__c = statCardContent
));

// 4. Alert Box
String alertContent = 
'=== UI COMPONENT: ALERT BOX ===\n\n' +
'Color-coded alerts for risks/warnings/success.\n' +
'CRITICAL (red), WARNING (orange), SUCCESS (green), INFO (blue).\n' +
'Limit 2-3 above-the-fold.';

newBuilders.add(new ccai__AI_Prompt__c(
    Name = 'Alert Box Component',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = correctAIConnection,
    ccai__AI_Data_Extraction_Mapping__c = correctDCM,
    ccai__Prompt_Command__c = alertContent
));

// 5. Healthcare Context
String healthcareContent = 
'=== CONTEXT TEMPLATE: HEALTHCARE PAYER ===\n\n' +
'Healthcare industry context, terminology, buying patterns.\n' +
'Long cycles (9-18 months), compliance focus (HIPAA/BAA), key stakeholders (CMO/CIO/CFO).';

newBuilders.add(new ccai__AI_Prompt__c(
    Name = 'Healthcare Payer Context',
    RecordTypeId = builderRtId,
    Category__c = 'Context Template',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = correctAIConnection,
    ccai__AI_Data_Extraction_Mapping__c = correctDCM,
    ccai__Prompt_Command__c = healthcareContent
));

insert newBuilders;
System.debug('✅ Created ' + newBuilders.size() + ' builders with CORRECT DCM');

// Create topic assignments
List<TopicAssignment> assignments = new List<TopicAssignment>();

// Evidence Binding topics
if (topicMap.containsKey('Evidence Binding')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[0].Id, TopicId = topicMap.get('Evidence Binding')));
}
if (topicMap.containsKey('Insight-Led Design')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[0].Id, TopicId = topicMap.get('Insight-Led Design')));
}
if (topicMap.containsKey('P0')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[0].Id, TopicId = topicMap.get('P0')));
}

// Risk Assessment topics
if (topicMap.containsKey('Risk Assessment')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[1].Id, TopicId = topicMap.get('Risk Assessment')));
}
if (topicMap.containsKey('Opportunity')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[1].Id, TopicId = topicMap.get('Opportunity')));
}
if (topicMap.containsKey('P0')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[1].Id, TopicId = topicMap.get('P0')));
}

// Stat Card topics
if (topicMap.containsKey('Stat Card')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[2].Id, TopicId = topicMap.get('Stat Card')));
}
if (topicMap.containsKey('Above-the-Fold')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[2].Id, TopicId = topicMap.get('Above-the-Fold')));
}
if (topicMap.containsKey('P0')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[2].Id, TopicId = topicMap.get('P0')));
}

// Alert Box topics
if (topicMap.containsKey('Alert Box')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[3].Id, TopicId = topicMap.get('Alert Box')));
}
if (topicMap.containsKey('Above-the-Fold')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[3].Id, TopicId = topicMap.get('Above-the-Fold')));
}
if (topicMap.containsKey('P0')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[3].Id, TopicId = topicMap.get('P0')));
}

// Healthcare topics
if (topicMap.containsKey('Healthcare')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[4].Id, TopicId = topicMap.get('Healthcare')));
}
if (topicMap.containsKey('Context Template')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[4].Id, TopicId = topicMap.get('Context Template')));
}
if (topicMap.containsKey('P1')) {
    assignments.add(new TopicAssignment(EntityId = newBuilders[4].Id, TopicId = topicMap.get('P1')));
}

insert assignments;
System.debug('✅ Created ' + assignments.size() + ' topic assignments');

System.debug('\n✅ ALL BUILDERS RECREATED AND TESTABLE');
System.debug('Evidence Binding: ' + newBuilders[0].Id);
System.debug('Risk Assessment: ' + newBuilders[1].Id);
System.debug('Stat Card: ' + newBuilders[2].Id);
System.debug('Alert Box: ' + newBuilders[3].Id);
System.debug('Healthcare Context: ' + newBuilders[4].Id);
