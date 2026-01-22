// Direct test of Stage08 builder loading
System.debug('═══════════════════════════════════════════════════════');
System.debug('🔬 DIAGNOSING STAGE08 BUILDER INJECTION');
System.debug('═══════════════════════════════════════════════════════\n');

// Step 1: Verify builders exist in database
System.debug('📊 STEP 1: Check if builders exist in database\n');

List<ccai__AI_Prompt__c> allBuilders = [
    SELECT Id, Name, Category__c, ccai__Status__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
    ORDER BY Category__c, Name
];

System.debug('Found ' + allBuilders.size() + ' builders:');
for (ccai__AI_Prompt__c b : allBuilders) {
    Integer contentSize = b.ccai__Prompt_Command__c != null ? b.ccai__Prompt_Command__c.length() : 0;
    System.debug('  - ' + b.Name + ' [' + b.Category__c + '] - ' + contentSize + ' chars, Status: ' + b.ccai__Status__c);
}

// Step 2: Test Quality Rules query (exact same query as Stage08)
System.debug('\n📊 STEP 2: Test Quality Rules query (as Stage08 does)\n');

try {
    List<ccai__AI_Prompt__c> rules = [
        SELECT Id, Name, ccai__Prompt_Command__c
        FROM ccai__AI_Prompt__c
        WHERE RecordType.DeveloperName = 'Builder'
          AND Category__c = 'Quality Rule'
          AND ccai__Status__c = 'Active'
        ORDER BY Name
    ];
    
    System.debug('✅ Query SUCCESS: Found ' + rules.size() + ' Quality Rules');
    for (ccai__AI_Prompt__c r : rules) {
        System.debug('  - ' + r.Name + ': ' + r.ccai__Prompt_Command__c.length() + ' chars');
    }
} catch (Exception e) {
    System.debug('❌ Query FAILED: ' + e.getMessage());
    System.debug('   Stack: ' + e.getStackTraceString());
}

// Step 3: Test Patterns query
System.debug('\n📊 STEP 3: Test Patterns query\n');

try {
    List<ccai__AI_Prompt__c> patterns = [
        SELECT Id, Name, ccai__Prompt_Command__c
        FROM ccai__AI_Prompt__c
        WHERE RecordType.DeveloperName = 'Builder'
          AND Category__c = 'Pattern'
          AND ccai__Status__c = 'Active'
        ORDER BY Name
    ];
    
    System.debug('✅ Query SUCCESS: Found ' + patterns.size() + ' Patterns');
    for (ccai__AI_Prompt__c p : patterns) {
        System.debug('  - ' + p.Name + ': ' + p.ccai__Prompt_Command__c.length() + ' chars');
    }
} catch (Exception e) {
    System.debug('❌ Query FAILED: ' + e.getMessage());
}

// Step 4: Check FLS on Category__c field
System.debug('\n📊 STEP 4: Check Field-Level Security on Category__c\n');

Schema.DescribeFieldResult categoryField = ccai__AI_Prompt__c.Category__c.getDescribe();
System.debug('Field Accessible: ' + categoryField.isAccessible());
System.debug('Field Updateable: ' + categoryField.isUpdateable());
System.debug('Field Type: ' + categoryField.getType());

if (categoryField.getPicklistValues().size() > 0) {
    System.debug('Picklist Values:');
    for (Schema.PicklistEntry ple : categoryField.getPicklistValues()) {
        System.debug('  - ' + ple.getValue() + ' (Active: ' + ple.isActive() + ')');
    }
}

// Step 5: Check Record Type access
System.debug('\n📊 STEP 5: Check Record Type access\n');

List<RecordType> rts = [
    SELECT Id, DeveloperName, Name, IsActive
    FROM RecordType
    WHERE SObjectType = 'ccai__AI_Prompt__c'
      AND DeveloperName = 'Builder'
];

if (!rts.isEmpty()) {
    System.debug('✅ Builder Record Type found: ' + rts[0].Id);
    System.debug('   Name: ' + rts[0].Name);
    System.debug('   Active: ' + rts[0].IsActive);
} else {
    System.debug('❌ Builder Record Type NOT FOUND!');
}

// Step 6: Simulate what Stage08 buildAIInstructions() would do
System.debug('\n📊 STEP 6: Simulate Stage08 buildAIInstructions()\n');

String instructions = 'Base instructions here...\n\n';
Integer initialLength = instructions.length();

System.debug('Initial length: ' + initialLength + ' chars');

// Load Quality Rules (same logic as Stage08)
try {
    List<ccai__AI_Prompt__c> rules = [
        SELECT Id, Name, ccai__Prompt_Command__c
        FROM ccai__AI_Prompt__c
        WHERE RecordType.DeveloperName = 'Builder'
          AND Category__c = 'Quality Rule'
          AND ccai__Status__c = 'Active'
        ORDER BY Name
    ];
    
    if (!rules.isEmpty()) {
        String allRules = '';
        for (ccai__AI_Prompt__c rule : rules) {
            allRules += '\n\n=== ' + rule.Name + ' ===\n\n';
            allRules += rule.ccai__Prompt_Command__c;
        }
        instructions += allRules + '\n\n';
        System.debug('✅ Injected Quality Rules: +' + allRules.length() + ' chars');
    } else {
        System.debug('⚠️ No Quality Rules to inject (query returned 0)');
    }
} catch (Exception e) {
    System.debug('❌ Quality Rules injection FAILED: ' + e.getMessage());
}

// Load Patterns
try {
    List<ccai__AI_Prompt__c> patterns = [
        SELECT Id, Name, ccai__Prompt_Command__c
        FROM ccai__AI_Prompt__c
        WHERE RecordType.DeveloperName = 'Builder'
          AND Category__c = 'Pattern'
          AND ccai__Status__c = 'Active'
        ORDER BY Name
    ];
    
    if (!patterns.isEmpty()) {
        String allPatterns = '';
        for (ccai__AI_Prompt__c pattern : patterns) {
            allPatterns += '\n\n=== ' + pattern.Name + ' ===\n\n';
            allPatterns += pattern.ccai__Prompt_Command__c;
        }
        instructions += allPatterns + '\n\n';
        System.debug('✅ Injected Patterns: +' + allPatterns.length() + ' chars');
    } else {
        System.debug('⚠️ No Patterns to inject (query returned 0)');
    }
} catch (Exception e) {
    System.debug('❌ Patterns injection FAILED: ' + e.getMessage());
}

Integer finalLength = instructions.length();
Integer added = finalLength - initialLength;

System.debug('\n📊 FINAL RESULTS:');
System.debug('   Initial length: ' + initialLength + ' chars');
System.debug('   Final length: ' + finalLength + ' chars');
System.debug('   Added by builders: ' + added + ' chars');

if (added > 1000) {
    System.debug('\n✅ SUCCESS: Builders ARE being injected! (+' + added + ' chars)');
} else {
    System.debug('\n❌ PROBLEM: Builders NOT being injected! Only +' + added + ' chars');
}

System.debug('\n═══════════════════════════════════════════════════════');
System.debug('🔬 DIAGNOSIS COMPLETE');
System.debug('═══════════════════════════════════════════════════════');
