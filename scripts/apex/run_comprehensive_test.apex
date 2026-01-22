// Comprehensive Integration Test: All 5 Builder Categories
// Tests Quality Rules + Patterns + UI Components + Context Templates

System.debug('=== COMPREHENSIVE INTEGRATION TEST ===');
System.debug('Testing all 5 builder categories in one prompt');

// Test Parameters (same as MVP)
String promptName = 'Comprehensive Test - All 5 Categories';
String rootObject = 'Opportunity';
String sampleRecordId = '006QH00000Hjl5qYAB';
String businessContext = 'This prompt reviews the opportunity and provides comprehensive coaching guidance on closing the deal, using all available builder prompts including quality rules, patterns, UI components, and industry context.';
String outputFormat = 'HTML';
String aiModelId = 'a01gD000003okzEQAQ';
String companyUrl = null;

System.debug('\nTest Parameters:');
System.debug('  Prompt: ' + promptName);
System.debug('  Object: ' + rootObject);
System.debug('  Record: ' + sampleRecordId);

// Verify all builders exist first
List<ccai__AI_Prompt__c> builders = [
    SELECT Id, Name, Category__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND ccai__Status__c = 'Active'
    ORDER BY Category__c, Name
];

System.debug('\n=== AVAILABLE BUILDERS (' + builders.size() + ') ===');
for (ccai__AI_Prompt__c b : builders) {
    System.debug('  [' + b.Category__c + '] ' + b.Name);
}

// Execute Prompt Factory
try {
    Id runId = PromptFactoryController.startPipelineRun(
        promptName,
        rootObject,
        sampleRecordId,
        businessContext,
        outputFormat,
        aiModelId,
        companyUrl
    );
    
    System.debug('\n✅ COMPREHENSIVE TEST STARTED');
    System.debug('Run ID: ' + runId);
    System.debug('\nExpected in Stage08 logs:');
    System.debug('  - "Loaded 1 Quality Rules"');
    System.debug('  - "Loaded 1 Patterns"');
    System.debug('  - "Loaded 2 UI Components"');
    System.debug('  - "Loaded 1 Context Templates"');
    System.debug('\nMonitor: SELECT Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = \'' + runId + '\'');
    
} catch (Exception e) {
    System.debug('\n❌ ERROR: ' + e.getMessage());
}

System.debug('\n=== TEST EXECUTION COMPLETE ===');
