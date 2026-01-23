/**
 * Test script to verify traversal loading logic works correctly
 * Tests both child chain discovery (Stage 3) and parent field loading (Stage 8)
 */

// Test 1: Verify child chain traversals are loadable for Opportunity
System.debug('=== TEST 1: Child Chain Discovery for Opportunity ===');

Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
    .get('Builder').getRecordTypeId();

List<ccai__AI_Prompt__c> oppChains = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND Category__c = 'Traversal'
      AND ccai__Status__c = 'Active'
      AND ccai__Object__c = 'Opportunity'
];

System.debug('Found ' + oppChains.size() + ' child chain traversals for Opportunity');
for (ccai__AI_Prompt__c chain : oppChains) {
    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(chain.ccai__Prompt_Command__c);
    String traversalType = (String) data.get('traversalType');
    if (traversalType == 'childChain') {
        System.debug('  ✓ ' + chain.Name);
        List<Object> chainSteps = (List<Object>) data.get('chain');
        for (Object step : chainSteps) {
            Map<String, Object> stepData = (Map<String, Object>) step;
            System.debug('    → ' + stepData.get('object'));
        }
    }
}

// Test 2: Verify parent field traversals for OpportunityContactRole
System.debug('');
System.debug('=== TEST 2: Parent Field Traversals for OpportunityContactRole ===');

List<ccai__AI_Prompt__c> ocrTraversals = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND Category__c = 'Traversal'
      AND ccai__Status__c = 'Active'
      AND ccai__Object__c = 'OpportunityContactRole'
];

System.debug('Found ' + ocrTraversals.size() + ' parent traversals for OpportunityContactRole');
for (ccai__AI_Prompt__c trav : ocrTraversals) {
    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(trav.ccai__Prompt_Command__c);
    String traversalType = (String) data.get('traversalType');

    // Skip childChain types - only process parent traversals
    if (traversalType == 'childChain') continue;

    String sourceField = (String) data.get('sourceField');
    String targetObject = (String) data.get('targetObject');
    List<Object> fields = (List<Object>) data.get('fields');

    System.debug('  ✓ ' + trav.Name);
    System.debug('    Source Field: ' + sourceField);
    System.debug('    Target Object: ' + targetObject);

    System.debug('    Parent Field Paths:');
    for (Object fieldObj : fields) {
        Map<String, Object> fieldData = (Map<String, Object>) fieldObj;
        String path = (String) fieldData.get('path');
        System.debug('      - ' + sourceField + '.' + path);
    }
}

// Test 3: Expected parent fields that should be added to DCM for OpportunityContactRole
System.debug('');
System.debug('=== TEST 3: Expected DCM Parent Fields ===');
System.debug('When OpportunityContactRole is in the DCM, these parent fields should be added:');
System.debug('  - ContactId.Name');
System.debug('  - ContactId.Title');
System.debug('  - ContactId.Email');
System.debug('  - ContactId.Phone');

System.debug('');
System.debug('=== TEST COMPLETE ===');
System.debug('To validate end-to-end, run the Prompt Factory with Opportunity root object.');
System.debug('Then check the DCM fields for ContactId.Name, ContactId.Title, etc.');
