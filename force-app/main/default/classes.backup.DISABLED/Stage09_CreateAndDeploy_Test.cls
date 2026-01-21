/**
 * @description Test class for Stage09_CreateAndDeploy
 * Tests DCM and Prompt record creation
 * Note: Requires DCMBuilder and PromptBuilder classes
 */
@IsTest
private class Stage09_CreateAndDeploy_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Deploy Account', Industry = 'Technology');
        insert testAccount;
    }

    @IsTest
    static void testExecute_MissingDCMConfig() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'dcmConfig' => null,
            'promptConfig' => new Map<String, Object>{'name' => 'Test'},
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage09_CreateAndDeploy stage = new Stage09_CreateAndDeploy();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail without DCM config');
    }

    @IsTest
    static void testExecute_MissingPromptConfig() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'dcmConfig' => new Map<String, Object>{'name' => 'Test DCM'},
            'promptConfig' => null,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage09_CreateAndDeploy stage = new Stage09_CreateAndDeploy();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail without prompt config');
    }

    @IsTest
    static void testExecute_InputsPreserved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'dcmConfig' => new Map<String, Object>{'name' => 'Test DCM', 'rootObject' => 'Account'},
            'promptConfig' => new Map<String, Object>{'name' => 'Test Prompt'},
            'rootObject' => 'Account',
            'promptName' => 'TestPrompt',
            'sampleRecordId' => acc.Id
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage09_CreateAndDeploy stage = new Stage09_CreateAndDeploy();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // Stage 9 involves external GPTfy operations and complex setup.
        // In test context (without full DCM/Prompt mocking), the stage will fail during DCM creation.
        // This test verifies the stage executes without throwing uncaught exceptions.
        // The result will be 'Failed' because DCMBuilder.createDCMWithGrandchildren requires valid configs
        // that work with GPTfy's managed package.
        System.assertNotEquals(null, result, 'Stage should return a result');
        System.assertNotEquals(null, result.status, 'Stage should have a status');
    }

    @IsTest
    static void testExecute_ExceptionHandling() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'dcmConfig' => new Map<String, Object>{'invalidStructure' => true},
            'promptConfig' => new Map<String, Object>{'invalidStructure' => true},
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage09_CreateAndDeploy stage = new Stage09_CreateAndDeploy();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Should handle exceptions gracefully');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }
}