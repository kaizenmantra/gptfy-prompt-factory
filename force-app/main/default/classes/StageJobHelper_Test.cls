/**
 * @description Test class for StageJobHelper
 * Tests sanitization, serialization, and helper methods
 */
@IsTest
private class StageJobHelper_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Helper Account');
        insert testAccount;
    }

    @IsTest
    static void testSerializeOutputs_EmptyMap() {
        Test.startTest();
        String result = StageJobHelper.serializeOutputs(new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('{}', result, 'Empty map should return {}');
    }

    @IsTest
    static void testSerializeOutputs_NullMap() {
        Test.startTest();
        String result = StageJobHelper.serializeOutputs(null);
        Test.stopTest();

        System.assertEquals('{}', result, 'Null map should return {}');
    }

    @IsTest
    static void testSerializeOutputs_SimpleMap() {
        Map<String, Object> outputs = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => 123,
            'key3' => true
        };

        Test.startTest();
        String result = StageJobHelper.serializeOutputs(outputs);
        Test.stopTest();

        System.assert(result.contains('key1'), 'Should contain key1');
        System.assert(result.contains('value1'), 'Should contain value1');
        System.assert(result.contains('123'), 'Should contain 123');
    }

    @IsTest
    static void testSanitizeMapForStorage_DenylistedKeys() {
        // Test sanitizeMapForStorage directly for denylisted keys
        Map<String, Object> outputs = new Map<String, Object>{
            'recordData' => 'large data here',
            'normalKey' => 'normal value'
        };

        Test.startTest();
        Map<String, Object> result = StageJobHelper.sanitizeMapForStorage(outputs, 0);
        Test.stopTest();

        System.assert(String.valueOf(result.get('recordData')).contains('OMITTED'), 'Should omit denylisted keys');
        System.assertEquals('normal value', result.get('normalKey'), 'Should keep normal keys');
    }

    @IsTest
    static void testSanitizeMapForStorage_DepthLimit() {
        // Create deeply nested map
        Map<String, Object> level5 = new Map<String, Object>{ 'deep' => 'value' };
        Map<String, Object> level4 = new Map<String, Object>{ 'nested' => level5 };
        Map<String, Object> level3 = new Map<String, Object>{ 'nested' => level4 };
        Map<String, Object> level2 = new Map<String, Object>{ 'nested' => level3 };
        Map<String, Object> level1 = new Map<String, Object>{ 'nested' => level2 };

        Test.startTest();
        Map<String, Object> result = StageJobHelper.sanitizeMapForStorage(level1, 0);
        Test.stopTest();

        // Verify depth limiting works
        String serialized = JSON.serialize(result);
        System.assert(serialized.contains('DEPTH_LIMIT'), 'Should hit depth limit');
    }

    @IsTest
    static void testSanitizeValueForStorage_StringTruncation() {
        String longString = 'x'.repeat(10000);

        Test.startTest();
        Object result = StageJobHelper.sanitizeValueForStorage(longString, 0);
        Test.stopTest();

        System.assert(((String)result).length() <= 5000, 'String should be truncated');
        System.assert(((String)result).endsWith('...'), 'Should end with ellipsis');
    }

    @IsTest
    static void testSanitizeValueForStorage_ListTruncation() {
        List<Object> largeList = new List<Object>();
        for (Integer i = 0; i < 300; i++) {
            largeList.add('item' + i);
        }

        Test.startTest();
        Object result = StageJobHelper.sanitizeValueForStorage(largeList, 0);
        Test.stopTest();

        List<Object> resultList = (List<Object>) result;
        System.assert(resultList.size() <= 201, 'List should be truncated');
    }

    @IsTest
    static void testSanitizeValueForStorage_SObject() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Object result = StageJobHelper.sanitizeValueForStorage(acc, 0);
        Test.stopTest();

        System.assertEquals(acc.Id, result, 'SObject should be converted to ID');
    }

    @IsTest
    static void testSanitizeValueForStorage_Primitives() {
        Test.startTest();
        System.assertEquals(123, StageJobHelper.sanitizeValueForStorage(123, 0), 'Integer preserved');
        System.assertEquals(true, StageJobHelper.sanitizeValueForStorage(true, 0), 'Boolean preserved');
        System.assertEquals(12.5, StageJobHelper.sanitizeValueForStorage(12.5, 0), 'Decimal preserved');
        Test.stopTest();
    }

    @IsTest
    static void testTruncate_Normal() {
        Test.startTest();
        String result = StageJobHelper.truncate('Hello World', 5);
        Test.stopTest();

        System.assertEquals('He...', result, 'Should truncate to 5 chars with ellipsis');
    }

    @IsTest
    static void testTruncate_Null() {
        Test.startTest();
        String result = StageJobHelper.truncate(null, 100);
        Test.stopTest();

        System.assertEquals(null, result, 'Null should return null');
    }

    @IsTest
    static void testTruncate_ShortString() {
        Test.startTest();
        String result = StageJobHelper.truncate('Hi', 100);
        Test.stopTest();

        System.assertEquals('Hi', result, 'Short string should not be truncated');
    }

    @IsTest
    static void testTruncateJson() {
        String longJson = '{"key":"' + 'x'.repeat(200000) + '"}';

        Test.startTest();
        String result = StageJobHelper.truncateJson(longJson, 130000);
        Test.stopTest();

        System.assert(result.length() <= 130000, 'JSON should be truncated');
        System.assert(result.contains('truncated'), 'Should indicate truncation');
    }

    @IsTest
    static void testLoadInputsFromStage_NoStage() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Load Inputs',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Test.startTest();
        Map<String, Object> result = StageJobHelper.loadInputsFromStage(run.Id, 99);
        Test.stopTest();

        System.assert(result.isEmpty(), 'Should return empty map when stage not found');
    }

    @IsTest
    static void testLoadInputsFromStage_WithStage() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Load Inputs',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        PF_Run_Stage__c stage = new PF_Run_Stage__c(
            Run__c = run.Id,
            Stage_Number__c = 5,
            Stage_Name__c = 'Test Stage',
            Status__c = 'Completed',
            Output_Data__c = '{"testKey":"testValue"}'
        );
        insert stage;

        Test.startTest();
        Map<String, Object> result = StageJobHelper.loadInputsFromStage(run.Id, 5);
        Test.stopTest();

        System.assertEquals('testValue', result.get('testKey'), 'Should load outputs from stage');
    }

    @IsTest
    static void testIsStageSuccess() {
        StageResult completed = new StageResult('Test');
        completed.status = 'Completed';

        StageResult warning = new StageResult('Test');
        warning.status = 'Warning';

        StageResult failed = new StageResult('Test');
        failed.status = 'Failed';

        Test.startTest();
        System.assert(StageJobHelper.isStageSuccess(completed), 'Completed should be success');
        System.assert(StageJobHelper.isStageSuccess(warning), 'Warning should be success');
        System.assert(!StageJobHelper.isStageSuccess(failed), 'Failed should not be success');
        System.assert(!StageJobHelper.isStageSuccess(null), 'Null should not be success');
        Test.stopTest();
    }

    @IsTest
    static void testMarkRunFailed() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Mark Failed',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'In Progress',
            Current_Stage__c = 1
        );
        insert run;

        Test.startTest();
        StageJobHelper.markRunFailed(run.Id, 'Test error message');
        Test.stopTest();

        PF_Run__c updatedRun = [SELECT Status__c, Error_Message__c FROM PF_Run__c WHERE Id = :run.Id];
        System.assertEquals('Failed', updatedRun.Status__c, 'Status should be Failed');
        System.assertEquals('Test error message', updatedRun.Error_Message__c, 'Error message should be set');
    }

    @IsTest
    static void testUpdateProgress() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Update Progress',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'In Progress',
            Current_Stage__c = 1
        );
        insert run;

        Test.startTest();
        StageJobHelper.updateProgress(run.Id, 7);
        Test.stopTest();

        PF_Run__c updatedRun = [SELECT Current_Stage__c FROM PF_Run__c WHERE Id = :run.Id];
        System.assertEquals(7, updatedRun.Current_Stage__c, 'Stage should be updated to 7');
    }

    @IsTest
    static void testSaveStageResult() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Save Result',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'In Progress',
            Current_Stage__c = 1
        );
        insert run;

        StageResult result = new StageResult('Test Stage');
        result.status = 'Completed';
        result.outputs = new Map<String, Object>{ 'output1' => 'value1' };

        Test.startTest();
        StageJobHelper.saveStageResult(run.Id, 5, result);
        Test.stopTest();

        List<PF_Run_Stage__c> stages = [
            SELECT Stage_Number__c, Stage_Name__c, Status__c, Output_Data__c
            FROM PF_Run_Stage__c
            WHERE Run__c = :run.Id
        ];
        System.assertEquals(1, stages.size(), 'Should create one stage record');
        System.assertEquals(5, stages[0].Stage_Number__c, 'Stage number should be 5');
        System.assertEquals('Completed', stages[0].Status__c, 'Status should be Completed');
        System.assert(stages[0].Output_Data__c.contains('output1'), 'Outputs should be serialized');
    }

    @IsTest
    static void testSanitizeValueForStorage_Date() {
        Date testDate = Date.today();

        Test.startTest();
        Object result = StageJobHelper.sanitizeValueForStorage(testDate, 0);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Date should be converted');
        System.assert(result instanceof String, 'Date should be converted to string');
    }

    @IsTest
    static void testSanitizeValueForStorage_DateTime() {
        DateTime testDateTime = DateTime.now();

        Test.startTest();
        Object result = StageJobHelper.sanitizeValueForStorage(testDateTime, 0);
        Test.stopTest();

        System.assertNotEquals(null, result, 'DateTime should be converted');
        System.assert(result instanceof String, 'DateTime should be converted to string');
    }

    @IsTest
    static void testSanitizeValueForStorage_Id() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Object result = StageJobHelper.sanitizeValueForStorage(acc.Id, 0);
        Test.stopTest();

        System.assertEquals(String.valueOf(acc.Id), result, 'Id should be converted to string');
    }
}