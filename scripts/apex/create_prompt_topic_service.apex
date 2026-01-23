// Create or Update Prompt Topic Service Builder Prompt
try {
    Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
    
    // Check for existing
    List<ccai__AI_Prompt__c> existing = [
        SELECT Id FROM ccai__AI_Prompt__c 
        WHERE Name = 'Contextual Topic Service' 
        LIMIT 1
    ];
    
    ccai__AI_Prompt__c service;
    if (existing.isEmpty()) {
        service = new ccai__AI_Prompt__c();
        service.Name = 'Contextual Topic Service';
    } else {
        service = existing[0];
    }
    
    service.RecordTypeId = builderRtId;
    service.Category__c = 'Apex Service';
    service.ccai__Prompt_Command__c = 'PromptTopicService';
    service.ccai__Status__c = 'Active';
    service.ccai__Object__c = null; // Universal
    
    upsert service;
    System.debug('Upserted Prompt Topic Service: ' + service.Id);
    
} catch (Exception e) {
    System.debug('Error upserting prompt: ' + e.getMessage());
}
