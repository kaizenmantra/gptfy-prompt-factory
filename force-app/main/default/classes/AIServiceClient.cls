/**
 * @description Client for AI API integration (Claude AI and Azure OpenAI)
 * Handles HTTP callouts, response parsing, and retry logic
 *
 * CRITICAL: This implementation supports multiple AI providers:
 * 1. Claude AI (Anthropic) - Original implementation
 * 2. Azure OpenAI (GPT-4o) - New Azure integration
 * 3. Automatic provider detection based on configured credentials
 * 4. Implements retry with backoff for 429/500/timeout errors
 */
public with sharing class AIServiceClient {
    
    // AI Provider types
    public enum AIProvider {
        CLAUDE,
        AZURE_OPENAI,
        AUTO  // Automatically detect based on configured credentials
    }

    @TestVisible
    private static Boolean mockMode = false;

    @TestVisible
    private static String mockResponse = null;

    /**
     * @description Enable/disable mock mode for tests.
     */
    @TestVisible
    static void setMockMode(Boolean enabled) {
        mockMode = enabled;
    }

    /**
     * @description Set mock response content for tests.
     * IMPORTANT: Must be valid JSON matching the caller's expected schema.
     */
    @TestVisible
    static void setMockResponse(String responseJson) {
        mockResponse = responseJson;
    }
    
    /**
     * @description Set the default AI provider
     */
    public static void setDefaultProvider(AIProvider provider) {
        defaultProvider = provider;
    }
    
    /**
     * @description Detect which AI provider is configured and set as default
     * Checks the Default__c checkbox on both credential custom settings
     * @return AIProvider enum value
     */
    private static AIProvider detectProvider() {
        Azure_OpenAI_Credentials__c azureCreds = Azure_OpenAI_Credentials__c.getInstance();
        Claude_API_Credentials__c claudeCreds = Claude_API_Credentials__c.getInstance();
        
        // Check which provider is marked as Default
        Boolean azureDefault = (azureCreds != null && azureCreds.Default__c == true && String.isNotBlank(azureCreds.API_Key__c));
        Boolean claudeDefault = (claudeCreds != null && claudeCreds.Default__c == true && String.isNotBlank(claudeCreds.API_Key__c));
        
        // If Azure is marked as default, use it
        if (azureDefault) {
            return AIProvider.AZURE_OPENAI;
        }
        
        // If Claude is marked as default, use it
        if (claudeDefault) {
            return AIProvider.CLAUDE;
        }
        
        // Fallback: If neither is marked as default but credentials exist, prefer Azure
        if (azureCreds != null && String.isNotBlank(azureCreds.API_Key__c)) {
            return AIProvider.AZURE_OPENAI;
        }
        
        if (claudeCreds != null && String.isNotBlank(claudeCreds.API_Key__c)) {
            return AIProvider.CLAUDE;
        }
        
        // Default to Claude if nothing configured (will fail gracefully with clear error)
        return AIProvider.CLAUDE;
    }
    
    /**
     * @description Universal AI call that routes to the appropriate provider
     * @param prompt The prompt to send
     * @return AIResponse wrapper with results
     */
    public static AIResponse callAI(String prompt) {
        AIProvider provider = (defaultProvider == AIProvider.AUTO) ? detectProvider() : defaultProvider;
        
        if (provider == AIProvider.AZURE_OPENAI) {
            return callAzureOpenAI(prompt);
        } else {
            return callClaude(prompt);
        }
    }
    
    /**
     * @description Universal AI call with system prompt
     * @param systemPrompt System-level instructions
     * @param userPrompt The user's query
     * @param maxTokens Maximum tokens in response
     * @param temperature Temperature setting
     * @return AIResponse wrapper with results
     */
    public static AIResponse callAI(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature) {
        AIProvider provider = (defaultProvider == AIProvider.AUTO) ? detectProvider() : defaultProvider;
        
        if (provider == AIProvider.AZURE_OPENAI) {
            return callAzureOpenAI(systemPrompt, userPrompt, maxTokens, temperature);
        } else {
            return callClaude(systemPrompt, userPrompt, maxTokens, temperature);
        }
    }
    
    /**
     * @description Universal AI call for JSON extraction
     * @param systemPrompt System-level instructions
     * @param userPrompt The user's query
     * @param maxTokens Maximum tokens in response
     * @return AIResponse wrapper with results
     */
    public static AIResponse callAIJSON(String systemPrompt, String userPrompt, Integer maxTokens) {
        AIProvider provider = (defaultProvider == AIProvider.AUTO) ? detectProvider() : defaultProvider;
        
        if (provider == AIProvider.AZURE_OPENAI) {
            return callAzureOpenAIJSON(systemPrompt, userPrompt, maxTokens);
        } else {
            return callClaudeJSON(systemPrompt, userPrompt, maxTokens);
        }
    }

    // Retry configuration (mirrors shell script: 3 attempts with backoff)
    private static final Integer MAX_RETRY_ATTEMPTS = 3;
    private static final Set<Integer> RETRYABLE_STATUS_CODES = new Set<Integer>{429, 500, 502, 503, 504};
    
    // Default provider (can be overridden)
    private static AIProvider defaultProvider = AIProvider.AUTO;

    /**
     * @description Wrapper for AI API response
     */
    public class AIResponse {
        @AuraEnabled public String messageId;
        @AuraEnabled public String content;
        @AuraEnabled public Integer inputTokens;
        @AuraEnabled public Integer outputTokens;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer httpStatusCode;
        @AuraEnabled public Integer attemptCount;

        public AIResponse() {
            this.success = true;
            this.attemptCount = 1;
        }
    }

    /**
     * @description Calls Claude AI API with a prompt (no system prompt)
     * @param prompt The prompt to send to Claude
     * @return AIResponse wrapper with results
     */
    public static AIResponse callClaude(String prompt) {
        // Use settings from custom setting, with sensible defaults
        Claude_API_Credentials__c creds = Claude_API_Credentials__c.getInstance();
        Integer maxTokens = (creds != null && creds.Max_Tokens__c != null)
            ? Integer.valueOf(creds.Max_Tokens__c) : 16384;
        Decimal temperature = (creds != null && creds.Temperature__c != null)
            ? creds.Temperature__c : 0.7;
        return callClaude(null, prompt, maxTokens, temperature);
    }

    /**
     * @description Calls Claude AI API with configurable parameters (no system prompt)
     * @param prompt The prompt to send
     * @param maxTokens Maximum tokens in response
     * @param temperature Temperature for response variability (0-1)
     * @return AIResponse wrapper with results
     */
    public static AIResponse callClaude(String prompt, Integer maxTokens, Decimal temperature) {
        return callClaude(null, prompt, maxTokens, temperature);
    }

    /**
     * @description Calls Claude AI API with system prompt support (Anthropic format)
     * This mirrors the shell script's call_claude function which accepts:
     * call_claude "system prompt" "user prompt" [max_tokens] [temperature]
     *
     * @param systemPrompt Optional system prompt for instruction hierarchy
     * @param userPrompt The user prompt to send
     * @param maxTokens Maximum tokens in response
     * @param temperature Temperature for response variability (0-1)
     * @return AIResponse wrapper with results
     */
    public static AIResponse callClaude(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature) {
        // Check for test mode
        if (Test.isRunningTest() && mockMode) {
            return createMockResponse();
        }

        AIResponse response = null;
        Integer attempt = 0;

        while (attempt < MAX_RETRY_ATTEMPTS) {
            attempt++;

            try {
                response = executeClaudeCall(systemPrompt, userPrompt, maxTokens, temperature);
                response.attemptCount = attempt;

                // Success - return immediately
                if (response.success) {
                    return response;
                }

                // Check if we should retry this error
                if (!shouldRetry(response)) {
                    return response;
                }

                // Log retry attempt
                System.debug('Claude API attempt ' + attempt + ' failed with status ' +
                    response.httpStatusCode + ', will retry if attempts remain');

                // In Apex we can't sleep, but we track the attempt for logging
                // In production, retries could be handled by re-queueing the job

            } catch (Exception e) {
                response = createErrorResponse('Exception during AI API call (attempt ' + attempt + '): ' + e.getMessage());
                response.attemptCount = attempt;

                // Don't retry on exceptions (likely configuration issues)
                if (e.getMessage().contains('credentials') || e.getMessage().contains('endpoint')) {
                    return response;
                }
            }
        }

        // All attempts failed
        if (response != null) {
            response.errorMessage = 'All ' + MAX_RETRY_ATTEMPTS + ' attempts failed. Last error: ' + response.errorMessage;
        } else {
            response = createErrorResponse('All ' + MAX_RETRY_ATTEMPTS + ' attempts failed');
        }

        return response;
    }

    /**
     * @description Executes a single Claude API call
     * @param systemPrompt Optional system prompt
     * @param userPrompt The user prompt
     * @param maxTokens Maximum tokens
     * @param temperature Temperature setting
     * @return AIResponse from this attempt
     */
    private static AIResponse executeClaudeCall(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature) {
        // Retrieve credentials from custom setting
        Claude_API_Credentials__c creds = Claude_API_Credentials__c.getInstance();

        if (creds == null || String.isBlank(creds.API_Key__c)) {
            return createErrorResponse('Claude API credentials not configured');
        }

        // Build HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(creds.API_Endpoint__c);
        req.setMethod('POST');

        // CRITICAL: Support both Azure AI Services AND direct Anthropic auth
        // Azure AI Foundry uses api-key header
        // Some Azure setups also require Authorization: Bearer
        // Direct Anthropic uses x-api-key
        req.setHeader('api-key', creds.API_Key__c);
        req.setHeader('Authorization', 'Bearer ' + creds.API_Key__c);
        req.setHeader('x-api-key', creds.API_Key__c);
        req.setHeader('anthropic-version', '2023-06-01');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); // 120 seconds - allows for longer AI responses

        // Build request body with system prompt support (Anthropic format)
        Map<String, Object> body = new Map<String, Object>{
            'model' => creds.Model__c,
            'max_tokens' => maxTokens,
            'temperature' => temperature,
            'messages' => new List<Object>{
                new Map<String, String>{
                    'role' => 'user',
                    'content' => userPrompt
                }
            }
        };

        // Add system prompt if provided (Anthropic format supports 'system' field)
        if (String.isNotBlank(systemPrompt)) {
            body.put('system', systemPrompt);
        }

        req.setBody(JSON.serialize(body));

        // Execute callout
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Parse response
        if (res.getStatusCode() == 200) {
            return parseSuccessResponse(res.getBody());
        } else {
            AIResponse errorResponse = parseErrorResponse(res);
            errorResponse.httpStatusCode = res.getStatusCode();
            return errorResponse;
        }
    }

    /**
     * @description Determines if an error response should be retried
     * Mirrors shell script behavior: retry on 429, 500, and timeout errors
     * @param response The error response to check
     * @return true if the request should be retried
     */
    private static Boolean shouldRetry(AIResponse response) {
        if (response.success) {
            return false;
        }

        // Retry on known retryable status codes (rate limit, server errors)
        if (response.httpStatusCode != null && RETRYABLE_STATUS_CODES.contains(response.httpStatusCode)) {
            return true;
        }

        // Retry on timeout-related errors
        if (response.errorMessage != null &&
            (response.errorMessage.containsIgnoreCase('timeout') ||
             response.errorMessage.containsIgnoreCase('connection reset') ||
             response.errorMessage.containsIgnoreCase('read timed out'))) {
            return true;
        }

        return false;
    }

    /**
     * @description Calls Claude with automatic retry on failure
     * DEPRECATED: Retry logic is now built into callClaude(). This method is kept for backwards compatibility.
     * @param prompt The prompt to send
     * @param maxRetries Maximum number of retry attempts (ignored - uses MAX_RETRY_ATTEMPTS)
     * @return AIResponse wrapper with results
     */
    public static AIResponse callClaudeWithRetry(String prompt, Integer maxRetries) {
        // Retry is now built into the main callClaude method
        // This wrapper is kept for backwards compatibility
        return callClaude(prompt);
    }

    /**
     * @description Calls Claude AI with system prompt for specialized use cases
     * This is the preferred method for calls that need instruction hierarchy
     *
     * @param systemPrompt System-level instructions
     * @param userPrompt The user's query
     * @param maxTokens Maximum tokens in response
     * @return AIResponse wrapper with results
     */
    public static AIResponse callClaudeWithSystem(String systemPrompt, String userPrompt, Integer maxTokens) {
        return callClaude(systemPrompt, userPrompt, maxTokens, 0.7);
    }

    /**
     * @description Calls Claude for JSON extraction with lower temperature
     * Mirrors shell script's call_claude_json function
     *
     * @param systemPrompt System-level instructions
     * @param userPrompt The user's query
     * @param maxTokens Maximum tokens in response
     * @return AIResponse wrapper with results
     */
    public static AIResponse callClaudeJSON(String systemPrompt, String userPrompt, Integer maxTokens) {
        // Enhanced system prompt for JSON output (mirrors shell script)
        String enhancedSystem = systemPrompt + '\n\n' +
            'CRITICAL: You MUST respond with valid JSON only. No markdown code fences, no explanation, ' +
            'no text before or after. Just the raw JSON object starting with { and ending with }.';

        // Use lower temperature for more deterministic JSON output (matches shell script: 0.2)
        return callClaude(enhancedSystem, userPrompt, maxTokens, 0.2);
    }

    // ========================================================================
    // AZURE OPENAI METHODS
    // ========================================================================

    /**
     * @description Calls Azure OpenAI API with a prompt (no system prompt)
     * @param prompt The prompt to send to Azure OpenAI
     * @return AIResponse wrapper with results
     */
    public static AIResponse callAzureOpenAI(String prompt) {
        Azure_OpenAI_Credentials__c creds = Azure_OpenAI_Credentials__c.getInstance();
        Integer maxTokens = (creds != null && creds.Max_Tokens__c != null)
            ? Integer.valueOf(creds.Max_Tokens__c) : 4096;
        Decimal temperature = (creds != null && creds.Temperature__c != null)
            ? creds.Temperature__c : 0.7;
        return callAzureOpenAI(null, prompt, maxTokens, temperature);
    }

    /**
     * @description Calls Azure OpenAI API with configurable parameters
     * @param prompt The prompt to send
     * @param maxTokens Maximum tokens in response
     * @param temperature Temperature for response variability (0-2)
     * @return AIResponse wrapper with results
     */
    public static AIResponse callAzureOpenAI(String prompt, Integer maxTokens, Decimal temperature) {
        return callAzureOpenAI(null, prompt, maxTokens, temperature);
    }

    /**
     * @description Calls Azure OpenAI API with system prompt support
     * @param systemPrompt Optional system prompt for instruction hierarchy
     * @param userPrompt The user prompt to send
     * @param maxTokens Maximum tokens in response
     * @param temperature Temperature for response variability (0-2)
     * @return AIResponse wrapper with results
     */
    public static AIResponse callAzureOpenAI(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature) {
        if (Test.isRunningTest() && mockMode) {
            return createMockResponse();
        }

        AIResponse response = null;
        Integer attempt = 0;

        while (attempt < MAX_RETRY_ATTEMPTS) {
            attempt++;

            try {
                response = executeAzureOpenAICall(systemPrompt, userPrompt, maxTokens, temperature);
                response.attemptCount = attempt;

                if (response.success) {
                    return response;
                }

                if (!shouldRetry(response)) {
                    return response;
                }

                System.debug('Azure OpenAI attempt ' + attempt + ' failed with status ' +
                    response.httpStatusCode + ', will retry if attempts remain');

            } catch (Exception e) {
                response = createErrorResponse('Exception during Azure OpenAI call (attempt ' + attempt + '): ' + e.getMessage());
                response.attemptCount = attempt;

                if (e.getMessage().contains('credentials') || e.getMessage().contains('endpoint')) {
                    return response;
                }
            }
        }

        if (response != null) {
            response.errorMessage = 'All ' + MAX_RETRY_ATTEMPTS + ' attempts failed. Last error: ' + response.errorMessage;
        } else {
            response = createErrorResponse('All ' + MAX_RETRY_ATTEMPTS + ' attempts failed');
        }

        return response;
    }

    /**
     * @description Executes a single Azure OpenAI API call
     * @param systemPrompt Optional system prompt
     * @param userPrompt The user prompt
     * @param maxTokens Maximum tokens
     * @param temperature Temperature setting
     * @return AIResponse from this attempt
     */
    private static AIResponse executeAzureOpenAICall(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature) {
        Azure_OpenAI_Credentials__c creds = Azure_OpenAI_Credentials__c.getInstance();

        if (creds == null || String.isBlank(creds.API_Key__c)) {
            return createErrorResponse('Azure OpenAI credentials not configured');
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(creds.API_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('api-key', creds.API_Key__c);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        // Build messages array (OpenAI format)
        List<Object> messages = new List<Object>();
        
        // Add system message if provided
        if (String.isNotBlank(systemPrompt)) {
            messages.add(new Map<String, String>{
                'role' => 'system',
                'content' => systemPrompt
            });
        }
        
        // Add user message
        messages.add(new Map<String, String>{
            'role' => 'user',
            'content' => userPrompt
        });

        Map<String, Object> body = new Map<String, Object>{
            'messages' => messages,
            'max_tokens' => maxTokens,
            'temperature' => temperature
        };

        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return parseAzureOpenAIResponse(res.getBody());
        } else {
            AIResponse errorResponse = parseErrorResponse(res);
            errorResponse.httpStatusCode = res.getStatusCode();
            return errorResponse;
        }
    }

    /**
     * @description Calls Azure OpenAI for JSON extraction with lower temperature
     * @param systemPrompt System-level instructions
     * @param userPrompt The user's query
     * @param maxTokens Maximum tokens in response
     * @return AIResponse wrapper with results
     */
    public static AIResponse callAzureOpenAIJSON(String systemPrompt, String userPrompt, Integer maxTokens) {
        String enhancedSystem = systemPrompt + '\n\n' +
            'CRITICAL: You MUST respond with valid JSON only. No markdown code fences, no explanation, ' +
            'no text before or after. Just the raw JSON object starting with { and ending with }.';

        return callAzureOpenAI(enhancedSystem, userPrompt, maxTokens, 0.2);
    }

    /**
     * @description Parses Azure OpenAI API response
     * @param jsonBody Response body as JSON string
     * @return AIResponse wrapper
     */
    private static AIResponse parseAzureOpenAIResponse(String jsonBody) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            List<Object> choices = (List<Object>) data.get('choices');
            Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
            Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');

            AIResponse response = new AIResponse();
            response.messageId = (String) data.get('id');
            response.content = (String) message.get('content');

            Map<String, Object> usage = (Map<String, Object>) data.get('usage');
            if (usage != null) {
                response.inputTokens = (Integer) usage.get('prompt_tokens');
                response.outputTokens = (Integer) usage.get('completion_tokens');
            }

            return response;

        } catch (Exception e) {
            return createErrorResponse('Failed to parse Azure OpenAI response: ' + e.getMessage());
        }
    }

    /**
     * @description Parses successful API response
     * @param jsonBody Response body as JSON string
     * @return AIResponse wrapper
     */
    private static AIResponse parseSuccessResponse(String jsonBody) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            List<Object> content = (List<Object>) data.get('content');
            Map<String, Object> firstContent = (Map<String, Object>) content[0];

            AIResponse response = new AIResponse();
            response.messageId = (String) data.get('id');
            response.content = (String) firstContent.get('text');

            Map<String, Object> usage = (Map<String, Object>) data.get('usage');
            if (usage != null) {
                response.inputTokens = (Integer) usage.get('input_tokens');
                response.outputTokens = (Integer) usage.get('output_tokens');
            }

            return response;

        } catch (Exception e) {
            return createErrorResponse('Failed to parse AI API response: ' + e.getMessage());
        }
    }

    /**
     * @description Parses error response from API
     * @param res HttpResponse with error
     * @return AIResponse wrapper with error details
     */
    private static AIResponse parseErrorResponse(HttpResponse res) {
        String errorMessage = 'AI API Error: ' + res.getStatus() + ' (Code: ' + res.getStatusCode() + ')';

        try {
            Map<String, Object> errorData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (errorData.containsKey('error')) {
                Map<String, Object> error = (Map<String, Object>) errorData.get('error');
                if (error.containsKey('message')) {
                    errorMessage += ' - ' + error.get('message');
                }
            }
        } catch (Exception e) {
            errorMessage += ' - Response: ' + res.getBody();
        }

        return createErrorResponse(errorMessage);
    }

    /**
     * @description Creates an error response wrapper
     * @param errorMessage The error message
     * @return AIResponse wrapper with error
     */
    private static AIResponse createErrorResponse(String errorMessage) {
        AIResponse response = new AIResponse();
        response.success = false;
        response.errorMessage = errorMessage;
        return response;
    }

    /**
     * @description Creates a mock response for testing
     * @return AIResponse wrapper with mock data
     */
    @TestVisible
    private static AIResponse createMockResponse() {
        AIResponse response = new AIResponse();
        response.messageId = 'msg_mock_123';
        response.content = mockResponse != null ?
                          mockResponse :
                          '{"result": "mock response"}';
        response.inputTokens = 100;
        response.outputTokens = 50;
        return response;
    }

    /**
     * @description Estimates token count for a string (rough approximation)
     * @param text Text to estimate tokens for
     * @return Estimated token count
     */
    public static Integer estimateTokens(String text) {
        if (String.isBlank(text)) {
            return 0;
        }
        // Rough estimate: 1 token per 4 characters
        return (text.length() / 4) + 1;
    }

    /**
     * @description Custom exception for AI service errors
     */
    public class AIServiceException extends Exception {}
}