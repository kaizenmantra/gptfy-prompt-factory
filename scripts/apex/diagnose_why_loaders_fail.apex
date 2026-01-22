// Diagnostic to figure out why loaders return empty in pipeline context
// This mimics the exact conditions of Stage08 in Queueable context

System.debug('=== DIAGNOSTIC START ===');

// Test 1: Can we query builders at all?
try {
    Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c
        .getRecordTypeInfosByDeveloperName()
        .get('Builder')
        .getRecordTypeId();
    
    System.debug('Test 1 - RecordType ID lookup: SUCCESS');
    System.debug('Builder RecordTypeId: ' + builderRtId);
    
    // Test 2: Can we query WITH RecordTypeId?
    List<ccai__AI_Prompt__c> test2 = [
        SELECT Id, Name
        FROM ccai__AI_Prompt__c
        WHERE RecordTypeId = :builderRtId
    ];
    System.debug('Test 2 - Query by RecordTypeId: ' + test2.size() + ' records');
    
    // Test 3: Can we query WITH Category__c filter?
    List<ccai__AI_Prompt__c> test3 = [
        SELECT Id, Name
        FROM ccai__AI_Prompt__c
        WHERE RecordTypeId = :builderRtId
          AND Category__c = 'Quality Rule'
    ];
    System.debug('Test 3 - Query with Category filter: ' + test3.size() + ' records');
    
    // Test 4: Can we query WITH Status filter?
    List<ccai__AI_Prompt__c> test4 = [
        SELECT Id, Name
        FROM ccai__AI_Prompt__c
        WHERE RecordTypeId = :builderRtId
          AND Category__c = 'Quality Rule'
          AND ccai__Status__c = 'Active'
    ];
    System.debug('Test 4 - Query with Status filter: ' + test4.size() + ' records');
    
    // Test 5: Can we access the content field?
    if (test4.size() > 0) {
        List<ccai__AI_Prompt__c> test5 = [
            SELECT Id, Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE RecordTypeId = :builderRtId
              AND Category__c = 'Quality Rule'
              AND ccai__Status__c = 'Active'
        ];
        System.debug('Test 5 - Query with content field: ' + test5.size() + ' records');
        
        if (test5.size() > 0 && test5[0].ccai__Prompt_Command__c != null) {
            System.debug('Test 5 - Content length: ' + test5[0].ccai__Prompt_Command__c.length() + ' chars');
            System.debug('Test 5 - First 100 chars: ' + test5[0].ccai__Prompt_Command__c.substring(0, Math.min(100, test5[0].ccai__Prompt_Command__c.length())));
        } else {
            System.debug('Test 5 - FAILED: Content is null!');
        }
    }
    
    // Test 6: Check describe info for Category__c
    Schema.DescribeFieldResult categoryField = ccai__AI_Prompt__c.Category__c.getDescribe();
    System.debug('Test 6 - Category__c accessible: ' + categoryField.isAccessible());
    System.debug('Test 6 - Category__c filterable: ' + categoryField.isFilterable());
    
    // Test 7: Check describe info for ccai__Status__c
    Schema.DescribeFieldResult statusField = ccai__AI_Prompt__c.ccai__Status__c.getDescribe();
    System.debug('Test 7 - ccai__Status__c accessible: ' + statusField.isAccessible());
    System.debug('Test 7 - ccai__Status__c filterable: ' + statusField.isFilterable());
    
} catch (Exception e) {
    System.debug('EXCEPTION: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

System.debug('=== DIAGNOSTIC END ===');

// Now test the EXACT code from loadQualityRules()
System.debug('=== TESTING EXACT loadQualityRules() CODE ===');
try {
    Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c
        .getRecordTypeInfosByDeveloperName()
        .get('Builder')
        .getRecordTypeId();
    
    List<ccai__AI_Prompt__c> rules = [
        SELECT Id, Name, ccai__Prompt_Command__c
        FROM ccai__AI_Prompt__c
        WHERE RecordTypeId = :builderRtId
          AND Category__c = 'Quality Rule'
          AND ccai__Status__c = 'Active'
        ORDER BY Name
    ];
    
    System.debug('Found ' + rules.size() + ' quality rules');
    
    String result = '';
    for (ccai__AI_Prompt__c rule : rules) {
        if (String.isNotBlank(rule.ccai__Prompt_Command__c)) {
            result += rule.ccai__Prompt_Command__c + '\n\n';
            System.debug('Added ' + rule.Name + ': ' + rule.ccai__Prompt_Command__c.length() + ' chars');
        } else {
            System.debug('WARNING: ' + rule.Name + ' has blank content!');
        }
    }
    
    System.debug('Total result length: ' + result.length() + ' chars');
    System.debug('Result is blank: ' + String.isBlank(result));
    
    if (result.length() > 0) {
        System.debug('First 200 chars of result:');
        System.debug(result.substring(0, Math.min(200, result.length())));
    }
    
} catch (Exception e) {
    System.debug('EXCEPTION in loadQualityRules: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}
