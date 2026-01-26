// Simplified V2.5 Test - Validate Template Generation with Merge Field Reference
// This tests the FIXED V2.5 logic without needing a full run record

// 1. Build selected fields
Map<String, Object> selectedFieldsRaw = new Map<String, Object>{
    'Account' => new List<String>{'Name', 'Industry', 'AnnualRevenue', 'NumberOfEmployees', 'Type', 'Rating'},
    'Opportunity' => new List<String>{'Name', 'Amount', 'StageName', 'CloseDate', 'Probability'},
    'Contact' => new List<String>{'Name', 'Email', 'Title', 'Phone'},
    'Case' => new List<String>{'CaseNumber', 'Subject', 'Status', 'Priority', 'Origin'}
};

Map<String, Object> selectedParentFieldsRaw = new Map<String, Object>{
    'Account' => new List<String>{'OwnerId.Name', 'OwnerId.Email'}
};

List<Object> selectedGrandchildrenRaw = new List<Object>();

String rootObject = 'Account';
String businessContext = 'Generate comprehensive account dashboard with financial metrics and relationship analysis';

// 2. Build DCM Analysis
Map<String, Object> dcmStructured = new Map<String, Object>{
    'Account' => new List<String>{'Name', 'Industry', 'AnnualRevenue', 'NumberOfEmployees', 'Type', 'Rating'},
    'Opportunity' => new List<String>{'Name', 'Amount', 'StageName', 'CloseDate', 'Probability'},
    'Contact' => new List<String>{'Name', 'Email', 'Title', 'Phone'},
    'Case' => new List<String>{'CaseNumber', 'Subject', 'Status', 'Priority', 'Origin'}
};

Map<String, Object> dcmAnalysis = new Map<String, Object>{
    'rootObject' => 'Account',
    'childObjects' => new List<String>{'Opportunity', 'Contact', 'Case'},
    'fields' => dcmStructured,
    'metrics' => new List<String>{'AnnualRevenue', 'NumberOfEmployees', 'Amount', 'Probability'},
    'dates' => new List<String>{'CloseDate'},
    'statuses' => new List<String>{'StageName', 'Status', 'Priority', 'Type', 'Rating', 'Origin'},
    'identifiers' => new List<String>{'Name', 'Email', 'Title', 'CaseNumber', 'Subject', 'Phone'}
};

String dcmAnalysisJson = JSON.serialize(dcmAnalysis);

// 3. Load V2.5 Meta-Prompt Builder
Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
List<ccai__AI_Prompt__c> builders = [
    SELECT ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND ccai__Type__c = 'Context Template'
      AND Name = 'GPTfy Prompt Generation Framework v2.5'
      AND ccai__Status__c = 'Active'
    LIMIT 1
];

if (builders.isEmpty()) {
    System.debug('ERROR: V2.5 meta-prompt builder not found!');
    return;
}

String metaPrompt = builders[0].ccai__Prompt_Command__c;

// Replace placeholders
metaPrompt = metaPrompt.replace('{{DCM_ANALYSIS}}', dcmAnalysisJson);
metaPrompt = metaPrompt.replace('{{BUSINESS_CONTEXT}}', businessContext);

System.debug('========================================');
System.debug('V2.5 SIMPLE TEST (POST-FIX VALIDATION)');
System.debug('========================================');
System.debug('Meta-prompt base length: ' + metaPrompt.length() + ' chars');

// 4. BUILD UI TOOLKIT (reused from V2.0)
List<ccai__AI_Prompt__c> uiBuilders = [
    SELECT ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND ccai__Type__c = 'UI Toolkit'
      AND ccai__Status__c = 'Active'
];

String uiToolkit = '=== UI TOOLKIT ===\n\n';
for (ccai__AI_Prompt__c builder : uiBuilders) {
    uiToolkit += builder.ccai__Prompt_Command__c + '\n\n';
}

System.debug('UI Toolkit length: ' + uiToolkit.length() + ' chars');

// 5. BUILD OUTPUT RULES (reused from V2.0)
List<ccai__AI_Prompt__c> outputBuilders = [
    SELECT ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
      AND ccai__Type__c = 'Output Rules'
      AND ccai__Status__c = 'Active'
];

String outputRules = '=== OUTPUT RULES ===\n\n';
for (ccai__AI_Prompt__c builder : outputBuilders) {
    outputRules += builder.ccai__Prompt_Command__c + '\n\n';
}

System.debug('Output Rules length: ' + outputRules.length() + ' chars');

// 6. BUILD MERGE FIELD REFERENCE (THE FIX!)
String mergeFieldRef = '=== AVAILABLE MERGE FIELDS ===\n\n';
mergeFieldRef += 'Use these merge fields to reference Salesforce data in your HTML output.\n';
mergeFieldRef += 'GPTfy will substitute these with actual values at runtime.\n\n';

// Root object fields
mergeFieldRef += rootObject.toUpperCase() + ' (Root Object) - use {{{FieldName}}}:\n';
for (Object field : (List<Object>) selectedFieldsRaw.get(rootObject)) {
    mergeFieldRef += '  {{{' + String.valueOf(field) + '}}}\n';
}

// Parent lookups
if (selectedParentFieldsRaw.containsKey(rootObject)) {
    mergeFieldRef += '  -- Parent Lookups --\n';
    for (Object pf : (List<Object>) selectedParentFieldsRaw.get(rootObject)) {
        String path = String.valueOf(pf).replace('Id.', '.');
        mergeFieldRef += '  {{{' + path + '}}}\n';
    }
}
mergeFieldRef += '\n';

// Child objects
for (String objName : selectedFieldsRaw.keySet()) {
    if (objName != rootObject) {
        List<Object> fields = (List<Object>) selectedFieldsRaw.get(objName);
        String relName = objName + 's'; // Simple pluralization

        mergeFieldRef += objName.toUpperCase() + ' - use {{#' + relName + '}}...{{/' + relName + '}} iteration:\n';
        for (Object field : fields) {
            mergeFieldRef += '  {{{' + String.valueOf(field) + '}}}\n';
        }
        mergeFieldRef += '\n';
    }
}

mergeFieldRef += 'CRITICAL RESTRICTION: You MUST ONLY use fields from this list.\n';
mergeFieldRef += 'Do NOT invent calculated fields like {{{HealthScore}}} or {{{CriticalAlert}}}.\n';
mergeFieldRef += 'Do NOT use invalid syntax like {{{CriticalCase.Subject}}} - use iteration blocks instead.\n';

System.debug('Merge Field Reference length: ' + mergeFieldRef.length() + ' chars');

// 7. Assemble final meta-prompt (what V2.5 now does)
String finalMetaPrompt = metaPrompt + '\n\n' + uiToolkit + '\n\n' + outputRules + '\n\n' + mergeFieldRef;

System.debug('Final meta-prompt length: ' + finalMetaPrompt.length() + ' chars');
System.debug('========================================');

// 8. Call AI API
System.debug('Calling AIServiceClient...');
AIServiceClient.AIResponse response = AIServiceClient.callAI(
    finalMetaPrompt,
    'Generate the template.',
    8192,
    0.7
);

if (!response.success) {
    System.debug('ERROR: ' + response.errorMessage);
    return;
}

String generatedTemplate = response.content;

System.debug('========================================');
System.debug('GENERATED TEMPLATE (V2.5 POST-FIX)');
System.debug('========================================');
System.debug('Length: ' + generatedTemplate.length() + ' chars');

// 9. CRITICAL VALIDATIONS
Boolean hasHealthScore = generatedTemplate.contains('{{{HealthScore}}}');
Boolean hasCriticalAlert = generatedTemplate.contains('{{{CriticalAlert}}}');
Boolean hasTotalRevenue = generatedTemplate.contains('{{{TotalRevenue}}}');
Boolean hasInvalidSyntax = generatedTemplate.contains('{{{CriticalCase.Subject}}}');
Integer mergeFieldCount = generatedTemplate.countMatches('{{{');
Integer iterationCount = generatedTemplate.countMatches('{{#');

// Check for expected real fields
Boolean hasName = generatedTemplate.contains('{{{Name}}}');
Boolean hasRevenue = generatedTemplate.contains('{{{AnnualRevenue}}}');
Boolean hasIndustry = generatedTemplate.contains('{{{Industry}}}');
Boolean hasAmount = generatedTemplate.contains('{{{Amount}}}');

System.debug('========================================');
System.debug('VALIDATION RESULTS');
System.debug('========================================');
System.debug('✓ No invented HealthScore: ' + (!hasHealthScore));
System.debug('✓ No invented CriticalAlert: ' + (!hasCriticalAlert));
System.debug('✓ No invented TotalRevenue: ' + (!hasTotalRevenue));
System.debug('✓ No invalid syntax: ' + (!hasInvalidSyntax));
System.debug('✓ Has merge fields (10+): ' + (mergeFieldCount >= 10) + ' (' + mergeFieldCount + ')');
System.debug('✓ Has iteration blocks (1+): ' + (iterationCount >= 1) + ' (' + iterationCount + ')');
System.debug('');
System.debug('Uses expected real fields:');
System.debug('✓ Name: ' + hasName);
System.debug('✓ AnnualRevenue: ' + hasRevenue);
System.debug('✓ Industry: ' + hasIndustry);
System.debug('✓ Amount: ' + hasAmount);

System.debug('========================================');
System.debug('TEMPLATE PREVIEW (First 1500 chars)');
System.debug('========================================');
System.debug(generatedTemplate.substring(0, Math.min(1500, generatedTemplate.length())));
System.debug('========================================');

// 10. Final verdict
Boolean allChecksPassed = !hasHealthScore && !hasCriticalAlert && !hasTotalRevenue &&
                          !hasInvalidSyntax && mergeFieldCount >= 10 && iterationCount >= 1 &&
                          hasName && hasRevenue;

System.debug('');
System.debug('OVERALL RESULT: ' + (allChecksPassed ? '✓ PASS - V2.5 FIX WORKING' : '✗ FAIL - Issues detected'));
System.debug('========================================');
