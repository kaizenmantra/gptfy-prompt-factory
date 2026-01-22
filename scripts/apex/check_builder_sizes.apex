// Check actual character sizes of builder content
List<ccai__AI_Prompt__c> builders = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = '012QH0000045bz7YAA'
      AND ccai__Status__c = 'Active'
    ORDER BY Name
];

Integer totalSize = 0;
System.debug('=== BUILDER SIZES ===');

for (ccai__AI_Prompt__c builder : builders) {
    Integer size = builder.ccai__Prompt_Command__c != null ? builder.ccai__Prompt_Command__c.length() : 0;
    totalSize += size;
    System.debug(builder.Name + ': ' + size + ' chars');
}

System.debug('---');
System.debug('Total Builder Content: ' + totalSize + ' chars');
System.debug('Base Prompt Content: ~10,000 chars');
System.debug('TOTAL EXPECTED: ' + (totalSize + 10000) + ' chars');
System.debug('Field Limit: 132,000 chars');
System.debug('---');

if (totalSize + 10000 > 132000) {
    System.debug('❌ WOULD EXCEED FIELD LIMIT!');
} else {
    System.debug('✅ Within field limit (margin: ' + (132000 - totalSize - 10000) + ' chars)');
}
