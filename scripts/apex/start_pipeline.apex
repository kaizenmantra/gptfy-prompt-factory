/**
 * Start the V2.0 pipeline by enqueuing the PromptFactoryPipeline Queueable
 */

// The PF_Run ID from test_v2_simple.apex
String runId = 'a0gQH000005GJGjYAO';

System.debug('===== STARTING V2.0 PIPELINE =====');
System.debug('PF_Run ID: ' + runId);

try {
    // Query current state
    PF_Run__c run = [
        SELECT Id, Name, Status__c, Current_Stage__c, Root_Object__c, Sample_Record_Id__c
        FROM PF_Run__c
        WHERE Id = :runId
    ];

    System.debug('Current Status: ' + run.Status__c);
    System.debug('Current Stage: ' + run.Current_Stage__c);
    System.debug('Root Object: ' + run.Root_Object__c);
    System.debug('Sample Record ID: ' + run.Sample_Record_Id__c);
    System.debug('');

    // Enqueue pipeline starting from Stage 1
    System.enqueueJob(new PromptFactoryPipeline(runId, 1));

    System.debug('✅ Pipeline enqueued successfully!');
    System.debug('');
    System.debug('===== PIPELINE WILL EXECUTE =====');
    System.debug('The Queueable job will:');
    System.debug('  1. Execute Stage 1 (Parse sample IDs)');
    System.debug('  2. Auto-chain to Stage 2 (Query metadata)');
    System.debug('  3. Auto-chain to Stage 3 (Build SOQL)');
    System.debug('  4. Auto-chain to Stage 4 (Profile records)');
    System.debug('  5. Chain breaker before Stage 5');
    System.debug('  6-9. Execute remaining stages with dedicated Queueable jobs');
    System.debug('');
    System.debug('Monitor with:');
    System.debug('sf data query -o agentictso -q "SELECT Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = \'' + runId + '\'"');
    System.debug('');
    System.debug('Check stage results:');
    System.debug('sf data query -o agentictso -q "SELECT Stage_Number__c, Stage_Name__c, Status__c, CreatedDate FROM PF_Run_Stage__c WHERE Run__c = \'' + runId + '\' ORDER BY Stage_Number__c"');

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}
