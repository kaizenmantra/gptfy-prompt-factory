// Check V2.5 execution for FRESH run

String runId = 'a0gQH000005GPNlYAO';

// Check run status
List<PF_Run__c> runs = [SELECT Status__c, Current_Stage__c, Error_Message__c FROM PF_Run__c WHERE Id = :runId];

if (runs.isEmpty()) {
    System.debug('❌ Run not found');
} else {
    PF_Run__c run = runs[0];
    System.debug('Run Status: ' + run.Status__c);
    System.debug('Current Stage: ' + run.Current_Stage__c);
    if (run.Error_Message__c != null) {
        System.debug('Error: ' + run.Error_Message__c);
    }
}

// Check ALL Stage 8 logs
List<PF_Run_Log__c> stage8Logs = [
    SELECT Stage_Number__c, Log_Level__c, Log_Message__c
    FROM PF_Run_Log__c
    WHERE Run__c = :runId AND Stage_Number__c = 8
    ORDER BY Timestamp__c
];

System.debug('');
System.debug('=== STAGE 8 LOGS (' + stage8Logs.size() + ' found) ===');
Integer v25Count = 0;
Boolean foundTemplate = false;
for (PF_Run_Log__c log : stage8Logs) {
    String msg = log.Log_Message__c;
    System.debug('[Stage ' + log.Stage_Number__c + '] ' + msg);

    if (msg.contains('V2.5')) {
        v25Count++;
    }
    if (msg.contains('Template generation successful')) {
        foundTemplate = true;
    }
}

System.debug('');
System.debug('V2.5 messages: ' + v25Count);
if (foundTemplate) {
    System.debug('✅ TEMPLATE GENERATED VIA V2.5');
} else if (v25Count > 0) {
    System.debug('⚠️  V2.5 started but template generation not confirmed');
} else {
    System.debug('❌ V2.5 NOT ACTIVATED');
}
