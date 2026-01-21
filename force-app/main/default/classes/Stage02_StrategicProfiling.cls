/**
 * @description Stage 2: Strategic Profiling with Company Research
 * Performs AI-powered company research and extracts target persona and objectives.
 * This stage now incorporates the company website to provide rich business context
 * about the customer organization, their products, services, and market position.
 */
public with sharing class Stage02_StrategicProfiling implements IStage {
    
    private static final Integer STAGE_NUMBER = 2;
    
    /**
     * @description Executes Stage 2: Strategic Profiling with Company Research
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing businessContext, companyWebsite and recordData from Stage 1
     * @return StageResult with profiling results including company intelligence in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 2: Strategic Profiling');

        try {
            result.queueInfo(runId, STAGE_NUMBER, 'Starting strategic profiling with company research');

            // Extract inputs from previous stage
            String businessContext = (String) inputs.get('businessContext');
            String rootObject = (String) inputs.get('rootObject');
            String outputFormat = (String) inputs.get('outputFormat');
            String companyWebsite = (String) inputs.get('companyWebsite');

            if (String.isBlank(businessContext)) {
                throw new StageException('Business context is required for profiling');
            }

            // Step 1: If company website provided, perform company research
            String companyIntelligence = '';
            if (String.isNotBlank(companyWebsite)) {
                result.queueInfo(runId, STAGE_NUMBER, 'Researching company: ' + companyWebsite);
                companyIntelligence = performCompanyResearch(companyWebsite, rootObject, runId, result);
            } else {
                result.queueInfo(runId, STAGE_NUMBER, 'No company website provided, skipping company research');
            }

            // Step 2: Build enhanced profiling prompt with company context
            String prompt = buildEnhancedProfilingPrompt(businessContext, rootObject, outputFormat, companyIntelligence);

            result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for strategic profiling');

            // Call AI (HTTP callout - no DML before this!)
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 4096, 0.7);

            if (!aiResponse.success) {
                throw new StageException('AI call failed: ' + aiResponse.errorMessage);
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'AI response received (Tokens: ' + aiResponse.inputTokens + '/' + aiResponse.outputTokens + ')');

            // Parse AI response
            Map<String, Object> profilingResult = parseProfilingResponse(aiResponse.content);

            // Build outputs
            result.outputs.put('targetPersona', profilingResult.get('targetPersona'));
            result.outputs.put('businessObjectives', profilingResult.get('businessObjectives'));
            result.outputs.put('keyMetrics', profilingResult.get('keyMetrics'));
            result.outputs.put('audienceLevel', profilingResult.get('audienceLevel'));
            result.outputs.put('profilingJson', aiResponse.content);
            result.aiReasoning = (String) profilingResult.get('reasoning');

            // Store company intelligence for downstream stages
            result.outputs.put('companyIntelligence', companyIntelligence);
            result.outputs.put('companyProfile', profilingResult.get('companyProfile'));
            result.outputs.put('industryContext', profilingResult.get('industryContext'));
            result.outputs.put('strategicInsights', profilingResult.get('strategicInsights'));

            // Pass through inputs
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            result.outputs.put('outputFormat', outputFormat);
            result.outputs.put('companyWebsite', companyWebsite);

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
     * @description Performs AI-powered company research based on website/name
     * @param companyWebsite Company website URL (e.g., apple.com)
     * @param rootObject The root Salesforce object for context
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return Company intelligence summary
     */
    private String performCompanyResearch(String companyWebsite, String rootObject, Id runId, StageResult result) {
        // Extract company name from website if needed
        String companyName = extractCompanyName(companyWebsite);
        
        String researchPrompt = 'You are a business intelligence analyst. Research and provide detailed information about this company.\n\n' +
            'COMPANY WEBSITE: ' + companyWebsite + '\n' +
            'COMPANY NAME: ' + companyName + '\n\n' +
            'RESEARCH THE FOLLOWING:\n\n' +
            '1. COMPANY OVERVIEW:\n' +
            '   - What does this company do?\n' +
            '   - What industry/sector are they in?\n' +
            '   - What is their market position?\n' +
            '   - Company size (if known)\n\n' +
            '2. PRODUCTS & SERVICES:\n' +
            '   - What are their main products/services?\n' +
            '   - What solutions do they offer?\n' +
            '   - Who are their target customers?\n\n' +
            '3. BUSINESS MODEL:\n' +
            '   - How do they generate revenue?\n' +
            '   - What is their go-to-market strategy?\n' +
            '   - Key differentiators from competitors?\n\n' +
            '4. STRATEGIC CONTEXT (for ' + rootObject + ' data):\n' +
            '   - What would be relevant insights about their ' + rootObject + ' relationships?\n' +
            '   - What business challenges might they face?\n' +
            '   - What opportunities could AI-generated insights highlight?\n\n' +
            'Provide a comprehensive but concise summary (500-800 words) that can be used to enrich ' +
            'AI-generated content about their ' + rootObject + ' records. Focus on actionable business context.\n\n' +
            'Return ONLY the research summary as plain text, no JSON formatting.';

        result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for company research: ' + companyName);

        // Use slightly higher temperature for creative research synthesis
        AIServiceClient.AIResponse researchResponse = AIServiceClient.callAI(null, researchPrompt, 2048, 0.8);

        if (!researchResponse.success) {
            result.queueWarning(runId, STAGE_NUMBER, 
                'Company research failed (non-critical): ' + researchResponse.errorMessage);
            return '';
        }

        result.queueInfo(runId, STAGE_NUMBER, 
            'Company research completed for: ' + companyName + 
            ' (Tokens: ' + researchResponse.inputTokens + '/' + researchResponse.outputTokens + ')');

        return researchResponse.content;
    }

    /**
     * @description Extracts company name from website URL
     * @param website Website URL
     * @return Company name derived from URL
     */
    private String extractCompanyName(String website) {
        if (String.isBlank(website)) return '';
        
        String name = website.toLowerCase();
        // Remove protocol
        name = name.replace('https://', '').replace('http://', '');
        // Remove www
        name = name.replace('www.', '');
        // Get domain only
        if (name.contains('/')) {
            name = name.substringBefore('/');
        }
        // Remove TLD
        if (name.contains('.')) {
            name = name.substringBefore('.');
        }
        // Capitalize first letter
        if (name.length() > 0) {
            name = name.substring(0, 1).toUpperCase() + name.substring(1);
        }
        return name;
    }

    /**
     * @description Builds enhanced profiling prompt with company research context
     * @param businessContext User-provided business requirements
     * @param rootObject Target Salesforce object
     * @param outputFormat Desired output format
     * @param companyIntelligence AI-generated company research
     * @return Formatted prompt string
     */
    private String buildEnhancedProfilingPrompt(String businessContext, String rootObject, 
                                                 String outputFormat, String companyIntelligence) {
        String prompt = 'You are an expert business analyst specializing in Salesforce AI implementations.\n\n';
        
        prompt += '=== USER\'S BUSINESS CONTEXT ===\n' + businessContext + '\n\n';
        
        prompt += 'TARGET OBJECT: ' + rootObject + '\n';
        prompt += 'OUTPUT FORMAT: ' + outputFormat + '\n\n';
        
        // Add company intelligence if available
        if (String.isNotBlank(companyIntelligence)) {
            prompt += '=== COMPANY INTELLIGENCE (Use this to enrich your analysis) ===\n';
            prompt += companyIntelligence + '\n\n';
        }
        
        prompt += '=== YOUR TASK ===\n';
        prompt += 'Analyze the business context and company intelligence to create a comprehensive profile.\n\n';
        
        prompt += 'EXTRACT THE FOLLOWING:\n\n';
        
        prompt += '1. TARGET PERSONA:\n';
        prompt += '   - Who will consume this AI output? (e.g., Sales Rep, Executive, Support Agent)\n';
        prompt += '   - What is their role and responsibilities?\n\n';
        
        prompt += '2. BUSINESS OBJECTIVES:\n';
        prompt += '   - What are the primary business goals? (2-3 key objectives)\n';
        prompt += '   - How does this relate to the company\'s products/services?\n\n';
        
        prompt += '3. KEY METRICS:\n';
        prompt += '   - What metrics will determine success? (2-4 metrics)\n';
        prompt += '   - Include both quantitative and qualitative measures\n\n';
        
        prompt += '4. AUDIENCE LEVEL:\n';
        prompt += '   - Technical expertise level (Executive, Manager, Practitioner)\n\n';
        
        prompt += '5. COMPANY PROFILE (if company info available):\n';
        prompt += '   - Brief summary of company, products, and market\n';
        prompt += '   - How their business model relates to the ' + rootObject + ' data\n\n';
        
        prompt += '6. INDUSTRY CONTEXT:\n';
        prompt += '   - Relevant industry terminology and best practices\n';
        prompt += '   - Common challenges and opportunities in this space\n\n';
        
        prompt += '7. STRATEGIC INSIGHTS:\n';
        prompt += '   - What kind of AI-generated insights would be most valuable?\n';
        prompt += '   - What patterns or trends should the output highlight?\n';
        prompt += '   - What actionable recommendations would help the persona?\n\n';
        
        prompt += '8. REASONING:\n';
        prompt += '   - Brief explanation of your analysis (2-3 sentences)\n\n';
        
        prompt += 'Return ONLY valid JSON in this exact format:\n';
        prompt += '{\n';
        prompt += '  "targetPersona": "string - specific role description",\n';
        prompt += '  "businessObjectives": ["objective1", "objective2", "objective3"],\n';
        prompt += '  "keyMetrics": ["metric1", "metric2", "metric3"],\n';
        prompt += '  "audienceLevel": "Executive|Manager|Practitioner",\n';
        prompt += '  "companyProfile": "string - brief company summary if known",\n';
        prompt += '  "industryContext": "string - industry-specific context and terminology",\n';
        prompt += '  "strategicInsights": ["insight1 - what patterns to highlight", "insight2 - what recommendations to make", "insight3 - what trends to analyze"],\n';
        prompt += '  "reasoning": "string - explanation of analysis"\n';
        prompt += '}';
        
        return prompt;
    }
    
    /**
     * @description Parses AI response into structured data
     * @param aiContent Raw response from AI
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
            
            // Set defaults for new optional fields
            if (!parsedData.containsKey('companyProfile')) {
                parsedData.put('companyProfile', '');
            }
            if (!parsedData.containsKey('industryContext')) {
                parsedData.put('industryContext', '');
            }
            if (!parsedData.containsKey('strategicInsights')) {
                parsedData.put('strategicInsights', new List<String>());
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
