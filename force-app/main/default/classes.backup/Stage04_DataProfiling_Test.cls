/**
 * @description Test class for Stage04_DataProfiling
 * Tests COUNT query execution and data availability filtering
 */
@IsTest
private class Stage04_DataProfiling_Test {

    @TestSetup
    static void setup() {
        // Create test data with multiple records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            accounts.add(new Account(
                Name = 'Data Profile Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id
            ));
        }
        insert contacts;
    }

    /**
     * @description Test successful data profiling
     */
    @IsTest
    static void testExecute_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'Account', 'Contact'},
            'rootObject' => 'Account',
            'businessContext' => 'Test',
            'targetPersona' => 'User'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Data Profiling',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Stage should complete successfully');
        System.assertNotEquals(null, result.outputs.get('objectsWithData'), 'Objects with data should be set');
        System.assertNotEquals(null, result.outputs.get('dataAvailability'), 'Data availability should be set');
    }

    /**
     * @description Test with null selectedObjects
     */
    @IsTest
    static void testExecute_NullSelectedObjects() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => null,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Null Selected Objects',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Stage should fail with null selectedObjects');
    }

    /**
     * @description Test data availability map is populated correctly
     */
    @IsTest
    static void testExecute_DataAvailabilityMap() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'Account', 'Contact'},
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Data Availability',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Map<String, Object> dataAvailability = (Map<String, Object>) result.outputs.get('dataAvailability');
        System.assertNotEquals(null, dataAvailability, 'Data availability map should exist');
        System.assert(dataAvailability.containsKey('Account'), 'Should have Account count');
    }

    /**
     * @description Test objects with no data are filtered out
     */
    @IsTest
    static void testExecute_FiltersEmptyObjects() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'Account'},
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Filter Empty Objects',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        List<Object> objectsWithData = (List<Object>) result.outputs.get('objectsWithData');
        // Should only include objects with MIN_RECORD_COUNT or more records
        for (Object obj : objectsWithData) {
            String objName = String.valueOf(obj);
            Map<String, Object> dataAvail = (Map<String, Object>) result.outputs.get('dataAvailability');
            Integer count = (Integer) dataAvail.get(objName);
            System.assert(count >= 1, 'Objects with data should have at least 1 record');
        }
    }

    /**
     * @description Test with invalid object name
     */
    @IsTest
    static void testExecute_InvalidObjectName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'InvalidObject__c'},
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Invalid Object',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        // Should complete but filter out invalid objects
        System.assertEquals('Completed', result.status, 'Should complete with invalid objects');
        List<Object> objectsWithData = (List<Object>) result.outputs.get('objectsWithData');
        System.assertEquals(0, objectsWithData.size(), 'Should filter out inaccessible objects');
    }

    /**
     * @description Test totalRecordsCounted calculation
     */
    @IsTest
    static void testExecute_TotalRecordsCounted() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'Account', 'Contact'},
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Total Records',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        Integer totalRecords = (Integer) result.outputs.get('totalRecordsCounted');
        System.assertNotEquals(null, totalRecords, 'Total records should be calculated');
        System.assert(totalRecords > 0, 'Total records should be greater than 0');
    }

    /**
     * @description Test dataSummary is formatted correctly
     */
    @IsTest
    static void testExecute_DataSummaryFormat() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'Account'},
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Data Summary Format',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        String dataSummary = (String) result.outputs.get('dataSummary');
        System.assertNotEquals(null, dataSummary, 'Data summary should exist');
        System.assert(dataSummary.contains('Account'), 'Summary should contain object name');
    }

    /**
     * @description Test pass through of critical inputs
     */
    @IsTest
    static void testExecute_PassThroughInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> recordData = new Map<String, Object>{'Name' => 'Test'};
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'Account'},
            'rootObject' => 'Account',
            'businessContext' => 'Context',
            'targetPersona' => 'Persona',
            'businessObjectives' => new List<String>{'Goal'},
            'recordData' => recordData
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Pass Through Inputs',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Account', result.outputs.get('rootObject'), 'Root object should pass through');
        System.assertEquals('Context', result.outputs.get('businessContext'), 'Context should pass through');
        System.assertEquals('Persona', result.outputs.get('targetPersona'), 'Persona should pass through');
    }

    /**
     * @description Test with empty selectedObjects list
     */
    @IsTest
    static void testExecute_EmptySelectedObjects() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>(),
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Empty Selected Objects',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Failed', result.status, 'Should fail with empty object list');
    }

    /**
     * @description Test bulk profiling with multiple objects
     */
    @IsTest
    static void testExecute_BulkMultipleObjects() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => new List<String>{'Account', 'Contact', 'User'},
            'rootObject' => 'Account',
            'sampleRecordId' => acc.Id
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Bulk Multiple Objects',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        System.assertEquals('Completed', result.status, 'Should complete with multiple objects');
        Map<String, Object> dataAvail = (Map<String, Object>) result.outputs.get('dataAvailability');
        System.assert(dataAvail.size() >= 2, 'Should profile multiple objects');
    }

    /**
     * @description Test selectedObjects are preserved in outputs
     */
    @IsTest
    static void testExecute_SelectedObjectsPreserved() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<String> originalObjects = new List<String>{'Account', 'Contact'};
        Map<String, Object> inputs = new Map<String, Object>{
            'selectedObjects' => originalObjects,
            'rootObject' => 'Account'
        };

        Test.startTest();
        PF_Run__c run = new PF_Run__c(
            Prompt_Name__c = 'Test Selected Objects Preserved',
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Status__c = 'Queued'
        );
        insert run;

        Stage04_DataProfiling stage = new Stage04_DataProfiling();
        StageResult result = stage.execute(run.Id, inputs);
        Test.stopTest();

        List<Object> preserved = (List<Object>) result.outputs.get('selectedObjects');
        System.assertEquals(2, preserved.size(), 'Should preserve original selected objects');
    }
}