// Simulate Stage 8 with Company Profile to reproduce Missing Middle
try {
    Id runId = null; 
    Map<String, Object> inputs = new Map<String, Object>();
    inputs.put('rootObject', 'Opportunity');
    inputs.put('businessContext', 'Test Context');
    inputs.put('targetPersona', 'Sales Rep');
    inputs.put('htmlTemplate', '<div>Output Here</div>');
    inputs.put('selectedFields', new Map<String, Object>{
        'Opportunity' => new List<Object>{'Name', 'StageName'}
    });
    
    // ADD COMPANY PROFILE (Suspect Cause)
    String profile = '## 1. Industry Context\n- Primary Industry: Health Insurance\n... [Imagine long text] ... member-centric focus.';
    inputs.put('companyProfile', profile);
    inputs.put('companyIntelligence', profile); // Ensure effective context is set
    
    // Mock Field Metadata
    Map<String, String> fieldMetadata = new Map<String, String>();
    fieldMetadata.put('StageName', 'PICKLIST');
    inputs.put('fieldMetadata', fieldMetadata);

    System.debug('▶️ Running Stage 8 Simulation with Company Profile...');
    
    Stage08_PromptAssembly stage8 = new Stage08_PromptAssembly();
    StageResult result = stage8.execute(runId, inputs);
    
    if (result.status == 'Completed' || result.status == 'Warning') {
        String instructions = (String) result.outputs.get('aiInstructions');
        
        System.debug('--- GENERATED INSTRUCTIONS START ---');
        System.debug(instructions);
        System.debug('--- GENERATED INSTRUCTIONS END ---');
        
        // CHECK CONTINUITY
        Boolean hasProfile = instructions.contains('member-centric focus');
        Boolean hasAnalysisReq = instructions.contains('CRITICAL: ANALYSIS REQUIREMENTS');
        Boolean hasApexService = instructions.contains('Picklist Context Analysis');
        
        if (hasProfile && !hasAnalysisReq) {
            System.debug('❌ REPRODUCED: Profile present, but Analysis Requirements MISSING!');
        } else if (hasProfile && hasAnalysisReq) {
             System.debug('✅ NOT REPRODUCED: Both Profile and Analysis Requirements present.');
        } else {
            System.debug('❓ INCONCLUSIVE: Profile missing? ' + hasProfile);
        }
        
    } else {
        System.debug('❌ Stage 8 Failed: ' + result.errorMessage);
    }

} catch (Exception e) {
    System.debug('❌ Exception: ' + e.getMessage());
}
