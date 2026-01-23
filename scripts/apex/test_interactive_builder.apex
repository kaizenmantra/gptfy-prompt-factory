// Test Interactive Builder with user's test data
System.debug('=== Testing Interactive Builder ===');

List<Id> oppIds = new List<Id>{
    '006QH00000HjgvlYAB',
    '006QH00000Hjl5qYAB',
    '006gD000001lqquQAA'
};

String businessContext = 'This prompt reviews the opportunity and the related activities on it and comes back with guidance on how can the sales rep improve the chances of closing this deal. It has to act like a coach and review the deal in terms of the business process around it and sales best practices.';

Id sessionId;
Id promptId;

// Step 1: Initialize Session
System.debug('\n=== Step 1: Initialize Session ===');
try {
    Map<String, Object> initResult = PromptBuilderController.initializeSession(
        'Opportunity',
        oppIds,
        businessContext
    );
    System.debug('Session initialized: ' + initResult.get('success'));
    sessionId = (Id)initResult.get('sessionId');
    System.debug('Session ID: ' + sessionId);
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    return;
}

// Step 2: Chat - Start Analysis
System.debug('\n=== Step 2: Chat - Start Analysis ===');
try {
    Map<String, Object> chatResult = PromptBuilderController.chat(sessionId, 'START');
    System.debug('Chat success: ' + chatResult.get('success'));
    String chatMessage = (String)chatResult.get('message');
    System.debug('Response length: ' + chatMessage.length());
    System.debug('Preview: ' + chatMessage.substring(0, Math.min(500, chatMessage.length())));
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    return;
}

// Step 3: Get AI Connection
System.debug('\n=== Step 3: Get AI Connections ===');
List<Map<String, String>> connections = PromptBuilderController.getAIConnections();
Id aiModelId = null;
for (Map<String, String> conn : connections) {
    System.debug('  - ' + conn.get('label'));
    if (conn.get('label').containsIgnoreCase('OpenAI')) {
        aiModelId = (Id)conn.get('value');
    }
}
if (aiModelId == null && !connections.isEmpty()) {
    aiModelId = (Id)connections[0].get('value');
}
System.debug('Using AI Model: ' + aiModelId);

// Step 4: Deploy Prompt
System.debug('\n=== Step 4: Deploy Prompt ===');
try {
    Map<String, Object> deployResult = PromptBuilderController.deployPrompt(
        sessionId,
        'Deal Coach Test - ' + DateTime.now().format('MMdd-HHmm'),
        aiModelId
    );
    System.debug('Deploy success: ' + deployResult.get('success'));
    promptId = (Id)deployResult.get('promptId');
    System.debug('Prompt ID: ' + promptId);
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
    System.debug('Stack: ' + e.getStackTraceString());
    return;
}

// Step 5: Check the prompt
System.debug('\n=== Step 5: Verify Prompt ===');
ccai__AI_Prompt__c prompt = [
    SELECT Id, Name, ccai__Prompt_Command__c, ccai__AI_Connection__c
    FROM ccai__AI_Prompt__c WHERE Id = :promptId
];

System.debug('Name: ' + prompt.Name);
System.debug('AI Connection: ' + prompt.ccai__AI_Connection__c);

String cmd = prompt.ccai__Prompt_Command__c;
if (cmd != null) {
    System.debug('Command length: ' + cmd.length());
    System.debug('Has HTML rules: ' + cmd.contains('SINGLE LINE'));
    System.debug('Has NO MARKDOWN: ' + cmd.contains('NO MARKDOWN'));
    System.debug('Has template section: ' + cmd.contains('--- HTML TEMPLATE ---'));

    // Print in chunks to avoid debug limit
    System.debug('\n=== Prompt Command ===');
    Integer chunkSize = 2000;
    for (Integer i = 0; i < cmd.length(); i += chunkSize) {
        System.debug('CHUNK ' + (i/chunkSize) + ': ' + cmd.substring(i, Math.min(i + chunkSize, cmd.length())));
    }
}

System.debug('\n=== Test Complete ===');
