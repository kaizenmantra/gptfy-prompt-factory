/**
 * Delete ALL duplicate builder prompts across all categories
 * Keeps the oldest record for each unique Name, deletes the rest
 */

System.debug('===== DELETING ALL DUPLICATE BUILDER PROMPTS =====');

// Get Builder RecordType ID
Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();

// Query ALL builders, ordered by CreatedDate
List<ccai__AI_Prompt__c> allBuilders = [
    SELECT Id, Name, Category__c, CreatedDate, ccai__Status__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
    ORDER BY Name, CreatedDate ASC
];

System.debug('Total Builder records found: ' + allBuilders.size());

// Group by Name to find duplicates
Map<String, List<ccai__AI_Prompt__c>> buildersByName = new Map<String, List<ccai__AI_Prompt__c>>();

for (ccai__AI_Prompt__c builder : allBuilders) {
    if (!buildersByName.containsKey(builder.Name)) {
        buildersByName.put(builder.Name, new List<ccai__AI_Prompt__c>());
    }
    buildersByName.get(builder.Name).add(builder);
}

System.debug('Unique Builder names: ' + buildersByName.size());

// Identify duplicates to delete (keep first/oldest, delete rest)
List<ccai__AI_Prompt__c> toDelete = new List<ccai__AI_Prompt__c>();
Integer duplicateGroupCount = 0;

for (String name : buildersByName.keySet()) {
    List<ccai__AI_Prompt__c> duplicates = buildersByName.get(name);

    if (duplicates.size() > 1) {
        duplicateGroupCount++;
        System.debug('\n[' + duplicateGroupCount + '] Found ' + duplicates.size() + ' duplicates for: ' + name);
        System.debug('  Category: ' + duplicates[0].Category__c);
        System.debug('  ✅ Keeping: ' + duplicates[0].Id + ' (Created: ' + duplicates[0].CreatedDate + ')');

        // Keep first (oldest), delete the rest
        for (Integer i = 1; i < duplicates.size(); i++) {
            System.debug('  ❌ Deleting: ' + duplicates[i].Id + ' (Created: ' + duplicates[i].CreatedDate + ')');
            toDelete.add(duplicates[i]);
        }
    }
}

System.debug('\n===== SUMMARY =====');
System.debug('Total builder prompts: ' + allBuilders.size());
System.debug('Unique names: ' + buildersByName.size());
System.debug('Names with duplicates: ' + duplicateGroupCount);
System.debug('Total duplicates to delete: ' + toDelete.size());

if (toDelete.isEmpty()) {
    System.debug('✅ No duplicates found - nothing to delete');
} else {
    System.debug('\nDeleting ' + toDelete.size() + ' duplicate records...');

    try {
        delete toDelete;
        System.debug('✅ Successfully deleted ' + toDelete.size() + ' duplicate Builder records');

        // Show final counts by category
        System.debug('\n===== FINAL COUNTS BY CATEGORY =====');

        AggregateResult[] categoryResults = [
            SELECT Category__c, COUNT(Id) cnt
            FROM ccai__AI_Prompt__c
            WHERE RecordTypeId = :builderRtId
            GROUP BY Category__c
            ORDER BY Category__c
        ];

        for (AggregateResult ar : categoryResults) {
            String category = (String) ar.get('Category__c');
            Integer count = (Integer) ar.get('cnt');
            System.debug('  ' + category + ': ' + count + ' records');
        }

        Integer totalRemaining = [
            SELECT COUNT()
            FROM ccai__AI_Prompt__c
            WHERE RecordTypeId = :builderRtId
        ];
        System.debug('\nTotal remaining Builder records: ' + totalRemaining);

    } catch (Exception e) {
        System.debug('❌ ERROR deleting duplicates: ' + e.getMessage());
        System.debug(e.getStackTraceString());
    }
}

System.debug('\n===== CLEANUP COMPLETE =====');
