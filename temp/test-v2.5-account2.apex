// Test V2.5 with Account 2: Vanguard Insurance Group
String accountId = '001QH000024mdDoYAI';
String objectName = 'Account';
String businessContext = 'Analyze this insurance account and identify cross-sell opportunities for the Account Executive';
String targetPersona = 'Account Executive';
String outputFormat = 'Narrative';

Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-Test-Account2-' + DateTime.now().getTime(),
    objectName,
    accountId,
    businessContext,
    outputFormat,
    null,
    'https://agentictso.my.salesforce.com'
);

System.debug('========================================');
System.debug('V2.5 TEST - Account 2: Vanguard Insurance Group');
System.debug('========================================');
System.debug('Run ID: ' + runId);
System.debug('========================================');
