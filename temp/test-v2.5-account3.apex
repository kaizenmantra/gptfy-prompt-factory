// Test V2.5 with Account 3: MediCare Solutions Inc.
String accountId = '001QH000024mdDpYAI';
String objectName = 'Account';
String businessContext = 'Analyze this healthcare account and assess renewal risk for the Customer Success Manager';
String targetPersona = 'Customer Success Manager';
String outputFormat = 'Narrative';

Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-Test-Account3-' + DateTime.now().getTime(),
    objectName,
    accountId,
    businessContext,
    outputFormat,
    null,
    'https://agentictso.my.salesforce.com'
);

System.debug('========================================');
System.debug('V2.5 TEST - Account 3: MediCare Solutions Inc.');
System.debug('========================================');
System.debug('Run ID: ' + runId);
System.debug('========================================');
