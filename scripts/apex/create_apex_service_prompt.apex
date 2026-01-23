// Create or Update Apex Service Builder Prompt
try {
    Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
    
    // Check for existing
    List<ccai__AI_Prompt__c> existing = [
        SELECT Id FROM ccai__AI_Prompt__c 
        WHERE Name = 'Picklist Intelligence Service' 
        LIMIT 1
    ];
    
    ccai__AI_Prompt__c service;
    if (existing.isEmpty()) {
        service = new ccai__AI_Prompt__c();
        service.Name = 'Picklist Intelligence Service';
    } else {
        service = existing[0];
    }
    
    service.RecordTypeId = builderRtId;
    service.Category__c = 'Apex Service';
    service.ccai__Prompt_Command__c = 'ApexFieldMetadataService';
    service.ccai__Status__c = 'Active';
    service.ccai__Object__c = null; // Universal
    // service.Weight__c = 10; // Field doesn't exist yet
    
    upsert service;
    System.debug('Upserted Apex Service Prompt: ' + service.Id);
    
} catch (Exception e) {
    System.debug('Error upserting prompt: ' + e.getMessage());
}
