/**
 * @description Test class for PipelineState
 * Tests all methods for JSON file-based pipeline state management
 *
 * @author Claude Opus 4.5
 * @date 2026-01-24
 */
@IsTest
private class PipelineState_Test {

    /**
     * @description Setup test data
     */
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    /**
     * @description Helper to create test run
     */
    private static PF_Run__c createTestRun() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = acc.Id,
            Business_Context__c = 'Test business context',
            Status__c = 'In Progress',
            Current_Stage__c = 1
        );
        insert run;
        return run;
    }

    /**
     * @description Test initialize creates new state file
     */
    @IsTest
    static void testInitialize_CreatesFile() {
        PF_Run__c run = createTestRun();

        Map<String, Object> initialData = new Map<String, Object>{
            'rootObject' => 'Account',
            'businessContext' => 'Test context'
        };

        Test.startTest();
        Boolean created = PipelineState.initialize(run.Id, initialData);
        Test.stopTest();

        System.assertEquals(true, created, 'File should be created');
        System.assertEquals(true, PipelineState.exists(run.Id), 'File should exist after initialization');

        Map<String, Object> state = PipelineState.read(run.Id);
        System.assertEquals('Account', state.get('rootObject'), 'rootObject should be set');
        System.assertEquals('Test context', state.get('businessContext'), 'businessContext should be set');
        System.assertNotEquals(null, state.get('createdAt'), 'createdAt should be set');
    }

    /**
     * @description Test initialize returns false if file exists
     */
    @IsTest
    static void testInitialize_FileExists() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        Boolean firstCreate = PipelineState.initialize(run.Id, null);
        Boolean secondCreate = PipelineState.initialize(run.Id, null);
        Test.stopTest();

        System.assertEquals(true, firstCreate, 'First initialize should return true');
        System.assertEquals(false, secondCreate, 'Second initialize should return false');
    }

    /**
     * @description Test initialize with null runId
     */
    @IsTest
    static void testInitialize_NullRunId() {
        Test.startTest();
        Boolean created = PipelineState.initialize(null, null);
        Test.stopTest();

        System.assertEquals(false, created, 'Should return false for null runId');
    }

    /**
     * @description Test read returns empty map when no file exists
     */
    @IsTest
    static void testRead_NoFile() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        Map<String, Object> state = PipelineState.read(run.Id);
        Test.stopTest();

        System.assertNotEquals(null, state, 'Should return non-null map');
        System.assertEquals(0, state.size(), 'Should return empty map');
    }

    /**
     * @description Test read returns correct data
     */
    @IsTest
    static void testRead_WithData() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, new Map<String, Object>{
            'testKey' => 'testValue',
            'testNumber' => 42
        });

        Test.startTest();
        Map<String, Object> state = PipelineState.read(run.Id);
        Test.stopTest();

        System.assertEquals('testValue', state.get('testKey'), 'Should return correct string value');
        System.assertEquals(42, state.get('testNumber'), 'Should return correct number value');
    }

    /**
     * @description Test read with null runId
     */
    @IsTest
    static void testRead_NullRunId() {
        Test.startTest();
        Map<String, Object> state = PipelineState.read(null);
        Test.stopTest();

        System.assertNotEquals(null, state, 'Should return non-null map');
        System.assertEquals(0, state.size(), 'Should return empty map');
    }

    /**
     * @description Test write creates new file if none exists
     */
    @IsTest
    static void testWrite_CreatesFile() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        PipelineState.write(run.Id, new Map<String, Object>{
            'key1' => 'value1'
        });
        Test.stopTest();

        System.assertEquals(true, PipelineState.exists(run.Id), 'File should exist');
        Map<String, Object> state = PipelineState.read(run.Id);
        System.assertEquals('value1', state.get('key1'), 'Data should be written');
    }

    /**
     * @description Test write merges with existing data
     */
    @IsTest
    static void testWrite_MergesData() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, new Map<String, Object>{
            'existingKey' => 'existingValue'
        });

        Test.startTest();
        PipelineState.write(run.Id, new Map<String, Object>{
            'newKey' => 'newValue'
        });
        Test.stopTest();

        Map<String, Object> state = PipelineState.read(run.Id);
        System.assertEquals('existingValue', state.get('existingKey'), 'Existing data should be preserved');
        System.assertEquals('newValue', state.get('newKey'), 'New data should be added');
    }

    /**
     * @description Test write overwrites existing keys
     */
    @IsTest
    static void testWrite_OverwritesKeys() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, new Map<String, Object>{
            'key' => 'oldValue'
        });

        Test.startTest();
        PipelineState.write(run.Id, new Map<String, Object>{
            'key' => 'newValue'
        });
        Test.stopTest();

        Map<String, Object> state = PipelineState.read(run.Id);
        System.assertEquals('newValue', state.get('key'), 'Value should be overwritten');
    }

    /**
     * @description Test write with null parameters
     */
    @IsTest
    static void testWrite_NullParameters() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        // Should not throw
        PipelineState.write(null, new Map<String, Object>{ 'key' => 'value' });
        PipelineState.write(run.Id, null);
        Test.stopTest();

        // Just verify no exception was thrown
        System.assert(true, 'Should handle null parameters gracefully');
    }

    /**
     * @description Test get convenience method
     */
    @IsTest
    static void testGet() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, new Map<String, Object>{
            'myKey' => 'myValue'
        });

        Test.startTest();
        Object value = PipelineState.get(run.Id, 'myKey');
        Object missing = PipelineState.get(run.Id, 'nonexistent');
        Test.stopTest();

        System.assertEquals('myValue', value, 'Should return correct value');
        System.assertEquals(null, missing, 'Should return null for missing key');
    }

    /**
     * @description Test put convenience method
     */
    @IsTest
    static void testPut() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, null);

        Test.startTest();
        PipelineState.put(run.Id, 'singleKey', 'singleValue');
        Test.stopTest();

        Object value = PipelineState.get(run.Id, 'singleKey');
        System.assertEquals('singleValue', value, 'Should return value set via put');
    }

    /**
     * @description Test log appends to logs array
     */
    @IsTest
    static void testLog() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, null);

        Test.startTest();
        PipelineState.log(run.Id, 1, 'INFO', 'First log message');
        PipelineState.log(run.Id, 2, 'DEBUG', 'Second log message');
        Test.stopTest();

        Map<String, Object> state = PipelineState.read(run.Id);
        List<Object> logs = (List<Object>) state.get('logs');

        System.assertNotEquals(null, logs, 'Logs array should exist');
        System.assertEquals(2, logs.size(), 'Should have 2 log entries');

        Map<String, Object> firstLog = (Map<String, Object>) logs[0];
        System.assertEquals(1, firstLog.get('stage'), 'First log stage should be 1');
        System.assertEquals('INFO', firstLog.get('level'), 'First log level should be INFO');
        System.assertEquals('First log message', firstLog.get('msg'), 'First log message should match');
    }

    /**
     * @description Test log with null runId
     */
    @IsTest
    static void testLog_NullRunId() {
        Test.startTest();
        // Should not throw
        PipelineState.log(null, 1, 'INFO', 'Test message');
        Test.stopTest();

        System.assert(true, 'Should handle null runId gracefully');
    }

    /**
     * @description Test getFileId returns ContentVersion Id
     */
    @IsTest
    static void testGetFileId() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        Id fileIdBefore = PipelineState.getFileId(run.Id);
        PipelineState.initialize(run.Id, null);
        Id fileIdAfter = PipelineState.getFileId(run.Id);
        Test.stopTest();

        System.assertEquals(null, fileIdBefore, 'Should return null before file exists');
        System.assertNotEquals(null, fileIdAfter, 'Should return Id after file exists');
    }

    /**
     * @description Test getDocumentId returns ContentDocumentId
     */
    @IsTest
    static void testGetDocumentId() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        Id docIdBefore = PipelineState.getDocumentId(run.Id);
        PipelineState.initialize(run.Id, null);
        Id docIdAfter = PipelineState.getDocumentId(run.Id);
        Test.stopTest();

        System.assertEquals(null, docIdBefore, 'Should return null before file exists');
        System.assertNotEquals(null, docIdAfter, 'Should return Id after file exists');
    }

    /**
     * @description Test exists method
     */
    @IsTest
    static void testExists() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        Boolean existsBefore = PipelineState.exists(run.Id);
        PipelineState.initialize(run.Id, null);
        Boolean existsAfter = PipelineState.exists(run.Id);
        Test.stopTest();

        System.assertEquals(false, existsBefore, 'Should return false before initialization');
        System.assertEquals(true, existsAfter, 'Should return true after initialization');
    }

    /**
     * @description Test getJson returns raw JSON
     */
    @IsTest
    static void testGetJson() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, new Map<String, Object>{
            'testKey' => 'testValue'
        });

        Test.startTest();
        String json = PipelineState.getJson(run.Id);
        Test.stopTest();

        System.assertNotEquals(null, json, 'Should return non-null JSON');
        System.assert(json.contains('testKey'), 'JSON should contain testKey');
        System.assert(json.contains('testValue'), 'JSON should contain testValue');
    }

    /**
     * @description Test getJson returns null when no file
     */
    @IsTest
    static void testGetJson_NoFile() {
        PF_Run__c run = createTestRun();

        Test.startTest();
        String json = PipelineState.getJson(run.Id);
        Test.stopTest();

        System.assertEquals(null, json, 'Should return null when no file exists');
    }

    /**
     * @description Test markStageComplete updates lastUpdatedByStage
     */
    @IsTest
    static void testMarkStageComplete() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, null);

        Test.startTest();
        PipelineState.markStageComplete(run.Id, 5);
        Test.stopTest();

        Map<String, Object> state = PipelineState.read(run.Id);
        System.assertEquals(5, state.get('lastUpdatedByStage'), 'lastUpdatedByStage should be 5');
    }

    /**
     * @description Test complex data types (nested maps, lists)
     */
    @IsTest
    static void testComplexDataTypes() {
        PF_Run__c run = createTestRun();

        Map<String, Object> complexData = new Map<String, Object>{
            'stringList' => new List<String>{ 'a', 'b', 'c' },
            'nestedMap' => new Map<String, Object>{
                'inner' => 'value'
            },
            'selectedFields' => new Map<String, Object>{
                'Account' => new List<String>{ 'Name', 'Industry' },
                'Contact' => new List<String>{ 'FirstName', 'LastName' }
            }
        };

        Test.startTest();
        PipelineState.initialize(run.Id, complexData);
        Map<String, Object> state = PipelineState.read(run.Id);
        Test.stopTest();

        // Verify list
        List<Object> stringList = (List<Object>) state.get('stringList');
        System.assertEquals(3, stringList.size(), 'List should have 3 items');

        // Verify nested map
        Map<String, Object> nestedMap = (Map<String, Object>) state.get('nestedMap');
        System.assertEquals('value', nestedMap.get('inner'), 'Nested map should be preserved');

        // Verify selected fields structure
        Map<String, Object> selectedFields = (Map<String, Object>) state.get('selectedFields');
        List<Object> accountFields = (List<Object>) selectedFields.get('Account');
        System.assertEquals(2, accountFields.size(), 'Account fields should have 2 items');
    }

    /**
     * @description Test multiple writes create new versions
     */
    @IsTest
    static void testMultipleWrites() {
        PF_Run__c run = createTestRun();
        PipelineState.initialize(run.Id, new Map<String, Object>{
            'stage1' => 'data1'
        });

        Test.startTest();
        PipelineState.write(run.Id, new Map<String, Object>{
            'stage2' => 'data2'
        });
        PipelineState.write(run.Id, new Map<String, Object>{
            'stage3' => 'data3'
        });
        Test.stopTest();

        Map<String, Object> state = PipelineState.read(run.Id);
        System.assertEquals('data1', state.get('stage1'), 'stage1 data should be preserved');
        System.assertEquals('data2', state.get('stage2'), 'stage2 data should be present');
        System.assertEquals('data3', state.get('stage3'), 'stage3 data should be present');
    }

    /**
     * @description Test large data handling
     */
    @IsTest
    static void testLargeData() {
        PF_Run__c run = createTestRun();

        // Create a large string (simulate large prompt or data)
        String largeString = '';
        for (Integer i = 0; i < 1000; i++) {
            largeString += 'This is line ' + i + ' of the large data. ';
        }

        Map<String, Object> largeData = new Map<String, Object>{
            'largeField' => largeString
        };

        Test.startTest();
        PipelineState.initialize(run.Id, largeData);
        Map<String, Object> state = PipelineState.read(run.Id);
        Test.stopTest();

        String retrieved = (String) state.get('largeField');
        System.assertEquals(largeString.length(), retrieved.length(), 'Large data should be fully preserved');
    }
}
