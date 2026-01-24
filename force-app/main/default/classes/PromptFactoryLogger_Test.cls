/**
 * @description Test class for PromptFactoryLogger
 * Tests logging, retrieval, and truncation functionality
 */
@IsTest
private class PromptFactoryLogger_Test {

    @TestSetup
    static void setup() {
        // Create test run record
        PF_Run__c testRun = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = '001000000000000',
            Business_Context__c = 'Test context',
            Output_Format__c = 'HTML',
            Prompt_Name__c = 'Test Prompt',
            Status__c = 'In Progress',
            Current_Stage__c = 1
        );
        insert testRun;
    }

    /**
     * @description Test basic log creation
     */
    @IsTest
    static void testLog_BasicCreation() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PromptFactoryLogger.log(run.Id, 1, 'INFO', 'Test log message');
        Test.stopTest();

        List<PF_Run_Log__c> logs = [
            SELECT Id, Run__c, Stage_Number__c, Log_Level__c, Log_Message__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
        ];

        System.assertEquals(1, logs.size(), 'Should create one log entry');
        System.assertEquals(1, logs[0].Stage_Number__c, 'Stage number should be 1');
        System.assertEquals('INFO', logs[0].Log_Level__c, 'Log level should be INFO');
        System.assertEquals('Test log message', logs[0].Log_Message__c, 'Message should match');
    }

    /**
     * @description Test log with component and details
     */
    @IsTest
    static void testLog_WithComponentAndDetails() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PromptFactoryLogger.log(run.Id, 2, 'DEBUG', 'Debug message',
            'TestComponent', '{"key": "value"}');
        Test.stopTest();

        List<PF_Run_Log__c> logs = [
            SELECT Id, Component__c, Details__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
        ];

        System.assertEquals(1, logs.size(), 'Should create one log entry');
        System.assertEquals('TestComponent', logs[0].Component__c, 'Component should be set');
        System.assertEquals('{"key": "value"}', logs[0].Details__c, 'Details should be set');
    }

    /**
     * @description Test bulk logging
     */
    @IsTest
    static void testBulkLog() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        List<PF_Run_Log__c> logEntries = new List<PF_Run_Log__c>();
        for (Integer i = 0; i < 10; i++) {
            logEntries.add(new PF_Run_Log__c(
                Run__c = run.Id,
                Stage_Number__c = 3,
                Log_Level__c = 'INFO',
                Log_Message__c = 'Bulk log message ' + i,
                Timestamp__c = System.now()
            ));
        }

        Test.startTest();
        PromptFactoryLogger.bulkLog(logEntries);
        Test.stopTest();

        List<PF_Run_Log__c> logs = [
            SELECT Id FROM PF_Run_Log__c WHERE Run__c = :run.Id
        ];

        System.assertEquals(10, logs.size(), 'Should create 10 log entries');
    }

    /**
     * @description Test bulk log with null/empty list
     */
    @IsTest
    static void testBulkLog_NullAndEmpty() {
        Test.startTest();
        PromptFactoryLogger.bulkLog(null);
        PromptFactoryLogger.bulkLog(new List<PF_Run_Log__c>());
        Test.stopTest();

        // Should not throw exception
        System.assert(true, 'Should handle null and empty lists gracefully');
    }

    /**
     * @description Test createLogEntry method
     */
    @IsTest
    static void testCreateLogEntry() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PF_Run_Log__c logEntry = PromptFactoryLogger.createLogEntry(
            run.Id, 4, 'WARNING', 'Warning message', 'WarningComponent'
        );
        Test.stopTest();

        System.assertNotEquals(null, logEntry, 'Should create log entry');
        System.assertEquals(run.Id, logEntry.Run__c, 'Run ID should be set');
        System.assertEquals(4, logEntry.Stage_Number__c, 'Stage number should be 4');
        System.assertEquals('WARNING', logEntry.Log_Level__c, 'Log level should be WARNING');
        System.assertEquals('Warning message', logEntry.Log_Message__c, 'Message should match');
        System.assertEquals('WarningComponent', logEntry.Component__c, 'Component should be set');
        System.assertNotEquals(null, logEntry.Timestamp__c, 'Timestamp should be set');
    }

    /**
     * @description Test getLogs method
     */
    @IsTest
    static void testGetLogs() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        // Create multiple logs
        List<PF_Run_Log__c> logsToInsert = new List<PF_Run_Log__c>();
        for (Integer i = 0; i < 15; i++) {
            logsToInsert.add(new PF_Run_Log__c(
                Run__c = run.Id,
                Stage_Number__c = 1,
                Log_Level__c = 'INFO',
                Log_Message__c = 'Log ' + i,
                Timestamp__c = System.now().addSeconds(i)
            ));
        }
        insert logsToInsert;

        Test.startTest();
        List<PF_Run_Log__c> logs = PromptFactoryLogger.getLogs(run.Id, 10);
        Test.stopTest();

        System.assertEquals(10, logs.size(), 'Should return only 10 logs');
        // Verify descending order (most recent first)
        System.assert(logs[0].Timestamp__c >= logs[logs.size()-1].Timestamp__c,
            'Should be ordered by timestamp descending');
    }

    /**
     * @description Test getStageLog method
     */
    @IsTest
    static void testGetStageLog() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        // Create logs for different stages
        List<PF_Run_Log__c> logsToInsert = new List<PF_Run_Log__c>();
        for (Integer stage = 1; stage <= 3; stage++) {
            for (Integer i = 0; i < 5; i++) {
                logsToInsert.add(new PF_Run_Log__c(
                    Run__c = run.Id,
                    Stage_Number__c = stage,
                    Log_Level__c = 'INFO',
                    Log_Message__c = 'Stage ' + stage + ' log ' + i,
                    Timestamp__c = System.now().addSeconds((stage * 10) + i)
                ));
            }
        }
        insert logsToInsert;

        Test.startTest();
        List<PF_Run_Log__c> stage2Logs = PromptFactoryLogger.getStageLog(run.Id, 2);
        Test.stopTest();

        System.assertEquals(5, stage2Logs.size(), 'Should return 5 logs for stage 2');
        for (PF_Run_Log__c log : stage2Logs) {
            System.assertEquals(2, log.Stage_Number__c, 'All logs should be for stage 2');
        }
        // Verify ascending order
        System.assert(stage2Logs[0].Timestamp__c <= stage2Logs[stage2Logs.size()-1].Timestamp__c,
            'Should be ordered by timestamp ascending');
    }

    /**
     * @description Test getLogsByLevel method
     */
    @IsTest
    static void testGetLogsByLevel() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        // Create logs with different levels
        List<PF_Run_Log__c> logsToInsert = new List<PF_Run_Log__c>();
        List<String> levels = new List<String>{'DEBUG', 'INFO', 'WARNING', 'ERROR'};
        for (String level : levels) {
            for (Integer i = 0; i < 3; i++) {
                logsToInsert.add(new PF_Run_Log__c(
                    Run__c = run.Id,
                    Stage_Number__c = 1,
                    Log_Level__c = level,
                    Log_Message__c = level + ' message ' + i,
                    Timestamp__c = System.now()
                ));
            }
        }
        insert logsToInsert;

        Test.startTest();
        List<PF_Run_Log__c> errorLogs = PromptFactoryLogger.getLogsByLevel(run.Id, 'ERROR');
        Test.stopTest();

        System.assertEquals(3, errorLogs.size(), 'Should return 3 ERROR logs');
        for (PF_Run_Log__c log : errorLogs) {
            System.assertEquals('ERROR', log.Log_Level__c, 'All logs should be ERROR level');
        }
    }

    /**
     * @description Test message truncation at 10,000 characters
     */
    @IsTest
    static void testTruncation_Message() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        // Create a message longer than 10,000 characters
        String longMessage = '';
        for (Integer i = 0; i < 1100; i++) {
            longMessage += '0123456789'; // 10 chars per iteration = 11,000 total
        }

        Test.startTest();
        PromptFactoryLogger.log(run.Id, 1, 'INFO', longMessage);
        Test.stopTest();

        PF_Run_Log__c log = [
            SELECT Log_Message__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertEquals(10000, log.Log_Message__c.length(),
            'Message should be truncated to 10,000 chars');
        System.assert(log.Log_Message__c.endsWith('...'),
            'Truncated message should end with ...');
    }

    /**
     * @description Test details truncation at 32,000 characters
     */
    @IsTest
    static void testTruncation_Details() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        // Create details longer than 32,000 characters
        String longDetails = '';
        for (Integer i = 0; i < 3300; i++) {
            longDetails += '0123456789'; // 10 chars per iteration = 33,000 total
        }

        Test.startTest();
        PromptFactoryLogger.log(run.Id, 1, 'INFO', 'Test message', 'Component', longDetails);
        Test.stopTest();

        PF_Run_Log__c log = [
            SELECT Details__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertEquals(32000, log.Details__c.length(),
            'Details should be truncated to 32,000 chars');
        System.assert(log.Details__c.endsWith('...'),
            'Truncated details should end with ...');
    }

    /**
     * @description Test convenience method: info()
     */
    @IsTest
    static void testConvenienceMethod_Info() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PromptFactoryLogger.info(run.Id, 5, 'Info message');
        Test.stopTest();

        PF_Run_Log__c log = [
            SELECT Log_Level__c, Log_Message__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertEquals('INFO', log.Log_Level__c, 'Level should be INFO');
        System.assertEquals('Info message', log.Log_Message__c, 'Message should match');
    }

    /**
     * @description Test convenience method: debug()
     */
    @IsTest
    static void testConvenienceMethod_Debug() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PromptFactoryLogger.debug(run.Id, 5, 'Debug message');
        Test.stopTest();

        PF_Run_Log__c log = [
            SELECT Log_Level__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertEquals('DEBUG', log.Log_Level__c, 'Level should be DEBUG');
    }

    /**
     * @description Test convenience method: warning()
     */
    @IsTest
    static void testConvenienceMethod_Warning() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PromptFactoryLogger.warning(run.Id, 5, 'Warning message');
        Test.stopTest();

        PF_Run_Log__c log = [
            SELECT Log_Level__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertEquals('WARNING', log.Log_Level__c, 'Level should be WARNING');
    }

    /**
     * @description Test convenience method: error()
     */
    @IsTest
    static void testConvenienceMethod_Error() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PromptFactoryLogger.error(run.Id, 5, 'Error message');
        Test.stopTest();

        PF_Run_Log__c log = [
            SELECT Log_Level__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertEquals('ERROR', log.Log_Level__c, 'Level should be ERROR');
    }

    /**
     * @description Test exception logging
     */
    @IsTest
    static void testLogException() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        try {
            Integer x = 1 / 0; // Cause exception
        } catch (Exception e) {
            Test.startTest();
            PromptFactoryLogger.logException(run.Id, 6, 'Division error occurred', e);
            Test.stopTest();

            PF_Run_Log__c log = [
                SELECT Log_Level__c, Log_Message__c, Details__c
                FROM PF_Run_Log__c
                WHERE Run__c = :run.Id
                LIMIT 1
            ];

            System.assertEquals('ERROR', log.Log_Level__c, 'Level should be ERROR');
            System.assert(log.Log_Message__c.contains('Division error occurred'),
                'Message should contain context');
            System.assert(log.Log_Message__c.contains('Divide by 0'),
                'Message should contain exception message');
            System.assertNotEquals(null, log.Details__c, 'Details should be populated');

            // Verify details contain exception info
            Map<String, String> details = (Map<String, String>)
                JSON.deserialize(log.Details__c, Map<String, String>.class);
            System.assert(details.containsKey('exceptionType'), 'Should have exception type');
            System.assert(details.containsKey('stackTrace'), 'Should have stack trace');
        }
    }

    /**
     * @description Test logging with null stage number (pipeline-level logs)
     */
    @IsTest
    static void testLog_NullStageNumber() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        Test.startTest();
        PromptFactoryLogger.log(run.Id, null, 'INFO', 'Pipeline-level message');
        Test.stopTest();

        PF_Run_Log__c log = [
            SELECT Stage_Number__c, Log_Message__c
            FROM PF_Run_Log__c
            WHERE Run__c = :run.Id
            LIMIT 1
        ];

        System.assertEquals(null, log.Stage_Number__c, 'Stage number should be null');
        System.assertEquals('Pipeline-level message', log.Log_Message__c, 'Message should match');
    }

    /**
     * @description Test that logging doesn't throw exceptions even with invalid data
     */
    @IsTest
    static void testLog_ErrorHandling() {
        Test.startTest();
        // These should not throw exceptions
        PromptFactoryLogger.log(null, 1, 'INFO', 'Test'); // Invalid run ID
        PromptFactoryLogger.log('001000000000001', 1, 'INFO', null); // Null message
        Test.stopTest();

        // Should complete without exception
        System.assert(true, 'Should handle errors gracefully');
    }

    /**
     * @description Test bulk operations - 200+ log entries
     */
    @IsTest
    static void testBulkOperations_200Plus() {
        PF_Run__c run = [SELECT Id FROM PF_Run__c LIMIT 1];

        List<PF_Run_Log__c> logEntries = new List<PF_Run_Log__c>();
        for (Integer i = 0; i < 250; i++) {
            logEntries.add(PromptFactoryLogger.createLogEntry(
                run.Id, 1, 'INFO', 'Bulk message ' + i, 'BulkComponent'
            ));
        }

        Test.startTest();
        PromptFactoryLogger.bulkLog(logEntries);
        Test.stopTest();

        Integer logCount = [SELECT COUNT() FROM PF_Run_Log__c WHERE Run__c = :run.Id];
        System.assertEquals(250, logCount, 'Should create all 250 log entries');
    }

    /**
     * @description Test log buffering mechanism
     */
    @IsTest
    static void testLogBuffering() {
        // Use a unique run for this test to ensure clean counts
        Account testAcc = new Account(Name = 'Buffering Test Account');
        insert testAcc;
        
        PF_Run__c buffRun = new PF_Run__c(
            Root_Object__c = 'Account',
            Sample_Record_Id__c = testAcc.Id,
            Business_Context__c = 'Test context',
            Output_Format__c = 'HTML',
            Prompt_Name__c = 'Buffering Test Prompt',
            Status__c = 'In Progress',
            Current_Stage__c = 1
        );
        insert buffRun;

        Test.startTest();
        
        // Enable buffering
        PromptFactoryLogger.enableBuffering();
        
        // Generate logs - these should NOT be inserted yet
        PromptFactoryLogger.log(buffRun.Id, 1, 'INFO', 'Buffered Log 1');
        PromptFactoryLogger.log(buffRun.Id, 1, 'INFO', 'Buffered Log 2');
        
        // Verify nothing inserted yet for this run
        Integer countBeforeFlush = [SELECT COUNT() FROM PF_Run_Log__c WHERE Run__c = :buffRun.Id];
        System.assertEquals(0, countBeforeFlush, 'Logs should not be inserted while buffering is enabled');
        
        // Flush logs
        PromptFactoryLogger.flushLogs();
        
        Test.stopTest();
        
        // Verify logs inserted after flush
        List<PF_Run_Log__c> logsAfterFlush = [SELECT Log_Message__c FROM PF_Run_Log__c WHERE Run__c = :buffRun.Id];
        System.assertEquals(2, logsAfterFlush.size(), 'Logs should be inserted after flush');
        
        // Verify content manually since we can't filter by Long Text Area in SOQL
        Boolean foundLog1 = false;
        Boolean foundLog2 = false;
        for(PF_Run_Log__c log : logsAfterFlush) {
            if(log.Log_Message__c == 'Buffered Log 1') foundLog1 = true;
            if(log.Log_Message__c == 'Buffered Log 2') foundLog2 = true;
        }
        System.assert(foundLog1, 'Should find Buffered Log 1');
        System.assert(foundLog2, 'Should find Buffered Log 2');
    }
}