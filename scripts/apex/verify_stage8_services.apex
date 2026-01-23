// Verify Stage 8 Service Integration
try {
    Stage08_PromptAssembly stage8 = new Stage08_PromptAssembly();
    Id runId = null; // Can be null for testing if logging handles it (PromptFactoryLogger might expect an Id, let's use a dummy or handle null)
    // Actually PromptFactoryLogger methods take runId. If null, they might throw or just log.
    // Let's create a dummy PF_Run__c if needed, or just rely on logger robustness.
    // Assuming logger is robust.
    
    Map<String, Object> inputs = new Map<String, Object>();
    inputs.put('rootObject', 'Opportunity');
    inputs.put('businessContext', 'Test Context');
    inputs.put('targetPersona', 'Sales Rep');
    inputs.put('htmlTemplate', '<div style="color:blue">{{{Name}}}</div>');
    inputs.put('selectedFields', new Map<String, Object>{
        'Opportunity' => new List<Object>{'Name', 'StageName', 'Amount'}
    });
    inputs.put('businessObjectives', new List<Object>{'Close Deals'});
    
    // MOCK FIELD METADATA (Crucial for ApexFieldMetadataService)
    Map<String, String> fieldMetadata = new Map<String, String>();
    fieldMetadata.put('StageName', 'PICKLIST');
    inputs.put('fieldMetadata', fieldMetadata);
    
    // Execute Stage 8
    StageResult result = stage8.execute(runId, inputs);
    
    if (result.status == 'Completed' || result.status == 'Warning') {
        String instructions = (String) result.outputs.get('aiInstructions');
        System.debug('Stage 8 Success!');
        
        // CHECK FOR SERVICE OUTPUT
        if (instructions.contains('=== AUTOMATED DATA ANALYSIS ===')) {
             System.debug('✅ Service Injection Block Found');
             
             if (instructions.contains('PICKLIST CONTEXT')) {
                 System.debug('✅ ApexFieldMetadataService output found!');
             } else {
                 System.debug('❌ ApexFieldMetadataService output NOT found in: ' + instructions.substring(0, Math.min(500, instructions.length())));
             }
             
             if (instructions.contains('RELEVANT PROMPT TOPICS')) {
                 System.debug('✅ PromptTopicService output found!');
             } else {
                 System.debug('❌ PromptTopicService output NOT found');
             }
        } else {
             System.debug('❌ Service Injection Block NOT Found');
        }
    } else {
        System.debug('Stage 8 Failed: ' + result.errorMessage);
    }

} catch (Exception e) {
    System.debug('Test Exception: ' + e.getMessage() + '\n' + e.getStackTraceString());
}
