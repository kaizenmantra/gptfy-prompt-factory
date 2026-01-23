// Test Opportunity Context Injection
// Target Object: Opportunity (Id: 006QH00000HjgvlYAB)

try {
    Id oppId = '006QH00000HjgvlYAB';
    
    // 1. Fetch Request inputs (simulating Stage 1-4)
    Map<String, Object> inputs = new Map<String, Object>();
    inputs.put('rootObject', 'Opportunity');
    inputs.put('recordId', oppId);
    inputs.put('businessContext', 'Sales Negotiation');
    inputs.put('targetPersona', 'Sales Manager');
    inputs.put('htmlTemplate', '<div>Output Here</div>');
    
    // 2. Simulate Stage 5 (Field Selection) Output
    // We explicitly selecting StageName to trigger the service
    Map<String, List<Object>> selectedFields = new Map<String, List<Object>>();
    selectedFields.put('Opportunity', new List<Object>{'Name', 'StageName', 'Amount', 'CloseDate'});
    inputs.put('selectedFields', selectedFields);
    
    // MOCK FIELD METADATA (This normally comes from Stage 5)
    // We are simulating the successful transmission of this data
    Map<String, String> fieldMetadata = new Map<String, String>();
    fieldMetadata.put('StageName', 'PICKLIST');
    fieldMetadata.put('Amount', 'CURRENCY');
    inputs.put('fieldMetadata', fieldMetadata);

    // 3. Fetch Record Data (Simulating missing data fetch stage, but Stage 8 doesn't need data values for prompt assembly, 
    // it needs metadata. Wait, ApexFieldMetadataService analyzes METADATA, not the record value itself?
    // Let's check ApexFieldMetadataService. 
    // Ah, it analyzes the METADATA of the FIELD (e.g. Stage "Prospecting" has 10% prob).
    // Does it need the current record's value? 
    // "Provide context about the fields".
    // Let's look at the service implementation.
    // ... It iterates over selected fields.
    // It outputs "Field: StageName (Type: Picklist) ... Values: ..."
    // It DOES NOT seem to need the specific record's value to generate the *Prompt Instructions*.
    // The *Prompt* will instruct the LLM on how to interpret the value when it sees it in the data json.
    
    System.debug('▶️ Running Stage 8 with Opportunity Context...');
    
    Stage08_PromptAssembly stage8 = new Stage08_PromptAssembly();
    StageResult result = stage8.execute(null, inputs); // runId is null for test
    
    if (result.status == 'Completed' || result.status == 'Warning') {
        String instructions = (String) result.outputs.get('aiInstructions');
        
        System.debug('✅ Stage 8 Completed');
        System.debug('--- GENERATED INSTRUCTIONS START ---');
        System.debug(instructions);
        System.debug('--- GENERATED INSTRUCTIONS END ---');
        
        // Assertions
        Boolean hasPicklistContext = instructions.contains('Picklist Context Analysis');
        Boolean hasTopicContext = instructions.contains('RELEVANT PROMPT TOPICS');
        
        if (hasPicklistContext) {
            System.debug('✅ SUCCESS: Picklist Intelligence Injected in Prompt');
        } else {
            System.debug('❌ FAILURE: Picklist Intelligence MISSING');
        }

        if (hasTopicContext) {
            System.debug('✅ SUCCESS: Topic Context Injected in Prompt');
        } else {
            System.debug('❌ FAILURE: Topic Context MISSING');
        }
        
    } else {
        System.debug('❌ Stage 8 Failed: ' + result.errorMessage);
    }

} catch (Exception e) {
    System.debug('❌ Exception: ' + e.getMessage() + '\n' + e.getStackTraceString());
}
