// MVP Test: Run Prompt Factory with Builder Prompts Injected
// This tests Stage08's ability to load and inject builder prompts

System.debug('=== MVP TEST: PROMPT FACTORY WITH BUILDER INJECTION ===');

// Test Parameters
String promptName = 'MVP Test - Builder Prompts';
String rootObject = 'Opportunity';
String sampleRecordId = '006QH00000Hjl5qYAB'; // Harrison - CRM Stock Diversification Program
String businessContext = 'This prompt reviews the opportunity and the related activities on it and comes back with guidance on how can the sales rep improve the chances of closing this deal. It has to act like a coach and review the deal in terms of the business process around it and sales best practices.';
String outputFormat = 'HTML';
String aiModelId = 'a01gD000003okzEQAQ'; // GPTfy (OpenAI)
String companyUrl = null;

System.debug('Test Parameters:');
System.debug('  Prompt Name: ' + promptName);
System.debug('  Root Object: ' + rootObject);
System.debug('  Sample Record ID: ' + sampleRecordId);
System.debug('  AI Model ID: ' + aiModelId);

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
    
    System.debug('✅ Prompt Factory Started Successfully');
    System.debug('Run ID: ' + runId);
    System.debug('\nNext Steps:');
    System.debug('1. Monitor: SELECT Id, Status__c, Current_Stage__c, Error_Message__c FROM PF_Run__c WHERE Id = \'' + runId + '\'');
    System.debug('2. Check logs for "Loaded X Quality Rules" and "Loaded X Patterns"');
    System.debug('3. Once complete, check Final_Prompt__c field for builder content');
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('\n=== MVP TEST EXECUTION COMPLETE ===');
