/**
 * Verify Parent Lookup Auto-Discovery Fix
 *
 * This script verifies that DCMBuilder now auto-discovers parent lookups
 * for child objects, specifically checking for:
 * - OpportunityContactRole → Contact parent lookup
 * - Contact.Name, Contact.Title, Contact.Email fields
 *
 * Run this after creating a NEW DCM (not an old one) to verify the fix works.
 */

System.debug('=== PARENT LOOKUP AUTO-DISCOVERY VERIFICATION ===\n');

// Query for a recent Opportunity DCM
List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
    SELECT Id, Name, ccai__Object_Name__c, CreatedDate,
           (SELECT Id, ccai__Object_Name__c, ccai__Type__c, ccai__RelationshipField__c,
                   ccai__RelationshipName__c
            FROM ccai__AI_Data_Extraction_Details__r
            WHERE ccai__Type__c = 'PARENT_LOOKUP'
            ORDER BY ccai__Object_Name__c)
    FROM ccai__AI_Data_Extraction_Mapping__c
    WHERE ccai__Object_Name__c = 'Opportunity'
    ORDER BY CreatedDate DESC
    LIMIT 1
];

if (dcms.isEmpty()) {
    System.debug('❌ No Opportunity DCM found. Create a new pipeline run first.\n');
} else {
    ccai__AI_Data_Extraction_Mapping__c dcm = dcms[0];
    System.debug('Found DCM: ' + dcm.Name + ' (Created: ' + dcm.CreatedDate + ')');
    System.debug('DCM ID: ' + dcm.Id + '\n');

    // Check for Contact parent lookup
    Boolean hasContactLookup = false;
    for (ccai__AI_Data_Extraction_Detail__c detail : dcm.ccai__AI_Data_Extraction_Details__r) {
        if (detail.ccai__Object_Name__c == 'Contact' &&
            detail.ccai__Type__c == 'PARENT_LOOKUP') {
            hasContactLookup = true;
            System.debug('✅ PARENT_LOOKUP detail found:');
            System.debug('   Target Object: ' + detail.ccai__Object_Name__c);
            System.debug('   Relationship Field: ' + detail.ccai__RelationshipField__c);
            System.debug('   Relationship Name: ' + detail.ccai__RelationshipName__c + '\n');
        }
    }

    if (!hasContactLookup) {
        System.debug('❌ No Contact PARENT_LOOKUP found!');
        System.debug('   This DCM was created BEFORE the parent lookup fix was deployed.\n');
        System.debug('   ACTION: Create a NEW pipeline run to test the fix.\n');
    }

    // Check for Contact fields
    if (hasContactLookup) {
        List<ccai__AI_Data_Extraction_Field__c> contactFields = [
            SELECT Id, ccai__Field_API_Name__c, ccai__Object_API_Name__c
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcm.Id
              AND ccai__Object_API_Name__c = 'Contact'
            ORDER BY ccai__Field_API_Name__c
        ];

        System.debug('Contact fields (' + contactFields.size() + ' total):');
        Set<String> requiredFields = new Set<String>{'Name', 'Title', 'Email'};
        Set<String> foundFields = new Set<String>();

        for (ccai__AI_Data_Extraction_Field__c field : contactFields) {
            System.debug('   - ' + field.ccai__Field_API_Name__c);
            if (requiredFields.contains(field.ccai__Field_API_Name__c)) {
                foundFields.add(field.ccai__Field_API_Name__c);
            }
        }

        System.debug('');
        if (foundFields.containsAll(requiredFields)) {
            System.debug('✅ All required Contact fields present: Name, Title, Email\n');
            System.debug('✅ PARENT LOOKUP AUTO-DISCOVERY IS WORKING!\n');
        } else {
            Set<String> missing = new Set<String>(requiredFields);
            missing.removeAll(foundFields);
            System.debug('❌ Missing Contact fields: ' + missing + '\n');
        }
    }
}

System.debug('=== VERIFICATION COMPLETE ===');
