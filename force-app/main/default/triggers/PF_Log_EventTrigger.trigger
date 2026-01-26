/**
 * @description Trigger on PF_Log_Event__e to process logging requests
 * asynchronously. This prevents "Uncommitted work pending" errors when logging
 * occurs before HTTP callouts in the same transaction.
 */
trigger PF_Log_EventTrigger on PF_Log_Event__e (after insert) {
    List<PF_Run_Log__c> logRecords = new List<PF_Run_Log__c>();
    
    for (PF_Log_Event__e event : Trigger.new) {
        logRecords.add(new PF_Run_Log__c(
            Run__c = event.Run_Id__c,
            Stage_Number__c = event.Stage_Number__c != null ? Integer.valueOf(event.Stage_Number__c) : null,
            Log_Level__c = event.Log_Level__c,
            Log_Message__c = event.Log_Message__c,
            Timestamp__c = System.now(),
            Component__c = event.Component__c,
            Details__c = event.Details__c
        ));
    }
    
    if (!logRecords.isEmpty()) {
        Database.insert(logRecords, false); // All or none = false to prevent one bad log from breaking others
    }
}
