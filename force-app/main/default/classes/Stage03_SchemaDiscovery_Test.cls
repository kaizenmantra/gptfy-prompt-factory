/**
 * @description Test class for Stage03_SchemaDiscovery
 * Tests schema discovery and AI-based object selection
 */
@IsTest
private class Stage03_SchemaDiscovery_Test {

    @TestSetup
    static void setup() {
        // Create test Account with Contacts and Opportunities
        Account testAccount = new Account(
            Name = 'Test Schema Account',
            Industry = 'Technology'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id
        );
        insert testContact;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        AIServiceClient.mockMode = true;
    }

    /**
     * @description Test successful schema discovery
     */
    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Sales analysis',
            'targetPersona' => 'Sales Rep'
        };

        AIServiceClient.mockResponse = '{"selectedObjects": ["Account", "Contact", "Opportunity"], ' +
            '"reasoning": "These objects provide comprehensive sales context"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('selectedObjects'), 'Selected objects should be set');
        List<Object> selectedObjs = (List<Object>) result.outputs.get('selectedObjects');
        System.assert(selectedObjs.size() > 0, 'Should select at least one object');
    }

    /**
     * @description Test with null root object
     */
    @IsTest
    static void testExecute_NullRootObject() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => null,
            'businessContext' => 'Test'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null root object');
    }

    /**
     * @description Test AI selection with markdown code block
     */
    @IsTest
    static void testExecute_MarkdownCodeBlock() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test',
            'targetPersona' => 'User'
        };

        AIServiceClient.mockResponse = '```json\n{"selectedObjects": ["Account", "Contact"], ' +
            '"reasoning": "Test"}\n```';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Should handle markdown code blocks');
    }

    /**
     * @description Test validation of selected objects against available objects
     */
    @IsTest
    static void testExecute_ValidateSelectedObjects() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test',
            'targetPersona' => 'User'
        };

        // AI tries to select an invalid object
        AIServiceClient.mockResponse = '{"selectedObjects": ["Account", "InvalidObject__c"], ' +
            '"reasoning": "Test"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // Should filter out invalid objects
        List<Object> selectedObjs = (List<Object>) result.outputs.get('selectedObjects');
        System.assert(selectedObjs.size() == 1, 'Should filter out invalid objects');
        System.assertEquals('Account', String.valueOf(selectedObjs[0]), 'Should only include valid Account');
    }

    /**
     * @description Test with invalid JSON response
     */
    @IsTest
    static void testExecute_InvalidJSON() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test'
        };

        AIServiceClient.mockResponse = '{invalid json}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with invalid JSON');
    }

    /**
     * @description Test with missing selectedObjects field
     */
    @IsTest
    static void testExecute_MissingSelectedObjects() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test'
        };

        AIServiceClient.mockResponse = '{"reasoning": "Test only"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail without selectedObjects');
    }

    /**
     * @description Test outputs pass through required inputs
     */
    @IsTest
    static void testExecute_PassThroughInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Sales context',
            'targetPersona' => 'Sales Manager',
            'businessObjectives' => new List<String>{'Close deals'},
            'recordData' => new Map<String, Object>{'Name' => 'Test'}
        };

        AIServiceClient.mockResponse = '{"selectedObjects": ["Account"], "reasoning": "Test"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Account', result.outputs.get('rootObject'), 'Root object should pass through');
        System.assertEquals('Sales context', result.outputs.get('businessContext'), 'Context should pass through');
        System.assertEquals('Sales Manager', result.outputs.get('targetPersona'), 'Persona should pass through');
    }

    /**
     * @description Test child relationships are captured
     */
    @IsTest
    static void testExecute_ChildRelationshipsCaptured() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test',
            'targetPersona' => 'User'
        };

        AIServiceClient.mockResponse = '{"selectedObjects": ["Account"], "reasoning": "Test"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertNotEquals(null, result.outputs.get('childRelationships'),
            'Child relationships should be captured');
        String relationshipsJson = (String) result.outputs.get('childRelationships');
        System.assert(relationshipsJson.length() > 0, 'Should have serialized relationships');
    }

    /**
     * @description Test allAvailableObjects is populated
     */
    @IsTest
    static void testExecute_AllAvailableObjectsPopulated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test'
        };

        AIServiceClient.mockResponse = '{"selectedObjects": ["Account"], "reasoning": "Test"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertNotEquals(null, result.outputs.get('allAvailableObjects'),
            'All available objects should be listed');
        List<Object> availableObjs = (List<Object>) result.outputs.get('allAvailableObjects');
        System.assert(availableObjs.size() > 0, 'Should have available objects');
    }

    /**
     * @description Test AI reasoning is captured
     */
    @IsTest
    static void testExecute_AIReasoningCaptured() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test'
        };

        AIServiceClient.mockResponse = '{"selectedObjects": ["Account"], ' +
            '"reasoning": "Selected Account for comprehensive customer data"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Selected Account for comprehensive customer data', result.aiReasoning,
            'AI reasoning should be captured');
    }

    /**
     * @description Test with empty available objects
     */
    @IsTest
    static void testExecute_NoValidObjectsSelected() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test'
        };

        // AI selects only invalid objects
        AIServiceClient.mockResponse = '{"selectedObjects": ["InvalidObject1__c", "InvalidObject2__c"], ' +
            '"reasoning": "Test"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Should fail when no valid objects selected');
    }

    /**
     * @description Test with Contact as root object
     */
    @IsTest
    static void testExecute_ContactRootObject() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Contact',
            'businessContext' => 'Contact management',
            'targetPersona' => 'Support Agent'
        };

        AIServiceClient.mockResponse = '{"selectedObjects": ["Contact", "Account"], ' +
            '"reasoning": "Contact with Account context"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Contact',
            Sample_Record_Id__c = con.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Should work with Contact root object');
    }

    /**
     * @description Test selectionJson is stored
     */
    @IsTest
    static void testExecute_SelectionJsonStored() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test'
        };

        AIServiceClient.mockResponse = '{"selectedObjects": ["Account"], "reasoning": "Test"}';

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage03_SchemaDiscovery stage = new Stage03_SchemaDiscovery();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertNotEquals(null, result.outputs.get('selectionJson'), 'Selection JSON should be stored');
    }
}