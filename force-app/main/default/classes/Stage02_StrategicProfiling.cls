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
            
            // DEBUG: Log all inputs received to trace data flow issue
            result.queueInfo(runId, STAGE_NUMBER, 'DEBUG - Inputs received from Stage 1:');
            result.queueInfo(runId, STAGE_NUMBER, '  rootObject: ' + rootObject);
            result.queueInfo(runId, STAGE_NUMBER, '  outputFormat: ' + outputFormat);
            result.queueInfo(runId, STAGE_NUMBER, '  companyWebsite: [' + (String.isBlank(companyWebsite) ? 'BLANK/NULL' : companyWebsite) + ']');
            result.queueInfo(runId, STAGE_NUMBER, '  businessContext length: ' + (String.isBlank(businessContext) ? '0' : String.valueOf(businessContext.length())));

            if (String.isBlank(businessContext)) {
                throw new StageException('Business context is required for profiling');
            }

            // Step 1: If company website provided, perform company research
            String companyIntelligence = '';
            if (String.isNotBlank(companyWebsite)) {
                result.queueInfo(runId, STAGE_NUMBER, '>>> COMPANY RESEARCH: Starting research for website: ' + companyWebsite);
                companyIntelligence = performCompanyResearch(companyWebsite, rootObject, runId, result);
                // DEBUG: Log whether research returned anything
                if (String.isNotBlank(companyIntelligence)) {
                    result.queueInfo(runId, STAGE_NUMBER, '>>> COMPANY RESEARCH: Received ' + companyIntelligence.length() + ' chars of intelligence');
                    // Log first 300 chars to see what was returned
                    String preview = companyIntelligence.length() > 300 ? companyIntelligence.substring(0, 300) : companyIntelligence;
                    result.queueInfo(runId, STAGE_NUMBER, '>>> COMPANY RESEARCH PREVIEW: ' + preview);
                } else {
                    result.queueWarning(runId, STAGE_NUMBER, '>>> COMPANY RESEARCH: Returned EMPTY - this is the bug!');
                }
            } else {
                result.queueWarning(runId, STAGE_NUMBER, '>>> COMPANY WEBSITE IS BLANK - skipping company research. This explains generic output!');
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
            String targetPersona = (String) profilingResult.get('targetPersona');
            String companyProfile = (String) profilingResult.get('companyProfile');
            String industryContext = (String) profilingResult.get('industryContext');
            
            result.outputs.put('targetPersona', targetPersona);
            result.outputs.put('businessObjectives', profilingResult.get('businessObjectives'));
            result.outputs.put('keyMetrics', profilingResult.get('keyMetrics'));
            result.outputs.put('audienceLevel', profilingResult.get('audienceLevel'));
            result.outputs.put('profilingJson', aiResponse.content);
            result.aiReasoning = (String) profilingResult.get('reasoning');

            // Store company intelligence for downstream stages
            result.outputs.put('companyIntelligence', companyIntelligence);
            result.outputs.put('companyProfile', companyProfile);
            result.outputs.put('industryContext', industryContext);
            
            // Flatten strategicInsights list to string for easier consumption
            Object insightsObj = profilingResult.get('strategicInsights');
            String insightsStr = '';
            if (insightsObj instanceof List<Object>) {
                List<String> insightsList = new List<String>();
                for (Object item : (List<Object>) insightsObj) {
                    insightsList.add('- ' + String.valueOf(item));
                }
                insightsStr = String.join(insightsList, '\n');
            }
            result.outputs.put('strategicInsights', insightsStr);

            // === OBSERVABILITY LOGGING ===
            // Log company research summary for troubleshooting
            if (String.isNotBlank(companyIntelligence)) {
                String intelligenceSummary = companyIntelligence.length() > 200 
                    ? companyIntelligence.substring(0, 200) + '...' 
                    : companyIntelligence;
                result.queueInfo(runId, STAGE_NUMBER, 'Company Research: ' + intelligenceSummary);
            }
            
            // Log extracted profile
            if (String.isNotBlank(companyProfile)) {
                String profileSummary = companyProfile.length() > 150 
                    ? companyProfile.substring(0, 150) + '...' 
                    : companyProfile;
                result.queueInfo(runId, STAGE_NUMBER, 'Company Profile: ' + profileSummary);
            }
            
            // Log industry context
            if (String.isNotBlank(industryContext)) {
                String industrySummary = industryContext.length() > 150 
                    ? industryContext.substring(0, 150) + '...' 
                    : industryContext;
                result.queueInfo(runId, STAGE_NUMBER, 'Industry Context: ' + industrySummary);
            }
            
            // Log strategic insights
            if (String.isNotBlank(insightsStr)) {
                result.queueInfo(runId, STAGE_NUMBER, 'Strategic Insights: ' + insightsStr);
            }
            
            // Log target persona
            result.queueInfo(runId, STAGE_NUMBER, 'Target Persona: ' + targetPersona);

            // Pass through inputs
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            result.outputs.put('outputFormat', outputFormat);
            result.outputs.put('companyWebsite', companyWebsite);

            result.markCompleted();
            result.queueInfo(runId, STAGE_NUMBER, 'Strategic profiling completed successfully');

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
        
        String researchPrompt = 'You are a senior industry analyst, enterprise sales strategist, and customer support domain expert.\n\n' +
            'Your task is to create a **rich, reusable industry and company profile** for the organization represented by the following website:\n\n' +
            '**' + companyWebsite + '** (' + companyName + ')\n\n' +
            'The website is provided **only to uniquely identify the company**.\n' +
            'You may and should use **broader public knowledge, industry norms, and reasonable inference** to enrich your analysis. ' +
            'Clearly distinguish factual information from informed inference when appropriate.\n\n' +
            'The output will be used as **upstream context** for:\n' +
            '* Account 360 summaries\n' +
            '* Deal coaching and opportunity analysis\n' +
            '* Customer sentiment analysis\n' +
            '* Sales, support, and operations enablement\n\n' +
            'Prioritize **accuracy, industry-native language, and go-to-market realism**. Avoid generic descriptions.\n\n' +
            '--- YOUR OUTPUT MUST COVER THESE 10 SECTIONS ---\n\n' +
            '## 1. Industry Context\n' +
            '* Primary industry and sub-industries\n' +
            '* Regulatory environment and constraints (if applicable)\n' +
            '* Industry dynamics that materially affect sales, support, and customer relationships\n' +
            '* Common pressures, risks, and priorities in this industry\n\n' +
            '## 2. Company Overview & Business Model\n' +
            '* What type of company this is and how it operates\n' +
            '* Core value propositions\n' +
            '* How the company generates revenue\n' +
            '* How trust, risk, or compliance factor into the business (if relevant)\n\n' +
            '## 3. Lines of Business & Offerings\n' +
            '* Major lines of business or divisions\n' +
            '* Key products and services per line\n' +
            '* Differences across consumer, commercial, and enterprise offerings (if applicable)\n' +
            '* Which offerings are relationship-driven vs. transactional\n\n' +
            '## 4. Customers & Segmentation\n' +
            '* Who the company sells to\n' +
            '* B2B, B2C, B2B2C, or hybrid (explain)\n' +
            '* Primary customer segments and personas\n' +
            '* How customers are grouped internally (e.g., retail, SMB, enterprise, institutional)\n\n' +
            '## 5. Go-To-Market & Sales Motion\n' +
            '* How the company sells (Direct, Digital, Field, Partners/Channels)\n' +
            '* Typical sales motion by segment (simple vs. consultative vs. long-cycle)\n' +
            '* Role of relationships vs. automation\n\n' +
            '## 6. Customer-Facing Roles & Terminology\n' +
            '* What the company calls Customers (e.g., clients, members, policyholders)\n' +
            '* What the company calls Sales roles (e.g., relationship managers, account executives)\n' +
            '* Differences in terminology by segment\n\n' +
            '## 7. Organizational Model (High-Level)\n' +
            '* How the organization is structured (product, segment, geo)\n' +
            '* Separation or integration between sales, service, and operations\n\n' +
            '## 8. Industry-Specific Language & Parlance\n' +
            '* Common terms and phrases used in this industry\n' +
            '* Concepts that are core to how this company thinks and communicates\n' +
            '* Words that should be used—or avoided—when engaging this company\n\n' +
            '## 9. Buying & Support Dynamics\n' +
            '* Likely buyer roles and influencers\n' +
            '* What matters most in purchasing and renewal decisions\n' +
            '* Common customer concerns, objections, or support needs\n\n' +
            '## 10. Enablement & Prompting Guidance\n' +
            '* How downstream AI systems should speak to this company\n' +
            '* Guidance for generating Account 360s and Executive Summaries\n\n' +
            '--- OUTPUT REQUIREMENTS ---\n' +
            '* Structured, scannable, and reusable\n' +
            '* Bullet points preferred\n' +
            '* Return ONLY the profile as plain text (markdown allowed).';

        result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for company research: ' + companyName);

        // Use lower temperature for more factual recall
        AIServiceClient.AIResponse researchResponse = AIServiceClient.callAI(null, researchPrompt, 2048, 0.3);

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
        
        prompt += 'CRITICAL RULE: DO NOT SUMMARIZE INTO GENERIC TEXT.\n';
        prompt += 'If the Company Intelligence above identifies a specific company (e.g., Wells Fargo), you MUST use that specific name and industry details in your output.\n';
        prompt += 'Never write "The company operates in a customer-focused industry".\n';
        prompt += 'Instead write "Wells Fargo operates in Retail Banking and Commercial Lending".\n\n';
        
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
        
        prompt += '5. COMPANY PROFILE:\n';
        prompt += '   - STRICT REQUIREMENT: Copy the specific industry and product details from the Company Intelligence above.\n';
        prompt += '   - Do NOT generalize. If it says "Medicare Advantage", use that exact term.\n';
        prompt += '   - Name the specific industry (e.g., "Health Insurance", "Retail Banking").\n\n';
        
        prompt += '6. INDUSTRY CONTEXT:\n';
        prompt += '   - STRICT REQUIREMENT: Use specific terminology (e.g., "claims", "underwriting", "deposits", "supply chain").\n';
        prompt += '   - Avoid generic terms like "customer engagement" if a more specific term exists (e.g., "patient enrollment").\n\n';
        
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