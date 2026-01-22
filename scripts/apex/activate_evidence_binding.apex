// Activate Evidence Binding builder
ccai__AI_Prompt__c builder = [
    SELECT Id, Name, ccai__Status__c, ccai__Message__c
    FROM ccai__AI_Prompt__c
    WHERE Id = 'a0DQH00000KYZxW2AX'
    LIMIT 1
];

System.debug('Current Status: ' + builder.ccai__Status__c);
System.debug('Current Message: ' + builder.ccai__Message__c);

try {
    builder.ccai__Status__c = 'Active';
    update builder;
    
    System.debug('✅ Successfully activated!');
    
    // Verify
    builder = [SELECT ccai__Status__c, ccai__Message__c FROM ccai__AI_Prompt__c WHERE Id = :builder.Id];
    System.debug('New Status: ' + builder.ccai__Status__c);
    System.debug('New Message: ' + builder.ccai__Message__c);
    
} catch (Exception e) {
    System.debug('❌ Activation FAILED: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    
    if (e instanceof DmlException) {
        DmlException dmlEx = (DmlException) e;
        System.debug('DML Message: ' + dmlEx.getDmlMessage(0));
        System.debug('DML Type: ' + dmlEx.getDmlType(0));
    }
}
