// Full End-to-End Test: V2.5 Through Complete Pipeline
// Directly creates PF_Run__c and starts pipeline (bypasses controller)

// Test account: Pinnacle Wealth Partners
String accountId = '001QH000024mdDnYAI';

System.debug('========================================');
System.debug('V2.5 FULL PIPELINE E2E TEST');
System.debug('========================================');
System.debug('Account: Pinnacle Wealth Partners (' + accountId + ')');
System.debug('V2.5 Enabled: true');
System.debug('========================================');

try {
    // Create PF_Run__c record
    PF_Run__c run = new PF_Run__c(
        Root_Object__c = 'Account',
        Sample_Record_Id__c = accountId,
        Business_Context__c = 'Generate comprehensive account dashboard with financial metrics, opportunities, contacts, and cases',
        Output_Format__c = 'HTML',
        Prompt_Name__c = 'V2.5 Test - Account Dashboard',
        AI_Model__c = 'a01gD000003okzEQAQ', // GPTfy (OpenAI)
        Status__c = 'Queued',
        Current_Stage__c = 1
    );

    insert run;

    System.debug('✓ Created PF_Run__c record: ' + run.Id);
    System.debug('Run URL: /' + run.Id);

    // Start pipeline by enqueuing Stage 1
    System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));

    System.debug('✓ Pipeline started (Stage 1 enqueued)');
    System.debug('========================================');
    System.debug('Monitor progress:');
    System.debug('1. Query: SELECT Id, Name, Status__c, Current_Stage__c, Error_Message__c FROM PF_Run__c WHERE Id = \'' + run.Id + '\'');
    System.debug('2. Expected stages: 1 (Init) → 2-7 → 8 (Prompt Assembly - V2.5) → 9-12');
    System.debug('========================================');
    System.debug('Key validation points:');
    System.debug('Stage 8: Should generate template with merge fields like {{{Name}}}, {{{AnnualRevenue}}}');
    System.debug('Stage 8: Should NOT generate invented fields like {{{HealthScore}}}, {{{CriticalAlert}}}');
    System.debug('Stage 8: Should include visual components (stat cards, tables)');
    System.debug('Stage 9: Should fill template with actual Account data');
    System.debug('Stage 10+: Should complete without merge field errors');
    System.debug('========================================');

} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('Stack: ' + e.getStackTraceString());
}
