// Check ALL Stage 8 logs including errors

String runId = 'a0gQH000005GPIvYAO';

// Check all logs for this run
List<PF_Run_Log__c> allLogs = [
    SELECT Stage_Number__c, Log_Level__c, Log_Message__c, Timestamp__c, Component__c
    FROM PF_Run_Log__c
    WHERE Run__c = :runId
    ORDER BY Timestamp__c
];

System.debug('=== ALL LOGS FOR RUN (' + allLogs.size() + ' total) ===');
System.debug('');

Integer stage8Count = 0;
Boolean foundV25Message = false;

for (PF_Run_Log__c log : allLogs) {
    String stageLabel = log.Stage_Number__c != null ? 'Stage ' + log.Stage_Number__c : 'Controller';
    String component = log.Component__c != null ? ' [' + log.Component__c + ']' : '';
    String msg = log.Log_Message__c;

    // Print all Stage 8 logs and errors
    if (log.Stage_Number__c == 8 || log.Log_Level__c == 'ERROR') {
        System.debug('[' + stageLabel + ']' + component + ' [' + log.Log_Level__c + '] ' + msg);

        if (log.Stage_Number__c == 8) {
            stage8Count++;
        }

        if (msg.contains('V2.5')) {
            foundV25Message = true;
        }
    }
}

System.debug('');
System.debug('Total Stage 8 logs: ' + stage8Count);
System.debug('V2.5 messages found: ' + foundV25Message);
