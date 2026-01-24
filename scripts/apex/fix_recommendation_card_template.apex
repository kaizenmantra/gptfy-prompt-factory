/**
 * Fix Recommendation Card Template - Remove Hardcoded Label
 *
 * ISSUE: The builder record has "Recommended Action" hardcoded in the template,
 * causing redundant labels in LLM output.
 *
 * BEFORE:
 * <div style="font-weight:600;color:#181818;">Recommended Action</div>
 *
 * AFTER:
 * <div style="font-weight:600;color:#181818;">Schedule call with CFO by Friday</div>
 *
 * The "When to use" text will guide the LLM to put the actual action as the title.
 */

Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c
    .getRecordTypeInfosByDeveloperName()
    .get('Builder')
    .getRecordTypeId();

List<ccai__AI_Prompt__c> builders = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND ccai__Type__c = 'UI Component'
      AND Name LIKE '%Recommendation Card%'
    LIMIT 1
];

if (builders.isEmpty()) {
    System.debug('ERROR: Recommendation Card Component builder not found');
} else {
    ccai__AI_Prompt__c builder = builders[0];

    System.debug('BEFORE UPDATE:');
    System.debug(builder.ccai__Prompt_Command__c);

    // NEW TEMPLATE: Remove hardcoded "Recommended Action" label
    // The title div should be filled with the actual action by the LLM
    String newContent = '--- Recommendation Card ---\n';
    newContent += 'When to use: Use for action items with urgency badges and rationale. Put the specific action as the title (e.g., "Schedule call with Sarah Johnson by Friday").\n';
    newContent += 'HTML Pattern:\n';
    newContent += '<div style="background:#FFFFFF;border-left:4px solid #2E844A;border-radius:6px;padding:16px;margin-bottom:12px;box-shadow:0 1px 3px rgba(0,0,0,0.1);">';
    newContent += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">';
    newContent += '<div style="font-weight:600;color:#181818;">[Specific action: who does what by when]</div>';
    newContent += '<div style="background:#DD7A01;color:white;padding:4px 12px;border-radius:12px;font-size:11px;font-weight:600;">URGENT</div>';
    newContent += '</div>';
    newContent += '<div style="color:#706E6B;margin-bottom:12px;line-height:1.5;">Detailed description of action and context</div>';
    newContent += '<div style="font-size:12px;color:#706E6B;"><strong>Why:</strong> Rationale for action with evidence</div>';
    newContent += '</div>';

    builder.ccai__Prompt_Command__c = newContent;

    update builder;

    System.debug('\n✅ UPDATED: ' + builder.Name + ' (ID: ' + builder.Id + ')');
    System.debug('\nAFTER UPDATE:');
    System.debug(builder.ccai__Prompt_Command__c);
}
