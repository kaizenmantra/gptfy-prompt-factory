/**
 * Test to verify Stage 8 parent field loading is working
 */

// Simulate inputs like Stage 8 would receive
Map<String, Object> selectedFieldsRaw = new Map<String, Object>{
    'Opportunity' => new List<String>{'Id', 'Name', 'Amount'},
    'OpportunityContactRole' => new List<String>{'Id', 'Role', 'IsPrimary'},
    'Event' => new List<String>{'Id', 'Subject'},
    'Task' => new List<String>{'Id', 'Subject'}
};

Map<String, Object> selectedParentFieldsRaw = null; // Simulate null from Stage 5

System.debug('=== Test Stage 8 Parent Field Loading ===');
System.debug('selectedFieldsRaw: ' + selectedFieldsRaw.keySet());
System.debug('selectedParentFieldsRaw before: ' + selectedParentFieldsRaw);

// This is the condition from Stage 8
if (selectedParentFieldsRaw == null || selectedParentFieldsRaw.isEmpty()) {
    System.debug('Condition TRUE - should auto-load parent fields');

    // Get Builder RecordType ID
    Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
        .get('Builder').getRecordTypeId();

    List<String> objectsForTraversal = new List<String>(selectedFieldsRaw.keySet());
    System.debug('Objects for traversal: ' + objectsForTraversal);

    // Query traversals
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

    for (ccai__AI_Prompt__c trav : traversals) {
        try {
            String objectName = trav.ccai__Object__c;
            Map<String, Object> travData = (Map<String, Object>) JSON.deserializeUntyped(trav.ccai__Prompt_Command__c);

            String traversalType = (String) travData.get('traversalType');
            if (traversalType == 'childChain') {
                continue;
            }

            String sourceField = (String) travData.get('sourceField');
            List<Object> fieldsRaw = (List<Object>) travData.get('fields');

            if (String.isNotBlank(sourceField) && fieldsRaw != null) {
                if (!parentFieldsByObject.containsKey(objectName)) {
                    parentFieldsByObject.put(objectName, new List<String>());
                }
                List<String> objectParentFields = (List<String>) parentFieldsByObject.get(objectName);

                for (Object fieldObj : fieldsRaw) {
                    Map<String, Object> fieldData = (Map<String, Object>) fieldObj;
                    String path = (String) fieldData.get('path');
                    if (String.isNotBlank(path)) {
                        String fullPath = sourceField + '.' + path;
                        if (!objectParentFields.contains(fullPath)) {
                            objectParentFields.add(fullPath);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    selectedParentFieldsRaw = parentFieldsByObject;
    System.debug('selectedParentFieldsRaw after: ' + JSON.serialize(selectedParentFieldsRaw));

} else {
    System.debug('Condition FALSE - selectedParentFieldsRaw already has data');
}

// Now simulate what buildMergeFieldReference would output
System.debug('');
System.debug('=== What buildMergeFieldReference would output ===');
for (String objName : selectedFieldsRaw.keySet()) {
    if (objName != 'Opportunity') {
        System.debug(objName + ' (Child):');
        if (selectedParentFieldsRaw != null && selectedParentFieldsRaw.containsKey(objName)) {
            System.debug('  Parent fields:');
            List<String> parentFields = (List<String>) selectedParentFieldsRaw.get(objName);
            for (String pathStr : parentFields) {
                String mergePath = pathStr;
                if (pathStr.contains('__c.')) {
                    mergePath = pathStr.replace('__c.', '__r.');
                } else if (pathStr.contains('Id.')) {
                    mergePath = pathStr.replace('Id.', '.');
                }
                System.debug('    {{{' + mergePath + '}}}');
            }
        } else {
            System.debug('  NO parent fields found');
        }
    }
}
