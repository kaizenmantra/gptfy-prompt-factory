// V2.5 Test for Account 1: Pinnacle Wealth Partners (FRESH RUN)
// Tests the two-layer meta-prompt architecture AFTER deployment

System.debug('=== V2.5 FRESH TEST: Account 1 - Pinnacle Wealth Partners ===');
System.debug('This run should use the deployed V2.5 flag = true');
System.debug('');

// Start pipeline
Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-FRESH-PinnacleWealth',
    'Account',
    '001QH000024mdDnYAI',
    'Analyze this account for health, opportunity pipeline, support issues, and engagement.',
    'Narrative',
    'a01gD000003okzEQAQ',
    'https://test.example.com'
);

System.debug('Pipeline started: ' + runId);
System.debug('');
System.debug('✅ Pipeline execution started with FRESH deployment');
System.debug('');
System.debug('Wait ~3 minutes then run:');
System.debug('SELECT Stage_Number__c, Log_Level__c, Log_Message__c FROM PF_Run_Log__c WHERE Run__c = \'' + runId + '\' AND Log_Message__c LIKE \'%V2.5%\' ORDER BY Timestamp__c');
