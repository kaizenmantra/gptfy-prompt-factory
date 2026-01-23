/**
 * Task 1.10: Remove emojis from Evidence Binding Rules v2
 * Replaces ✅ with "GOOD:" and ❌ with "BAD:"
 */

String builderId = 'a0DQH00000KYtZe2AL'; // Evidence Binding Rules v2

ccai__AI_Prompt__c builder = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Id = :builderId
];

System.debug('Original content has emojis: ' + builder.ccai__Prompt_Command__c.contains('✅'));

// Remove emojis and replace with text
String cleaned = builder.ccai__Prompt_Command__c
    .replace('✅ GOOD:', 'GOOD:')
    .replace('❌ BAD:', 'BAD:')
    .replace('✅ ALWAYS', 'ALWAYS')
    .replace('❌ NEVER', 'NEVER');

builder.ccai__Prompt_Command__c = cleaned;

update builder;

System.debug('✅ Updated Evidence Binding Rules v2 - removed emojis');
System.debug('Cleaned content preview: ' + cleaned.substring(0, 200));
