// Full End-to-End Test: V2.5 Through Complete GPTfy Pipeline
// Test with real account: Pinnacle Wealth Partners

Id accountId = '001QH000024mdDnYAI';

// Build field selection
Map<String, Object> selectedFieldsRaw = new Map<String, Object>{
    'Account' => new List<String>{'Name', 'Industry', 'AnnualRevenue', 'NumberOfEmployees', 'Type', 'Rating'},
    'Opportunity' => new List<String>{'Name', 'Amount', 'StageName', 'CloseDate'},
    'Contact' => new List<String>{'Name', 'Email', 'Title'},
    'Case' => new List<String>{'CaseNumber', 'Subject', 'Status', 'Priority'}
};

Map<String, Object> selectedParentFieldsRaw = new Map<String, Object>{
    'Account' => new List<String>{'OwnerId.Name', 'OwnerId.Email'}
};

List<Object> selectedGrandchildrenRaw = new List<Object>();

String businessContext = 'Generate comprehensive account dashboard with financial metrics and relationship insights';

System.debug('========================================');
System.debug('V2.5 FULL PIPELINE TEST');
System.debug('========================================');
System.debug('Account: Pinnacle Wealth Partners (' + accountId + ')');
System.debug('V2.5 Enabled: true');
System.debug('========================================');

// Execute full pipeline
Map<String, Object> pipelineInputs = new Map<String, Object>{
    'rootObject' => 'Account',
    'recordId' => accountId,
    'selectedFields' => selectedFieldsRaw,
    'selectedParentFields' => selectedParentFieldsRaw,
    'selectedGrandchildren' => selectedGrandchildrenRaw,
    'businessContext' => businessContext
};

try {
    Id runId = GPTfyOrchestrator.executeFullPipeline(pipelineInputs);

    System.debug('Pipeline started successfully');
    System.debug('Run ID: ' + runId);
    System.debug('========================================');
    System.debug('Check GPTfy Run record for results:');
    System.debug('- Navigate to: /' + runId);
    System.debug('- Or query: SELECT Id, Name, ccai__Status__c, ccai__Error_Message__c FROM ccai__GPTfy_Run__c WHERE Id = \'' + runId + '\'');
    System.debug('========================================');

} catch (Exception e) {
    System.debug('ERROR: Pipeline execution failed');
    System.debug('Message: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
