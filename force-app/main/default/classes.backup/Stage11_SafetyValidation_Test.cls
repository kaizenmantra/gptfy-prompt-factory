/**
 * @description Test class for Stage11_SafetyValidation
 * Tests HTML safety checks and content validation
 */
@IsTest
private class Stage11_SafetyValidation_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Safety Account', Industry = 'Technology');
        insert testAccount;
    }

    @IsTest
    static void testExecute_SafeHTML() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String safeHTML = '<div class="slds-card"><h1>Account Name</h1><p>This is safe content</p></div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => safeHTML,
            'promptId' => acc.Id,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete with safe HTML');
        Boolean isSafe = (Boolean) result.outputs.get('isSafe');
        System.assertEquals(true, isSafe, 'HTML should be marked as safe');
    }

    @IsTest
    static void testExecute_NullOutputHtml() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => null,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null HTML');
    }

    @IsTest
    static void testExecute_ScriptInjectionDetected() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String unsafeHTML = '<div><script>alert("XSS")</script></div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => unsafeHTML,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with script injection');
        List<Object> issues = (List<Object>) result.outputs.get('issues');
        System.assert(issues.size() > 0, 'Should detect script injection');
    }

    @IsTest
    static void testExecute_ErrorMessageDetected() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String htmlWithError = '<div>Error: Failed to process request</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => htmlWithError,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Should detect error messages');
    }

    @IsTest
    static void testExecute_UnsubstitutedFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String htmlWithMergeFields = '<div>{{{UnsubstitutedField}}}</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => htmlWithMergeFields,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        List<Object> warnings = (List<Object>) result.outputs.get('warnings');
        System.assertNotEquals(null, warnings, 'Should detect unsubstituted fields');
    }

    @IsTest
    static void testExecute_ContentTooShort() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String shortHTML = '<div>Hi</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => shortHTML,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Should fail with insufficient content');
    }

    @IsTest
    static void testExecute_SafetyScoreCalculated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String safeHTML = '<div class="slds-card"><p>This is a comprehensive test of safety validation with sufficient content to pass all checks</p></div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => safeHTML,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Decimal safetyScore = (Decimal) result.outputs.get('safetyScore');
        System.assertNotEquals(null, safetyScore, 'Safety score should be calculated');
        System.assert(safetyScore >= 0 && safetyScore <= 100, 'Safety score should be between 0-100');
    }

    @IsTest
    static void testExecute_PassThroughInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String safeHTML = '<div>Safe content with sufficient text to pass validation checks successfully</div>';
        Map<String, Object> inputs = new Map<String, Object>{
            'outputHtml' => safeHTML,
            'promptId' => acc.Id,
            'sampleRecordId' => acc.Id,
            'dcmId' => acc.Id,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(Root_Object__c = 'Account', Sample_Record_Id__c = acc.Id, Prompt_Name__c = 'Test Prompt', Status__c = 'Queued', Current_Stage__c = 1);
        insert run;

        Stage11_SafetyValidation stage = new Stage11_SafetyValidation();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals(acc.Id, result.outputs.get('promptId'), 'Should pass through prompt ID');
        System.assertEquals('Account', result.outputs.get('rootObject'), 'Should pass through root object');
    }
}