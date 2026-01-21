/**
 * @description Test class for P_PromptCatalogueController
 *              Provides comprehensive test coverage with positive and negative scenarios
 * @author      Salesforce Development Team
 * @group       GPTfy Components
 * @date        2025-11-09
 */
@IsTest
private class P_PromptCatalogueController_Test {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create AI Card Configurations
        List<ccai__AI_Card_Configuration__c> cards = new List<ccai__AI_Card_Configuration__c>();
        
        for (Integer i = 0; i < 10; i++) {
            cards.add(new ccai__AI_Card_Configuration__c(
                Name = 'Test Card ' + i,
                Description__c = 'Test description for card ' + i,
                Icon_Details__c = 'standard:account',
                Icon_Source__c = 'SLDS',
                Sequence__c = i,
                Enabled__c = true,
                Feature__c = 'PROMPT_CATALOGUE',
                External_Id__c = 'test_card_' + i
            ));
        }
        
        // Add inactive card for filtering test
        cards.add(new ccai__AI_Card_Configuration__c(
            Name = 'Inactive Card',
            Description__c = 'This card should not appear',
            Icon_Details__c = 'standard:account',
            Icon_Source__c = 'SLDS',
            Sequence__c = 99,
            Enabled__c = false,
            Feature__c = 'PROMPT_CATALOGUE'
        ));
        
        // Add card with different feature
        cards.add(new ccai__AI_Card_Configuration__c(
            Name = 'Other Feature Card',
            Description__c = 'Different feature card',
            Icon_Details__c = 'standard:opportunity',
            Icon_Source__c = 'SLDS',
            Sequence__c = 100,
            Enabled__c = true,
            Feature__c = 'OTHER_FEATURE'
        ));
        
        Database.insert(cards, AccessLevel.USER_MODE);
        
        // Create AI Connections
        List<ccai__AI_Connection__c> connections = new List<ccai__AI_Connection__c>();
        connections.add(new ccai__AI_Connection__c(
            Name = 'Test Connection 1',
            AI_Technology__c = 'OpenAI'
        ));
        connections.add(new ccai__AI_Connection__c(
            Name = 'Test Connection 2',
            AI_Technology__c = 'Azure'
        ));
        
        Database.insert(connections, AccessLevel.USER_MODE);
        
        // Create AI Data Extraction Mappings
        List<AI_Data_Extraction_Mapping__c> mappings = new List<AI_Data_Extraction_Mapping__c>();
        mappings.add(new AI_Data_Extraction_Mapping__c(
            Name = 'Test Mapping 1',
            Object_Name__c = 'Account'
        ));
        mappings.add(new AI_Data_Extraction_Mapping__c(
            Name = 'Test Mapping 2',
            Object_Name__c = 'Contact'
        ));
        
        Database.insert(mappings, AccessLevel.USER_MODE);
        
        // Create AI Prompts
        List<AI_Prompt__c> prompts = new List<AI_Prompt__c>();
        
        for (Integer i = 0; i < 5; i++) {
            prompts.add(new AI_Prompt__c(
                Name = 'Test Prompt ' + i,
                Description__c = 'Test prompt description ' + i,
                ccai__AI_Connection__c = connections[0].Id,
                AI_Data_Extraction_Mapping__c = mappings[0].Id,
                Object__c = 'Account',
                Purpose__c = 'Data Extraction;Analysis',
                Status__c = 'Active'
            ));
        }
        
        // Add prompt with different purpose
        prompts.add(new AI_Prompt__c(
            Name = 'Summary Prompt',
            Description__c = 'Summarize records',
            ccai__AI_Connection__c = connections[1].Id,
            AI_Data_Extraction_Mapping__c = mappings[1].Id,
            Object__c = 'Contact',
            Purpose__c = 'Summarization',
            Status__c = 'Active'
        ));
        
        // Add inactive prompt
        prompts.add(new AI_Prompt__c(
            Name = 'Inactive Prompt',
            Description__c = 'Should not appear',
            ccai__AI_Connection__c = connections[0].Id,
            AI_Data_Extraction_Mapping__c = mappings[0].Id,
            Object__c = 'Account',
            Purpose__c = 'Testing',
            Status__c = 'Inactive'
        ));
        
        Database.insert(prompts, AccessLevel.USER_MODE);
    }
    
    /**
     * @description Test successful retrieval of prompt cards
     */
    @IsTest
    static void testGetPromptCards_Success() {
        Test.startTest();
        List<ccai__AI_Card_Configuration__c> cards = P_PromptCatalogueController.getPromptCards();
        Test.stopTest();
        
        // Assert cards are returned
        Assert.isNotNull(cards, 'Cards should not be null');
        Assert.areEqual(10, cards.size(), 'Should return 10 active PROMPT_CATALOGUE cards');
        
        // Assert ordering
        Assert.isTrue(cards[0].Sequence__c <= cards[1].Sequence__c, 'Cards should be ordered by Sequence__c');
        
        // Assert all cards are enabled
        for (ccai__AI_Card_Configuration__c card : cards) {
            Assert.isTrue(card.Enabled__c, 'All returned cards should be enabled');
            Assert.areEqual('PROMPT_CATALOGUE', card.Feature__c, 'All cards should have PROMPT_CATALOGUE feature');
        }
    }
    
    /**
     * @description Test retrieval when no cards exist
     */
    @IsTest
    static void testGetPromptCards_NoRecords() {
        // Delete all test cards
        List<ccai__AI_Card_Configuration__c> allCards = [SELECT Id FROM ccai__AI_Card_Configuration__c];
        Database.delete(allCards, AccessLevel.USER_MODE);
        
        Test.startTest();
        List<ccai__AI_Card_Configuration__c> cards = P_PromptCatalogueController.getPromptCards();
        Test.stopTest();
        
        // Assert empty list is returned
        Assert.isNotNull(cards, 'Cards list should not be null');
        Assert.areEqual(0, cards.size(), 'Should return empty list when no cards exist');
    }
    
    /**
     * @description Test retrieval of prompts grouped by purpose
     */
    @IsTest
    static void testGetPromptsByPurpose_Success() {
        Test.startTest();
        Map<String, Object> result = P_PromptCatalogueController.getPromptsByPurpose();
        Test.stopTest();
        
        // Assert result is not null
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(true, result.get('success'), 'Success flag should be true');
        
        // Assert prompts are grouped by purpose
        Map<String, Object> promptsByPurpose = (Map<String, Object>) result.get('promptsByPurpose');
        Assert.isNotNull(promptsByPurpose, 'Prompts by purpose should not be null');
        
        // Assert purposes are returned
        List<String> purposes = (List<String>) result.get('purposes');
        Assert.isNotNull(purposes, 'Purposes list should not be null');
        Assert.isTrue(purposes.size() > 0, 'Should have at least one purpose');
        
        // Assert total prompts count
        Integer totalPrompts = (Integer) result.get('totalPrompts');
        Assert.isTrue(totalPrompts > 0, 'Should have active prompts');
    }
    
    /**
     * @description Test search prompts with valid search term
     */
    @IsTest
    static void testSearchPrompts_Success() {
        Test.startTest();
        List<P_PromptCatalogueController.PromptWrapper> results = 
            P_PromptCatalogueController.searchPrompts('Test Prompt');
        Test.stopTest();
        
        // Assert results are returned
        Assert.isNotNull(results, 'Results should not be null');
        Assert.isTrue(results.size() > 0, 'Should find matching prompts');
        
        // Assert wrapper fields are populated
        for (P_PromptCatalogueController.PromptWrapper wrapper : results) {
            Assert.isNotNull(wrapper.promptId, 'Prompt ID should not be null');
            Assert.isNotNull(wrapper.name, 'Name should not be null');
            Assert.isTrue(wrapper.name.contains('Test Prompt'), 'Name should contain search term');
        }
    }
    
    /**
     * @description Test search prompts with blank search term
     */
    @IsTest
    static void testSearchPrompts_BlankTerm() {
        Test.startTest();
        List<P_PromptCatalogueController.PromptWrapper> results = 
            P_PromptCatalogueController.searchPrompts('');
        Test.stopTest();
        
        // Assert empty list is returned
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty list for blank search term');
    }
    
    /**
     * @description Test search prompts with no matching results
     */
    @IsTest
    static void testSearchPrompts_NoResults() {
        Test.startTest();
        List<P_PromptCatalogueController.PromptWrapper> results = 
            P_PromptCatalogueController.searchPrompts('NonExistentPrompt12345');
        Test.stopTest();
        
        // Assert empty list is returned
        Assert.isNotNull(results, 'Results should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty list when no matches found');
    }
    
    /**
     * @description Test search by description
     */
    @IsTest
    static void testSearchPrompts_ByDescription() {
        Test.startTest();
        List<P_PromptCatalogueController.PromptWrapper> results = 
            P_PromptCatalogueController.searchPrompts('Summarize');
        Test.stopTest();
        
        // Assert results are returned
        Assert.isNotNull(results, 'Results should not be null');
        Assert.isTrue(results.size() > 0, 'Should find prompts by description');
    }
    
    /**
     * @description Test bulk data retrieval (governor limits)
     */
    @IsTest
    static void testGetPromptCards_BulkData() {
        // Create additional cards
        List<ccai__AI_Card_Configuration__c> bulkCards = new List<ccai__AI_Card_Configuration__c>();
        
        for (Integer i = 10; i < 150; i++) {
            bulkCards.add(new ccai__AI_Card_Configuration__c(
                Name = 'Bulk Card ' + i,
                Description__c = 'Bulk description ' + i,
                Icon_Details__c = 'standard:account',
                Icon_Source__c = 'SLDS',
                Sequence__c = i,
                Enabled__c = true,
                Feature__c = 'PROMPT_CATALOGUE'
            ));
        }
        
        Database.insert(bulkCards, AccessLevel.USER_MODE);
        
        Test.startTest();
        List<ccai__AI_Card_Configuration__c> cards = P_PromptCatalogueController.getPromptCards();
        Test.stopTest();
        
        // Assert limit is respected
        Assert.isNotNull(cards, 'Cards should not be null');
        Assert.areEqual(100, cards.size(), 'Should respect LIMIT of 100 records');
    }
    
    /**
     * @description Test PromptWrapper construction
     */
    @IsTest
    static void testPromptWrapper_Construction() {
        AI_Prompt__c prompt = [
            SELECT Id, Name, Description__c, ccai__AI_Connection__c, AI_Connection__r.Name,
                   AI_Data_Extraction_Mapping__c, AI_Data_Extraction_Mapping__r.Name,
                   Object__c, Purpose__c, Status__c
            FROM AI_Prompt__c
            WHERE Name = 'Test Prompt 0'
            LIMIT 1
        ];
        
        Test.startTest();
        P_PromptCatalogueController.PromptWrapper wrapper = 
            new P_PromptCatalogueController.PromptWrapper(prompt);
        Test.stopTest();
        
        // Assert wrapper fields are populated correctly
        Assert.areEqual(prompt.Id, wrapper.promptId, 'Prompt ID should match');
        Assert.areEqual(prompt.Name, wrapper.name, 'Name should match');
        Assert.areEqual(prompt.Description__c, wrapper.description, 'Description should match');
        Assert.areEqual(prompt.ccai__AI_Connection__c, wrapper.connectionId, 'Connection ID should match');
        Assert.areEqual(prompt.Object__c, wrapper.objectName, 'Object name should match');
        Assert.isNotNull(wrapper.promptUrl, 'Prompt URL should be generated');
        Assert.isTrue(wrapper.promptUrl.contains(prompt.Id), 'Prompt URL should contain record ID');
    }
    
    /**
     * @description Test with different user context for security
     */
    @IsTest
    static void testGetPromptCards_UserMode() {
        // Create a test user with limited permissions
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@gptfy.test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        
        insert testUser;
        
        System.runAs(testUser) {
            Test.startTest();
            try {
                List<ccai__AI_Card_Configuration__c> cards = P_PromptCatalogueController.getPromptCards();
                // If successful, verify results
                Assert.isNotNull(cards, 'Cards should not be null');
            } catch (Exception ex) {
                // If access is denied, that's expected behavior for USER_MODE
                Assert.isTrue(ex instanceof AuraHandledException, 'Should throw AuraHandledException for permission issues');
            }
            Test.stopTest();
        }
    }
}