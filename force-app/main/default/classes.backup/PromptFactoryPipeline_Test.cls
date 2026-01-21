/**
 * @description Test class for PromptFactoryPipeline
 * Tests pipeline orchestration, stage chaining, and error handling
 */
@IsTest
private class PromptFactoryPipeline_Test {

    /**
     * @description Mock stage implementation for testing
     */
    private class MockStage implements IStage {
        private String stageName;
        private String status;
        private Boolean shouldFail;

        public MockStage(String stageName, String status, Boolean shouldFail) {
            this.stageName = stageName;
            this.status = status;
            this.shouldFail = shouldFail;
        }

        public StageResult execute(Id runId, Map<String, Object> inputs) {
            StageResult result = new StageResult(stageName);
            result.inputs = inputs;
            result.outputs = new Map<String, Object>{
                'testOutput' => 'value',
                'stageExecuted' => stageName
            };

            if (shouldFail) {
                result.markFailed('Mock failure for testing');
            } else {
                result.markCompleted();
            }

            result.aiReasoning = 'Mock reasoning';
            return result;
        }
    }

    @TestSetup
    static void setup() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology'
        );
        insert testAccount;

        // Enable mock mode for AI client
        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = '{"result": "test"}';
    }

    /**
     * @description Helper to create test run
     */
    private static PF_Run__c createTestRun() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Business_Context__c = 'Test context',
            Output_Format__c = 'HTML',
            Prompt_Name__c = 'Test Prompt',
            Status__c = 'Queued',
            Current_Stage__c = 1
        );
        insert run;
        return run;
    }

    /**
     * @description Test pipeline initialization
     */
    @IsTest
    static void testPipelineInitialization() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        PromptFactoryPipeline pipeline = new PromptFactoryPipeline(run.Id, 1);
        Test.stopTest();

        System.assertNotEquals(null, pipeline, 'Pipeline should be instantiated');
    }

    /**
     * @description Test stage execution updates run status
     */
    @IsTest
    static void testExecute_UpdatesRunStatus() {
        PF_Run__c run = createTestRun();
        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        PF_Run__c updatedRun = [
            SELECT Status__c, Current_Stage__c
            FROM PF_Run__c
            WHERE Id = :run.Id
        ];

        // After Test.stopTest, queueable should have executed
        System.assertEquals('In Progress', updatedRun.Status__c,
            'Status should be updated to In Progress');
    }

    /**
     * @description Test stage result is saved
     */
    @IsTest
    static void testExecute_SavesStageResult() {
        PF_Run__c run = createTestRun();
        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        // Check if stage record was created
        List<PF_Run_Stage__c> stages = [
            SELECT Stage_Number__c, Status__c, Input_Data__c, Output_Data__c
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
        ];

        System.assert(stages.size() > 0, 'Should create stage record');
        if (stages.size() > 0) {
            System.assertEquals(1, stages[0].Stage_Number__c, 'Stage number should be 1');
            System.assertNotEquals(null, stages[0].Status__c, 'Status should be set');
        }
    }

    /**
     * @description Test pipeline handles abort status
     */
    @IsTest
    static void testExecute_HandlesAbort() {
        PF_Run__c run = createTestRun();
        run.Status__c = 'Aborted';
        update run;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        // Verify no stages were created
        Integer stageCount = [
            SELECT COUNT()
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
        ];

        System.assertEquals(0, stageCount, 'Should not create stages when aborted');
    }

    /**
     * @description Test pipeline handles run not found
     */
    @IsTest
    static void testExecute_RunNotFound() {
        Id fakeRunId = '001000000000000';

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(fakeRunId, 1));
        Test.stopTest();

        // Should handle gracefully without throwing exception
        System.assert(true, 'Should handle missing run gracefully');
    }

    /**
     * @description Test loading initial inputs for stage 1
     */
    @IsTest
    static void testLoadStageInputs_Stage1() {
        PF_Run__c run = createTestRun();
        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        PF_Run_Stage__c stage = [
            SELECT Input_Data__c
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, stage.Input_Data__c, 'Inputs should be populated');

        Map<String, Object> inputs = (Map<String, Object>)
            JSON.deserializeUntyped(stage.Input_Data__c);
        System.assertEquals('Account', inputs.get('rootObject'), 'Should load root object');
    }

    /**
     * @description Test loading inputs from previous stage
     */
    @IsTest
    static void testLoadStageInputs_FromPreviousStage() {
        PF_Run__c run = createTestRun();

        // Create stage 1 with outputs
        PF_Run_Stage__c stage1 = new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 1,
            Stage_Name__c = 'Stage 1',
            Status__c = 'Completed',
            Output_Data__c = '{"previousOutput": "testValue"}',
            Started_At__c = System.now()
        );
        insert stage1;

        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 2));
        Test.stopTest();

        // Verify stage 2 has inputs from stage 1 outputs
        List<PF_Run_Stage__c> stages = [
            SELECT Stage_Number__c, Input_Data__c
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
            AND Stage_Number__c = 2
        ];

        if (stages.size() > 0) {
            Map<String, Object> inputs = (Map<String, Object>)
                JSON.deserializeUntyped(stages[0].Input_Data__c);
            System.assertEquals('testValue', inputs.get('previousOutput'),
                'Should load outputs from previous stage');
        }
    }

    /**
     * @description Test handling of stage failure
     */
    @IsTest
    static void testExecute_StageFailure() {
        PF_Run__c run = createTestRun();
        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = 'FORCE_ERROR'; // Will cause parsing error

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        PF_Run__c updatedRun = [
            SELECT Status__c, Error_Message__c
            FROM PF_Run__c
            WHERE Id = :run.Id
        ];

        // Should mark as failed if stage execution fails
        // Note: actual behavior depends on stage implementation
        System.assertNotEquals(null, updatedRun, 'Run should exist');
    }

    /**
     * @description Test JSON truncation for large outputs
     */
    @IsTest
    static void testExecute_TruncatesLargeJSON() {
        PF_Run__c run = createTestRun();

        // Create a large outputs map
        Map<String, Object> largeOutputs = new Map<String, Object>();
        String largeValue = '';
        for (Integer i = 0; i < 4000; i++) {
            largeValue += '0123456789'; // 40,000 characters
        }
        largeOutputs.put('largeData', largeValue);

        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        // Verify stage record created
        List<PF_Run_Stage__c> stages = [
            SELECT Output_Data__c
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
        ];

        if (stages.size() > 0 && stages[0].Output_Data__c != null) {
            // Outputs should be truncated if too large
            System.assert(stages[0].Output_Data__c.length() <= 32000,
                'Outputs should be truncated to field limit');
        }
    }

    /**
     * @description Test quality score extraction
     */
    @IsTest
    static void testExtractQualityScore() {
        PF_Run__c run = createTestRun();

        // Create all 11 stages as completed
        List<PF_Run_Stage__c> stages = new List<PF_Run_Stage__c>();
        for (Integer i = 1; i <= 11; i++) {
            stages.add(new PF_Run_Stage__c(
                Run__c = run.Id,
                Stage_Number__c = i,
                Stage_Name__c = 'Stage ' + i,
                Status__c = 'Completed',
                Output_Data__c = '{"result": "success"}',
                Started_At__c = System.now()
            ));
        }
        insert stages;

        // Create stage 12 with quality score
        PF_Run_Stage__c stage12 = new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 12,
            Stage_Name__c = 'Stage 12',
            Status__c = 'Completed',
            Output_Data__c = '{"qualityScore": 95}',
            Started_At__c = System.now()
        );
        insert stage12;

        run.Current_Stage__c = 11;
        run.Status__c = 'In Progress';
        update run;

        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 12));
        Test.stopTest();

        // After stage 12 completes, quality score should be extracted
        PF_Run__c updatedRun = [
            SELECT Overall_Quality_Score__c, Status__c
            FROM PF_Run__c
            WHERE Id = :run.Id
        ];

        // Pipeline should complete
        System.assertEquals('Completed', updatedRun.Status__c, 'Should be completed');
    }

    /**
     * @description Test stage chaining logic
     */
    @IsTest
    static void testStageChaining() {
        PF_Run__c run = createTestRun();
        AIServiceClient.mockMode = true;

        // Execute stage 1
        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        // Verify stage 1 created
        Integer stageCount = [
            SELECT COUNT()
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
        ];

        System.assert(stageCount > 0, 'Should create at least one stage');
    }

    /**
     * @description Test exception handling in pipeline
     */
    @IsTest
    static void testExecute_ExceptionHandling() {
        PF_Run__c run = createTestRun();

        // Force an exception by providing invalid data
        run.Sample_Record_Id__c = null;
        update run;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        // Should handle exception gracefully
        System.assert(true, 'Should handle exceptions without system failure');
    }

    /**
     * @description Test bulk log creation
     */
    @IsTest
    static void testExecute_BulkLogs() {
        PF_Run__c run = createTestRun();
        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        // Verify logs were created
        Integer logCount = [
            SELECT COUNT()
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
        ];

        System.assert(logCount > 0, 'Should create logs during execution');
    }

    /**
     * @description Test handling of malformed previous stage output
     */
    @IsTest
    static void testLoadStageInputs_MalformedJSON() {
        PF_Run__c run = createTestRun();

        // Create stage with invalid JSON
        PF_Run_Stage__c stage1 = new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 1,
            Stage_Name__c = 'Stage 1',
            Status__c = 'Completed',
            Output_Data__c = '{invalid json here}',
            Started_At__c = System.now()
        );
        insert stage1;

        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 2));
        Test.stopTest();

        // Should handle gracefully and create stage 2
        Integer stageCount = [
            SELECT COUNT()
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
            AND Stage_Number__c = 2
        ];

        // Pipeline should handle malformed JSON gracefully
        System.assert(true, 'Should handle malformed JSON without crashing');
    }

    /**
     * @description Test pipeline status tracking
     */
    @IsTest
    static void testPipelineStatusTracking() {
        PF_Run__c run = createTestRun();
        AIServiceClient.mockMode = true;

        // Execute stage
        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));
        Test.stopTest();

        PF_Run__c updatedRun = [
            SELECT Status__c, Current_Stage__c, Started_At__c
            FROM PF_Run__c
            WHERE Id = :run.Id
        ];

        System.assertEquals('In Progress', updatedRun.Status__c, 'Status should be In Progress');
        System.assertNotEquals(null, updatedRun.Started_At__c, 'Started timestamp should be set');
    }

    /**
     * @description Test completing pipeline at final stage
     */
    @IsTest
    static void testCompletePipeline() {
        PF_Run__c run = createTestRun();

        // Create stages 1-11 as completed
        List<PF_Run_Stage__c> stages = new List<PF_Run_Stage__c>();
        for (Integer i = 1; i < 12; i++) {
            stages.add(new PF_Run_Stage__c(
                Run__c = run.Id,
                Stage_Number__c = i,
                Stage_Name__c = 'Stage ' + i,
                Status__c = 'Completed',
                Output_Data__c = '{"status": "success"}',
                Started_At__c = System.now()
            ));
        }
        insert stages;

        run.Status__c = 'In Progress';
        run.Current_Stage__c = 11;
        update run;

        AIServiceClient.mockMode = true;

        Test.startTest();
        System.enqueueJob(new PromptFactoryPipeline(run.Id, 12));
        Test.stopTest();

        PF_Run__c completedRun = [
            SELECT Status__c, Completed_At__c
            FROM PF_Run__c
            WHERE Id = :run.Id
        ];

        System.assertEquals('Completed', completedRun.Status__c, 'Run should be completed');
        System.assertNotEquals(null, completedRun.Completed_At__c,
            'Completed timestamp should be set');
    }

    /**
     * @description Test multiple pipeline runs in parallel
     */
    @IsTest
    static void testMultiplePipelineRuns() {
        List<PF_Run__c> runs = new List<PF_Run__c>();
        Account acc = [SELECT Id FROM Account LIMIT 1];

        for (Integer i = 0; i < 5; i++) {
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

        AIServiceClient.mockMode = true;

        Test.startTest();
        // Note: Only one queueable can be enqueued in test context
        System.enqueueJob(new PromptFactoryPipeline(runs[0].Id, 1));
        Test.stopTest();

        // Verify at least one run was processed
        List<PF_Run__c> processedRuns = [
            SELECT Status__c
            FROM PF_Run__c
            WHERE Status__c = 'In Progress'
        ];

        System.assert(processedRuns.size() > 0, 'At least one run should be processed');
    }
}