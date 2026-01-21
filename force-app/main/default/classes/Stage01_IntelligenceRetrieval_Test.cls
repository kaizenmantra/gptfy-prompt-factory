/**
 * @description Test class for Stage01_IntelligenceRetrieval
 * Tests sample record fetching, business context loading, and error handling
 */
@IsTest
private class Stage01_IntelligenceRetrieval_Test {

    @TestSetup
    static void setup() {
        // Create test Account with various field types
        Account testAccount = new Account(
            Name = 'Test Account for Intelligence Retrieval',
            Industry = 'Technology',
            AnnualRevenue = 1000000,
            NumberOfEmployees = 50,
            Phone = '555-0123',
            Website = 'www.testaccount.com',
            BillingCity = 'San Francisco',
            BillingState = 'CA'
        );
        insert testAccount;
    }

    /**
     * @description Helper to create test run
     */
    private static PF_Run__c createTestRun(Id sampleRecordId) {
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = sampleRecordId,
            Business_Context__c = 'Create a comprehensive summary for sales executives',
            Output_Format__c = 'HTML',
            Prompt_Name__c = 'Account Summary Prompt',
            Status__c = 'Queued',
            Current_Stage__c = 1
        );
        insert run;
        return run;
    }

    /**
     * @description Test successful intelligence retrieval
     */
    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('rootObject'), 'Root object should be in outputs');
        System.assertEquals('Account', result.outputs.get('rootObject'), 'Root object should be Account');
        System.assertNotEquals(null, result.outputs.get('recordData'), 'Record data should be populated');
        System.assertNotEquals(null, result.outputs.get('businessContext'), 'Business context should be populated');
        System.assertEquals(acc.Id, result.outputs.get('sampleRecordId'), 'Sample record ID should match');
    }

    /**
     * @description Test record data contains expected fields
     */
    @IsTest
    static void testExecute_RecordDataFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        Map<String, Object> recordData = (Map<String, Object>) result.outputs.get('recordData');
        System.assertNotEquals(null, recordData, 'Record data map should exist');
        System.assert(recordData.containsKey('Id'), 'Should include Id field');
        System.assert(recordData.containsKey('Name'), 'Should include Name field');
        System.assert(recordData.size() > 5, 'Should include multiple fields');
    }

    /**
     * @description Test with null run ID
     */
    @IsTest
    static void testExecute_NullRunId() {
        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(null, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null run ID');
        System.assertNotEquals(null, result.errorMessage, 'Error message should be set');
    }

    /**
     * @description Test with invalid run ID
     */
    @IsTest
    static void testExecute_InvalidRunId() {
        Id fakeRunId = '001000000000000AAA';

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(fakeRunId, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with invalid run ID');
        System.assert(result.errorMessage.contains('Run record not found'), 'Should indicate run not found');
    }

    /**
     * @description Test with null sample record ID
     */
    @IsTest
    static void testExecute_NullSampleRecordId() {
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = null,
            Business_Context__c = 'Test context',
            Status__c = 'Queued'
        );
        insert run;

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null sample record ID');
        System.assertNotEquals(null, result.errorMessage, 'Error message should be set');
    }

    /**
     * @description Test with invalid sample record ID
     */
    @IsTest
    static void testExecute_InvalidSampleRecordId() {
        Id fakeAccountId = '001000000000000AAA';
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = fakeAccountId,
            Business_Context__c = 'Test context',
            Status__c = 'Queued'
        );
        insert run;

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with invalid record ID');
        System.assert(result.errorMessage.contains('Record not found'), 'Should indicate record not found');
    }

    /**
     * @description Test with blank object name
     */
    @IsTest
    static void testExecute_BlankObjectName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = '',
            Sample_Record_Id__c = acc.Id,
            Business_Context__c = 'Test context',
            Status__c = 'Queued'
        );
        insert run;

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with blank object name');
        System.assertNotEquals(null, result.errorMessage, 'Error message should be set');
    }

    /**
     * @description Test with invalid object name
     */
    @IsTest
    static void testExecute_InvalidObjectName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'InvalidObject__c',
            Sample_Record_Id__c = acc.Id,
            Business_Context__c = 'Test context',
            Status__c = 'Queued'
        );
        insert run;

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with invalid object name');
        System.assert(result.errorMessage.contains('Object not found'), 'Should indicate object not found');
    }

    /**
     * @description Test with null business context
     */
    @IsTest
    static void testExecute_NullBusinessContext() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Business_Context__c = null,
            Output_Format__c = 'HTML',
            Status__c = 'Queued'
        );
        insert run;

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        // Should complete successfully even with null business context
        System.assertEquals('Completed', result.status, 'Stage should complete with null business context');
        System.assertEquals(null, result.outputs.get('businessContext'), 'Business context should be null');
    }

    /**
     * @description Test recordDataJson is valid JSON
     */
    @IsTest
    static void testExecute_RecordDataJsonValidity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        String recordDataJson = (String) result.outputs.get('recordDataJson');
        System.assertNotEquals(null, recordDataJson, 'recordDataJson should be populated');

        // Verify it's valid JSON by deserializing
        Boolean jsonValid = false;
        try {
            JSON.deserializeUntyped(recordDataJson);
            jsonValid = true;
        } catch (Exception e) {
            System.assert(false, 'recordDataJson should be valid JSON');
        }
        System.assert(jsonValid, 'recordDataJson should be valid JSON');
    }

    /**
     * @description Test with Contact object (different object type)
     */
    @IsTest
    static void testExecute_ContactObject() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com'
        );
        insert testContact;

        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Contact',
            Sample_Record_Id__c = testContact.Id,
            Business_Context__c = 'Contact analysis',
            Output_Format__c = 'HTML',
            Status__c = 'Queued'
        );
        insert run;

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete for Contact object');
        System.assertEquals('Contact', result.outputs.get('rootObject'), 'Root object should be Contact');
        Map<String, Object> recordData = (Map<String, Object>) result.outputs.get('recordData');
        System.assert(recordData.containsKey('LastName'), 'Should include LastName field');
    }

    /**
     * @description Test output format is preserved
     */
    @IsTest
    static void testExecute_OutputFormatPreserved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('HTML', result.outputs.get('outputFormat'), 'Output format should be preserved');
    }

    /**
     * @description Test inputs are preserved in result
     */
    @IsTest
    static void testExecute_InputsPreserved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = createTestRun(acc.Id);

        Map<String, Object> inputs = new Map<String, Object>{
            'testKey' => 'testValue'
        };

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals(inputs, result.inputs, 'Inputs should be preserved in result');
    }

    /**
     * @description Test bulk execution with multiple runs (simulated)
     */
    @IsTest
    static void testExecute_BulkSimulation() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                Name = 'Bulk Test Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert accounts;

        List<PF_Run__c> runs = new List<PF_Run__c>();
        for (Account acc : accounts) {
            runs.add(new PF_Run__c(
                Root_Object__c = 'Account',
                Sample_Record_Id__c = acc.Id,
                Business_Context__c = 'Test context ' + acc.Name,
                Status__c = 'Queued'
            ));
        }
        insert runs;

        Test.startTest();
        Stage01_IntelligenceRetrieval stage = new Stage01_IntelligenceRetrieval();
        Integer successCount = 0;
        for (PF_Run__c run : runs) {
            StageResult result = stage.execute(run.Id, new Map<String, Object>());
            if (result.status == 'Completed') {
                successCount++;
            }
        }
        Test.stopTest();

        System.assertEquals(5, successCount, 'All bulk executions should succeed');
    }
}