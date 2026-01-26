// Check V2.5 Stage 8 execution for Run a0gQH000005GPIvYAO

String runId = 'a0gQH000005GPIvYAO';

// Check run status
List<PF_Run__c> runs = [
    SELECT Id, Status__c, Current_Stage__c, Error_Message__c
    FROM PF_Run__c
    WHERE Id = :runId
];

if (runs.isEmpty()) {
    System.debug('❌ Run not found');
} else {
    PF_Run__c run = runs[0];
    System.debug('Run Status: ' + run.Status__c);
    System.debug('Current Stage: ' + run.Current_Stage__c);
    if (run.Error_Message__c != null) {
        System.debug('Error: ' + run.Error_Message__c);
    }

    // Check Stage 8 logs
    List<PF_Run_Log__c> stage8Logs = [
        SELECT Stage_Number__c, Log_Level__c, Log_Message__c, Timestamp__c
        FROM PF_Run_Log__c
        WHERE Run__c = :runId AND Stage_Number__c = 8
        ORDER BY Timestamp__c
    ];

    System.debug('');
    System.debug('=== STAGE 8 LOGS (' + stage8Logs.size() + ' total) ===');
    System.debug('');

    Boolean foundV25 = false;
    Boolean foundTemplate = false;
    Boolean foundMergeFields = false;

    for (PF_Run_Log__c log : stage8Logs) {
        String msg = log.Log_Message__c;
        System.debug('[' + log.Log_Level__c + '] ' + msg);

        if (msg.contains('V2.5:')) {
            foundV25 = true;
        }
        if (msg.contains('Template generation successful')) {
            foundTemplate = true;
        }
        if (msg.contains('merge fields') || msg.contains('{{{')) {
            foundMergeFields = true;
        }
    }

    System.debug('');
    System.debug('=== V2.5 STATUS ===');
    System.debug('V2.5 Architecture: ' + (foundV25 ? '✅ ACTIVE' : '❌ NOT DETECTED'));
    System.debug('Template Generated: ' + (foundTemplate ? '✅ YES' : '❌ NO'));
    System.debug('Merge Fields Used: ' + (foundMergeFields ? '✅ YES' : '❌ NO'));

    // Get the created prompt
    List<ccai__AI_Prompt__c> prompts = [
        SELECT Id, Name, ccai__Prompt_Command__c
        FROM ccai__AI_Prompt__c
        WHERE Name LIKE 'V2.5-Test-PinnacleWealth%'
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    if (!prompts.isEmpty()) {
        ccai__AI_Prompt__c prompt = prompts[0];
        String template = prompt.ccai__Prompt_Command__c;

        System.debug('');
        System.debug('=== GENERATED TEMPLATE ===');
        System.debug('Template Length: ' + template.length() + ' chars');
        System.debug('Merge Fields: ' + template.countMatches('{{{'));
        System.debug('Iteration Blocks: ' + template.countMatches('{{#'));

        // Check for hardcoded values
        List<String> hardcodedValues = new List<String>{'Pinnacle Wealth', 'TESTDATA_', 'Sarah Chen'};
        Boolean hasHardcoded = false;
        for (String hardcoded : hardcodedValues) {
            if (template.contains(hardcoded)) {
                System.debug('⚠️  Found hardcoded value: ' + hardcoded);
                hasHardcoded = true;
            }
        }

        if (!hasHardcoded) {
            System.debug('✅ No hardcoded values detected');
        }

        // Show first 500 chars of template
        System.debug('');
        System.debug('Template Preview (first 500 chars):');
        System.debug(template.substring(0, Math.min(500, template.length())));
    } else {
        System.debug('');
        System.debug('⚠️  Prompt not yet created (may still be in progress)');
    }
}
