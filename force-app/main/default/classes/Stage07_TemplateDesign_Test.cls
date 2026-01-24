/**
 * @description Test class for Stage07_TemplateDesign
 * Tests HTML template generation and safety validation
 */
@IsTest
private class Stage07_TemplateDesign_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Template Account', Industry = 'Technology');
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
            'rootObject' => 'Account',
            'businessContext' => 'Test',
            'targetPersona' => 'User',
            'outputFormat' => 'HTML'
        };

        // Must set mock mode in each test method (not in TestSetup)
        AIServiceClient.mockMode = true;
        // Use only fields from whitelist, no CSS classes
        AIServiceClient.mockResponse = '<div style="padding:20px"><h1>{{{Name}}}</h1><p>{{{Industry}}}</p></div>';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Template',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage07_TemplateDesign stage = new Stage07_TemplateDesign();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('htmlTemplate'), 'HTML template should be generated');
    }

    @IsTest
    static void testExecute_NullSelectedFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => null,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Null Fields',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage07_TemplateDesign stage = new Stage07_TemplateDesign();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null selected fields');
    }

    @IsTest
    static void testExecute_ScriptTagDetection() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = '<div>{{{Name}}}<script>alert("XSS")</script></div>';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Script Detection',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage07_TemplateDesign stage = new Stage07_TemplateDesign();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        List<Object> safetyIssues = (List<Object>) result.outputs.get('safetyIssues');
        System.assertNotEquals(null, safetyIssues, 'Safety issues should be detected');
        String template = (String) result.outputs.get('htmlTemplate');
        System.assert(!template.contains('<script'), 'Script tags should be sanitized');
    }

    @IsTest
    static void testExecute_MergeFieldsExtracted() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Include both Name and Industry in selected fields
        Map<String, Object> selectedFields = new Map<String, Object>{
            'Account' => new List<String>{'Name', 'Industry'}
        };
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockMode = true;
        // Response uses fields from the whitelist
        AIServiceClient.mockResponse = '<div>{{{Name}}}{{{Industry}}}</div>';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Merge Fields',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage07_TemplateDesign stage = new Stage07_TemplateDesign();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Integer mergeFieldCount = (Integer) result.outputs.get('mergeFieldCount');
        System.assertEquals(2, mergeFieldCount, 'Should extract 2 merge fields');
    }

    // testExecute_WhitelistValidationFails removed (Target V2.0 uses safe generated templates)

    @IsTest
    static void testExecute_TemplateSummary() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = '<div>{{{Name}}}</div>';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Summary',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage07_TemplateDesign stage = new Stage07_TemplateDesign();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String summary = (String) result.outputs.get('templateSummary');
        System.assertNotEquals(null, summary, 'Template summary should exist');
        System.assert(summary.contains('Template:'), 'Summary should contain template stats');
    }

    @IsTest
    static void testExecute_MarkdownCodeBlock() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields,
            'rootObject' => 'Account'
        };

        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = '```html\n<div>{{{Name}}}</div>\n```';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Markdown',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage07_TemplateDesign stage = new Stage07_TemplateDesign();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String template = (String) result.outputs.get('htmlTemplate');
        System.assert(!template.contains('```'), 'Markdown should be removed');
    }

    @IsTest
    static void testExecute_NoPassThroughOutputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> selectedFields = new Map<String, Object>{'Account' => new List<String>{'Name'}};
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedFields' => selectedFields,
            'rootObject' => 'Account',
            'businessContext' => 'Context',
            'outputFormat' => 'HTML'
        };

        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = '<div>{{{Name}}}</div>';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Pass Through',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage07_TemplateDesign stage = new Stage07_TemplateDesign();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // PHASE 2F: Verify we DO NOT output pass-throughs anymore
        System.assertEquals(null, result.outputs.get('rootObject'), 'Should NOT pass through root object');
        System.assertEquals(null, result.outputs.get('outputFormat'), 'Should NOT pass through output format');
    }
}