Map<String, Schema.SObjectField> fields = PF_Run__c.SObjectType.getDescribe().fields.getMap();
System.debug('Total fields: ' + fields.size());
for (String fname : fields.keySet()) {
    System.debug('Field: ' + fname);
}
