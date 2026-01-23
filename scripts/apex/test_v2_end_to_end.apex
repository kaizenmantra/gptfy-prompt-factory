/**
 * Task 4.1: V2.0 End-to-End Test
 *
 * Tests full V2.0 flow with:
 * - Multi-sample profiling (3 Opportunities)
 * - Pattern detection
 * - Meta-prompt assembly with 6 sections
 */

// Test input: 3 Opportunities with varied amounts and stages
String sampleRecordIds = '006QH00000Hjl5qYAB,006QH00000HjgvlYAB,006gD000001lqquQAA';
// Harrison ($1.35M, Proposal/Price Quote)
// Employee Health Insurance ($1.5M, Needs Analysis)
// GPTfy Sales Enablement ($150K, Proposal/Price Quote)

System.debug('===== STARTING V2.0 END-TO-END TEST =====');
System.debug('Sample IDs: ' + sampleRecordIds);

// Start pipeline run
String runId;
try {
    runId = PromptFactoryController.startPipelineRun(
        'Sales Manager Dashboard',  // templateName
        'Opportunity',               // rootObject
        sampleRecordIds,             // sampleRecordId (comma-separated)
        'Sales Manager',             // targetPersona
        null,                        // industry
        null,                        // promptTemplateId
        null                         // recordTypeDeveloperName
    );

    System.debug('✅ PF_Run created: ' + runId);
} catch (Exception e) {
    System.debug('❌ ERROR creating PF_Run: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}

// Query the PF_Run to check initial state
if (runId != null) {
    PF_Run__c run = [
        SELECT Id, Name, Status__c, Current_Stage__c,
               Sample_Record_Id__c, Root_Object__c
        FROM PF_Run__c
        WHERE Id = :runId
    ];

    System.debug('\n===== PF_RUN INITIAL STATE =====');
    System.debug('ID: ' + run.Id);
    System.debug('Name: ' + run.Name);
    System.debug('Status: ' + run.Status__c);
    System.debug('Current Stage: ' + run.Current_Stage__c);
    System.debug('Sample Record ID (primary): ' + run.Sample_Record_Id__c);
    System.debug('Root Object: ' + run.Root_Object__c);
    System.debug('\nNOTE: Multi-sample IDs parsing will be checked in PromptFactoryController');
}

System.debug('\n===== TEST INITIATED =====');
System.debug('The pipeline will execute stages 1-9 asynchronously.');
System.debug('To monitor progress:');
System.debug('1. Query PF_Run__c WHERE Id = \'' + runId + '\'');
System.debug('2. Check Status__c and Current_Stage__c fields');
System.debug('3. Check Stage outputs (Stage04_Output__c, Stage07_Output__c, Stage08_Output__c)');
System.debug('4. Final AI Prompt: SELECT ccai__Prompt_Command__c FROM ccai__AI_Prompt__c WHERE PF_Run__c = \'' + runId + '\' AND RecordType.DeveloperName = \'Instruction\'');

System.debug('\n===== VALIDATION CHECKLIST =====');
System.debug('After pipeline completes, verify:');
System.debug('[ ] Stage 4: multiSampleProfile with 3 samples, patterns detected');
System.debug('[ ] Stage 5: selectedFields considering multi-sample data');
System.debug('[ ] Stage 7: useMetaPrompt = true in output');
System.debug('[ ] Stage 8: AI Prompt has 6 meta-prompt sections');
System.debug('[ ] Meta-prompt includes compressed builders (not verbose)');
System.debug('[ ] UI Toolkit section present');
System.debug('[ ] Data Payload section shows patterns');

System.debug('\n===== RUN ID FOR REFERENCE =====');
System.debug(runId);
