// Simple test: Check if we can manually call the buildAIInstructions method
System.debug('=== TESTING IF BUILDERS ARE LOADED ===\n');

// Query a recent prompt to see its size
ccai__AI_Prompt__c recentPrompt = [
    SELECT Id, Name, ccai__Prompt_Command__c, CreatedDate
    FROM ccai__AI_Prompt__c 
    WHERE Id = 'a0DQH00000KYck52AD'
    LIMIT 1
];

System.debug('Prompt: ' + recentPrompt.Name);
System.debug('Created: ' + recentPrompt.CreatedDate);
System.debug('Size: ' + recentPrompt.ccai__Prompt_Command__c.length() + ' chars\n');

// Check for builder content markers
String promptBody = recentPrompt.ccai__Prompt_Command__c;

Boolean hasEvidenceBinding = promptBody.contains('Evidence Binding') || promptBody.contains('EVIDENCE BINDING');
Boolean hasRiskAssessment = promptBody.contains('Risk Assessment') || promptBody.contains('RISK ASSESSMENT');  
Boolean hasStatCard = promptBody.contains('Stat Card') || promptBody.contains('STAT CARD');
Boolean hasAlertBox = promptBody.contains('Alert Box') || promptBody.contains('ALERT BOX');
Boolean hasHealthcare = promptBody.contains('Healthcare Payer') || promptBody.contains('HEALTHCARE PAYER');

System.debug('Builder Content Check:');
System.debug('  Evidence Binding: ' + hasEvidenceBinding);
System.debug('  Risk Assessment: ' + hasRiskAssessment);
System.debug('  Stat Card: ' + hasStatCard);
System.debug('  Alert Box: ' + hasAlertBox);
System.debug('  Healthcare Context: ' + hasHealthcare);

Integer builderCount = (hasEvidenceBinding ? 1 : 0) + 
                       (hasRiskAssessment ? 1 : 0) + 
                       (hasStatCard ? 1 : 0) + 
                       (hasAlertBox ? 1 : 0) + 
                       (hasHealthcare ? 1 : 0);

System.debug('\nTotal Builders Found: ' + builderCount + ' of 5');

if (builderCount == 0) {
    System.debug('\n❌ NO BUILDER CONTENT FOUND');
    System.debug('Issue: Stage08 builder loading may not be working');
    
    // Let's check if builders exist in database
    Integer totalBuilders = [
        SELECT COUNT() 
        FROM ccai__AI_Prompt__c 
        WHERE RecordType.DeveloperName = 'Builder' 
          AND ccai__Status__c = 'Active'
    ];
    
    System.debug('\nBuilders in Database: ' + totalBuilders);
    System.debug('If builders exist but not in prompt, Stage08 loading failed');
    
} else if (builderCount < 5) {
    System.debug('\n⚠️ PARTIAL BUILDER CONTENT');
    System.debug('Some builders missing - check Stage08 logic');
} else {
    System.debug('\n✅ ALL BUILDERS PRESENT!');
}
