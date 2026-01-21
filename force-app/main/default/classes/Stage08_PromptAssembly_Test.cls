/**
 * @description Test class for Stage08_PromptAssembly
 * Tests prompt configuration assembly and merge field validation
 */
@IsTest
private class Stage08_PromptAssembly_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Assembly Account', Industry = 'Technology');
        insert testAccount;
    }

    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Id', 'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'htmlTemplate' => '<div>{{{Name}}}</div>',
            'rootObject' => 'Account',
            'businessContext' => 'Test',
            'targetPersona' => 'User',
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Prompt',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('promptConfiguration'), 'Prompt config should be generated');
    }

    @IsTest
    static void testExecute_NullHtmlTemplate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> inputs = new Map<String, Object>{'htmlTemplate' => null, 'rootObject' => 'Account'};

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Null Template',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null template');
    }

    @IsTest
    static void testExecute_AIInstructionsGenerated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'htmlTemplate' => '<div>{{{Name}}}</div>',
            'rootObject' => 'Account',
            'businessContext' => 'Sales analysis',
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test AI Instructions',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String aiInstructions = (String) result.outputs.get('aiInstructions');
        System.assertNotEquals(null, aiInstructions, 'AI instructions should be generated');
        System.assert(aiInstructions.contains('AI assistant'), 'Should contain AI instructions');
    }

    @IsTest
    static void testExecute_GroundingRulesGenerated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'htmlTemplate' => '<div>{{{Name}}}</div>',
            'rootObject' => 'Account',
            'targetPersona' => 'Executive',
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Grounding Rules',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String groundingRules = (String) result.outputs.get('groundingRules');
        System.assertNotEquals(null, groundingRules, 'Grounding rules should be generated');
        System.assert(groundingRules.contains('Grounding Rules'), 'Should contain grounding rules');
    }

    @IsTest
    static void testExecute_InvalidMergeFields_ShouldFail() {
        // UPDATED: Invalid merge fields should now cause stage to FAIL (not just warn)
        // This mirrors the shell script behavior: fail fast if whitelist validation fails
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'htmlTemplate' => '<div>{{{InvalidField__c}}}</div>',
            'rootObject' => 'Account',
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Invalid Fields',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // Stage should FAIL when invalid merge fields are detected
        System.assertEquals('Failed', result.status, 'Stage should fail with invalid merge fields');
        System.assert(result.errorMessage.contains('VALIDATION FAILED'), 'Error should indicate validation failure');
        System.assert(result.errorMessage.contains('invalid merge field'), 'Error should mention invalid merge fields');
    }

    @IsTest
    static void testExecute_AssemblySummary() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'htmlTemplate' => '<div>{{{Name}}}</div>',
            'rootObject' => 'Account',
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Assembly Summary',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String summary = (String) result.outputs.get('assemblySummary');
        System.assertNotEquals(null, summary, 'Assembly summary should exist');
        System.assert(summary.contains('Prompt assembled'), 'Summary should describe assembly');
    }

    @IsTest
    static void testExecute_PromptConfigurationComplete() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'htmlTemplate' => '<div>{{{Name}}}</div>',
            'rootObject' => 'Account',
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Prompt Config',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Map<String, Object> config = (Map<String, Object>) result.outputs.get('promptConfiguration');
        System.assertNotEquals(null, config, 'Config should exist');
        System.assert(config.containsKey('promptText'), 'Should have prompt text');
        System.assert(config.containsKey('version'), 'Should have version');
    }

    @IsTest
    static void testExecute_DCMConfig_SkipsLowSignalChildObjects() {
        // If a child object only has Id/*Id fields, it provides no useful context and should be excluded.
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Id', 'Name'},
            // Low-signal child: ID-only fields (common problematic pattern)
            'ContentDocumentLink' => new List<String>{'Id', 'LinkedEntityId', 'ContentDocumentId'}
        };

        Map<String, Object> inputs = new Map<String, Object>{
            'htmlTemplate' => '<div>{{{Name}}}</div>',
            'rootObject' => 'Account',
            'selectedFields' => selectedFields
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test DCM Low Signal Filter',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage08_PromptAssembly stage = new Stage08_PromptAssembly();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete');

        Map<String, Object> dcmConfig = (Map<String, Object>) result.outputs.get('dcmConfig');
        System.assertNotEquals(null, dcmConfig, 'Should output dcmConfig');

        // Ensure fieldsByObject does not include low-signal object
        Map<String, Object> fieldsByObject = (Map<String, Object>) dcmConfig.get('fieldsByObject');
        System.assertNotEquals(null, fieldsByObject, 'Should have fieldsByObject');
        System.assert(!fieldsByObject.containsKey('ContentDocumentLink'), 'Should exclude low-signal child object from fieldsByObject');
    }
}