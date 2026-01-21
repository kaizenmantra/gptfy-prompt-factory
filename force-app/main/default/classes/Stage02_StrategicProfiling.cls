/**
 * @description Stage 2: Strategic Profiling
 * Calls Claude AI to analyze business context and extract target persona and objectives
 */
public with sharing class Stage02_StrategicProfiling implements IStage {
    
    private static final Integer STAGE_NUMBER = 2;
    
    /**
     * @description Executes Stage 2: Strategic Profiling
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing businessContext and recordData from Stage 1
     * @return StageResult with profiling results in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 2: Strategic Profiling');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            // Use deferred logging (no DML) - logs will be inserted AFTER callout completes
            result.queueInfo(runId, STAGE_NUMBER, 'Starting strategic profiling with Claude AI');

            // Extract inputs from previous stage
            String businessContext = (String) inputs.get('businessContext');
            String rootObject = (String) inputs.get('rootObject');
            String outputFormat = (String) inputs.get('outputFormat');

            if (String.isBlank(businessContext)) {
                throw new StageException('Business context is required for profiling');
            }

            // Build prompt for Claude
            String prompt = buildProfilingPrompt(businessContext, rootObject, outputFormat);

            result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for strategic profiling');

            // Call AI (HTTP callout - no DML before this!)
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 2048, 0.7);

            if (!aiResponse.success) {
                throw new StageException('AI call failed: ' + aiResponse.errorMessage);
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Claude AI response received (Tokens: ' + aiResponse.inputTokens + '/' + aiResponse.outputTokens + ')');

            // Parse AI response
            Map<String, Object> profilingResult = parseProfilingResponse(aiResponse.content);

            // Build outputs
            result.outputs.put('targetPersona', profilingResult.get('targetPersona'));
            result.outputs.put('businessObjectives', profilingResult.get('businessObjectives'));
            result.outputs.put('keyMetrics', profilingResult.get('keyMetrics'));
            result.outputs.put('audienceLevel', profilingResult.get('audienceLevel'));
            result.outputs.put('profilingJson', aiResponse.content);
            result.aiReasoning = (String) profilingResult.get('reasoning');

            // Pass through inputs (avoid large data to prevent serialization issues)
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            // recordData omitted - causes stack overflow during serialization
            result.outputs.put('outputFormat', outputFormat);

            result.markCompleted();
            result.queueInfo(runId, STAGE_NUMBER,
                'Strategic profiling completed. Persona: ' + profilingResult.get('targetPersona'));

        } catch (Exception e) {
            String errorMsg = 'Failed to complete strategic profiling: ' + e.getMessage();
            result.markFailed(errorMsg);
            result.queueError(runId, STAGE_NUMBER, 'Stage execution failed: ' + e.getMessage());
        }

        return result;
    }
    
    /**
     * @description Builds the prompt for Claude AI to analyze business context
     * @param businessContext User-provided business requirements
     * @param rootObject Target Salesforce object
     * @param outputFormat Desired output format
     * @return Formatted prompt string
     */
    private String buildProfilingPrompt(String businessContext, String rootObject, String outputFormat) {
        return 'You are an expert business analyst specializing in Salesforce AI implementations.\n\n' +
               'BUSINESS CONTEXT:\n' + businessContext + '\n\n' +
               'TARGET OBJECT: ' + rootObject + '\n' +
               'OUTPUT FORMAT: ' + outputFormat + '\n\n' +
               'Analyze this business context and extract:\n' +
               '1. TARGET PERSONA: Who will consume this AI output? (e.g., Sales Rep, Executive, Support Agent)\n' +
               '2. BUSINESS OBJECTIVES: What are the primary business goals? (2-3 key objectives)\n' +
               '3. KEY METRICS: What metrics will determine success? (2-4 metrics)\n' +
               '4. AUDIENCE LEVEL: Technical expertise level (Executive, Manager, Practitioner)\n' +
               '5. REASONING: Brief explanation of your analysis (2-3 sentences)\n\n' +
               'Return ONLY valid JSON in this exact format:\n' +
               '{\n' +
               '  "targetPersona": "string",\n' +
               '  "businessObjectives": ["objective1", "objective2"],\n' +
               '  "keyMetrics": ["metric1", "metric2"],\n' +
               '  "audienceLevel": "string",\n' +
               '  "reasoning": "string"\n' +
               '}';
    }
    
    /**
     * @description Parses Claude AI response into structured data
     * @param aiContent Raw response from Claude
     * @return Map with parsed profiling data
     */
    private Map<String, Object> parseProfilingResponse(String aiContent) {
        try {
            // Remove markdown code blocks if present
            String cleanJson = aiContent.trim();
            if (cleanJson.startsWith('```json')) {
                cleanJson = cleanJson.substringAfter('```json').substringBefore('```').trim();
            } else if (cleanJson.startsWith('```')) {
                cleanJson = cleanJson.substringAfter('```').substringBefore('```').trim();
            }
            
            // Parse JSON response
            Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);
            
            // Validate required fields
            if (!parsedData.containsKey('targetPersona') || 
                !parsedData.containsKey('businessObjectives')) {
                throw new StageException('Invalid AI response: missing required fields');
            }
            
            return parsedData;
            
        } catch (JSONException e) {
            throw new StageException('Failed to parse AI response as JSON: ' + e.getMessage());
        }
    }
    
    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}