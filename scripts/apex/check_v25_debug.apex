// Check V2.5 debug flag log

String runId = 'a0gQH000005GPPNYA4';

List<PF_Run_Log__c> stage8Logs = [
    SELECT Log_Message__c
    FROM PF_Run_Log__c
    WHERE Run__c = :runId AND Stage_Number__c = 8
    ORDER BY Timestamp__c
];

System.debug('=== STAGE 8 LOGS ===');
for (PF_Run_Log__c log : stage8Logs) {
    System.debug(log.Log_Message__c);
}
