/**
 * @description DeepSeek LLM Provider implementation
 * DeepSeek-R1 is hosted on Azure AI and provides advanced reasoning capabilities
 * 
 * API Format: OpenAI-compatible with unique reasoning_content field
 * Endpoint: Azure AI Services
 * Model: DeepSeek-R1
 */
public with sharing class DeepSeekProvider implements ILLMProvider {
    
    private static final Integer MAX_RETRY_ATTEMPTS = 3;
    private static final Set<Integer> RETRYABLE_STATUS_CODES = new Set<Integer>{429, 500, 502, 503, 504};
    
    /**
     * @description Check if DeepSeek credentials are configured
     */
    public Boolean isConfigured() {
        DeepSeek_Credentials__c creds = DeepSeek_Credentials__c.getInstance();
        return (creds != null && String.isNotBlank(creds.API_Key__c) && String.isNotBlank(creds.API_Endpoint__c));
    }
    
    /**
     * @description Check if DeepSeek is set as default provider
     */
    public Boolean isDefault() {
        DeepSeek_Credentials__c creds = DeepSeek_Credentials__c.getInstance();
        return (creds != null && creds.Default__c == true);
    }
    
    /**
     * @description Get provider name
     */
    public String getProviderName() {
        return 'DeepSeek-R1';
    }
    
    /**
     * @description Simple AI call with just a prompt
     */
    public AIServiceClient.AIResponse callAI(String prompt) {
        DeepSeek_Credentials__c creds = DeepSeek_Credentials__c.getInstance();
        Integer maxTokens = (creds != null && creds.Max_Tokens__c != null) 
            ? Integer.valueOf(creds.Max_Tokens__c) : 4096;
        Decimal temperature = (creds != null && creds.Temperature__c != null) 
            ? creds.Temperature__c : 0.7;
        
        return callAI(null, prompt, maxTokens, temperature);
    }
    
    /**
     * @description AI call with system prompt and parameters
     */
    public AIServiceClient.AIResponse callAI(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature) {
        AIServiceClient.AIResponse response = null;
        Integer attempt = 0;
        
        while (attempt < MAX_RETRY_ATTEMPTS) {
            attempt++;
            
            try {
                response = executeDeepSeekCall(systemPrompt, userPrompt, maxTokens, temperature);
                response.attemptCount = attempt;
                
                if (response.success) {
                    return response;
                }
                
                if (!shouldRetry(response)) {
                    return response;
                }
                
                System.debug('DeepSeek API attempt ' + attempt + ' failed with status ' +
                    response.httpStatusCode + ', will retry if attempts remain');
                    
            } catch (Exception e) {
                response = createErrorResponse('Exception during DeepSeek API call (attempt ' + attempt + '): ' + e.getMessage());
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
     * @description AI call expecting JSON response
     */
    public AIServiceClient.AIResponse callAIJSON(String systemPrompt, String userPrompt, Integer maxTokens) {
        String enhancedSystem = systemPrompt + '\n\n' +
            'CRITICAL: You MUST respond with valid JSON only. No markdown code fences, no explanation, ' +
            'no text before or after. Just the raw JSON object starting with { and ending with }.';
        
        return callAI(enhancedSystem, userPrompt, maxTokens, 0.2);
    }
    
    /**
     * @description Execute the actual DeepSeek API call
     */
    private AIServiceClient.AIResponse executeDeepSeekCall(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature) {
        DeepSeek_Credentials__c creds = DeepSeek_Credentials__c.getInstance();
        
        if (creds == null || String.isBlank(creds.API_Key__c)) {
            return createErrorResponse('DeepSeek credentials not configured');
        }
        
        if (String.isBlank(creds.API_Endpoint__c)) {
            return createErrorResponse('DeepSeek API endpoint not configured');
        }
        
        // Build messages array
        List<Map<String, String>> messages = new List<Map<String, String>>();
        if (String.isNotBlank(systemPrompt)) {
            messages.add(new Map<String, String>{
                'role' => 'system',
                'content' => systemPrompt
            });
        }
        messages.add(new Map<String, String>{
            'role' => 'user',
            'content' => userPrompt
        });
        
        // Build request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'model' => creds.Model_Name__c != null ? creds.Model_Name__c : 'DeepSeek-R1',
            'messages' => messages,
            'max_tokens' => maxTokens,
            'temperature' => temperature
        };
        
        // Make HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(creds.API_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('api-key', creds.API_Key__c);
        req.setTimeout(120000); // 120 second timeout
        req.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        return parseDeepSeekResponse(res);
    }
    
    /**
     * @description Parse DeepSeek API response
     * DeepSeek returns OpenAI-compatible format with additional reasoning_content field
     */
    private AIServiceClient.AIResponse parseDeepSeekResponse(HttpResponse res) {
        AIServiceClient.AIResponse response = new AIServiceClient.AIResponse();
        response.httpStatusCode = res.getStatusCode();
        
        if (res.getStatusCode() == 200) {
            try {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Extract completion content
                List<Object> choices = (List<Object>) jsonResponse.get('choices');
                if (choices != null && !choices.isEmpty()) {
                    Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
                    Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
                    
                    if (message != null) {
                        response.content = (String) message.get('content');
                        
                        // DeepSeek-R1 specific: Extract reasoning content if available
                        String reasoningContent = (String) message.get('reasoning_content');
                        if (String.isNotBlank(reasoningContent)) {
                            System.debug('DeepSeek Reasoning: ' + reasoningContent.substring(0, Math.min(200, reasoningContent.length())));
                        }
                    }
                }
                
                // Extract token usage
                Map<String, Object> usage = (Map<String, Object>) jsonResponse.get('usage');
                if (usage != null) {
                    response.inputTokens = ((Integer) usage.get('prompt_tokens'));
                    response.outputTokens = ((Integer) usage.get('completion_tokens'));
                }
                
                response.messageId = (String) jsonResponse.get('id');
                response.success = true;
                
            } catch (Exception e) {
                response.success = false;
                response.errorMessage = 'Failed to parse DeepSeek response: ' + e.getMessage();
                System.debug('DeepSeek response body: ' + res.getBody());
            }
        } else {
            response.success = false;
            try {
                Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> error = (Map<String, Object>) errorBody.get('error');
                if (error != null) {
                    response.errorMessage = 'DeepSeek API error: ' + error.get('message');
                } else {
                    response.errorMessage = 'DeepSeek API error: ' + res.getBody();
                }
            } catch (Exception e) {
                response.errorMessage = 'DeepSeek API error (status ' + res.getStatusCode() + '): ' + res.getBody();
            }
        }
        
        return response;
    }
    
    /**
     * @description Determine if we should retry this error
     */
    private Boolean shouldRetry(AIServiceClient.AIResponse response) {
        return RETRYABLE_STATUS_CODES.contains(response.httpStatusCode);
    }
    
    /**
     * @description Create an error response
     */
    private AIServiceClient.AIResponse createErrorResponse(String errorMessage) {
        AIServiceClient.AIResponse response = new AIServiceClient.AIResponse();
        response.success = false;
        response.errorMessage = errorMessage;
        response.httpStatusCode = 0;
        return response;
    }
}
