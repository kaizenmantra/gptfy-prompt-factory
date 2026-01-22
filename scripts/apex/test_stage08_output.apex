// Test what Stage08 actually outputs
System.debug('=== TESTING STAGE08 OUTPUT ===\n');

// Create minimal inputs
Map<String, Object> inputs = new Map<String, Object>{
    'promptName' => 'Stage08 Test Output',
    'sampleRecordId' => '006QH00000Hjl5qYAB',
    'rootObject' => 'Opportunity',
    'businessContext' => 'Healthcare Insurance',
    'targetPersona' => 'Sales Rep',
    'businessObjectives' => new List<String>{'Close deals'},
    'htmlTemplate' => '<div>Test</div>',
    'selectedFields' => new List<String>{'Name', 'Amount'},
    'companyResearch' => new Map<String, Object>{
        'companyProfile' => 'Test Company',
        'industryContext' => 'Healthcare',
        'strategicInsights' => 'Test insights'
    },
    'recordTypeId' => '012QH0000045bz7YAA' // Builder RecordTypeId
};

// Create a test run
PF_Run__c testRun = new PF_Run__c(
    Root_Object__c = 'Opportunity',
    Status__c = 'In Progress',
    Current_Stage__c = 8,
    Prompt_Name__c = 'Stage08 Test Output',
    Sample_Record_Id__c = '006QH00000Hjl5qYAB'
);
insert testRun;

try {
    // Execute Stage08
    System.debug('Executing Stage08...');
    Stage08_PromptAssembly stage8 = new Stage08_PromptAssembly();
    StageResult result = stage8.execute(testRun.Id, inputs);
    
    System.debug('\n✅ Stage08 Completed: ' + result.status);
    
    // Check outputs
    if (result.outputs.containsKey('aiInstructions')) {
        String aiInstructions = (String) result.outputs.get('aiInstructions');
        System.debug('\n📊 AI Instructions Length: ' + aiInstructions.length() + ' chars');
        
        // Check for builder headers
        Boolean hasEvidence = aiInstructions.contains('Evidence Binding');
        Boolean hasRisk = aiInstructions.contains('Risk Assessment');
        Boolean hasUI = aiInstructions.contains('Stat Card') || aiInstructions.contains('Alert Box');
        Boolean hasContext = aiInstructions.contains('Healthcare');
        
        System.debug('Contains Evidence Binding: ' + hasEvidence);
        System.debug('Contains Risk Assessment: ' + hasRisk);
        System.debug('Contains UI Components: ' + hasUI);
        System.debug('Contains Healthcare Context: ' + hasContext);
        
        if (hasEvidence || hasRisk) {
            System.debug('\n✅ Builder content IS in Stage08 output!');
        } else {
            System.debug('\n❌ Builder content NOT in Stage08 output!');
        }
        
        // Check promptConfig
        if (result.outputs.containsKey('promptConfig')) {
            Map<String, Object> promptConfig = (Map<String, Object>) result.outputs.get('promptConfig');
            String promptCommand = (String) promptConfig.get('promptCommand');
            System.debug('\n📊 promptConfig.promptCommand Length: ' + promptCommand.length() + ' chars');
            System.debug('promptCommand == aiInstructions: ' + (promptCommand == aiInstructions));
        }
    }
    
} catch (Exception e) {
    System.debug('❌ Error: ' + e.getMessage());
    System.debug('Stack: ' + e.getStackTraceString());
} finally {
    delete testRun;
}
