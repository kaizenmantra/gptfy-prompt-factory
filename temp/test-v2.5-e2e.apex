// End-to-End Test: V2.5 with Actual Data in Meta-Prompt
// Tests that the thinking model receives real data values (not just schema)

// Test account: Pinnacle Wealth Partners
Id accountId = '001QH000024mdDnYAI';

System.debug('========================================');
System.debug('V2.5 END-TO-END TEST');
System.debug('========================================');
System.debug('Account ID: ' + accountId);
System.debug('Testing: Actual data values in meta-prompt');
System.debug('========================================');

// Create PF_Run (meta-prompt is enabled automatically in Stage 7)
// AI Model: GPTfy (OpenAI) = a01gD000003okzEQAQ
PF_Run__c run = new PF_Run__c(
    Sample_Record_Id__c = accountId,
    Root_Object__c = 'Account',
    Prompt_Name__c = 'V2.5 Test - ' + System.now().format('yyyy-MM-dd HH:mm'),
    Status__c = 'Queued',
    Business_Context__c = 'Executive dashboard for account management with financial insights',
    AI_Model__c = 'a01gD000003okzEQAQ'  // GPTfy (OpenAI)
);

try {
    insert run;
    System.debug('Created PF_Run: ' + run.Id);

    // Start the pipeline from Stage 1
    System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));

    System.debug('');
    System.debug('========================================');
    System.debug('PIPELINE STARTED');
    System.debug('========================================');
    System.debug('Run ID: ' + run.Id);
    System.debug('');
    System.debug('V2.5 Enhancement: Stage 8 will now include:');
    System.debug('  - ACTUAL DATA VALUES section with real field values');
    System.debug('  - INFORMATION HIERARCHY section (lead with insights)');
    System.debug('  - Parent lookup values (e.g., Owner.Name)');
    System.debug('  - Child records (Opportunities, Contacts, etc.)');
    System.debug('');
    System.debug('========================================');
    System.debug('MONITORING');
    System.debug('========================================');
    System.debug('Check progress:');
    System.debug('sf data query -o agentictso -q "SELECT Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = \'' + run.Id + '\'"');
    System.debug('');
    System.debug('View Stage 8 logs (after Stage 8 completes):');
    System.debug('sf data query -o agentictso -q "SELECT Message__c FROM PF_Run_Log__c WHERE Run__c = \'' + run.Id + '\' AND Stage_Number__c = 8 ORDER BY CreatedDate" --json');
    System.debug('');
    System.debug('View final prompt (after Stage 9):');
    System.debug('sf data query -o agentictso -q "SELECT ccai__Prompt_Command__c FROM ccai__AI_Prompt__c WHERE Id IN (SELECT Deployed_Prompt__c FROM PF_Run__c WHERE Id = \'' + run.Id + '\')" --json');

} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}
