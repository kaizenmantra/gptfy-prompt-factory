/**
 * @description Test class for Stage12_QualityAudit
 * Tests AI-powered quality scoring and audit record creation
 */
@IsTest
private class Stage12_QualityAudit_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Quality Account', Industry = 'Technology');
        insert testAccount;
        AIServiceClient.mockMode = true;
    }

    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div class="slds-card"><h1>Account Summary</h1><p>Comprehensive analysis</p></div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'businessContext' => 'Sales analysis',
            'targetPersona' => 'Sales Executive',
            'businessObjectives' => new List<String>{'Increase revenue'},
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"visualQuality": 8, "dataAccuracy": 9, "personaFit": 8, ' +
            '"actionability": 7, "businessValue": 9, ' +
            '"reasoning": "High quality output", ' +
            '"strengths": ["Clear", "Actionable"], ' +
            '"improvements": ["Add metrics"]}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('qualityScorecard'), 'Quality scorecard should exist');
    }

    @IsTest
    static void testExecute_NullOutputHtml() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => null,
            'businessContext' => 'Test',
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null HTML');
    }

    @IsTest
    static void testExecute_InvalidJSON() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div>Test content</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'businessContext' => 'Test',
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{invalid json}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with invalid JSON');
    }

    @IsTest
    static void testExecute_OverallScoreCalculated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div>Test content</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"visualQuality": 8, "dataAccuracy": 8, "personaFit": 8, ' +
            '"actionability": 8, "businessValue": 8, ' +
            '"reasoning": "Consistent quality", ' +
            '"strengths": ["Clear"], "improvements": ["None"]}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Decimal overallScore = (Decimal) result.outputs.get('overallScore');
        System.assertEquals(8.00, overallScore, 'Overall score should be average of 5 dimensions');
    }

    @IsTest
    static void testExecute_ThresholdCheck() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div>Test content</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"visualQuality": 9, "dataAccuracy": 9, "personaFit": 9, ' +
            '"actionability": 9, "businessValue": 9, ' +
            '"reasoning": "Excellent", "strengths": ["All"], "improvements": ["None"]}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Boolean meetsThreshold = (Boolean) result.outputs.get('meetsThreshold');
        System.assertEquals(true, meetsThreshold, 'Should meet quality threshold');
        System.assertEquals('Completed', result.status, 'Should complete when threshold met');
    }

    @IsTest
    static void testExecute_BelowThreshold() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div>Test content</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"visualQuality": 5, "dataAccuracy": 5, "personaFit": 5, ' +
            '"actionability": 5, "businessValue": 5, ' +
            '"reasoning": "Below standard", "strengths": ["None"], "improvements": ["Many"]}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Boolean meetsThreshold = (Boolean) result.outputs.get('meetsThreshold');
        System.assertEquals(false, meetsThreshold, 'Should not meet quality threshold');
    }

    @IsTest
    static void testExecute_AIReasoningCaptured() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div>Test content</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"visualQuality": 8, "dataAccuracy": 8, "personaFit": 8, ' +
            '"actionability": 8, "businessValue": 8, ' +
            '"reasoning": "This is the AI audit reasoning", ' +
            '"strengths": ["Good"], "improvements": ["Better"]}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('This is the AI audit reasoning', result.aiReasoning, 'AI reasoning should be captured');
    }

    @IsTest
    static void testExecute_QualityScoreRecordCreated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div>Test content</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"visualQuality": 8, "dataAccuracy": 8, "personaFit": 8, ' +
            '"actionability": 8, "businessValue": 8, ' +
            '"reasoning": "Test", "strengths": ["A"], "improvements": ["B"]}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Id qualityScoreId = (Id) result.outputs.get('qualityScoreId');
        System.assertNotEquals(null, qualityScoreId, 'Quality score record should be created');

        PF_Quality_Score__c score = [SELECT Overall_Score__c FROM PF_Quality_Score__c WHERE Id = :qualityScoreId];
        System.assertEquals(8.00, score.Overall_Score__c, 'Overall score should be saved');
    }

    @IsTest
    static void testExecute_MarkdownCodeBlock() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String outputHTML = '<div>Test content</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => outputHTML,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '```json\n{"visualQuality": 7, "dataAccuracy": 7, "personaFit": 7, ' +
            '"actionability": 7, "businessValue": 7, ' +
            '"reasoning": "Test", "strengths": ["A"], "improvements": ["B"]}\n```';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage12_QualityAudit stage = new Stage12_QualityAudit();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Should handle markdown code blocks');
    }
}