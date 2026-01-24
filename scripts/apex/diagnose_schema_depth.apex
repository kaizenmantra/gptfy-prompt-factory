/**
 * Diagnostic script to analyze schema traversal depth for Account 001gD000004K2TTQA0
 * Phase 2G.1: Understanding current DCM depth capabilities
 */

Id testAccountId = '001gD000004K2TTQA0';
String rootObject = 'Account';

System.debug('=== PHASE 2G: SCHEMA DEPTH DIAGNOSTIC ===');
System.debug('Test Account: ' + testAccountId);
System.debug('Root Object: ' + rootObject);

// ============================================
// STEP 1: Check what childChain traversals exist
// ============================================
System.debug('');
System.debug('=== STEP 1: EXISTING CHILD CHAIN TRAVERSALS ===');

Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
    .get('Builder').getRecordTypeId();

List<ccai__AI_Prompt__c> traversals = [
    SELECT Id, Name, ccai__Object__c, Category__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND Category__c = 'Traversal'
      AND ccai__Status__c = 'Active'
    ORDER BY ccai__Object__c, Name
];

System.debug('Found ' + traversals.size() + ' active traversals');

Map<String, List<String>> traversalsByType = new Map<String, List<String>>();
for (ccai__AI_Prompt__c trav : traversals) {
    try {
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(trav.ccai__Prompt_Command__c);
        String travType = (String) data.get('traversalType');
        if (!traversalsByType.containsKey(travType)) {
            traversalsByType.put(travType, new List<String>());
        }
        traversalsByType.get(travType).add(trav.Name + ' (' + trav.ccai__Object__c + ')');

        if (travType == 'childChain') {
            System.debug('');
            System.debug('CHILD CHAIN: ' + trav.Name);
            System.debug('  Root: ' + data.get('rootObject'));
            System.debug('  Description: ' + data.get('description'));
            List<Object> chain = (List<Object>) data.get('chain');
            if (chain != null) {
                for (Integer i = 0; i < chain.size(); i++) {
                    Map<String, Object> step = (Map<String, Object>) chain[i];
                    System.debug('  Step ' + (i+1) + ': ' + step.get('object') +
                        ' (via ' + step.get('relationshipField') + ')');
                }
            }
        }
    } catch (Exception e) {
        System.debug('  ERROR parsing: ' + e.getMessage());
    }
}

System.debug('');
System.debug('Traversal Types Summary:');
for (String travType : traversalsByType.keySet()) {
    System.debug('  ' + travType + ': ' + traversalsByType.get(travType).size() + ' traversals');
}

// ============================================
// STEP 2: Discover child relationships for Account
// ============================================
System.debug('');
System.debug('=== STEP 2: LEVEL 1 CHILDREN OF ACCOUNT ===');

List<SchemaHelper.ChildRelationship> children = SchemaHelper.getChildRelationships(rootObject);
System.debug('Found ' + children.size() + ' child relationships');

// Key children we care about
Set<String> keyChildren = new Set<String>{
    'Opportunity', 'Contact', 'Case', 'Task', 'Event', 'Contract', 'Order'
};

List<String> selectedChildren = new List<String>();
for (SchemaHelper.ChildRelationship rel : children) {
    if (keyChildren.contains(rel.childObject)) {
        selectedChildren.add(rel.childObject);
        System.debug('  KEY: ' + rel.childObject + ' (via ' + rel.field + ')');
    }
}

// ============================================
// STEP 3: Discover grandchildren (Level 2)
// ============================================
System.debug('');
System.debug('=== STEP 3: LEVEL 2 GRANDCHILDREN ===');

Map<String, List<SchemaHelper.ChildRelationship>> grandchildren =
    SchemaHelper.discoverGrandchildRelationships(rootObject, selectedChildren);

for (String parentChild : grandchildren.keySet()) {
    System.debug('');
    System.debug(parentChild + ' children:');
    for (SchemaHelper.ChildRelationship gc : grandchildren.get(parentChild)) {
        System.debug('  - ' + gc.childObject + ' (via ' + gc.field + ')');
    }
}

// ============================================
// STEP 4: Check if we can go 3 levels deep
// ============================================
System.debug('');
System.debug('=== STEP 4: LEVEL 3 GREAT-GRANDCHILDREN (Opportunity → OCR → ???) ===');

// OCR is a grandchild of Account. What are OCR's children?
List<SchemaHelper.ChildRelationship> ocrChildren =
    SchemaHelper.getChildRelationships('OpportunityContactRole');

System.debug('OpportunityContactRole has ' + ocrChildren.size() + ' child relationships');
for (SchemaHelper.ChildRelationship rel : ocrChildren) {
    System.debug('  - ' + rel.childObject + ' (via ' + rel.field + ')');
}

// OCR doesn't have many children, but it has a PARENT lookup to Contact
System.debug('');
System.debug('OCR Parent Lookups (for UP traversal):');
List<SchemaHelper.ParentRelationship> ocrParents =
    SchemaHelper.getParentRelationships('OpportunityContactRole');
for (SchemaHelper.ParentRelationship parent : ocrParents) {
    System.debug('  - ' + parent.fieldApi + ' → ' + parent.referenceTo +
        ' (relationship: ' + parent.relationshipName + ')');
}

// ============================================
// STEP 5: Check existing DCMs for this Account
// ============================================
System.debug('');
System.debug('=== STEP 5: EXISTING DCMs FOR ACCOUNT ===');

List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
    SELECT Id, Name, ccai__Object_Name__c, CreatedDate,
        (SELECT Id, ccai__Object_Name__c, ccai__Type__c, ccai__Parent_Detail__c
         FROM ccai__AI_Data_Extraction_Details__r
         ORDER BY ccai__Type__c)
    FROM ccai__AI_Data_Extraction_Mapping__c
    WHERE ccai__Object_Name__c = :rootObject
    ORDER BY CreatedDate DESC
    LIMIT 5
];

System.debug('Found ' + dcms.size() + ' DCMs for Account');
for (ccai__AI_Data_Extraction_Mapping__c dcm : dcms) {
    System.debug('');
    System.debug('DCM: ' + dcm.Name + ' (Created: ' + dcm.CreatedDate + ')');
    System.debug('  Details:');
    for (ccai__AI_Data_Extraction_Detail__c detail : dcm.ccai__AI_Data_Extraction_Details__r) {
        String parentInfo = detail.ccai__Parent_Detail__c != null ?
            ' [Parent: ' + detail.ccai__Parent_Detail__c + ']' : '';
        System.debug('    - ' + detail.ccai__Object_Name__c + ' (' + detail.ccai__Type__c + ')' + parentInfo);
    }
}

// ============================================
// STEP 6: Summary and Recommendations
// ============================================
System.debug('');
System.debug('=== SUMMARY ===');
System.debug('Current architecture supports:');
System.debug('  - Level 1: Direct children (Opportunity, Contact, Case, etc.)');
System.debug('  - Level 2: Grandchildren (OCR, OpportunityLineItem, CaseComment, etc.)');
System.debug('  - Parent Fields: UP traversal via lookups (OCR.ContactId → Contact.Name)');
System.debug('');
System.debug('To get Contact data in OCR context:');
System.debug('  - Option A: Use parent field traversal (OCR → Contact via ContactId)');
System.debug('  - Option B: Add Level 3 support (if GPTfy DCM supports GREAT_GRANDCHILD)');
System.debug('');
System.debug('=== END DIAGNOSTIC ===');
