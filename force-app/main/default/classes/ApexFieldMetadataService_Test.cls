@IsTest
private class ApexFieldMetadataService_Test {
    
    @IsTest
    static void testOpportunityStageContext() {
        // Setup inputs
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('rootObject', 'Opportunity');
        
        // Mock selected fields
        Map<String, List<String>> selectedFields = new Map<String, List<String>>();
        selectedFields.put('Opportunity', new List<String>{'StageName'});
        inputs.put('selectedFields', selectedFields);
        
        Test.startTest();
        ApexFieldMetadataService service = new ApexFieldMetadataService();
        String result = service.execute(inputs);
        Test.stopTest();
        
        System.assert(result.contains('Opportunity.StageName'), 'Should contain field header');
        System.assert(result.contains('Probability'), 'Should contain probability column');
        // Note: Specific stage names depend on the org, but IsWon/IsClosed logic should be generic enough
    }

    @IsTest
    static void testStandardPicklistContext() {
        // Setup inputs
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('rootObject', 'Account');
        
        // Mock selected fields
        Map<String, List<String>> selectedFields = new Map<String, List<String>>();
        // Industry is a standard picklist on Account
        selectedFields.put('Account', new List<String>{'Industry'});
        inputs.put('selectedFields', selectedFields);
        
        Test.startTest();
        ApexFieldMetadataService service = new ApexFieldMetadataService();
        String result = service.execute(inputs);
        Test.stopTest();
        
        System.assert(result.contains('Account.Industry'), 'Should contain field header');
        System.assert(result.contains('Defined Values'), 'Should contain value list');
    }

    @IsTest
    static void testOptimizationWithFieldMetadata() {
        // Setup inputs
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('rootObject', 'Case');
        
        // Mock selected fields
        Map<String, List<String>> selectedFields = new Map<String, List<String>>();
        selectedFields.put('Case', new List<String>{'Status'}); // Special field
        inputs.put('selectedFields', selectedFields);
        
        // Provide optimization map
        Map<String, String> fieldMetadata = new Map<String, String>();
        fieldMetadata.put('Status', 'PICKLIST');
        inputs.put('fieldMetadata', fieldMetadata);

        Test.startTest();
        ApexFieldMetadataService service = new ApexFieldMetadataService();
        String result = service.execute(inputs);
        Test.stopTest();
        
        System.assert(result.contains('Case.Status'), 'Should contain field header');
        System.assert(result.contains('Support Process'), 'Should contain special context description');
    }
    
    @IsTest
    static void testNoPicklistSelected() {
        // Setup inputs
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('rootObject', 'Account');
        
        // Mock selected fields - selecting a text field (Name)
        Map<String, List<String>> selectedFields = new Map<String, List<String>>();
        selectedFields.put('Account', new List<String>{'Name'});
        inputs.put('selectedFields', selectedFields);
        
        Test.startTest();
        ApexFieldMetadataService service = new ApexFieldMetadataService();
        String result = service.execute(inputs);
        Test.stopTest();
        
        System.assertEquals('', result, 'Should return empty string for no picklists');
    }
}
