/**
 * Test script to verify parent field loading from traversals
 * Simulates what Stage 8 does with loadParentFieldsFromTraversals
 */

System.debug('=== Testing Parent Field Loading ===');

// Simulate the objects that would be in selectedFieldsRaw
List<String> objectsForTraversal = new List<String>{
    'Opportunity', 'Event', 'Task', 'OpportunityContactRole'
};

System.debug('Objects to check: ' + objectsForTraversal);

// Get Builder RecordType ID
Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
    .get('Builder').getRecordTypeId();

System.debug('Builder RecordType ID: ' + builderRtId);

// Query traversals for these objects (only parent-type traversals, not childChain)
Set<String> objectSet = new Set<String>(objectsForTraversal);
List<ccai__AI_Prompt__c> traversals = [
    SELECT Id, Name, ccai__Object__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND Category__c = 'Traversal'
      AND ccai__Status__c = 'Active'
      AND ccai__Object__c IN :objectSet
    ORDER BY ccai__Object__c, Name
];

System.debug('Found ' + traversals.size() + ' traversals');

Map<String, Object> parentFieldsByObject = new Map<String, Object>();

// Parse each traversal and build parent field paths
for (ccai__AI_Prompt__c trav : traversals) {
    System.debug('Processing traversal: ' + trav.Name + ' for ' + trav.ccai__Object__c);
    System.debug('  Command: ' + trav.ccai__Prompt_Command__c);

    try {
        String objectName = trav.ccai__Object__c;
        Map<String, Object> travData = (Map<String, Object>) JSON.deserializeUntyped(trav.ccai__Prompt_Command__c);

        // Skip childChain type traversals - only process parent traversals
        String traversalType = (String) travData.get('traversalType');
        System.debug('  Traversal type: ' + traversalType);

        if (traversalType == 'childChain') {
            System.debug('  SKIPPING - childChain type');
            continue;
        }

        String sourceField = (String) travData.get('sourceField');
        List<Object> fieldsRaw = (List<Object>) travData.get('fields');

        System.debug('  Source field: ' + sourceField);
        System.debug('  Fields count: ' + (fieldsRaw != null ? fieldsRaw.size() : 0));

        if (String.isNotBlank(sourceField) && fieldsRaw != null) {
            // Initialize list for this object if needed
            if (!parentFieldsByObject.containsKey(objectName)) {
                parentFieldsByObject.put(objectName, new List<String>());
            }
            List<String> objectParentFields = (List<String>) parentFieldsByObject.get(objectName);

            // Build parent field paths (e.g., "ContactId.Name", "ContactId.Title")
            for (Object fieldObj : fieldsRaw) {
                Map<String, Object> fieldData = (Map<String, Object>) fieldObj;
                String path = (String) fieldData.get('path');
                if (String.isNotBlank(path)) {
                    String fullPath = sourceField + '.' + path;
                    if (!objectParentFields.contains(fullPath)) {
                        objectParentFields.add(fullPath);
                        System.debug('  Added field: ' + fullPath);
                    }
                }
            }
        }
    } catch (Exception e) {
        System.debug('  ERROR: ' + e.getMessage());
    }
}

System.debug('');
System.debug('=== RESULT ===');
System.debug('Parent fields by object: ' + JSON.serializePretty(parentFieldsByObject));

// Show expected merge field notation
System.debug('');
System.debug('=== Expected Merge Fields ===');
for (String objName : parentFieldsByObject.keySet()) {
    System.debug(objName + ':');
    List<String> fields = (List<String>) parentFieldsByObject.get(objName);
    for (String field : fields) {
        // Convert to merge field notation
        String mergePath = field;
        if (field.contains('__c.')) {
            mergePath = field.replace('__c.', '__r.');
        } else if (field.contains('Id.')) {
            mergePath = field.replace('Id.', '.');
        }
        System.debug('  {{{' + mergePath + '}}}  (from ' + field + ')');
    }
}
