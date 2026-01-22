// Phase 4: Create Apex Service Builder
// Field Metadata Service

System.debug('=== PHASE 4: APEX SERVICE BUILDER ===');

// Get Builder record type
Id builderRtId = [SELECT Id FROM RecordType 
                   WHERE SobjectType = 'ccai__AI_Prompt__c' 
                   AND DeveloperName = 'Builder' 
                   LIMIT 1].Id;

// Get topic IDs
Map<String, Id> topicMap = new Map<String, Id>();
for (Topic t : [SELECT Id, Name FROM Topic 
                WHERE Name IN ('Picklist Metadata', 'Opportunity', 'P0')]) {
    topicMap.put(t.Name, t.Id);
}

System.debug('✅ Builder RecordType: ' + builderRtId);
System.debug('✅ Topics found: ' + topicMap.size());

// Create Field Metadata Service Builder
String fieldServiceDesc = 
'Apex Service: FieldMetadataService\n\n' +
'Extracts picklist field metadata at runtime and provides stage-relative context.\n\n' +
'PURPOSE:\n' +
'- Dynamically extract picklist values from Salesforce metadata\n' +
'- Provide current value position (early/mid/late stage)\n' +
'- Include probability percentages for OpportunityStage\n' +
'- Give AI context to interpret field values appropriately\n\n' +
'INPUT PARAMETERS (passed as Map<String, Object>):\n' +
'- objectName: Salesforce object API name (e.g., "Opportunity")\n' +
'- fieldName: Field API name (e.g., "StageName")\n' +
'- currentValue: Current field value from record\n\n' +
'OUTPUT FORMAT:\n' +
'=== FIELD CONTEXT: Opportunity.StageName ===\n\n' +
'Current Value: "Proposal/Price Quote"\n\n' +
'Available Values (7 total):\n' +
'  1. Prospecting (10% probability)\n' +
'  2. Qualification (20% probability)\n' +
'  3. Needs Analysis (30% probability)\n' +
'  4. Value Proposition (50% probability)\n' +
'  5. Proposal/Price Quote (75% probability) ← CURRENT\n' +
'  6. Negotiation/Review (90% probability)\n' +
'  7. Closed Won (100% probability)\n\n' +
'Stage Analysis:\n' +
'- Position: LATE stage (5 of 7)\n' +
'- Typical behavior: Contract negotiation, high probability, near close\n' +
'- Risk threshold: Probability <60% or missing stakeholders is HIGH RISK\n\n' +
'IMPORTANT: When evaluating this field, consider the expected behavior for this stage position.\n\n' +
'---\n\n' +
'IMPLEMENTATION:\n' +
'- Apex Class: FieldMetadataService.cls\n' +
'- Interface: IFieldService\n' +
'- Runtime Execution: Stage08 invokes via Type.forName() and newInstance()\n' +
'- No callouts required (uses Describe API)\n' +
'- Cache-friendly (Describe results cached by Salesforce)\n\n' +
'USE CASES:\n' +
'- Opportunity.StageName analysis (avoid false positives on low probability in early stages)\n' +
'- Case.Status evaluation (understand status progression)\n' +
'- Lead.Status assessment (conversion pipeline analysis)\n' +
'- Any picklist field requiring stage-relative context\n\n' +
'BENEFITS:\n' +
'- Eliminates false alarms (AI understands 20% prob in early stage is normal)\n' +
'- Provides ordered list of stages (AI can calculate "X stages away from close")\n' +
'- Shows probability expectations (AI can flag misalignment)\n' +
'- No hardcoded values (adapts to org-specific picklist customizations)';

ccai__AI_Prompt__c fieldService = new ccai__AI_Prompt__c(
    Name = 'Field Metadata Service',
    RecordTypeId = builderRtId,
    Category__c = 'Apex Service',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = 'a01gD000003okzEQAQ',
    ccai__AI_Data_Extraction_Mapping__c = 'a05QH000008Olh8YAC',
    ccai__Description__c = 'Extracts picklist field metadata and provides stage-relative context. Invokes FieldMetadataService.cls at runtime.',
    ccai__Prompt_Command__c = fieldServiceDesc,
    ccai__How_it_works__c = 'FieldMetadataService' // Store Apex class name here
);

insert fieldService;
System.debug('✅ Created Field Metadata Service Builder: ' + fieldService.Id);

// Create topic assignments
List<TopicAssignment> assignments = new List<TopicAssignment>();

if (topicMap.containsKey('Picklist Metadata')) {
    assignments.add(new TopicAssignment(EntityId = fieldService.Id, TopicId = topicMap.get('Picklist Metadata')));
}
if (topicMap.containsKey('Opportunity')) {
    assignments.add(new TopicAssignment(EntityId = fieldService.Id, TopicId = topicMap.get('Opportunity')));
}
if (topicMap.containsKey('P0')) {
    assignments.add(new TopicAssignment(EntityId = fieldService.Id, TopicId = topicMap.get('P0')));
}

if (!assignments.isEmpty()) {
    insert assignments;
    System.debug('✅ Created ' + assignments.size() + ' topic assignments');
}

// Verification
ccai__AI_Prompt__c builder = [
    SELECT Id, Name, Category__c, ccai__Status__c, ccai__How_it_works__c
    FROM ccai__AI_Prompt__c
    WHERE Id = :fieldService.Id
];

System.debug('\n=== VERIFICATION ===');
System.debug('📦 ' + builder.Name + ' (' + builder.Category__c + ') - ' + builder.ccai__Status__c);
System.debug('   Apex Class: ' + builder.ccai__How_it_works__c);
System.debug('\n✅ PHASE 4 COMPLETE');
System.debug('Field Service ID: ' + fieldService.Id);
