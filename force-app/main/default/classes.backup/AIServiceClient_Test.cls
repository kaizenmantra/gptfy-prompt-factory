/**
 * @description Test class for AIServiceClient
 * Tests AI API integration with mock HTTP responses
 */
@IsTest
private class AIServiceClient_Test {

    /**
     * @description Mock HTTP callout for successful Claude API response
     */
    private class ClaudeSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');

            Map<String, Object> responseBody = new Map<String, Object>{
                'id' => 'msg_01ABC123',
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'text',
                        'text' => '{"analysis": "This is the AI response"}'
                    }
                },
                'usage' => new Map<String, Object>{
                    'input_tokens' => 150,
                    'output_tokens' => 75
                }
            };

            res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }

    /**
     * @description Mock HTTP callout for failed Claude API response
     */
    private class ClaudeErrorMock implements HttpCalloutMock {
        private Integer statusCode;
        private String errorMessage;

        public ClaudeErrorMock(Integer statusCode, String errorMessage) {
            this.statusCode = statusCode;
            this.errorMessage = errorMessage;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus('Error');

            Map<String, Object> errorBody = new Map<String, Object>{
                'error' => new Map<String, Object>{
                    'type' => 'invalid_request_error',
                    'message' => this.errorMessage
                }
            };

            res.setBody(JSON.serialize(errorBody));
            return res;
        }
    }

    @TestSetup
    static void setup() {
        // Create Claude API credentials
        Claude_API_Credentials__c creds = new Claude_API_Credentials__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            API_Key__c = 'test_api_key_123',
            API_Endpoint__c = 'https://api.anthropic.com/v1/messages',
            Model__c = 'claude-sonnet-4.5'
        );
        insert creds;
    }

    /**
     * @description Test successful AI API call
     */
    @IsTest
    static void testCallClaude_Success() {
        Test.setMock(HttpCalloutMock.class, new ClaudeSuccessMock());

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(response.success, 'Response should be successful');
        System.assertEquals('msg_01ABC123', response.messageId, 'Message ID should match');
        System.assertNotEquals(null, response.content, 'Content should be populated');
        System.assert(response.content.contains('AI response'), 'Content should match');
        System.assertEquals(150, response.inputTokens, 'Input tokens should be 150');
        System.assertEquals(75, response.outputTokens, 'Output tokens should be 75');
        System.assertEquals(null, response.errorMessage, 'Should have no error message');
    }

    /**
     * @description Test AI API call with custom parameters
     */
    @IsTest
    static void testCallClaude_CustomParameters() {
        Test.setMock(HttpCalloutMock.class, new ClaudeSuccessMock());

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude(
            'Test prompt', 2048, 0.5
        );
        Test.stopTest();

        System.assert(response.success, 'Response should be successful');
        System.assertNotEquals(null, response.content, 'Content should be populated');
    }

    /**
     * @description Test AI API call with 400 error
     */
    @IsTest
    static void testCallClaude_400Error() {
        Test.setMock(HttpCalloutMock.class,
            new ClaudeErrorMock(400, 'Invalid request format'));

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(!response.success, 'Response should indicate failure');
        System.assertNotEquals(null, response.errorMessage, 'Should have error message');
        System.assert(response.errorMessage.contains('400'), 'Error should include status code');
        System.assert(response.errorMessage.contains('Invalid request format'),
            'Error should include message from API');
    }

    /**
     * @description Test AI API call with 401 unauthorized
     */
    @IsTest
    static void testCallClaude_401Unauthorized() {
        Test.setMock(HttpCalloutMock.class,
            new ClaudeErrorMock(401, 'Invalid API key'));

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(!response.success, 'Response should indicate failure');
        System.assert(response.errorMessage.contains('401'), 'Error should mention 401');
        System.assert(response.errorMessage.contains('Invalid API key'),
            'Error should include API key message');
    }

    /**
     * @description Test AI API call with 429 rate limit
     */
    @IsTest
    static void testCallClaude_429RateLimit() {
        Test.setMock(HttpCalloutMock.class,
            new ClaudeErrorMock(429, 'Rate limit exceeded'));

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(!response.success, 'Response should indicate failure');
        System.assert(response.errorMessage.contains('429'), 'Error should mention 429');
        System.assert(response.errorMessage.contains('Rate limit'),
            'Error should include rate limit message');
    }

    /**
     * @description Test AI API call with 500 server error
     */
    @IsTest
    static void testCallClaude_500ServerError() {
        Test.setMock(HttpCalloutMock.class,
            new ClaudeErrorMock(500, 'Internal server error'));

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(!response.success, 'Response should indicate failure');
        System.assert(response.errorMessage.contains('500'), 'Error should mention 500');
    }

    /**
     * @description Test AI API call with missing credentials
     */
    @IsTest
    static void testCallClaude_MissingCredentials() {
        // Delete credentials
        delete [SELECT Id FROM Claude_API_Credentials__c];

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(!response.success, 'Response should indicate failure');
        System.assert(response.errorMessage.contains('credentials not configured'),
            'Error should mention missing credentials');
    }

    /**
     * @description Test retry logic
     */
    @IsTest
    static void testCallClaudeWithRetry_SuccessOnFirstAttempt() {
        Test.setMock(HttpCalloutMock.class, new ClaudeSuccessMock());

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaudeWithRetry('Test prompt', 3);
        Test.stopTest();

        System.assert(response.success, 'Should succeed on first attempt');
        System.assertNotEquals(null, response.content, 'Content should be populated');
    }

    /**
     * @description Test retry logic with eventual failure
     */
    @IsTest
    static void testCallClaudeWithRetry_AllAttemptsFail() {
        Test.setMock(HttpCalloutMock.class,
            new ClaudeErrorMock(500, 'Server error'));

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaudeWithRetry('Test prompt', 3);
        Test.stopTest();

        System.assert(!response.success, 'All attempts should fail');
        System.assertNotEquals(null, response.errorMessage, 'Should have error message');
    }

    /**
     * @description Test mock mode for testing
     */
    @IsTest
    static void testMockMode() {
        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = '{"test": "mock data"}';

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(response.success, 'Mock response should be successful');
        System.assertEquals('msg_mock_123', response.messageId, 'Should use mock message ID');
        System.assert(response.content.contains('mock data'), 'Should use mock content');
        System.assertEquals(100, response.inputTokens, 'Should use mock input tokens');
        System.assertEquals(50, response.outputTokens, 'Should use mock output tokens');
    }

    /**
     * @description Test mock mode with default response
     */
    @IsTest
    static void testMockMode_DefaultResponse() {
        AIServiceClient.mockMode = true;
        AIServiceClient.mockResponse = null;

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(response.success, 'Mock response should be successful');
        System.assert(response.content.contains('mock response'),
            'Should use default mock response');
    }

    /**
     * @description Test token estimation
     */
    @IsTest
    static void testEstimateTokens() {
        Test.startTest();
        Integer tokensEmpty = AIServiceClient.estimateTokens('');
        Integer tokensNull = AIServiceClient.estimateTokens(null);
        Integer tokensShort = AIServiceClient.estimateTokens('Hello World');
        Integer tokensLong = AIServiceClient.estimateTokens('This is a much longer string with many more characters to estimate tokens for testing purposes.');
        Test.stopTest();

        System.assertEquals(0, tokensEmpty, 'Empty string should be 0 tokens');
        System.assertEquals(0, tokensNull, 'Null string should be 0 tokens');
        System.assert(tokensShort > 0, 'Short string should have some tokens');
        System.assert(tokensLong > tokensShort, 'Longer string should have more tokens');
        // Rough estimate: ~1 token per 4 characters
        System.assert(tokensLong >= 25, 'Long string should have at least 25 tokens');
    }

    /**
     * @description Test AIResponse wrapper class initialization
     */
    @IsTest
    static void testAIResponseWrapper() {
        Test.startTest();
        AIServiceClient.AIResponse response = new AIServiceClient.AIResponse();
        Test.stopTest();

        System.assert(response.success, 'Should default to success = true');
        System.assertEquals(null, response.messageId, 'Message ID should be null by default');
        System.assertEquals(null, response.content, 'Content should be null by default');
        System.assertEquals(null, response.inputTokens, 'Input tokens should be null by default');
        System.assertEquals(null, response.outputTokens, 'Output tokens should be null by default');
        System.assertEquals(null, response.errorMessage, 'Error message should be null by default');
    }

    /**
     * @description Test handling of malformed JSON response
     */
    @IsTest
    static void testCallClaude_MalformedJSON() {
        // Mock that returns invalid JSON
        Test.setMock(HttpCalloutMock.class, new MalformedJSONMock());

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(!response.success, 'Should fail with malformed JSON');
        System.assert(response.errorMessage.contains('parse'),
            'Error should mention parsing issue');
    }

    /**
     * @description Mock for malformed JSON response
     */
    private class MalformedJSONMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{invalid json here}');
            return res;
        }
    }

    /**
     * @description Test handling of response without usage data
     */
    @IsTest
    static void testCallClaude_NoUsageData() {
        Test.setMock(HttpCalloutMock.class, new NoUsageMock());

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(response.success, 'Should succeed even without usage data');
        System.assertEquals(null, response.inputTokens, 'Input tokens should be null');
        System.assertEquals(null, response.outputTokens, 'Output tokens should be null');
    }

    /**
     * @description Mock for response without usage data
     */
    private class NoUsageMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');

            Map<String, Object> responseBody = new Map<String, Object>{
                'id' => 'msg_test',
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'text',
                        'text' => 'Response text'
                    }
                }
                // No usage field
            };

            res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }

    /**
     * @description Test error response without error details
     */
    @IsTest
    static void testCallClaude_ErrorWithoutDetails() {
        Test.setMock(HttpCalloutMock.class, new PlainErrorMock());

        Test.startTest();
        AIServiceClient.AIResponse response = AIServiceClient.callClaude('Test prompt');
        Test.stopTest();

        System.assert(!response.success, 'Response should indicate failure');
        System.assertNotEquals(null, response.errorMessage, 'Should have error message');
        System.assert(response.errorMessage.contains('500'), 'Should include status code');
    }

    /**
     * @description Mock for error without structured error details
     */
    private class PlainErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('Plain error text without JSON structure');
            return res;
        }
    }

    /**
     * @description Test bulk token estimation
     */
    @IsTest
    static void testEstimateTokens_Bulk() {
        List<String> texts = new List<String>();
        for (Integer i = 0; i < 100; i++) {
            texts.add('This is test string number ' + i + ' for token estimation.');
        }

        Test.startTest();
        Integer totalTokens = 0;
        for (String text : texts) {
            totalTokens += AIServiceClient.estimateTokens(text);
        }
        Test.stopTest();

        System.assert(totalTokens > 0, 'Should estimate tokens for all texts');
        System.assert(totalTokens > 1000, 'Should have significant token count for 100 strings');
    }
}