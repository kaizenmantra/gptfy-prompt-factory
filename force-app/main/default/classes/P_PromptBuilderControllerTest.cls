/**
 * @description Test class for P_PromptBuilderController
 * @author Piyush Chourasia
 * @group Plumcloud Labs
 * @last modified on 11-12-2024
 * @last modified by AI Assistant
 */
@isTest
private class P_PromptBuilderControllerTest {
    
    /**
     * Setup test data
     */
    @TestSetup
    static void setupTestData() {
        // Create AI Connection
        ccai__AI_Connection__c connection = new ccai__AI_Connection__c(
            Name = 'GPTfy Test Connection',
            AI_Technology__c = 'GPTfy',
            Named_Credential__c = 'GPTfy',
            Model__c = 'gpt-4',
            Max_Tokens__c = 3000,
            Temperature__c = 0.7,
            Top_P__c = 1.0,
            EndPoint_URL__c = '/api/gptfyall'
        );
        Database.insert(connection, AccessLevel.USER_MODE);
        
        // Create sample AI Data Extraction Mapping
        AI_Data_Extraction_Mapping__c mapping = new AI_Data_Extraction_Mapping__c(
            Name = 'Test Mapping',
            Object_Name__c = 'Account',
            Description__c = 'Test mapping description',
            Status__c = 'Active'
        );
        Database.insert(mapping, AccessLevel.USER_MODE);
        
        // Create sample AI Prompt
        AI_Prompt__c prompt = new AI_Prompt__c(
            Name = 'Test Prompt',
            Description__c = 'Test prompt for sentiment analysis',
            Object__c = 'Account',
            Prompt_Command__c = 'Generate a sentiment analysis for this account.',
            Type__c = 'Text',
            Status__c = 'Active',
            ccai__AI_Connection__c = connection.Id,
            AI_Data_Extraction_Mapping__c = mapping.Id
        );
        Database.insert(prompt, AccessLevel.USER_MODE);
    }
    
    /**
     * Test generatePromptDetails method with success scenario
     */
    @isTest
    static void testGeneratePromptDetails_Success() {
        // Setup mock response
        Test.setMock(HttpCalloutMock.class, new P_PromptBuilderMockHttpResponse(200, true));
        
        List<Map<String, String>> existingPrompts = P_PromptBuilderController.getExistingPrompts();
        String existingPromptsJson = JSON.serialize(existingPrompts);
        
        Test.startTest();
        String result = P_PromptBuilderController.generatePromptDetails(
            'Create a prompt to analyze opportunity pipeline',
            existingPromptsJson
        );
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('data'), 'Result should contain data field');
    }
    
    /**
     * Test generatePromptDetails method with empty input
     */
    @isTest
    static void testGeneratePromptDetails_EmptyInput() {
        Test.startTest();
        try {
            P_PromptBuilderController.generatePromptDetails('', '[]');
            Assert.fail('Expected AuraHandledException for empty input');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('empty'), 'Exception message should mention empty input');
        }
        Test.stopTest();
    }
    
    /**
     * Test generatePromptDetails method with error response
     */
    @isTest
    static void testGeneratePromptDetails_ErrorResponse() {
        // Setup mock error response
        Test.setMock(HttpCalloutMock.class, new P_PromptBuilderMockHttpResponse(500, false));
        
        Test.startTest();
        try {
            P_PromptBuilderController.generatePromptDetails(
                'Create a prompt for case analysis',
                '[]'
            );
            Assert.fail('Expected AuraHandledException for error response');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error'), 'Exception message should mention error');
        }
        Test.stopTest();
    }
    
    /**
     * Test createPromptWithMapping method with valid data
     */
    @isTest
    static void testCreatePromptWithMapping_Success() {
        Map<String, Object> dataContext = new Map<String, Object>{
            'childRelationships' => new List<Object>{
                new Map<String, Object>{
                    'relationshipName' => 'Opportunities',
                    'objectName' => 'Opportunity',
                    'fields' => new List<String>{'Name', 'StageName', 'Amount'},
                    'whereClause' => 'ORDER BY CreatedDate DESC LIMIT 10'
                }
            },
            'mainObjectFields' => new List<String>{'Name', 'Industry', 'AnnualRevenue'}
        };
        
        String dataContextJson = JSON.serialize(dataContext);
        
        Test.startTest();
        String promptId = P_PromptBuilderController.createPromptWithMapping(
            'New AI Prompt',
            'Account',
            'Test description for new prompt',
            'Generate comprehensive analysis of this account.',
            dataContextJson
        );
        Test.stopTest();
        
        Assert.isNotNull(promptId, 'Prompt ID should not be null');
        
        AI_Prompt__c createdPrompt = [
            SELECT Id, Name, Object__c, Type__c, Status__c, AI_Data_Extraction_Mapping__c
            FROM AI_Prompt__c 
            WHERE Id = :promptId
        ];
        
        Assert.areEqual('New AI Prompt', createdPrompt.Name, 'Prompt name should match');
        Assert.areEqual('Account', createdPrompt.Object__c, 'Target object should match');
        Assert.areEqual('Text', createdPrompt.Type__c, 'Type should be Text');
        Assert.areEqual('Draft', createdPrompt.Status__c, 'Status should be Draft');
        Assert.isNotNull(createdPrompt.AI_Data_Extraction_Mapping__c, 'Data extraction mapping should be created');
    }
    
    /**
     * Test createPromptWithMapping without data context
     */
    @isTest
    static void testCreatePromptWithMapping_NoDataContext() {
        Test.startTest();
        String promptId = P_PromptBuilderController.createPromptWithMapping(
            'Simple Prompt',
            'Case',
            'Simple prompt description',
            'Analyze this case and provide insights.',
            null
        );
        Test.stopTest();
        
        Assert.isNotNull(promptId, 'Prompt ID should not be null');
        
        AI_Prompt__c createdPrompt = [
            SELECT Id, Name, AI_Data_Extraction_Mapping__c
            FROM AI_Prompt__c 
            WHERE Id = :promptId
        ];
        
        Assert.areEqual('Simple Prompt', createdPrompt.Name, 'Prompt name should match');
        Assert.isNull(createdPrompt.AI_Data_Extraction_Mapping__c, 'Data extraction mapping should be null');
    }
    
    /**
     * Test createPromptWithMapping with missing required fields
     */
    @isTest
    static void testCreatePromptWithMapping_MissingFields() {
        Test.startTest();
        try {
            P_PromptBuilderController.createPromptWithMapping(
                '',
                'Account',
                'Description',
                'Command',
                null
            );
            Assert.fail('Expected AuraHandledException for missing required fields');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('cannot be empty'), 'Exception message should mention empty fields');
        }
        Test.stopTest();
    }
    
    /**
     * Test getSalesforceObjectsMetadata method
     */
    @isTest
    static void testGetSalesforceObjectsMetadata() {
        Test.startTest();
        List<Map<String, Object>> objects = P_PromptBuilderController.getSalesforceObjectsMetadata();
        Test.stopTest();
        
        Assert.isNotNull(objects, 'Objects list should not be null');
        Assert.isTrue(objects.size() > 0, 'Objects list should not be empty');
        
        Boolean foundAccount = false;
        for (Map<String, Object> obj : objects) {
            if (obj.get('name') == 'Account') {
                foundAccount = true;
                Assert.isNotNull(obj.get('label'), 'Object should have a label');
                Assert.isNotNull(obj.get('childRelationships'), 'Object should have child relationships');
                break;
            }
        }
        
        Assert.isTrue(foundAccount, 'Should find Account object in the list');
    }
    
    /**
     * Test getExistingPrompts method
     */
    @isTest
    static void testGetExistingPrompts() {
        Test.startTest();
        List<Map<String, String>> prompts = P_PromptBuilderController.getExistingPrompts();
        Test.stopTest();
        
        Assert.isNotNull(prompts, 'Prompts list should not be null');
        Assert.areEqual(1, prompts.size(), 'Should return 1 active prompt');
        Assert.isTrue(prompts[0].get('name').contains('Test'), 'Prompt name should contain Test');
        Assert.isNotNull(prompts[0].get('object'), 'Prompt should have object field');
    }
    
    /**
     * Mock HTTP Response class for testing
     */
    public class P_PromptBuilderMockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private Boolean isSuccess;
        
        public P_PromptBuilderMockHttpResponse(Integer statusCode, Boolean isSuccess) {
            this.statusCode = statusCode;
            this.isSuccess = isSuccess;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            
            if (isSuccess) {
                Map<String, Object> responseData = new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'hasValue' => true,
                        'value' => new Map<String, Object>{
                            'choices' => new List<Object>{
                                new Map<String, Object>{
                                    'message' => new Map<String, Object>{
                                        'content' => '{"name":"Test Prompt","targetObject":"Account","description":"Test description","promptCommand":"Test command","dataContextMapping":{"childRelationships":[],"mainObjectFields":["Name"]}}'
                                    }
                                }
                            }
                        }
                    }
                };
                res.setBody(JSON.serialize(responseData));
                res.setHeader('Content-Type', 'application/json');
            } else {
                res.setStatus('Internal Server Error');
                res.setBody('{"error":"Test error message"}');
            }
            
            return res;
        }
    }
}