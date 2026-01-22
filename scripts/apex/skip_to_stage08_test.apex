// Workaround: Test Stage08 directly by creating a run with Stage 1-7 data already populated
// This bypasses Stage 2 AI issues and lets us test builder loading

// Create a test run with minimal required data
PF_Run__c testRun = new PF_Run__c(
    Root_Object__c = 'Opportunity',
    Status__c = 'In Progress',
    Current_Stage__c = 7, // Start at 7, will go to 8
    Prompt_Name__c = 'Stage08 Builder Test',
    Sample_Record_Id__c = '006gD000001lqquQAA',
    Business_Context__c = 'Test builder loading',
    Output_Format__c = 'Report',
    AI_Model__c = 'a01gD000003okzEQAQ'
);
insert testRun;

System.debug('Created test run: ' + testRun.Id);

// Manually trigger Stage08 with minimal inputs
Stage08_PromptAssembly stage08 = new Stage08_PromptAssembly();

Map<String, Object> inputs = new Map<String, Object>{
    'rootObject' => 'Opportunity',
    'businessContext' => 'Test prompt to verify builder content injection',
    'targetPersona' => 'Sales Representative',
    'businessObjectives' => new List<String>{'Increase deal velocity', 'Improve forecast accuracy'},
    'selectedFields' => new Map<String, Object>{
        'Opportunity' => new List<String>{'Name', 'Amount', 'StageName', 'CloseDate'}
    },
    'promptName' => 'Builder Injection Test',
    'sampleRecordId' => '006gD000001lqquQAA',
    'htmlTemplate' => '<div>Test template with {{{Name}}}</div>',
    'companyProfile' => 'Test company in healthcare',
    'strategicInsights' => 'Focus on value-based care',
    'industryContext' => 'Healthcare payer market'
};

System.debug('=== EXECUTING STAGE08 ===');

try {
    StageResult result = stage08.execute(testRun.Id, inputs);
    
    System.debug('Stage08 Status: ' + result.status);
    System.debug('Stage08 Success: ' + result.success);
    
    if (!result.success) {
        System.debug('❌ STAGE08 FAILED');
        System.debug('Error: ' + result.errorMessage);
    } else {
        System.debug('✅ STAGE08 SUCCEEDED');
        
        // Check if aiInstructions has builder content
        String aiInstructions = (String) result.outputs.get('aiInstructions');
        if (aiInstructions != null) {
            System.debug('AI Instructions Length: ' + aiInstructions.length() + ' chars');
            
            // Check for builder headers
            Integer evidenceCount = aiInstructions.countMatches('Evidence Binding');
            Integer riskCount = aiInstructions.countMatches('Risk Assessment');
            Integer nextActionCount = aiInstructions.countMatches('Next Best Action');
            
            System.debug('Evidence Binding mentions: ' + evidenceCount);
            System.debug('Risk Assessment mentions: ' + riskCount);
            System.debug('Next Best Action mentions: ' + nextActionCount);
            
            if (evidenceCount > 0 || riskCount > 0 || nextActionCount > 0) {
                System.debug('✅✅✅ BUILDERS FOUND IN OUTPUT! ✅✅✅');
            } else {
                System.debug('❌ NO BUILDERS FOUND - Check logs for errors');
            }
            
            // Show first 500 chars
            System.debug('First 500 chars of aiInstructions:');
            System.debug(aiInstructions.substring(0, Math.min(500, aiInstructions.length())));
        } else {
            System.debug('❌ aiInstructions is NULL');
        }
    }
    
} catch (Exception e) {
    System.debug('❌ EXCEPTION IN STAGE08:');
    System.debug('Message: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('Stack: ' + e.getStackTraceString());
    
    // THIS IS THE ERROR WE'VE BEEN LOOKING FOR!
    System.debug('');
    System.debug('=== THIS IS THE ROOT CAUSE ===');
    System.debug(e.getMessage());
    System.debug('==============================');
}

// Check logs
List<PF_Run_Log__c> logs = [
    SELECT Log_Level__c, Stage_Number__c, Log_Message__c, Details__c
    FROM PF_Run_Log__c
    WHERE Run__c = :testRun.Id
    ORDER BY CreatedDate
];

System.debug('');
System.debug('=== LOGS (' + logs.size() + ' entries) ===');
for (PF_Run_Log__c log : logs) {
    System.debug('[' + log.Log_Level__c + '] Stage ' + log.Stage_Number__c + ': ' + log.Log_Message__c);
    if (log.Log_Level__c == 'ERROR' && String.isNotBlank(log.Details__c)) {
        System.debug('  Details: ' + log.Details__c.substring(0, Math.min(200, log.Details__c.length())));
    }
}

// Clean up
delete testRun;
