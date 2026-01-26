// V2.5 Test for Account 1: Pinnacle Wealth Partners
// Tests the two-layer meta-prompt architecture

System.debug('=== V2.5 TEST: Account 1 - Pinnacle Wealth Partners ===');

// Start pipeline
Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-Test-PinnacleWealth',
    'Account',
    '001QH000024mdDnYAI',
    'Analyze this account for health, opportunity pipeline, support issues, and engagement.',
    'Narrative',
    'a01gD000003okzEQAQ',
    'https://test.example.com'
);

System.debug('Pipeline started: ' + runId);
System.debug('');
System.debug('✅ Pipeline execution started');
System.debug('');
System.debug('Next steps:');
System.debug('1. Wait for Stage 8 to complete (~2-3 minutes)');
System.debug('2. Query PF_Run_Log__c for Stage 8 logs');
System.debug('3. Look for "V2.5: Template generation successful"');
System.debug('4. Check generated template for merge fields');
System.debug('');
System.debug('Query to check Stage 8 logs:');
System.debug('SELECT Stage__c, Level__c, Message__c FROM PF_Run_Log__c WHERE Run__c = \'' + runId + '\' AND Stage__c = 8 ORDER BY CreatedDate');
