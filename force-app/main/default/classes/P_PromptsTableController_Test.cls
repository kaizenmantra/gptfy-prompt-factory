/**
 * @description Test class for P_PromptsTableController
 * @author      Salesforce Development Team
 * @date        2025-11-10
 */
@isTest
private class P_PromptsTableController_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create AI Connection for testing
        ccai__AI_Connection__c connection = new ccai__AI_Connection__c(
            Name = 'Test Connection',
            Type__c = 'Azure',
            AI_Technology__c = 'GPT-4'
        );
        insert connection;
        
        // Create test prompts
        List<AI_Prompt__c> prompts = new List<AI_Prompt__c>();
        
        prompts.add(new AI_Prompt__c(
            Name = 'Test Prompt 1',
            Object__c = 'Case',
            ccai__AI_Connection__c = connection.Id,
            Description__c = 'Test Description 1',
            Status__c = 'Active',
            Purpose__c = 'Facilitate Customer Success'
        ));
        
        prompts.add(new AI_Prompt__c(
            Name = 'Test Prompt 2',
            Object__c = 'Account',
            ccai__AI_Connection__c = connection.Id,
            Description__c = 'Test Description 2',
            Status__c = 'Active',
            Purpose__c = 'Facilitate Customer Success'
        ));
        
        prompts.add(new AI_Prompt__c(
            Name = 'Test Prompt 3',
            Object__c = 'Lead',
            ccai__AI_Connection__c = connection.Id,
            Description__c = 'Test Description 3',
            Status__c = 'Draft',
            Purpose__c = 'Configuration'
        ));
        
        insert prompts;
    }
    
    @isTest
    static void testGetPromptsByPurpose() {
        Test.startTest();
        List<P_PromptsTableController.PromptWrapper> results = P_PromptsTableController.getPromptsByPurpose('Facilitate Customer Success');
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return 2 prompts for Facilitate Customer Success');
        Assert.isNotNull(results[0].id, 'Wrapper should have id');
        Assert.isNotNull(results[0].promptName, 'Wrapper should have promptName');
        Assert.isNotNull(results[0].primaryObject, 'Wrapper should have primaryObject');
        Assert.isNotNull(results[0].connection, 'Wrapper should have connection');
        Assert.isNotNull(results[0].status, 'Wrapper should have status');
    }
    
    @isTest
    static void testGetAllPrompts() {
        Test.startTest();
        List<AI_Prompt__c> results = P_PromptsTableController.getAllPrompts();
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return all 3 prompts');
    }
    
    @isTest
    static void testGetUniquePurposes() {
        Test.startTest();
        List<String> purposes = P_PromptsTableController.getUniquePurposes();
        Test.stopTest();
        
        System.assertEquals(2, purposes.size(), 'Should return 2 unique purposes');
        System.assert(purposes.contains('Facilitate Customer Success'), 'Should contain Facilitate Customer Success');
        System.assert(purposes.contains('Configuration'), 'Should contain Configuration');
    }
}