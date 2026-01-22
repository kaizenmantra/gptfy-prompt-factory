// Final Test: All 6 Builders Active (including updated Evidence Binding + Next Best Action)
System.debug('═══════════════════════════════════════════════════════');
System.debug('🎯 FINAL COMPREHENSIVE TEST - 6 BUILDERS');
System.debug('═══════════════════════════════════════════════════════\n');

System.debug('Builders in org (all should be Active):');
System.debug('  1. Evidence Binding Rules v2 (Quality Rule) - NOW WITH SPECIFICITY RULES');
System.debug('  2. Risk Assessment Pattern');
System.debug('  3. Next Best Action Pattern - NEW!');
System.debug('  4. Stat Card Component');
System.debug('  5. Alert Box Component');
System.debug('  6. Healthcare Payer Context\n');

Id runId = PromptFactoryController.startPipelineRun(
    'Final Test - 6 Builders Active',
    'Opportunity',
    '006QH00000Hjl5qYAB',
    'Generate a deal review with coaching guidance',
    'HTML',
    'a01gD000003okzEQAQ',
    null
);

System.debug('✅ Pipeline Started: ' + runId);
System.debug('\n⏳ Wait 60 seconds, then check:');
System.debug('Run Status: SELECT Status__c, Current_Stage__c, Created_Prompt_Id__c FROM PF_Run__c WHERE Id = \'' + runId + '\'');
System.debug('\nExpected Results:');
System.debug('  - Prompt should be ~40KB (vs 10KB without builders)');
System.debug('  - Should contain: "=== Evidence Binding Rules v2 ==="');
System.debug('  - Should contain: "=== Risk Assessment Pattern ==="');
System.debug('  - Should contain: "=== Next Best Action Pattern ==="');
System.debug('  - Should contain: "=== Stat Card Component ==="');
System.debug('  - Should contain: "=== Alert Box Component ==="');
System.debug('  - Should contain: "=== Healthcare Payer Context ==="');
System.debug('\n  Total builder content: ~35KB');
