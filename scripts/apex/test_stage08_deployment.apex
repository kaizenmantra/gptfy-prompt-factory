// Test if Stage08 has builder loading methods
System.debug('=== TESTING STAGE08 DEPLOYMENT ===');

// Create a test context
PF_Run__c testRun = new PF_Run__c(
    Run_Name__c = 'Stage08 Test',
    Object__c = 'Opportunity',
    Status__c = 'Running',
    Current_Stage__c = 8
);
insert testRun;

try {
    // Instantiate Stage08
    Stage08_PromptAssembly stage8 = new Stage08_PromptAssembly();
    
    // Check if class has the new methods by invoking execute
    stage8.execute(testRun.Id);
    
    // Retrieve the created prompt
    testRun = [SELECT Created_Prompt_Id__c FROM PF_Run__c WHERE Id = :testRun.Id];
    
    if (testRun.Created_Prompt_Id__c != null) {
        ccai__AI_Prompt__c prompt = [
            SELECT ccai__Prompt_Command__c 
            FROM ccai__AI_Prompt__c 
            WHERE Id = :testRun.Created_Prompt_Id__c
        ];
        
        // Check for builder markers
        Boolean hasEvidenceBinding = prompt.ccai__Prompt_Command__c.contains('Evidence Binding');
        Boolean hasRiskAssessment = prompt.ccai__Prompt_Command__c.contains('Risk Assessment');
        Boolean hasStatCard = prompt.ccai__Prompt_Command__c.contains('Stat Card');
        Boolean hasHealthcare = prompt.ccai__Prompt_Command__c.contains('Healthcare');
        
        System.debug('\n✅ Stage08 Executed Successfully');
        System.debug('Prompt Length: ' + prompt.ccai__Prompt_Command__c.length());
        System.debug('Has Evidence Binding: ' + hasEvidenceBinding);
        System.debug('Has Risk Assessment: ' + hasRiskAssessment);
        System.debug('Has Stat Card: ' + hasStatCard);
        System.debug('Has Healthcare Context: ' + hasHealthcare);
        
        if (!hasEvidenceBinding && !hasRiskAssessment) {
            System.debug('\n⚠️ WARNING: Builder content NOT found in prompt!');
            System.debug('This suggests Stage08 may not have builder loading code deployed.');
        } else {
            System.debug('\n✅ VERIFIED: Builder content IS present!');
        }
    }
    
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack: ' + e.getStackTraceString());
} finally {
    // Cleanup
    delete testRun;
}
