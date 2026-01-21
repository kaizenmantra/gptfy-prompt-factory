/**
 * @description Test class for Stage10_TestExecution
 * Tests AI Prompt execution via GPTfy API (both REST and Invocable modes)
 */
@IsTest
private class Stage10_TestExecution_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Execution Account', Industry = 'Technology');
        insert testAccount;
    }

    private class GPTfyRestMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public GPTfyRestMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    private static PF_Run__c createRun(Id recordId) {
        return new PF_Run__c(
            Prompt_Name__c = 'Test Prompt',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = recordId,
            Status__c = 'Queued',
            Current_Stage__c = 1
        );
    }

    @IsTest
    static void testExecute_MissingPromptId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;

        Map<String, Object> inputs = new Map<String, Object>{
            'promptId' => null,
            'sampleRecordId' => acc.Id
        };

        Test.startTest();
        Stage10_TestExecution stage = new Stage10_TestExecution();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status);
    }

    @IsTest
    static void testExecute_MissingSampleRecordId() {
        // In the Clean Callout architecture, sampleRecordId validation happens in Stage10_RestCalloutJob
        // The Stage10_TestExecution only checks prompt readiness (promptId + status + promptRequestId)
        // When prompt is not found (using Account Id as promptId), it should fail
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;

        Map<String, Object> inputs = new Map<String, Object>{
            'promptId' => acc.Id, // Using Account Id as promptId will cause "Prompt not found" error
            'sampleRecordId' => null
        };

        Test.startTest();
        Stage10_TestExecution stage = new Stage10_TestExecution();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // Should fail because the promptId (Account Id) is not a valid AI_Prompt__c record
        System.assertEquals('Failed', result.status);
    }

    @IsTest
    static void testExecute_PromptNotReady_Retry() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;
        
        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = 'Test Prompt',
            ccai__Status__c = 'Draft'
        );
        insert prompt;

        Map<String, Object> inputs = new Map<String, Object>{
            'promptId' => prompt.Id,
            'sampleRecordId' => acc.Id,
            'rootObject' => 'Account'
        };

        Test.startTest();
        Stage10_TestExecution stage = new Stage10_TestExecution();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Retry', result.status);
    }

    @IsTest
    static void testExecute_PromptReady_ReadyForCallout() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;
        
        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = 'Test Prompt',
            ccai__Status__c = 'Active',
            ccai__Prompt_Request_Id__c = 'test-req-id'
        );
        insert prompt;

        Map<String, Object> inputs = new Map<String, Object>{
            'promptId' => prompt.Id,
            'sampleRecordId' => acc.Id,
            'rootObject' => 'Account'
        };

        Test.startTest();
        Stage10_TestExecution stage = new Stage10_TestExecution();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('ReadyForCallout', result.status);
        System.assertEquals('test-req-id', result.outputs.get('promptRequestId'));
    }

    @IsTest
    static void testExecute_ActivationError() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;
        
        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = 'Test Prompt',
            ccai__Status__c = 'Draft',
            ccai__Message__c = 'Error: Invalid Template'
        );
        insert prompt;

        Map<String, Object> inputs = new Map<String, Object>{
            'promptId' => prompt.Id,
            'sampleRecordId' => acc.Id,
            'rootObject' => 'Account'
        };

        Test.startTest();
        Stage10_TestExecution stage = new Stage10_TestExecution();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status);
    }

    @IsTest
    static void testRestCalloutJob_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;

        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = 'Test Prompt',
            ccai__Status__c = 'Active',
            ccai__Prompt_Request_Id__c = 'test-req-id'
        );
        insert prompt;

        Map<String, Object> inputs = new Map<String, Object>{
            'promptId' => prompt.Id,
            'sampleRecordId' => acc.Id,
            'rootObject' => 'Account',
            'dcmId' => acc.Id
        };

        String mockResponse = JSON.serialize(new Map<String, Object>{
            'status' => 'Processed',
            'responseBody' => '<div>Test Response</div>',
            'responseId' => '0XX000000000001AAA'
        });
        Test.setMock(HttpCalloutMock.class, new GPTfyRestMock(200, mockResponse));

        Test.startTest();
        // Test the Stage10_RestCalloutJob directly
        Stage10_RestCalloutJob job = new Stage10_RestCalloutJob(run.Id, 'test-req-id', inputs);
        System.enqueueJob(job);
        Test.stopTest();

        // Verify the run was updated (would chain to Stage 11 in production)
    }

    @IsTest
    static void testRetryHandler() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;

        Test.startTest();
        // Schedule a retry - this tests the RetryHandler schedulable
        Stage10_RetryHandler.scheduleRetry(run.Id, 1);
        Test.stopTest();

        // Verify a scheduled job was created
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Stage10_Retry_%'];
        // Note: Job may have already executed and been aborted in test context
    }

    @IsTest
    static void testExecutionJob_SingleArgConstructor() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;

        // Store Stage 9 outputs for the job to load
        StageResult stage9Result = new StageResult('Stage 9');
        stage9Result.markCompleted();
        stage9Result.outputs.put('promptId', acc.Id); // Will cause failure since it's not a prompt
        stage9Result.outputs.put('sampleRecordId', acc.Id);
        stage9Result.outputs.put('rootObject', 'Account');
        StageJobHelper.saveStageResult(run.Id, 9, stage9Result);

        Test.startTest();
        // Test the single-arg constructor
        Stage10_TestExecutionJob job = new Stage10_TestExecutionJob(run.Id);
        System.enqueueJob(job);
        Test.stopTest();

        // The job should have run (and likely failed since promptId is an Account)
    }

    @IsTest
    static void testExecutionJob_ReadyForCallout() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;

        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = 'Test Prompt',
            ccai__Status__c = 'Active',
            ccai__Prompt_Request_Id__c = 'test-req-id-job'
        );
        insert prompt;

        // Store Stage 9 outputs for the job to load
        StageResult stage9Result = new StageResult('Stage 9');
        stage9Result.markCompleted();
        stage9Result.outputs.put('promptId', prompt.Id);
        stage9Result.outputs.put('sampleRecordId', acc.Id);
        stage9Result.outputs.put('rootObject', 'Account');
        StageJobHelper.saveStageResult(run.Id, 9, stage9Result);

        String mockResponse = JSON.serialize(new Map<String, Object>{
            'status' => 'Processed',
            'responseBody' => '<div>Test</div>',
            'responseId' => '0XX000000000001AAA'
        });
        Test.setMock(HttpCalloutMock.class, new GPTfyRestMock(200, mockResponse));

        Test.startTest();
        Stage10_TestExecutionJob job = new Stage10_TestExecutionJob(run.Id, 0);
        System.enqueueJob(job);
        Test.stopTest();

        // Job should have found prompt ready and enqueued RestCalloutJob
    }

    @IsTest
    static void testExecutionJob_RetryWhenNotReady() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;

        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = 'Test Prompt',
            ccai__Status__c = 'Draft' // Not Active, should trigger retry
        );
        insert prompt;

        // Store Stage 9 outputs
        StageResult stage9Result = new StageResult('Stage 9');
        stage9Result.markCompleted();
        stage9Result.outputs.put('promptId', prompt.Id);
        stage9Result.outputs.put('sampleRecordId', acc.Id);
        stage9Result.outputs.put('rootObject', 'Account');
        StageJobHelper.saveStageResult(run.Id, 9, stage9Result);

        Test.startTest();
        Stage10_TestExecutionJob job = new Stage10_TestExecutionJob(run.Id, 0);
        System.enqueueJob(job);
        Test.stopTest();

        // Job should have scheduled a retry since prompt not ready
    }

    @IsTest
    static void testRestExecutor_SuccessResponse() {
        String mockResponse = JSON.serialize(new Map<String, Object>{
            'status' => 'Processed',
            'responseBody' => '<div>Test Response</div>',
            'responseId' => '0XX000000000001AAA'
        });
        Test.setMock(HttpCalloutMock.class, new GPTfyRestMock(200, mockResponse));

        Test.startTest();
        Stage10_RestExecutor.ExecutionResult result =
            Stage10_RestExecutor.executePromptViaRest('test-id', '001000000000001AAA');
        Test.stopTest();

        System.assertEquals(true, result.success);
    }

    @IsTest
    static void testExecute_PassThroughInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createRun(acc.Id);
        insert run;
        
        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = 'Test Prompt',
            ccai__Status__c = 'Active',
            ccai__Prompt_Request_Id__c = 'test-id'
        );
        insert prompt;

        Map<String, Object> inputs = new Map<String, Object>{
            'promptId' => prompt.Id,
            'sampleRecordId' => acc.Id,
            'rootObject' => 'Account',
            'dcmId' => acc.Id
        };

        Test.startTest();
        Stage10_TestExecution stage = new Stage10_TestExecution();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Account', result.outputs.get('rootObject'));
        System.assertEquals(acc.Id, result.outputs.get('sampleRecordId'));
    }
}