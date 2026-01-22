// Test the EXACT Stage02 prompt to reproduce the error

String businessContext = 'This prompt reviews the opportunity and the related activities on it and comes back with guidance on how can the sales rep improve the chances of closing this deal. It has to act like a coach and review the deal in terms of the business process around it and sales best practices.';
String rootObject = 'Opportunity';
String outputFormat = 'Report';
String companyIntelligence = ''; // Empty, same as failed run

// Build EXACT prompt from Stage02
String prompt = buildExactStage02Prompt(businessContext, rootObject, outputFormat, companyIntelligence);

System.debug('=== CALLING AI WITH EXACT STAGE02 PROMPT ===');
System.debug('Prompt length: ' + prompt.length() + ' chars');

// Call AI 3 times to see if it's intermittent
for (Integer i = 1; i <= 3; i++) {
    System.debug('');
    System.debug('=== ATTEMPT ' + i + ' ===');
    
    try {
        AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 4096, 0.7);
        
        System.debug('Success: ' + aiResponse.success);
        
        if (aiResponse.success && aiResponse.content != null) {
            String cleanJson = aiResponse.content.trim();
            
            System.debug('Response length: ' + aiResponse.content.length());
            System.debug('First 100 chars: ' + cleanJson.substring(0, Math.min(100, cleanJson.length())));
            
            // Try to parse like Stage02 does
            if (cleanJson.startsWith('```json')) {
                cleanJson = cleanJson.substringAfter('```json').substringBefore('```').trim();
            } else if (cleanJson.startsWith('```')) {
                cleanJson = cleanJson.substringAfter('```').substringBefore('```').trim();
            }
            
            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);
                System.debug('✅ JSON PARSED - Keys: ' + parsed.keySet());
            } catch (JSONException e) {
                System.debug('❌ JSON PARSE FAILED');
                System.debug('Error: ' + e.getMessage());
                System.debug('First char code: ' + ((Integer) cleanJson.charAt(0)));
                System.debug('Cleaned JSON (first 200): ' + cleanJson.substring(0, Math.min(200, cleanJson.length())));
            }
        } else {
            System.debug('❌ AI Call Failed: ' + aiResponse.errorMessage);
        }
        
    } catch (Exception e) {
        System.debug('❌ EXCEPTION: ' + e.getMessage());
    }
    
    // Small delay between attempts
    if (i < 3) {
        System.debug('Waiting before next attempt...');
    }
}

// EXACT copy of Stage02 buildEnhancedProfilingPrompt method
private static String buildExactStage02Prompt(String businessContext, String rootObject, 
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
