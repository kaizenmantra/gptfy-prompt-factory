// Create Next Best Action Pattern (Compressed) builder for V2.0 testing
// This creates a compressed version alongside the original for comparison

// First check if it already exists
List<ccai__AI_Prompt__c> existing = [
    SELECT Id, Name
    FROM ccai__AI_Prompt__c
    WHERE Name = 'Next Best Action Pattern (Compressed)'
      AND RecordType.DeveloperName = 'Builder'
];

if (!existing.isEmpty()) {
    System.debug('❌ Compressed Next Best Action builder already exists: ' + existing[0].Id);
    System.debug('Delete it first if you want to recreate');
} else {
    // Get Record Type
    Id builderRTId = Schema.SObjectType.ccai__AI_Prompt__c
        .getRecordTypeInfosByDeveloperName()
        .get('Builder')
        .getRecordTypeId();

    // Compressed content from docs/quality-rules/next_best_action_pattern_compressed.md
    String compressedContent =
        'Every action: WHO does WHAT by WHEN and WHY?\n\n' +
        '**Requirements:**\n' +
        '- Specific: Use names, dates (not "stakeholder", "soon")\n' +
        '- Actionable: Clear verbs (Schedule, Send, Validate)\n' +
        '- Deadline: by Friday, within 48h, before [event]\n' +
        '- Evidence: Cite data (Task X overdue 7d)\n' +
        '- Priority: CRITICAL > HIGH > MEDIUM\n\n' +
        '**Triggers:** Overdue tasks, MEDDIC gaps, stakeholder gaps >14d\n\n' +
        '**Output:** Action | Why | Impact | Priority | Owner | Deadline | Success';

    // Create the compressed builder
    ccai__AI_Prompt__c builder = new ccai__AI_Prompt__c(
        Name = 'Next Best Action Pattern (Compressed)',
        RecordTypeId = builderRTId,
        Category__c = 'Pattern',
        ccai__Object__c = 'Opportunity',
        ccai__Status__c = 'Active',
        ccai__Prompt_Command__c = compressedContent,
        ccai__How_it_Works__c = 'Compressed version (444 chars) of Next Best Action Pattern for V2.0 Builder. ' +
            '93% reduction from original 6,500 chars while maintaining core principles.'
    );

    insert builder;

    System.debug('✅ Created Compressed Next Best Action builder: ' + builder.Id);
    System.debug('📊 Content length: ' + compressedContent.length() + ' chars');
    System.debug('📖 View: https://agentictso.lightning.force.com/lightning/r/ccai__AI_Prompt__c/' + builder.Id + '/view');

    // Assign topics
    List<Topic> topics = [SELECT Id, Name FROM Topic WHERE Name IN ('Next Best Action', 'Opportunity', 'P0', 'V2')];
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

    System.debug('\n📋 NEXT STEPS:');
    System.debug('1. Run a pipeline test with this compressed builder');
    System.debug('2. Compare output quality with original builder');
    System.debug('3. Document findings in BUILDER_IMPROVEMENTS.md');
}
