/**
 * Diagnostic script to understand why parent fields aren't appearing in Stage 8 output
 * This script checks:
 * 1. What inputs Stage 8 receives from prior stages
 * 2. Whether loadParentFieldsFromTraversals is being called
 * 3. What the final merge field reference looks like
 */

System.debug('=== STAGE 8 PARENT FIELD DIAGNOSTICS ===');

// Step 1: Check the most recent run to see what inputs Stage 8 received
List<PF_Run__c> recentRuns = [
    SELECT Id, Name, Stage__c, Status__c, CreatedDate, Root_Object__c
    FROM PF_Run__c
    WHERE Status__c = 'Completed'
    ORDER BY CreatedDate DESC
    LIMIT 1
];

if (recentRuns.isEmpty()) {
    System.debug('No completed runs found!');
} else {
    PF_Run__c run = recentRuns[0];
    System.debug('Most recent run: ' + run.Name + ' (ID: ' + run.Id + ')');
    System.debug('  Root Object: ' + run.Root_Object__c);
    System.debug('  Status: ' + run.Status__c);
    System.debug('  Created: ' + run.CreatedDate);
}

// Step 2: Query the traversals to see if they exist and are active
Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
    .get('Builder').getRecordTypeId();

List<ccai__AI_Prompt__c> allTraversals = [
    SELECT Id, Name, ccai__Object__c, ccai__Status__c, Category__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND Category__c = 'Traversal'
    ORDER BY ccai__Object__c, Name
];

System.debug('');
System.debug('=== ALL TRAVERSAL RECORDS ===');
System.debug('Found ' + allTraversals.size() + ' traversal records');

for (ccai__AI_Prompt__c trav : allTraversals) {
    System.debug('');
    System.debug('Traversal: ' + trav.Name);
    System.debug('  Object: ' + trav.ccai__Object__c);
    System.debug('  Status: ' + trav.ccai__Status__c);
    System.debug('  Category: ' + trav.Category__c);

    // Parse the command to show structure
    try {
        Map<String, Object> travData = (Map<String, Object>) JSON.deserializeUntyped(trav.ccai__Prompt_Command__c);
        String traversalType = (String) travData.get('traversalType');
        String sourceField = (String) travData.get('sourceField');
        String targetObject = (String) travData.get('targetObject');
        System.debug('  Type: ' + traversalType);
        System.debug('  Source Field: ' + sourceField);
        System.debug('  Target Object: ' + targetObject);

        List<Object> fieldsRaw = (List<Object>) travData.get('fields');
        if (fieldsRaw != null) {
            System.debug('  Fields count: ' + fieldsRaw.size());
            for (Object f : fieldsRaw) {
                Map<String, Object> fieldData = (Map<String, Object>) f;
                System.debug('    - ' + fieldData.get('path'));
            }
        }
    } catch (Exception e) {
        System.debug('  ERROR parsing command: ' + e.getMessage());
    }
}

// Step 3: Simulate what loadParentFieldsFromTraversals would return for OpportunityContactRole
System.debug('');
System.debug('=== SIMULATING loadParentFieldsFromTraversals ===');

List<String> testObjects = new List<String>{'Opportunity', 'OpportunityContactRole', 'Event', 'Task'};
Set<String> objectSet = new Set<String>(testObjects);

System.debug('Input objects: ' + testObjects);

List<ccai__AI_Prompt__c> matchingTraversals = [
    SELECT Id, Name, ccai__Object__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND Category__c = 'Traversal'
      AND ccai__Status__c = 'Active'
      AND ccai__Object__c IN :objectSet
    ORDER BY ccai__Object__c, Name
];

System.debug('Matching active traversals: ' + matchingTraversals.size());

Map<String, Object> parentFieldsByObject = new Map<String, Object>();

for (ccai__AI_Prompt__c trav : matchingTraversals) {
    System.debug('  Processing: ' + trav.Name + ' for ' + trav.ccai__Object__c);
    try {
        String objectName = trav.ccai__Object__c;
        Map<String, Object> travData = (Map<String, Object>) JSON.deserializeUntyped(trav.ccai__Prompt_Command__c);

        // Skip childChain type
        String traversalType = (String) travData.get('traversalType');
        if (traversalType == 'childChain') {
            System.debug('    SKIPPED: childChain type');
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
                        System.debug('    ADDED: ' + fullPath);
                    }
                }
            }
        }
    } catch (Exception e) {
        System.debug('    ERROR: ' + e.getMessage());
    }
}

System.debug('');
System.debug('=== RESULT: parentFieldsByObject ===');
System.debug(JSON.serializePretty(parentFieldsByObject));

// Step 4: Check what the most recent prompt's AVAILABLE MERGE FIELDS section looks like
System.debug('');
System.debug('=== CHECKING RECENT PROMPT OUTPUT ===');

List<ccai__AI_Prompt__c> recentPrompts = [
    SELECT Id, Name, ccai__Object__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Execution'
      AND ccai__Object__c = 'Opportunity'
    ORDER BY CreatedDate DESC
    LIMIT 1
];

if (!recentPrompts.isEmpty()) {
    ccai__AI_Prompt__c prompt = recentPrompts[0];
    String promptText = prompt.ccai__Prompt_Command__c;
    if (promptText != null && promptText.contains('AVAILABLE MERGE FIELDS')) {
        Integer startIdx = promptText.indexOf('=== AVAILABLE MERGE FIELDS ===');
        Integer endIdx = promptText.indexOf('===', startIdx + 30);
        if (endIdx < 0) endIdx = Math.min(promptText.length(), startIdx + 2000);

        String mergeFieldSection = promptText.substring(startIdx, Math.min(endIdx, promptText.length()));
        System.debug('Merge Field Section from prompt ' + prompt.Name + ':');
        System.debug(mergeFieldSection);

        // Check if it contains parent field patterns
        Boolean hasParentFields = mergeFieldSection.contains('Parent Fields via Lookup') ||
                                  mergeFieldSection.contains('Parent fields (within');
        System.debug('');
        System.debug('Contains parent field section? ' + hasParentFields);
    }
}
