/**
 * Simplified V2.0 End-to-End Test
 * Tests the pipeline by creating a PF_Run record directly
 */

String sampleRecordIds = '006QH00000Hjl5qYAB,006QH00000HjgvlYAB,006gD000001lqquQAA';

System.debug('===== V2.0 SIMPLIFIED END-TO-END TEST =====');
System.debug('Sample IDs (comma-separated): ' + sampleRecordIds);
System.debug('Expected behavior: PromptFactoryController will parse these IDs');
System.debug('');

// Parse the IDs like the controller does
List<String> sampleIds = new List<String>();
for (String id : sampleRecordIds.split(',')) {
    String trimmedId = id.trim();
    if (trimmedId.length() >= 15) {
        sampleIds.add(trimmedId);
    }
}

System.debug('Parsed ' + sampleIds.size() + ' sample IDs:');
for (String id : sampleIds) {
    System.debug('  - ' + id);
}
System.debug('');

// Create PF_Run directly (bypassing @AuraEnabled controller)
PF_Run__c run = new PF_Run__c(
    Sample_Record_Id__c = sampleIds[0],  // Primary sample (backward compat)
    Root_Object__c = 'Opportunity',
    Prompt_Name__c = 'Sales Manager Dashboard - V2.0 Test',
    Status__c = 'Queued',
    Business_Context__c = 'V2.0 multi-sample test with 3 Opportunities'
);

try {
    insert run;
    System.debug('✅ Created PF_Run: ' + run.Id);
    System.debug('');

    // Query back to confirm
    PF_Run__c createdRun = [
        SELECT Id, Name, Status__c, Current_Stage__c,
               Sample_Record_Id__c, Root_Object__c, Prompt_Name__c
        FROM PF_Run__c
        WHERE Id = :run.Id
    ];

    System.debug('===== PF_RUN CREATED =====');
    System.debug('ID: ' + createdRun.Id);
    System.debug('Name: ' + createdRun.Name);
    System.debug('Status: ' + createdRun.Status__c);
    System.debug('Sample Record ID: ' + createdRun.Sample_Record_Id__c);
    System.debug('Root Object: ' + createdRun.Root_Object__c);
    System.debug('');

    System.debug('===== NEXT STEPS =====');
    System.debug('1. Manually trigger the pipeline for this run');
    System.debug('2. OR update Status to "Running" and Current_Stage__c to 1');
    System.debug('3. Monitor progress by querying: SELECT Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = \'' + run.Id + '\'');
    System.debug('');
    System.debug('NOTE: Multi-sample support requires:');
    System.debug('  - Sample_Record_Ids__c field deployed to PF_Run__c');
    System.debug('  - PromptFactoryController.parseSampleIds() to populate it');
    System.debug('  - Stage 4 to call profileMultipleSamples()');

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}
