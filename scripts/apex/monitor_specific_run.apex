// Monitor Specific Run
Id runId = 'a0gQH000005GHTRYA4';

System.debug('🔍 Monitoring Run: ' + runId);

// 1. Check Run Status
PF_Run__c run = [SELECT Id, Status__c, Current_Stage__c, Error_Message__c FROM PF_Run__c WHERE Id = :runId];
System.debug('Run Status: ' + run.Status__c + ' | Stage: ' + run.Current_Stage__c);

if (run.Error_Message__c != null) {
    System.debug('❌ Error: ' + run.Error_Message__c);
}

// 2. Check Stage 8 Logs for Fix Verification
List<PF_Run_Log__c> stage8Logs = [
    SELECT Log_Level__c, Log_Message__c 
    FROM PF_Run_Log__c 
    WHERE Run__c = :runId 
    AND Stage_Number__c = 8 
    ORDER BY Timestamp__c ASC
];

if (!stage8Logs.isEmpty()) {
    System.debug('--- Stage 8 Logs ---');
    for (PF_Run_Log__c log : stage8Logs) {
        if (log.Log_Message__c.contains('✅') || log.Log_Level__c == 'ERROR' || log.Log_Message__c.contains('📊')) {
             System.debug(log.Log_Message__c);
        }
    }
} else {
    System.debug('ℹ️ No logs for Stage 8 yet.');
}

// 3. Get Stage 8 Result (if available) to check content length
// Note: We can't query StageResult directly as it's not a record, 
// but we can infer success from the run status moving past 8.
if (run.Current_Stage__c > 8 || run.Status__c == 'Completed') {
     System.debug('✅ Stage 8 Completed.');
}
