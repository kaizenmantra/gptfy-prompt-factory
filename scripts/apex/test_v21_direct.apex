/**
 * Task 1.11: Test multi-sample flow with 3 records (Direct - no controller)
 */

// Get 3 Opportunities
List<Opportunity> opps = [
    SELECT Id, Name, Amount, StageName
    FROM Opportunity
    WHERE Amount != null AND AccountId != null
    ORDER BY CreatedDate DESC
    LIMIT 3
];

if (opps.size() < 3) {
    System.debug('ERROR: Need 3 Opportunities with Amount/AccountId. Found: ' + opps.size());
} else {
    List<String> oppIds = new List<String>();
    System.debug('===== TEST OPPORTUNITIES =====');
    for (Opportunity opp : opps) {
        System.debug(opp.Name + ' - $' + opp.Amount);
        oppIds.add(opp.Id);
    }
    String allIds = String.join(oppIds, ',');

    // Create PF_Run directly (store comma-separated IDs in Sample_Record_Id__c)
    PF_Run__c run = new PF_Run__c(
        Root_Object__c = 'Opportunity',
        Sample_Record_Id__c = allIds,  // Comma-separated, Stage01 will parse
        Business_Context__c = 'Generate a sales pipeline dashboard. Focus on deal health and next steps.',
        Output_Format__c = 'Dashboard',
        Prompt_Name__c = 'V2.1 Test - ' + DateTime.now().format('HH:mm:ss'),
        Status__c = 'Queued',
        Current_Stage__c = 1
    );
    insert run;

    System.debug('');
    System.debug('===== PF_RUN CREATED: ' + run.Id + ' =====');

    // Enqueue pipeline
    System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));

    System.debug('Pipeline enqueued!');
    System.debug('');
    System.debug('Monitor: sf data query -o agentictso -q "SELECT Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = \'' + run.Id + '\'"');
    System.debug('');
    System.debug('Run ID: ' + run.Id);
}
