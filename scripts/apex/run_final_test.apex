// Final Test: Verify builder injection works end-to-end
System.debug('=== FINAL INTEGRATION TEST ===');

Id runId = PromptFactoryController.startPipelineRun(
    'Final Test - Complete Builders',
    'Opportunity',
    '006QH00000Hjl5qYAB',
    'Review this opportunity and provide coaching guidance.',
    'HTML',
    'a01gD000003okzEQAQ',
    null
);

System.debug('✅ Run Started: ' + runId);
System.debug('\nWait 60 seconds then check:');
System.debug('SELECT Id, Status__c, Current_Stage__c, Created_Prompt_Id__c FROM PF_Run__c WHERE Id = \'' + runId + '\'');
System.debug('\nThen verify prompt injection:');
System.debug('SELECT ccai__Prompt_Command__c FROM ccai__AI_Prompt__c WHERE Id = [Created_Prompt_Id]');
System.debug('\nLook for these markers in prompt:');
System.debug('  - "Evidence Binding Rules v2"');
System.debug('  - "Risk Assessment Pattern"');
System.debug('  - "Stat Card Component"');
System.debug('  - "Alert Box Component"');
System.debug('  - "Healthcare Payer Context"');
