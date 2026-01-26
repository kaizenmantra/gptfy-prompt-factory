// Test V2.5 with Account 1: Pinnacle Wealth Partners
String accountId = '001QH000024mdDnYAI';
String objectName = 'Account';
String businessContext = 'Analyze this financial services account and provide executive insights for the Relationship Manager';
String targetPersona = 'Relationship Manager';
String outputFormat = 'Narrative';

// Start pipeline run
Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-Test-Account1-' + DateTime.now().getTime(),
    objectName,
    accountId,
    businessContext,
    outputFormat,
    null, // businessObjectives
    'https://gptfy--agentictso.sandbox.my.salesforce.com'
);

System.debug('========================================');
System.debug('V2.5 TEST - Account 1');
System.debug('========================================');
System.debug('Run ID: ' + runId);
System.debug('Account: TESTDATA_Pinnacle Wealth Partners ($15M)');
System.debug('Expected: Stage 8 should show "V2.5: Using two-layer meta-prompt architecture"');
System.debug('Check logs after pipeline completes');
System.debug('========================================');
