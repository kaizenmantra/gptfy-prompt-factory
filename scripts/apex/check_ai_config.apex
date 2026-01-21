
// Diagnostic Script: check_ai_config.apex
// 1. Prints Azure Custom Settings
// 2. Prints Claude Custom Settings
// 3. Runs AIServiceClient.detectProvider()
// 4. Attempts a simple call (optional, can comment out if just checking config)

System.debug('=== DIAGNOSTIC START ===');

// Check Azure Settings
Azure_OpenAI_Credentials__c azure = Azure_OpenAI_Credentials__c.getInstance();
System.debug('Azure_OpenAI_Credentials__c.getInstance(): ' + azure);
if (azure != null) {
    System.debug('Azure API Key Present: ' + String.isNotBlank(azure.API_Key__c));
    System.debug('Azure Default__c: ' + azure.Default__c);
} else {
    System.debug('Azure Config is NULL');
}

// Check Claude Settings
Claude_API_Credentials__c claude = Claude_API_Credentials__c.getInstance();
System.debug('Claude_API_Credentials__c.getInstance(): ' + claude);
if (claude != null) {
    System.debug('Claude API Key Present: ' + String.isNotBlank(claude.API_Key__c));
    System.debug('Claude Default__c: ' + claude.Default__c);
} else {
    System.debug('Claude Config is NULL');
}

// Check Provider Detection
try {
    // Reflectively access detectProvider if it's private (it is private in the file we saw)
    // Actually, detectProvider is private. We can't call it directly from Anon Apex without making it public or @TestVisible.
    // Instead, we'll infer it by checking the logic ourselves or calling callAI with a dummy prompt.
    
    System.debug('--- Attempting AIServiceClient.callAI() ---');
    AIServiceClient.AIResponse response = AIServiceClient.callAI('Hello, are you working?');
    System.debug('Response Success: ' + response.success);
    System.debug('Response Error: ' + response.errorMessage);
    System.debug('Response Content: ' + response.content);
} catch (Exception e) {
    System.debug('Exception during callAI: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}

System.debug('=== DIAGNOSTIC END ===');
