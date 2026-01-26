/**
 * Manual Verification: V2.5 Pipeline (Stage 8 -> Stage 9)
 */
Id runId = 'a0gQH000005GPz2YAG'; // Use an existing run ID or create a new one
// Note: It's better to create a new one to be sure
PF_Run__c run = new PF_Run__c(
    Root_Object__c = 'Opportunity',
    Sample_Record_Id__c = '006QH00000HjgvlYAB',
    Prompt_Name__c = 'V2.5 Verification Run',
    Status__c = 'Queued',
    Current_Stage__c = 0
);
insert run;

System.debug('--- STARTING V2.5 VERIFICATION RUN: ' + run.Id + ' ---');

// Mock AI Service for Stage 8 template generation
AIServiceClient.setMockMode(true);
AIServiceClient.setMockResponse('{"template": "Account: {{{Name}}}, Amount: {{{Amount}}}, Items: {{#OpportunityLineItems}}{{{OpportunityLineItems.Product2.Name}}} - {{{OpportunityLineItems.TotalPrice}}}, {{/OpportunityLineItems}}"}');
// Since the user has a Factory LWC, I can't easily trigger the "whole" async pipeline from here without knowing the job structure.
// But I can run Stage 8 and then Stage 9 manually in this script.

Map<String, Object> inputs = PipelineState.read(run.Id);
// In a real run, Stage 7 provides these. We'll mock the essential ones.
inputs.put('rootObject', 'Opportunity');
inputs.put('sampleRecordId', '006QH00000HjgvlYAB');
inputs.put('htmlTemplate', '<div>{{{Name}}}</div>');
inputs.put('businessContext', 'Sales summary');
inputs.put('selectedFields', new Map<String, Object>{
    'Opportunity' => new List<String>{'Name', 'Amount', 'StageName'},
    'OpportunityLineItem' => new List<String>{'Product2.Name', 'Quantity', 'TotalPrice'}
});

// Run Stage 8
System.debug('--- Running Stage 8 ---');
Stage08_PromptAssembly stage8 = new Stage08_PromptAssembly();
StageResult result8 = stage8.execute(run.Id, inputs);
System.debug('Stage 8 Status: ' + result8.status);

// Run Stage 9
System.debug('--- Running Stage 9 ---');
// Merge Stage 8 outputs into inputs for Stage 9
inputs.putAll(result8.outputs);
Stage09_CreateAndDeploy stage9 = new Stage09_CreateAndDeploy();
StageResult result9 = stage9.execute(run.Id, inputs);
System.debug('Stage 9 Status: ' + result9.status);

// Inspect the final promptCommand (Merge Gate result)
Map<String, Object> finalPromptConfig = (Map<String, Object>) inputs.get('promptConfig');
String finalPrompt = (String) finalPromptConfig.get('promptCommand');

System.debug('--- FINAL RENDERED PROMPT ---');
System.debug(finalPrompt);

if (String.isNotBlank(finalPrompt) && !finalPrompt.contains('{{{')) {
    System.debug('VERIFICATION SUCCESS: Prompt is fully rendered.');
} else {
    System.debug('VERIFICATION FAILURE: Prompt contains raw merge fields or is empty.');
}
