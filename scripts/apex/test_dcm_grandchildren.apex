/**
 * Test DCM creation with grandchildren (Phase 2G.5)
 * Directly tests DCMBuilder to verify grandchild support works
 * Bypasses stage pipeline to isolate DCM creation logic
 */

System.debug('=== TEST: DCM CREATION WITH GRANDCHILDREN ===');

// Build a test configuration with grandchildren
DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
config.name = 'Test_Account_Grandchildren_' + System.now().getTime();
config.rootObject = 'Account';

// Add child objects (Level 1)
config.childObjects = new List<DCMBuilder.ObjectConfig>();

// Child 1: Opportunity (direct child of Account)
DCMBuilder.ObjectConfig oppConfig = new DCMBuilder.ObjectConfig(
    'Opportunity', 'Opportunities', 'AccountId'
);
oppConfig.maxRecords = 10;
config.childObjects.add(oppConfig);

// Child 2: Contact (direct child of Account)
DCMBuilder.ObjectConfig contactConfig = new DCMBuilder.ObjectConfig(
    'Contact', 'Contacts', 'AccountId'
);
contactConfig.maxRecords = 10;
config.childObjects.add(contactConfig);

// Grandchild 1: OpportunityContactRole (child of Opportunity)
DCMBuilder.ObjectConfig ocrConfig = new DCMBuilder.ObjectConfig(
    'OpportunityContactRole', 'OpportunityContactRoles', 'OpportunityId', 'Opportunity'
);
ocrConfig.maxRecords = 5;
config.childObjects.add(ocrConfig);

// Grandchild 2: OpportunityLineItem (child of Opportunity)
DCMBuilder.ObjectConfig oliConfig = new DCMBuilder.ObjectConfig(
    'OpportunityLineItem', 'OpportunityLineItems', 'OpportunityId', 'Opportunity'
);
oliConfig.maxRecords = 10;
config.childObjects.add(oliConfig);

// Add fields for each object
config.fieldsByObject = new Map<String, List<String>>();
config.fieldsByObject.put('Account', new List<String>{'Name', 'Industry', 'Type'});
config.fieldsByObject.put('Opportunity', new List<String>{'Name', 'Amount', 'StageName', 'CloseDate'});
config.fieldsByObject.put('Contact', new List<String>{'Name', 'Email', 'Title'});
config.fieldsByObject.put('OpportunityContactRole', new List<String>{'Role', 'IsPrimary'});
config.fieldsByObject.put('OpportunityLineItem', new List<String>{'Quantity', 'TotalPrice', 'Description'});

// Add parent fields (V2.2 feature)
config.selectedParentFields = new Map<String, List<String>>();
config.selectedParentFields.put('Opportunity', new List<String>{'OwnerId.Name'});
config.selectedParentFields.put('OpportunityContactRole', new List<String>{'ContactId.Name', 'ContactId.Email'});

// Validate configuration first
System.debug('');
System.debug('=== VALIDATING CONFIGURATION ===');
List<String> errors = DCMBuilder.validateConfigWithSchema(config);
if (!errors.isEmpty()) {
    System.debug('VALIDATION ERRORS:');
    for (String err : errors) {
        System.debug('  - ' + err);
    }
    return;
}
System.debug('Configuration is valid');

// Create the DCM
System.debug('');
System.debug('=== CREATING DCM ===');
Id dcmId;
try {
    dcmId = DCMBuilder.createDCMWithGrandchildren(config);
    System.debug('DCM created successfully: ' + dcmId);
} catch (Exception e) {
    System.debug('ERROR creating DCM: ' + e.getMessage());
    System.debug('Stack: ' + e.getStackTraceString());
    return;
}

// Verify the created DCM structure
System.debug('');
System.debug('=== VERIFYING DCM STRUCTURE ===');

// Query the DCM with details
List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
    SELECT Id, Name, ccai__Object_Name__c,
        (SELECT Id, ccai__Object_Name__c, ccai__Type__c, ccai__RelationshipField__c,
                ccai__Parent_Detail__c, ccai__Record_Limit__c
         FROM ccai__AI_Data_Extraction_Details__r
         ORDER BY ccai__Type__c, ccai__Object_Name__c)
    FROM ccai__AI_Data_Extraction_Mapping__c
    WHERE Id = :dcmId
];

if (dcms.isEmpty()) {
    System.debug('ERROR: DCM not found after creation!');
    return;
}

ccai__AI_Data_Extraction_Mapping__c dcm = dcms[0];
System.debug('DCM: ' + dcm.Name);
System.debug('Root Object: ' + dcm.ccai__Object_Name__c);
System.debug('Details: ' + dcm.ccai__AI_Data_Extraction_Details__r.size());

Integer childCount = 0;
Integer grandchildCount = 0;

for (ccai__AI_Data_Extraction_Detail__c detail : dcm.ccai__AI_Data_Extraction_Details__r) {
    String parentInfo = detail.ccai__Parent_Detail__c != null
        ? ' [Parent: ' + detail.ccai__Parent_Detail__c + ']'
        : '';
    System.debug('  - ' + detail.ccai__Object_Name__c +
        ' (Type: ' + detail.ccai__Type__c +
        ', RelField: ' + detail.ccai__RelationshipField__c +
        ', Limit: ' + detail.ccai__Record_Limit__c + ')' + parentInfo);

    if (detail.ccai__Type__c == 'CHILD') {
        childCount++;
    } else if (detail.ccai__Type__c == 'GRANDCHILD') {
        grandchildCount++;
    }
}

System.debug('');
System.debug('=== SUMMARY ===');
System.debug('CHILD objects: ' + childCount);
System.debug('GRANDCHILD objects: ' + grandchildCount);

// Query fields created
Integer fieldCount = [SELECT COUNT() FROM ccai__AI_Data_Extraction_Field__c WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId];
System.debug('Total fields created: ' + fieldCount);

// Query parent fields specifically
List<ccai__AI_Data_Extraction_Field__c> parentFields = [
    SELECT Id, ccai__Field__c, ccai__Object__c, ccai__Label__c
    FROM ccai__AI_Data_Extraction_Field__c
    WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
      AND ccai__Field__c LIKE '%.%'
];
System.debug('Parent fields (dot notation): ' + parentFields.size());
for (ccai__AI_Data_Extraction_Field__c pf : parentFields) {
    System.debug('  - ' + pf.ccai__Object__c + ': ' + pf.ccai__Field__c + ' (' + pf.ccai__Label__c + ')');
}

if (grandchildCount > 0) {
    System.debug('');
    System.debug('SUCCESS: Grandchild support is working!');
} else {
    System.debug('');
    System.debug('WARNING: No grandchild objects created - check DCMBuilder logic');
}

// Clean up - delete the test DCM
System.debug('');
System.debug('=== CLEANUP ===');
try {
    delete dcms;
    System.debug('Test DCM deleted successfully');
} catch (Exception e) {
    System.debug('Warning: Could not delete test DCM: ' + e.getMessage());
}

System.debug('');
System.debug('=== TEST COMPLETE ===');
