// Test Step 2 - Chat with existing session
// Using session from Step 1: a0gQH000005GHbXYAW

Id sessionId = 'a0gQH000005GHbXYAW';

System.debug('=== Loading Session ===');
PF_Run__c session = [
    SELECT Id, Root_Object__c, Business_Context__c, Sample_Record_Id__c, AI_Model__c, Current_Draft__c
    FROM PF_Run__c WHERE Id = :sessionId
];
System.debug('Root Object: ' + session.Root_Object__c);
System.debug('Business Context: ' + session.Business_Context__c);

// Load exemplars
System.debug('\n=== Loading Exemplars ===');
StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'PromptExemplars' LIMIT 1];
Map<String, Object> exemplars = (Map<String, Object>)JSON.deserializeUntyped(sr.Body.toString());
System.debug('Exemplars loaded: ' + exemplars.keySet());

String systemPrompt = (String)exemplars.get('SYSTEM_PROMPT');
System.debug('System prompt length: ' + (systemPrompt != null ? systemPrompt.length() : 0));

// Get sample records
List<String> recordIdStrings = session.Sample_Record_Id__c.split(',');
List<Id> sampleRecordIds = new List<Id>();
for (String s : recordIdStrings) {
    sampleRecordIds.add((Id)s.trim());
}

// Query sample data
String soql = 'SELECT Id, Name, Amount, StageName, CloseDate, Probability FROM Opportunity WHERE Id IN :sampleRecordIds';
List<SObject> sampleRecords = Database.query(soql);
System.debug('\n=== Sample Data ===');
for (SObject rec : sampleRecords) {
    System.debug('  ' + rec.get('Name') + ' - $' + rec.get('Amount') + ' - ' + rec.get('StageName'));
}

// Build user prompt
String userPrompt = '## WHAT I\'M BUILDING\n\n' +
    session.Business_Context__c + '\n\n' +
    '## SAMPLE RECORDS\n\n';

for (SObject rec : sampleRecords) {
    userPrompt += '### ' + rec.get('Name') + '\n';
    userPrompt += '- Amount: $' + rec.get('Amount') + '\n';
    userPrompt += '- Stage: ' + rec.get('StageName') + '\n';
    userPrompt += '- Close Date: ' + rec.get('CloseDate') + '\n\n';
}

userPrompt += 'Generate analysis following deal coaching best practices.';

System.debug('\n=== Calling AI ===');
System.debug('User prompt length: ' + userPrompt.length());

AIServiceClient.AIResponse response = AIServiceClient.callAI(
    systemPrompt,
    userPrompt,
    4096,
    1.0
);

System.debug('\n=== AI Response ===');
System.debug('Success: ' + response.success);
if (response.success) {
    System.debug('Response length: ' + response.content.length());
    System.debug('Preview: ' + response.content.substring(0, Math.min(1000, response.content.length())));

    // Save to session
    session.Current_Draft__c = response.content;
    update session;
    System.debug('\nDraft saved to session');
} else {
    System.debug('Error: ' + response.errorMessage);
}
