// Start pipeline run for golden test account
// Account: 001QH000024mdDnYAI (TESTDATA_Pinnacle Wealth Partners)

Id runId = PromptFactoryController.startPipelineRun(
    'Account 360 - Pinnacle Wealth Partners (Golden Test)',  // promptName
    'Account',                                                 // rootObject
    '001QH000024mdDnYAI',                                     // sampleRecordId
    'Analyze this wealth management firm for account health, opportunity pipeline, support issues, and engagement. Provide actionable insights for account executives.', // businessContext
    'Narrative',                                              // outputFormat
    'a01gD000003okzEQAQ',                                     // aiModelId (GPTfy OpenAI)
    'https://pinnaclewealth.example.com'                      // companyUrl
);

System.debug('Pipeline run created: ' + runId);
System.debug('View run details: https://agentictso.lightning.force.com/lightning/r/PF_Run__c/' + runId + '/view');
