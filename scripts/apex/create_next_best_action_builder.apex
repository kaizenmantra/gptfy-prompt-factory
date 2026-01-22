// Create Next Best Action Pattern builder

// First check if it already exists
List<ccai__AI_Prompt__c> existing = [
    SELECT Id, Name
    FROM ccai__AI_Prompt__c
    WHERE Name = 'Next Best Action Pattern'
      AND RecordType.DeveloperName = 'Builder'
];

if (!existing.isEmpty()) {
    System.debug('❌ Next Best Action builder already exists: ' + existing[0].Id);
    System.debug('Delete it first if you want to recreate');
} else {
    // Get Record Type
    Id builderRTId = Schema.SObjectType.ccai__AI_Prompt__c
        .getRecordTypeInfosByDeveloperName()
        .get('Builder')
        .getRecordTypeId();
    
    // Create the builder (content needs to be added manually due to size)
    ccai__AI_Prompt__c builder = new ccai__AI_Prompt__c(
        Name = 'Next Best Action Pattern',
        RecordTypeId = builderRTId,
        Category__c = 'Pattern',
        ccai__Object__c = 'Opportunity',
        ccai__AI_Data_Extraction_Mapping__c = 'a05QH000008PLavYAG', // Opportunity DCM
        ccai__Status__c = 'Active',
        ccai__Prompt_Command__c = '# Next Best Action Pattern\n\n' +
            'Provides specific, actionable recommendations with clear owners, deadlines, and evidence.\n\n' +
            'CRITICAL: Use actual names, specific dates, bounded actions.\n\n' +
            '** FULL CONTENT NEEDS TO BE ADDED MANUALLY ** \n\n' +
            'See: docs/quality-rules/next_best_action_pattern.md',
        ccai__How_it_Works__c = 'Provides specific, actionable recommendations with clear owners, deadlines, and evidence. ' +
            'Enforces use of actual names, specific dates, and bounded actions. Extracted from Phase 0B Variant 16.'
    );
    
    insert builder;
    
    System.debug('✅ Created Next Best Action builder: ' + builder.Id);
    System.debug('\n⚠️ IMPORTANT: Update content manually:');
    System.debug('1. Open: https://agentictso.lightning.force.com/lightning/r/ccai__AI_Prompt__c/' + builder.Id + '/view');
    System.debug('2. Click Edit');
    System.debug('3. Paste full content from: docs/quality-rules/next_best_action_pattern.md');
    System.debug('4. Save');
    
    // Assign topics
    List<Topic> topics = [SELECT Id, Name FROM Topic WHERE Name IN ('Next Best Action', 'Opportunity', 'P0')];
    List<TopicAssignment> assignments = new List<TopicAssignment>();
    
    for (Topic t : topics) {
        assignments.add(new TopicAssignment(
            TopicId = t.Id,
            EntityId = builder.Id
        ));
    }
    
    if (!assignments.isEmpty()) {
        insert assignments;
        System.debug('✅ Assigned ' + assignments.size() + ' topics');
    }
}
