/**
 * Task 1.11: Test multi-sample flow with 3 records
 * V2.1 validation of:
 * - Multi-sample profiling
 * - Pattern detection
 * - Traversal suggestions (new in V2.1)
 */

// First, get 3 Opportunity IDs from the org
List<Opportunity> opps = [
    SELECT Id, Name, Amount, StageName, AccountId
    FROM Opportunity
    WHERE Amount != null AND AccountId != null
    ORDER BY CreatedDate DESC
    LIMIT 3
];

if (opps.size() < 3) {
    System.debug('ERROR: Need at least 3 Opportunities with Amount and AccountId. Found: ' + opps.size());
} else {
    List<String> oppIds = new List<String>();
    System.debug('===== TEST OPPORTUNITIES =====');
    for (Opportunity opp : opps) {
        System.debug(opp.Name + ' - ' + opp.StageName + ' - $' + opp.Amount);
        oppIds.add(opp.Id);
    }

    String sampleRecordIds = String.join(oppIds, ',');
    System.debug('');
    System.debug('Sample Record IDs: ' + sampleRecordIds);

    // Create PF_Run record
    PF_Run__c run = new PF_Run__c();
    run.Name = 'V2.1 Multi-Sample Test - ' + DateTime.now().format('yyyy-MM-dd HH:mm');
    run.Status__c = 'Not Started';
    run.Root_Object__c = 'Opportunity';
    run.Sample_Record_Id__c = oppIds[0]; // Primary sample ID
    run.Sample_Record_Ids__c = sampleRecordIds; // All sample IDs
    run.Target_Persona__c = 'Sales Manager';
    run.Business_Context__c = 'Generate a sales manager dashboard for pipeline review. Focus on deal health, stakeholder engagement, and next steps.';
    run.Prompt_Name__c = 'V2.1 Test - Sales Pipeline Dashboard';

    insert run;
    System.debug('');
    System.debug('===== PF_RUN CREATED =====');
    System.debug('Run ID: ' + run.Id);
    System.debug('Name: ' + run.Name);

    // Enqueue the pipeline
    System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));

    System.debug('');
    System.debug('===== PIPELINE STARTED =====');
    System.debug('Monitor progress:');
    System.debug('sf data query -o agentictso -q "SELECT Status__c, Current_Stage__c, Error_Message__c FROM PF_Run__c WHERE Id = \'' + run.Id + '\'"');
    System.debug('');
    System.debug('Check Stage 5 output for traversal suggestions:');
    System.debug('sf data query -o agentictso -q "SELECT Stage05_Output__c FROM PF_Run__c WHERE Id = \'' + run.Id + '\'"');
    System.debug('');
    System.debug('===== EXPECTED V2.1 BEHAVIOR =====');
    System.debug('1. Stage 4: Multi-sample profiling with 3 Opportunities');
    System.debug('2. Stage 5: Traversal builders loaded, parent field suggestions in prompt');
    System.debug('3. Stage 5 output: selectedParentFields should contain Owner.Name, Account.Name, etc.');
    System.debug('4. Stage 8: Parent fields should appear in final prompt');
    System.debug('');
    System.debug('Run ID: ' + run.Id);
}
