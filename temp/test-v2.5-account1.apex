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
    'https://agentictso.my.salesforce.com' // Fixed instance URL
);

System.debug('========================================');
System.debug('V2.5 TEST - Account 1: Pinnacle Wealth Partners');
System.debug('========================================');
System.debug('Run ID: ' + runId);
System.debug('Expected: V2.5 two-layer architecture');
System.debug('Stage 8: Generate template with merge fields');
System.debug('Stage 9: Substitute real data (Merge Gate)');
System.debug('Stage 10: Execute via GPTfy API');
System.debug('========================================');
