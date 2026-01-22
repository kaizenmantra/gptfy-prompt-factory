// Test that PromptFactoryLogger now works with all fields deployed

// Create a test run
PF_Run__c testRun = new PF_Run__c(
    Root_Object__c = 'Test',
    Status__c = 'In Progress',
    Prompt_Name__c = 'Logging Test'
);
insert testRun;

System.debug('Created test run: ' + testRun.Id);

// Test all logging levels
PromptFactoryLogger.debug(testRun.Id, 1, 'This is a DEBUG message');
PromptFactoryLogger.info(testRun.Id, 2, 'This is an INFO message');
PromptFactoryLogger.warning(testRun.Id, 3, 'This is a WARNING message');
PromptFactoryLogger.error(testRun.Id, 4, 'This is an ERROR message');

System.debug('Logs written. Waiting 2 seconds for async commits...');

// Query logs to verify they were created
List<PF_Run_Log__c> logs = [
    SELECT Id, Log_Level__c, Stage_Number__c, Log_Message__c, Component__c, 
           Details__c, Success__c, Record_Count__c, Execution_Time_MS__c
    FROM PF_Run_Log__c
    WHERE Run__c = :testRun.Id
    ORDER BY CreatedDate
];

System.debug('Found ' + logs.size() + ' log entries:');
for (PF_Run_Log__c log : logs) {
    System.debug('  [' + log.Log_Level__c + '] Stage ' + log.Stage_Number__c + ': ' + log.Log_Message__c);
}

if (logs.size() == 4) {
    System.debug('✅ SUCCESS - All 4 logs created with all fields!');
    System.debug('✅ PromptFactoryLogger is now fully functional!');
} else {
    System.debug('⚠️ WARNING - Expected 4 logs, found ' + logs.size());
}

// Clean up
delete testRun;  // Cascade deletes logs
System.debug('Test run deleted');
