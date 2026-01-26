// V2.5 Test with DEBUG to confirm deployment

System.debug('=== V2.5 DEBUG TEST ===');

Id runId = PromptFactoryController.startPipelineRun(
    'V2.5-DEBUG-Test',
    'Account',
    '001QH000024mdDnYAI',
    'Analyze this account.',
    'Narrative',
    'a01gD000003okzEQAQ',
    'https://test.example.com'
);

System.debug('Run ID: ' + runId);
System.debug('');
System.debug('Wait ~3 min, then look for log message: "V2.5 flag value:"');
