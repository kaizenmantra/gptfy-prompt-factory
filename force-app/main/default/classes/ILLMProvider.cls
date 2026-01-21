/**
 * @description Interface for LLM Provider implementations
 * Each LLM (Claude, Azure OpenAI, DeepSeek, etc.) should implement this interface
 * 
 * This allows easy addition of new LLM providers without modifying AIServiceClient
 */
public interface ILLMProvider {
    
    /**
     * @description Check if this provider is configured and ready to use
     * @return true if credentials are configured, false otherwise
     */
    Boolean isConfigured();
    
    /**
     * @description Check if this provider is set as the default
     * @return true if Default__c checkbox is checked
     */
    Boolean isDefault();
    
    /**
     * @description Get the provider name for logging/debugging
     * @return Provider name (e.g., "Claude AI", "Azure OpenAI", "DeepSeek")
     */
    String getProviderName();
    
    /**
     * @description Execute an AI call with just a prompt
     * @param prompt The prompt to send
     * @return AIResponse wrapper with results
     */
    AIServiceClient.AIResponse callAI(String prompt);
    
    /**
     * @description Execute an AI call with system and user prompts
     * @param systemPrompt System-level instructions
     * @param userPrompt The user's query
     * @param maxTokens Maximum tokens in response
     * @param temperature Temperature setting (0-1)
     * @return AIResponse wrapper with results
     */
    AIServiceClient.AIResponse callAI(String systemPrompt, String userPrompt, Integer maxTokens, Decimal temperature);
    
    /**
     * @description Execute an AI call expecting JSON response
     * @param systemPrompt System-level instructions
     * @param userPrompt The user's query
     * @param maxTokens Maximum tokens in response
     * @return AIResponse wrapper with results
     */
    AIServiceClient.AIResponse callAIJSON(String systemPrompt, String userPrompt, Integer maxTokens);
}
