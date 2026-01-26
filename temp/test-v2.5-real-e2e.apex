// Full End-to-End Test: V2.5 Through Complete GPTfy Pipeline
// Uses PromptFactoryController to start a real pipeline run

// Test account: Pinnacle Wealth Partners
String accountId = '001QH000024mdDnYAI';

// Pipeline configuration
String promptName = 'V2.5 Test - Account Dashboard';
String rootObject = 'Account';
String businessContext = 'Generate comprehensive account dashboard with financial metrics, opportunities, contacts, and cases';
String outputFormat = 'Executive Summary';
String aiModelId = 'a01gD000003okzEQAQ'; // GPTfy (OpenAI)
String companyUrl = '';

System.debug('========================================');
System.debug('V2.5 FULL PIPELINE E2E TEST');
System.debug('========================================');
System.debug('Account: ' + accountId);
System.debug('V2.5 Enabled: true (confirmed in Stage08_PromptAssembly.cls)');
System.debug('========================================');

try {
    // Start the pipeline using the controller
    Id runId = PromptFactoryController.startPipelineRun(
        promptName,
        rootObject,
        accountId,
        businessContext,
        outputFormat,
        aiModelId,
        companyUrl
    );

    System.debug('✓ Pipeline started successfully');
    System.debug('Run ID: ' + runId);
    System.debug('Run URL: /' + runId);
    System.debug('========================================');
    System.debug('Monitor progress:');
    System.debug('1. Navigate to: https://agentictso--dev.sandbox.my.salesforce.com/' + runId);
    System.debug('2. Check Status field for completion');
    System.debug('3. Review Current_Stage__c to see progress');
    System.debug('4. Stage 8 should generate template with ONLY real fields');
    System.debug('5. Stage 9 should fill template with data');
    System.debug('========================================');
    System.debug('Expected behavior:');
    System.debug('- Stage 8: Generate template using V2.5 meta-prompt');
    System.debug('- Template should use fields like {{{Name}}}, {{{AnnualRevenue}}}');
    System.debug('- NO invented fields like {{{HealthScore}}} or {{{CriticalAlert}}}');
    System.debug('- Visual components: stat cards, tables, proper hierarchy');
    System.debug('========================================');

} catch (Exception e) {
    System.debug('ERROR: Failed to start pipeline');
    System.debug('Message: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
