/**
 * Migrate existing Builder prompts from Category__c to ccai__Type__c
 * V2.4 Task 4.10
 */

// Get Builder record type ID
Id builderRecordTypeId = Schema.SObjectType.ccai__AI_Prompt__c
    .getRecordTypeInfosByDeveloperName()
    .get('Builder')
    .getRecordTypeId();

// Query all builders that have Category__c set but Type is still 'Text'
List<ccai__AI_Prompt__c> buildersToMigrate = [
    SELECT Id, Name, Category__c, ccai__Type__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRecordTypeId
    AND Category__c != null
    AND ccai__Type__c = 'Text'
];

System.debug('Found ' + buildersToMigrate.size() + ' builders to migrate');

// Track migration counts
Map<String, Integer> migrationCounts = new Map<String, Integer>();
List<ccai__AI_Prompt__c> toUpdate = new List<ccai__AI_Prompt__c>();

for (ccai__AI_Prompt__c builder : buildersToMigrate) {
    String category = builder.Category__c;

    // Map Category to Type (they're the same values now)
    // Valid types: Quality Rule, Pattern, UI Component, Context Template, Traversal, Apex Service
    if (category == 'Quality Rule' || category == 'Pattern' ||
        category == 'UI Component' || category == 'Context Template' ||
        category == 'Traversal' || category == 'Apex Service') {

        builder.ccai__Type__c = category;
        toUpdate.add(builder);

        // Track counts
        Integer count = migrationCounts.get(category);
        migrationCounts.put(category, count == null ? 1 : count + 1);

        System.debug('Migrating: ' + builder.Name + ' -> Type: ' + category);
    } else {
        System.debug('SKIPPED (unknown category): ' + builder.Name + ' - Category: ' + category);
    }
}

// Update records
if (!toUpdate.isEmpty()) {
    update toUpdate;
    System.debug('=== Migration Complete ===');
    System.debug('Total migrated: ' + toUpdate.size());
    for (String cat : migrationCounts.keySet()) {
        System.debug('  ' + cat + ': ' + migrationCounts.get(cat));
    }
} else {
    System.debug('No builders to migrate');
}

// Verify results
List<AggregateResult> results = [
    SELECT ccai__Type__c, COUNT(Id) cnt
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRecordTypeId
    GROUP BY ccai__Type__c
];

System.debug('=== Builder Type Distribution ===');
for (AggregateResult ar : results) {
    System.debug('  ' + ar.get('ccai__Type__c') + ': ' + ar.get('cnt'));
}
