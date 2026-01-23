/**
 * Trigger the V2.0 pipeline for the test PF_Run
 */

// The PF_Run ID from test_v2_simple.apex
String runId = 'a0gQH000005GJGjYAO';

System.debug('===== TRIGGERING V2.0 PIPELINE =====');
System.debug('PF_Run ID: ' + runId);

try {
    // Update Status to "In Progress" and set Current_Stage__c to 1
    PF_Run__c run = [
        SELECT Id, Status__c, Current_Stage__c
        FROM PF_Run__c
        WHERE Id = :runId
    ];

    System.debug('Current Status: ' + run.Status__c);
    System.debug('Current Stage: ' + run.Current_Stage__c);
    System.debug('');

    run.Status__c = 'In Progress';
    run.Current_Stage__c = 1;

    update run;

    System.debug('✅ Pipeline triggered!');
    System.debug('Updated Status to: In Progress');
    System.debug('Updated Current_Stage__c to: 1');
    System.debug('');

    System.debug('===== MONITORING INSTRUCTIONS =====');
    System.debug('The pipeline will execute stages 1-9 asynchronously.');
    System.debug('To monitor progress, run:');
    System.debug('');
    System.debug('sf data query -o agentictso -q "SELECT Status__c, Current_Stage__c, Stage04_Output__c, Stage07_Output__c FROM PF_Run__c WHERE Id = \'' + runId + '\'"');
    System.debug('');
    System.debug('Expected flow:');
    System.debug('  Stage 1: Parse sample IDs');
    System.debug('  Stage 2: Query metadata');
    System.debug('  Stage 3: Build SOQL queries');
    System.debug('  Stage 4: Profile 3 Opportunities (multi-sample)');
    System.debug('  Stage 5: Select fields');
    System.debug('  Stage 6: Extract patterns');
    System.debug('  Stage 7: Design template (useMetaPrompt = true)');
    System.debug('  Stage 8: Assemble AI Prompt (6-section meta-prompt)');
    System.debug('  Stage 9: Deploy prompt');

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}
