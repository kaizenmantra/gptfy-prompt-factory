/**
 * @description Test class for Stage02_StrategicProfiling
 * Tests Claude AI integration for persona and objective extraction
 */
@IsTest
private class Stage02_StrategicProfiling_Test {

    @TestSetup
    static void setup() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Strategic Account',
            Industry = 'Technology'
        );
        insert testAccount;

        // Enable mock mode for AI client
        AIServiceClient.mockMode = true;
    }

    /**
     * @description Helper to create test run
     */
    private static PF_Run__c createTestRun(Id accountId) {
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = accountId,
            Business_Context__c = 'Generate executive summary for sales team to identify upsell opportunities',
            Output_Format__c = 'HTML',
            Status__c = 'Queued'
        );
        insert run;
        return run;
    }

    /**
     * @description Test successful profiling with valid AI response
     */
    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Generate executive summary for sales team',
            'rootObject' => 'Account',
            'outputFormat' => 'HTML',
            'recordData' => new Map<String, Object>{'Name' => 'Test Account'}
        };

        String mockAIResponse = '{"targetPersona": "Sales Executive", ' +
            '"businessObjectives": ["Increase revenue", "Improve customer satisfaction"], ' +
            '"keyMetrics": ["Deal size", "Close rate"], ' +
            '"audienceLevel": "Executive", ' +
            '"reasoning": "This is tailored for sales leadership"}';
        AIServiceClient.mockResponse = mockAIResponse;

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('targetPersona'), 'Target persona should be set');
        System.assertEquals('Sales Executive', result.outputs.get('targetPersona'), 'Should parse persona');
        System.assertNotEquals(null, result.outputs.get('businessObjectives'), 'Business objectives should be set');
        System.assertNotEquals(null, result.aiReasoning, 'AI reasoning should be captured');
    }

    /**
     * @description Test with null business context
     */
    @IsTest
    static void testExecute_NullBusinessContext() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => null,
            'rootObject' => 'Account',
            'outputFormat' => 'HTML'
        };

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null business context');
        System.assert(result.errorMessage.contains('Business context is required'),
            'Error message should indicate missing context');
    }

    /**
     * @description Test with blank business context
     */
    @IsTest
    static void testExecute_BlankBusinessContext() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => '',
            'rootObject' => 'Account'
        };

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with blank business context');
    }

    /**
     * @description Test with AI response in markdown code block
     */
    @IsTest
    static void testExecute_MarkdownCodeBlock() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Test context',
            'rootObject' => 'Account',
            'outputFormat' => 'HTML'
        };

        String mockAIResponse = '```json\n{"targetPersona": "Manager", ' +
            '"businessObjectives": ["Goal 1"], ' +
            '"keyMetrics": ["Metric 1"], ' +
            '"audienceLevel": "Manager", ' +
            '"reasoning": "Test"}\n```';
        AIServiceClient.mockResponse = mockAIResponse;

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should handle markdown code blocks');
        System.assertEquals('Manager', result.outputs.get('targetPersona'), 'Should parse persona from markdown');
    }

    /**
     * @description Test with invalid JSON response
     */
    @IsTest
    static void testExecute_InvalidJSON() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Test context',
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{invalid json response}';

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with invalid JSON');
        System.assert(result.errorMessage.contains('Failed to parse'), 'Should indicate parsing error');
    }

    /**
     * @description Test with missing required fields in response
     */
    @IsTest
    static void testExecute_MissingRequiredFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Test context',
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"audienceLevel": "Manager"}';

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with missing required fields');
        System.assert(result.errorMessage.contains('missing required fields'),
            'Should indicate missing fields');
    }

    /**
     * @description Test outputs pass through required inputs
     */
    @IsTest
    static void testExecute_PassThroughInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> recordData = new Map<String, Object>{'Name' => 'Test'};
        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Test context',
            'rootObject' => 'Account',
            'outputFormat' => 'HTML',
            'recordData' => recordData
        };

        AIServiceClient.mockResponse = '{"targetPersona": "User", ' +
            '"businessObjectives": ["Goal"], ' +
            '"keyMetrics": ["Metric"], ' +
            '"audienceLevel": "User", ' +
            '"reasoning": "Test"}';

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Account', result.outputs.get('rootObject'), 'Root object should pass through');
        System.assertEquals('Test context', result.outputs.get('businessContext'), 'Context should pass through');
        System.assertEquals(recordData, result.outputs.get('recordData'), 'Record data should pass through');
        System.assertEquals('HTML', result.outputs.get('outputFormat'), 'Output format should pass through');
    }

    /**
     * @description Test profiling JSON is stored
     */
    @IsTest
    static void testExecute_ProfilingJsonStored() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Test context',
            'rootObject' => 'Account'
        };

        String mockAIResponse = '{"targetPersona": "Analyst", ' +
            '"businessObjectives": ["Objective"], ' +
            '"keyMetrics": ["Metric"], ' +
            '"audienceLevel": "Practitioner", ' +
            '"reasoning": "Analysis"}';
        AIServiceClient.mockResponse = mockAIResponse;

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertNotEquals(null, result.outputs.get('profilingJson'), 'Profiling JSON should be stored');
        String storedJson = (String) result.outputs.get('profilingJson');
        System.assert(storedJson.contains('targetPersona'), 'JSON should contain raw response');
    }

    /**
     * @description Test with multiple business objectives
     */
    @IsTest
    static void testExecute_MultipleObjectives() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Complex business context',
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"targetPersona": "Director", ' +
            '"businessObjectives": ["Revenue growth", "Cost reduction", "Market expansion"], ' +
            '"keyMetrics": ["ARR", "CAC", "Market share", "NPS"], ' +
            '"audienceLevel": "Manager", ' +
            '"reasoning": "Comprehensive analysis"}';

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should handle multiple objectives');
        List<Object> objectives = (List<Object>) result.outputs.get('businessObjectives');
        System.assertEquals(3, objectives.size(), 'Should have 3 business objectives');
    }

    /**
     * @description Test with empty inputs map
     */
    @IsTest
    static void testExecute_EmptyInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with empty inputs');
    }

    /**
     * @description Test AI reasoning extraction
     */
    @IsTest
    static void testExecute_AIReasoningExtraction() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Test',
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"targetPersona": "User", ' +
            '"businessObjectives": ["Goal"], ' +
            '"keyMetrics": ["Metric"], ' +
            '"audienceLevel": "User", ' +
            '"reasoning": "This is the AI reasoning for the analysis"}';

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('This is the AI reasoning for the analysis', result.aiReasoning,
            'AI reasoning should be extracted');
    }

    /**
     * @description Test bulk execution with different contexts
     */
    @IsTest
    static void testExecute_BulkDifferentContexts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<String> contexts = new List<String>{
            'Sales analysis',
            'Customer success review',
            'Executive dashboard',
            'Support analytics'
        };

        AIServiceClient.mockResponse = '{"targetPersona": "User", ' +
            '"businessObjectives": ["Goal"], ' +
            '"keyMetrics": ["Metric"], ' +
            '"audienceLevel": "User", ' +
            '"reasoning": "Test"}';

        Test.startTest();
        Integer successCount = 0;
        for (String context : contexts) {
            PF_Run__c run = new PF_Run__c(
                Root_Object__c = 'Account',
                Sample_Record_Id__c = acc.Id,
                Business_Context__c = context,
                Status__c = 'Queued'
            );
            insert run;

            Map<String, Object> inputs = new Map<String, Object>{
                'businessContext' => context,
                'rootObject' => 'Account'
            };

            Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
            StageResult result = stage.execute(run.Id, inputs);
            if (result.status == 'Completed') {
                successCount++;
            }
        }
        Test.stopTest();

        System.assertEquals(4, successCount, 'All bulk executions should succeed');
    }

    /**
     * @description Test with special characters in business context
     */
    @IsTest
    static void testExecute_SpecialCharactersInContext() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'businessContext' => 'Context with "quotes" and \'apostrophes\' & special chars: <>&',
            'rootObject' => 'Account'
        };

        AIServiceClient.mockResponse = '{"targetPersona": "User", ' +
            '"businessObjectives": ["Goal"], ' +
            '"keyMetrics": ["Metric"], ' +
            '"audienceLevel": "User", ' +
            '"reasoning": "Test"}';

        Test.startTest();
        Stage02_StrategicProfiling stage = new Stage02_StrategicProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Should handle special characters');
    }
}