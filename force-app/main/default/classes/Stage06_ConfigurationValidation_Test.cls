/**
 * @description Test class for Stage06_ConfigurationValidation
 * Tests CRUD/FLS validation and configuration checks
 */
@IsTest
private class Stage06_ConfigurationValidation_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Validation Account', Industry = 'Technology');
        insert testAccount;
    }

    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Id', 'Name', 'Industry'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertNotEquals('Failed', result.status, 'Stage should not fail');
        System.assertNotEquals(null, result.outputs.get('validationChecklist'), 'Validation checklist should exist');
    }

    @IsTest
    static void testExecute_NullSelectedFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> inputs = new Map<String, Object>{'selectedFields' => null};

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null fields');
    }

    @IsTest
    static void testExecute_ValidationCounts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Id', 'Name'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Integer totalChecks = (Integer) result.outputs.get('totalChecks');
        Integer passedChecks = (Integer) result.outputs.get('passedChecks');
        System.assert(totalChecks > 0, 'Should have validation checks');
        System.assert(passedChecks >= 0, 'Should have passed checks count');
    }

    @IsTest
    static void testExecute_ValidationSummary() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Id', 'Name'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String summary = (String) result.outputs.get('validationSummary');
        System.assertNotEquals(null, summary, 'Validation summary should exist');
        System.assert(summary.contains('validation checks'), 'Summary should contain validation text');
    }

    @IsTest
    static void testExecute_AllValidationsPassedFlag() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Id', 'Name'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertNotEquals(null, result.outputs.get('allValidationsPassed'), 'All validations flag should exist');
    }

    @IsTest
    static void testExecute_InvalidField() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'InvalidField__c'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // Should complete with warnings
        Integer failedChecks = (Integer) result.outputs.get('failedChecks');
        System.assert(failedChecks > 0, 'Should have failed checks for invalid field');
    }

    @IsTest
    static void testExecute_NoPassThroughOutputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Id'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields,
            'rootObject' => 'Account',
            'businessContext' => 'Context'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // PHASE 2F: Verify we DO NOT output rootObject anymore
        System.assertEquals(null, result.outputs.get('rootObject'), 'Should NOT pass through inputs manually');
        // But validationChecklist should be present
        System.assertNotEquals(null, result.outputs.get('validationChecklist'), 'Should have stage outputs');
    }

    @IsTest
    static void testExecute_MultipleObjects() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Id', 'Name'},
            'Contact' => new List<String>{'FirstName', 'LastName'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage06_ConfigurationValidation stage = new Stage06_ConfigurationValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Integer totalChecks = (Integer) result.outputs.get('totalChecks');
        System.assert(totalChecks > 5, 'Should validate multiple objects and fields');
    }
}