/**
 * Delete duplicate Traversal builder prompts
 * Keeps the oldest record for each unique Name, deletes the rest
 */

System.debug('===== DELETING DUPLICATE TRAVERSAL BUILDER PROMPTS =====');

// Get Builder RecordType ID
Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();

// Query all Traversal builders, ordered by CreatedDate
List<ccai__AI_Prompt__c> allTraversals = [
    SELECT Id, Name, CreatedDate, Category__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND Category__c = 'Traversal'
    ORDER BY Name, CreatedDate ASC
];

System.debug('Total Traversal records found: ' + allTraversals.size());

// Group by Name to find duplicates
Map<String, List<ccai__AI_Prompt__c>> traversalsByName = new Map<String, List<ccai__AI_Prompt__c>>();

for (ccai__AI_Prompt__c traversal : allTraversals) {
    if (!traversalsByName.containsKey(traversal.Name)) {
        traversalsByName.put(traversal.Name, new List<ccai__AI_Prompt__c>());
    }
    traversalsByName.get(traversal.Name).add(traversal);
}

System.debug('Unique Traversal names: ' + traversalsByName.size());

// Identify duplicates to delete (keep first, delete rest)
List<ccai__AI_Prompt__c> toDelete = new List<ccai__AI_Prompt__c>();

for (String name : traversalsByName.keySet()) {
    List<ccai__AI_Prompt__c> duplicates = traversalsByName.get(name);

    if (duplicates.size() > 1) {
        System.debug('Found ' + duplicates.size() + ' duplicates for: ' + name);
        System.debug('  Keeping: ' + duplicates[0].Id + ' (Created: ' + duplicates[0].CreatedDate + ')');

        // Keep first (oldest), delete the rest
        for (Integer i = 1; i < duplicates.size(); i++) {
            System.debug('  Deleting: ' + duplicates[i].Id + ' (Created: ' + duplicates[i].CreatedDate + ')');
            toDelete.add(duplicates[i]);
        }
    } else {
        System.debug('No duplicates for: ' + name);
    }
}

System.debug('\n===== SUMMARY =====');
System.debug('Total duplicates to delete: ' + toDelete.size());

if (toDelete.isEmpty()) {
    System.debug('✅ No duplicates found - nothing to delete');
} else {
    System.debug('Deleting ' + toDelete.size() + ' duplicate records...');

    try {
        delete toDelete;
        System.debug('✅ Successfully deleted ' + toDelete.size() + ' duplicate Traversal records');

        // Show final count
        Integer remainingCount = [
            SELECT COUNT()
            FROM ccai__AI_Prompt__c
            WHERE RecordTypeId = :builderRtId
              AND Category__c = 'Traversal'
        ];
        System.debug('Remaining Traversal records: ' + remainingCount);

    } catch (Exception e) {
        System.debug('❌ ERROR deleting duplicates: ' + e.getMessage());
        System.debug(e.getStackTraceString());
    }
}

System.debug('\n===== CLEANUP COMPLETE =====');
