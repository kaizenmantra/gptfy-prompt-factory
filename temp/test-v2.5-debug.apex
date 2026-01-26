// Quick debug test for V2.5 template generation
String accountId = '001QH000024mdDnYAI';

try {
    PF_Run__c run = new PF_Run__c(
        Root_Object__c = 'Account',
        Sample_Record_Id__c = accountId,
        Business_Context__c = 'Simple account summary with opportunities',
        Output_Format__c = 'HTML',
        Prompt_Name__c = 'V2.5 Debug Test',
        AI_Model__c = 'a01gD000003okzEQAQ',
        Status__c = 'Queued',
        Current_Stage__c = 1
    );

    insert run;
    System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));

    System.debug('✓ Debug test started');
    System.debug('Run ID: ' + run.Id);
    System.debug('Check logs for DEBUG output');

} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
