// Test if Stage08 builder queries work
System.debug('=== TESTING BUILDER QUERIES ===');

// Test Quality Rules query
List<ccai__AI_Prompt__c> rules = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND Category__c = 'Quality Rule'
      AND ccai__Status__c = 'Active'
    ORDER BY Name
];

System.debug('\n1. Quality Rules Query:');
System.debug('   Found: ' + rules.size() + ' rules');
for (ccai__AI_Prompt__c r : rules) {
    System.debug('   - ' + r.Name + ' (Content length: ' + r.ccai__Prompt_Command__c.length() + ' chars)');
    System.debug('     First 200 chars: ' + r.ccai__Prompt_Command__c.substring(0, Math.min(200, r.ccai__Prompt_Command__c.length())));
}

// Test Patterns query
List<ccai__AI_Prompt__c> patterns = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND Category__c = 'Pattern'
      AND ccai__Status__c = 'Active'
    ORDER BY Name
];

System.debug('\n2. Patterns Query:');
System.debug('   Found: ' + patterns.size() + ' patterns');
for (ccai__AI_Prompt__c p : patterns) {
    System.debug('   - ' + p.Name + ' (Content length: ' + p.ccai__Prompt_Command__c.length() + ' chars)');
}

// Test UI Components query
List<ccai__AI_Prompt__c> components = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND Category__c = 'UI Component'
      AND ccai__Status__c = 'Active'
    ORDER BY Name
];

System.debug('\n3. UI Components Query:');
System.debug('   Found: ' + components.size() + ' components');
for (ccai__AI_Prompt__c c : components) {
    System.debug('   - ' + c.Name);
}

// Test Context Templates query
List<ccai__AI_Prompt__c> templates = [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND Category__c = 'Context Template'
      AND ccai__Status__c = 'Active'
    ORDER BY Name
];

System.debug('\n4. Context Templates Query:');
System.debug('   Found: ' + templates.size() + ' templates');
for (ccai__AI_Prompt__c t : templates) {
    System.debug('   - ' + t.Name);
}

System.debug('\n=== ALL QUERIES SUCCESSFUL ===');
System.debug('Total builders: ' + (rules.size() + patterns.size() + components.size() + templates.size()));
