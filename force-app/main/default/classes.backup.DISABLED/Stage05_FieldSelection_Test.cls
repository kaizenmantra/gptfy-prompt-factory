/**
 * @description Test class for Stage05_FieldSelection
 * Tests field selection with schema validation
 */
@IsTest
private class Stage05_FieldSelection_Test {

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Field Account', Industry = 'Technology');
        insert testAccount;
    }

    private static void enableClaudeMockForRoot(String rootObject) {
        // Enable mock mode so Stage05 doesn't require real Claude credentials in the org.
        AIServiceClient.setMockMode(true);

        // Minimal-but-valid schema expected by Stage05.parseFieldSelectionResponse()
        // Include multiple meaningful fields so Stage05 passes MIN_MEANINGFUL_FIELDS gate.
        String responseJson =
            '{' +
            '  "selectedFields": {' +
            '    "' + rootObject + '": ["Id","Name","Description","CreatedDate","LastModifiedDate"]' +
            '  },' +
            '  "reasoning": "Test mock field selection"' +
            '}';
        AIServiceClient.setMockResponse(responseJson);
    }

    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        enableClaudeMockForRoot('Account');
        Map<String, Object> inputs = new Map<String, Object>{
            'objectsWithData' => new List<String>{'Account'},
            'rootObject' => 'Account',
            'businessContext' => 'Sales analysis',
            'targetPersona' => 'Sales Rep'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Field Selection',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('selectedFields'), 'Selected fields should be set');
    }

    @IsTest
    static void testExecute_AccountFields() {
        // Test that Account fields are validated against schema
        Account acc = [SELECT Id FROM Account LIMIT 1];
        enableClaudeMockForRoot('Account');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Account Fields',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete');
        Map<String, Object> selectedFields = (Map<String, Object>) result.outputs.get('selectedFields');
        System.assert(selectedFields.containsKey('Account'), 'Should have Account fields');

        // Verify common fields are included
        List<Object> accountFields = (List<Object>) selectedFields.get('Account');
        Set<String> fieldSet = new Set<String>();
        for (Object f : accountFields) {
            fieldSet.add(String.valueOf(f));
        }
        System.assert(fieldSet.contains('Id'), 'Should include Id');
        System.assert(fieldSet.contains('Name'), 'Should include Name');
    }

    @IsTest
    static void testExecute_OpportunityFields() {
        // Test Opportunity field selection and validation
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        enableClaudeMockForRoot('Opportunity');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Opportunity',
            'businessContext' => 'Sales pipeline'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Opp Fields',
            Root_Object__c = 'Opportunity',
            Sample_Record_Id__c = opp.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete');
        Map<String, Object> selectedFields = (Map<String, Object>) result.outputs.get('selectedFields');
        System.assert(selectedFields.containsKey('Opportunity'), 'Should have Opportunity fields');
    }

    @IsTest
    static void testExecute_ContactFields() {
        // Test Contact field selection and validation
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id
        );
        insert con;

        enableClaudeMockForRoot('Contact');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Contact',
            'businessContext' => 'Contact management'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Contact Fields',
            Root_Object__c = 'Contact',
            Sample_Record_Id__c = con.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete');
        Map<String, Object> selectedFields = (Map<String, Object>) result.outputs.get('selectedFields');
        System.assert(selectedFields.containsKey('Contact'), 'Should have Contact fields');
    }

    @IsTest
    static void testExecute_GenericObject() {
        // Test generic fallback for unknown objects
        Account acc = [SELECT Id FROM Account LIMIT 1];
        enableClaudeMockForRoot('Lead');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Lead',
            'businessContext' => 'Lead management'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Generic Fields',
            Root_Object__c = 'Lead',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete');
        Map<String, Object> selectedFields = (Map<String, Object>) result.outputs.get('selectedFields');
        System.assert(selectedFields.containsKey('Lead'), 'Should have Lead fields');
    }

    @IsTest
    static void testExecute_TotalFieldsCalculated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        enableClaudeMockForRoot('Account');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Total Fields',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Integer totalFields = (Integer) result.outputs.get('totalFieldsSelected');
        System.assert(totalFields > 0, 'Should have selected fields');
    }

    @IsTest
    static void testExecute_SelectionSummaryGenerated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        enableClaudeMockForRoot('Account');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Summary',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String summary = (String) result.outputs.get('selectionSummary');
        System.assertNotEquals(null, summary, 'Selection summary should exist');
        System.assert(summary.contains('Account'), 'Summary should contain object name');
    }

    @IsTest
    static void testExecute_PassThroughInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        enableClaudeMockForRoot('Account');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Context',
            'targetPersona' => 'Persona',
            'businessObjectives' => new List<String>{'Goal'}
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Pass Through',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Account', result.outputs.get('rootObject'), 'Should pass through root object');
        System.assertEquals('Context', result.outputs.get('businessContext'), 'Should pass through context');
    }

    @IsTest
    static void testExecute_SchemaValidation() {
        // Test that schema validation is performed
        Account acc = [SELECT Id FROM Account LIMIT 1];
        enableClaudeMockForRoot('Account');
        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Schema Validation',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage05_FieldSelection stage = new Stage05_FieldSelection();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // All fields should be validated - only valid ones included
        System.assertEquals('Completed', result.status, 'Stage should complete');
        Map<String, Object> selectedFields = (Map<String, Object>) result.outputs.get('selectedFields');
        List<Object> fields = (List<Object>) selectedFields.get('Account');

        // Verify all returned fields actually exist in schema
        for (Object fieldObj : fields) {
            String fieldName = String.valueOf(fieldObj);
            System.assert(
                SchemaHelper.isFieldAccessible('Account', fieldName),
                'Field ' + fieldName + ' should be accessible in schema'
            );
        }
    }
}