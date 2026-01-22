// Check what Category__c picklist values are actually available in the org

System.debug('=== CHECKING CATEGORY__C PICKLIST VALUES ===');

Schema.DescribeFieldResult fieldDescribe = 
    ccai__AI_Prompt__c.Category__c.getDescribe();

System.debug('Field Type: ' + fieldDescribe.getType());
System.debug('Is Restricted: ' + fieldDescribe.isRestrictedPicklist());

List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
System.debug('Total Values: ' + entries.size());

System.debug('\nAvailable Picklist Values:');
for (Schema.PicklistEntry entry : entries) {
    System.debug('  - "' + entry.getValue() + '" (Label: "' + entry.getLabel() + '", Active: ' + entry.isActive() + ')');
}

System.debug('\n=== END ===');
