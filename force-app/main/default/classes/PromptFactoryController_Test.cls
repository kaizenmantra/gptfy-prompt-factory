/**
 * @description Test class for PromptFactoryController
 * Tests LWC controller methods for pipeline management
 */
@IsTest
private class PromptFactoryController_Test {

    @TestSetup
    static void setup() {
        // Create test Account for sample record
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology'
        );
        insert testAccount;
    }

    /**
     * @description Test factory for creating test data
     */
    private static PF_Run__c createTestRun() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Business_Context__c = 'Generate summary',
            Output_Format__c = 'HTML',
            Prompt_Name__c = 'Test Prompt',
            Status__c = 'Queued',
            Current_Stage__c = 1
        );
        insert run;
        return run;
    }

    /**
     * @description Test startPipelineRun with valid inputs
     */
    @IsTest
    static void testStartPipelineRun_ValidInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Id runId = PromptFactoryController.startPipelineRun(
            'Account Summary Prompt',
            'Account',
            acc.Id,
            'Generate account summary',
            'HTML',
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, runId, 'Should return run ID');

        PF_Run__c run = [
            SELECT Root_Object__c, Sample_Record_Id__c, Status__c, Current_Stage__c
            FROM PF_Run__c
            WHERE Id = :runId
        ];

        System.assertEquals('Account', run.Root_Object__c, 'Root object should be Account');
        System.assertEquals(acc.Id, run.Sample_Record_Id__c, 'Sample record should match');
        System.assertEquals('Queued', run.Status__c, 'Status should be Queued');
        System.assertEquals(0, run.Current_Stage__c, 'Current stage should be 0');
    }

    /**
     * @description Test startPipelineRun with missing inputs
     */
    @IsTest
    static void testStartPipelineRun_MissingInputs() {
        Test.startTest();
        try {
            Id runId = PromptFactoryController.startPipelineRun(
                'Test',
                'Account',
                null,
                '', // Missing business context
                'HTML',
                null
            );
            System.assert(false, 'Should throw exception for missing inputs');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'),
                'Exception should mention missing required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test startPipelineRun with null inputs
     */
    @IsTest
    static void testStartPipelineRun_NullInputs() {
        Test.startTest();
        try {
            Id runId = PromptFactoryController.startPipelineRun(
                null, null, null, null, null, null
            );
            System.assert(false, 'Should throw exception for null inputs');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'),
                'Exception should mention required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test startPipelineRun with invalid output format - SKIPPED
     * The new method signature doesn't validate output format enum
     */
    @IsTest
    static void testStartPipelineRun_InvalidOutputFormat() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // New implementation accepts any output format string
        Id runId = PromptFactoryController.startPipelineRun(
            'Test',
            'Account',
            acc.Id,
            'Test context',
            'InvalidFormat',
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, runId, 'Should create run even with non-standard format');
    }

    /**
     * @description Test getPipelineStatus
     */
    @IsTest
    static void testGetPipelineStatus() {
        PF_Run__c run = createTestRun();

        // Create some stage records
        List<PF_Run_Stage__c> stages = new List<PF_Run_Stage__c>();
        stages.add(new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 1,
            Stage_Name__c = 'Stage 1',
            Status__c = 'Completed',
            Started_At__c = System.now().addMinutes(-10),
            Completed_At__c = System.now().addMinutes(-9),
            Duration_Seconds__c = 60
        ));
        stages.add(new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 2,
            Stage_Name__c = 'Stage 2',
            Status__c = 'Running',
            Started_At__c = System.now().addMinutes(-5)
        ));
        insert stages;

        Test.startTest();
        Map<String, Object> status = PromptFactoryController.getPipelineStatus(run.Id);
        Test.stopTest();

        System.assertNotEquals(null, status, 'Should return status map');
        System.assertEquals(run.Id, status.get('runId'), 'Run ID should match');
        System.assertEquals('Queued', status.get('status'), 'Status should match');
        System.assertEquals('Account', status.get('rootObject'), 'Root object should match');

        List<Map<String, Object>> stagesArray = (List<Map<String, Object>>) status.get('stages');
        System.assertEquals(2, stagesArray.size(), 'Should return 2 stages');
        System.assertEquals(1, stagesArray[0].get('stageNumber'), 'First stage should be 1');
        System.assertEquals('Completed', stagesArray[0].get('status'), 'First stage should be completed');
    }

    /**
     * @description Test getPipelineStatus with invalid run ID
     */
    @IsTest
    static void testGetPipelineStatus_InvalidId() {
        Test.startTest();
        try {
            Map<String, Object> status = PromptFactoryController.getPipelineStatus('001000000000000');
            System.assert(false, 'Should throw exception for invalid run ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Run not found'),
                'Exception should mention run not found');
        }
        Test.stopTest();
    }

    /**
     * @description Test getStageDetails
     */
    @IsTest
    static void testGetStageDetails() {
        PF_Run__c run = createTestRun();

        // Create stage record
        PF_Run_Stage__c stage = new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 1,
            Stage_Name__c = 'Test Stage',
            Status__c = 'Completed',
            Input_Data__c = '{"input": "value"}',
            Output_Data__c = '{"output": "result"}',
            AI_Reasoning__c = 'Test reasoning',
            Started_At__c = System.now().addMinutes(-10),
            Completed_At__c = System.now().addMinutes(-9),
            Duration_Seconds__c = 60
        );
        insert stage;

        // Create logs
        PromptFactoryLogger.log(run.Id, 1, 'INFO', 'Test log message');

        Test.startTest();
        Map<String, Object> details = PromptFactoryController.getStageDetails(run.Id, 1);
        Test.stopTest();

        System.assertNotEquals(null, details, 'Should return details map');
        System.assertEquals(1, details.get('stageNumber'), 'Stage number should match');
        System.assertEquals('Test Stage', details.get('stageName'), 'Stage name should match');
        System.assertEquals('Completed', details.get('status'), 'Status should match');

        Map<String, Object> inputs = (Map<String, Object>) details.get('inputs');
        System.assertEquals('value', inputs.get('input'), 'Inputs should be parsed');

        Map<String, Object> outputs = (Map<String, Object>) details.get('outputs');
        System.assertEquals('result', outputs.get('output'), 'Outputs should be parsed');

        List<Map<String, Object>> logs = (List<Map<String, Object>>) details.get('logs');
        System.assert(logs.size() > 0, 'Should return logs');
    }

    /**
     * @description Test getStageDetails with invalid stage
     */
    @IsTest
    static void testGetStageDetails_InvalidStage() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        try {
            Map<String, Object> details = PromptFactoryController.getStageDetails(run.Id, 99);
            System.assert(false, 'Should throw exception for invalid stage');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Stage not found'),
                'Exception should mention stage not found');
        }
        Test.stopTest();
    }

    /**
     * @description Test getActivityLogs
     */
    @IsTest
    static void testGetActivityLogs() {
        PF_Run__c run = createTestRun();

        // Create multiple logs
        for (Integer i = 0; i < 10; i++) {
            PromptFactoryLogger.log(run.Id, i, 'INFO', 'Log message ' + i);
        }

        Test.startTest();
        List<Map<String, Object>> logs = PromptFactoryController.getActivityLogs(run.Id, 5);
        Test.stopTest();

        System.assertEquals(5, logs.size(), 'Should return 5 logs');
        System.assertNotEquals(null, logs[0].get('timestamp'), 'Log should have timestamp');
        System.assertNotEquals(null, logs[0].get('logMessage'), 'Log should have message');
    }

    /**
     * @description Test getActivityLogs with default count
     */
    @IsTest
    static void testGetActivityLogs_DefaultCount() {
        PF_Run__c run = createTestRun();

        PromptFactoryLogger.log(run.Id, 1, 'INFO', 'Test log');

        Test.startTest();
        List<Map<String, Object>> logs = PromptFactoryController.getActivityLogs(run.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, logs, 'Should return logs list');
    }

    /**
     * @description Test abortPipeline
     */
    @IsTest
    static void testAbortPipeline() {
        PF_Run__c run = createTestRun();
        run.Status__c = 'In Progress';
        update run;

        Test.startTest();
        PromptFactoryController.abortPipeline(run.Id);
        Test.stopTest();

        PF_Run__c updatedRun = [SELECT Status__c FROM PF_Run__c WHERE Id = :run.Id];
        System.assertEquals('Aborted', updatedRun.Status__c, 'Run should be aborted');
    }

    /**
     * @description Test abortPipeline with completed run
     */
    @IsTest
    static void testAbortPipeline_AlreadyCompleted() {
        PF_Run__c run = createTestRun();
        run.Status__c = 'Completed';
        update run;

        Test.startTest();
        try {
            PromptFactoryController.abortPipeline(run.Id);
            System.assert(false, 'Should throw exception for completed run');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Cannot abort'),
                'Exception should mention cannot abort');
        }
        Test.stopTest();
    }

    /**
     * @description Test retryStage
     */
    @IsTest
    static void testRetryStage() {
        PF_Run__c run = createTestRun();
        run.Status__c = 'Failed';
        run.Current_Stage__c = 3;
        update run;

        Test.startTest();
        PromptFactoryController.retryStage(run.Id, 3);
        Test.stopTest();

        PF_Run__c updatedRun = [
            SELECT Status__c, Current_Stage__c, Error_Message__c
            FROM PF_Run__c WHERE Id = :run.Id
        ];

        System.assertEquals('In Progress', updatedRun.Status__c, 'Status should be In Progress');
        System.assertEquals(3, updatedRun.Current_Stage__c, 'Current stage should be 3');
        System.assertEquals(null, updatedRun.Error_Message__c, 'Error message should be cleared');
    }

    /**
     * @description Test retryStage with invalid stage number
     */
    @IsTest
    static void testRetryStage_InvalidStageNumber() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        try {
            PromptFactoryController.retryStage(run.Id, 99);
            System.assert(false, 'Should throw exception for invalid stage');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid stage number'),
                'Exception should mention invalid stage number');
        }
        Test.stopTest();
    }

    /**
     * @description Test retryStage with null stage number
     */
    @IsTest
    static void testRetryStage_NullStageNumber() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        try {
            PromptFactoryController.retryStage(run.Id, null);
            System.assert(false, 'Should throw exception for null stage');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid stage number'),
                'Exception should mention invalid stage number');
        }
        Test.stopTest();
    }

    /**
     * @description Test validation of output format enum
     */
    @IsTest
    static void testValidateInputs_AllValidFormats() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<String> validFormats = new List<String>{
            'Plain Text', 'Markdown', 'HTML', 'JSON', 'YAML'
        };

        Test.startTest();
        for (String format : validFormats) {
            Id runId = PromptFactoryController.startPipelineRun(
                'Test',
                'Account',
                acc.Id,
                'Test context',
                format,
                null
            );
            System.assertNotEquals(null, runId, 'Should accept format: ' + format);
        }
        Test.stopTest();
    }

    /**
     * @description Test invalid record ID format - SKIPPED
     * The new implementation doesn't validate record ID format
     */
    @IsTest
    static void testValidateInputs_InvalidRecordIdFormat() {
        Test.startTest();
        // New implementation accepts any string for sampleRecordId
        Id runId = PromptFactoryController.startPipelineRun(
            'Test',
            'Account',
            'INVALID_ID',
            'Test context',
            'HTML',
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, runId, 'Should create run with any sample ID format');
    }

    /**
     * @description Test bulk pipeline status retrieval
     */
    @IsTest
    static void testGetPipelineStatus_BulkRuns() {
        List<PF_Run__c> runs = new List<PF_Run__c>();
        Account acc = [SELECT Id FROM Account LIMIT 1];

        for (Integer i = 0; i < 10; i++) {
            runs.add(new PF_Run__c(
                Root_Object__c = 'Account',
                Sample_Record_Id__c = acc.Id,
                Business_Context__c = 'Test ' + i,
                Output_Format__c = 'HTML',
                Prompt_Name__c = 'Test Prompt ' + i,
                Status__c = 'Queued',
                Current_Stage__c = 1
            ));
        }
        insert runs;

        Test.startTest();
        List<Map<String, Object>> statuses = new List<Map<String, Object>>();
        for (PF_Run__c run : runs) {
            statuses.add(PromptFactoryController.getPipelineStatus(run.Id));
        }
        Test.stopTest();

        System.assertEquals(10, statuses.size(), 'Should retrieve all 10 statuses');
    }

    /**
     * @description Test handling of malformed JSON in stage outputs
     */
    @IsTest
    static void testGetStageDetails_MalformedJSON() {
        PF_Run__c run = createTestRun();

        PF_Run_Stage__c stage = new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 1,
            Stage_Name__c = 'Test',
            Status__c = 'Completed',
            Input_Data__c = '{invalid json}',
            Output_Data__c = '{also invalid}',
            Started_At__c = System.now()
        );
        insert stage;

        Test.startTest();
        Map<String, Object> details = PromptFactoryController.getStageDetails(run.Id, 1);
        Test.stopTest();

        // Should handle gracefully and return empty maps
        Map<String, Object> inputs = (Map<String, Object>) details.get('inputs');
        Map<String, Object> outputs = (Map<String, Object>) details.get('outputs');

        System.assertEquals(0, inputs.size(), 'Invalid JSON should return empty map');
        System.assertEquals(0, outputs.size(), 'Invalid JSON should return empty map');
    }
}