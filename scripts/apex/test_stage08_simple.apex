// Simple Stage08 test - no logging queries, just catch the exception

System.debug('=== TESTING STAGE08 BUILDER LOADING ===');

// Create minimal test run
PF_Run__c testRun = new PF_Run__c(
    Root_Object__c = 'Opportunity',
    Status__c = 'In Progress',
    Prompt_Name__c = 'Builder Test',
    Sample_Record_Id__c = '006gD000001lqquQAA'
);
insert testRun;

// Call Stage08
Stage08_PromptAssembly stage08 = new Stage08_PromptAssembly();

Map<String, Object> inputs = new Map<String, Object>{
    'rootObject' => 'Opportunity',
    'businessContext' => 'Test',
    'targetPersona' => 'Sales Rep',
    'businessObjectives' => new List<String>{'Test'},
    'selectedFields' => new Map<String, Object>{
        'Opportunity' => new List<String>{'Name', 'Amount'}
    },
    'htmlTemplate' => '<div>Test</div>',
    'promptName' => 'Test',
    'sampleRecordId' => '006gD000001lqquQAA'
};

try {
    System.debug('Calling Stage08.execute()...');
    StageResult result = stage08.execute(testRun.Id, inputs);
    
    System.debug('Result status: ' + result.status);
    String aiInstructions = (String) result.outputs.get('aiInstructions');
    
    if (aiInstructions != null) {
        System.debug('✅ Stage08 completed');
        System.debug('AI Instructions: ' + aiInstructions.length() + ' chars');
        
        if (aiInstructions.contains('Evidence Binding') || aiInstructions.contains('Risk Assessment')) {
            System.debug('');
            System.debug('🎉🎉🎉 BUILDERS ARE INJECTING! 🎉🎉🎉');
            System.debug('');
        } else {
            System.debug('');
            System.debug('❌ NO BUILDERS FOUND IN OUTPUT');
            System.debug('');
        }
    } else {
        System.debug('❌ aiInstructions is null');
    }
    
} catch (Exception e) {
    System.debug('');
    System.debug('═══════════════════════════════════════');
    System.debug('🔥 EXCEPTION CAUGHT - THIS IS THE ERROR WE NEED! 🔥');
    System.debug('═══════════════════════════════════════');
    System.debug('Type: ' + e.getTypeName());
    System.debug('Message: ' + e.getMessage());
    System.debug('');
    System.debug('Stack Trace:');
    System.debug(e.getStackTraceString());
    System.debug('═══════════════════════════════════════');
}

delete testRun;
System.debug('Test complete');
