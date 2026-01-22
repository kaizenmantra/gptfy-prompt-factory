// Diagnose Stage 2 AI response issue
// This script will call the AI with the same prompt and show exactly what's coming back

String businessContext = 'This prompt reviews the opportunity and the related activities on it and comes back with guidance on how can the sales rep improve the chances of closing this deal. It has to act like a coach and review the deal in terms of the business process around it and sales best practices.';
String rootObject = 'Opportunity';
String outputFormat = 'Report';
String companyIntelligence = ''; // Empty since company website is blank

// Build the exact prompt Stage 2 uses
String prompt = buildProfilingPrompt(businessContext, rootObject, outputFormat, companyIntelligence);

System.debug('=== PROMPT SENT TO AI ===');
System.debug(prompt);
System.debug('');
System.debug('=== CALLING AI ===');

// Call AI with same parameters as Stage 2
AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 4096, 0.7);

System.debug('AI Success: ' + aiResponse.success);
System.debug('AI Response Length: ' + (aiResponse.content != null ? aiResponse.content.length() : 0));
System.debug('');
System.debug('=== RAW AI RESPONSE (First 500 chars) ===');
if (aiResponse.content != null) {
    System.debug(aiResponse.content.substring(0, Math.min(500, aiResponse.content.length())));
} else {
    System.debug('NULL CONTENT');
}
System.debug('');
System.debug('=== CHECKING FOR JSON ===');

if (aiResponse.content != null) {
    String cleanJson = aiResponse.content.trim();
    System.debug('Starts with ```json? ' + cleanJson.startsWith('```json'));
    System.debug('Starts with ```? ' + cleanJson.startsWith('```'));
    System.debug('Starts with {? ' + cleanJson.startsWith('{'));
    System.debug('First 50 chars: ' + cleanJson.substring(0, Math.min(50, cleanJson.length())));
    
    // Try to parse
    try {
        if (cleanJson.startsWith('```json')) {
            cleanJson = cleanJson.substringAfter('```json').substringBefore('```').trim();
        } else if (cleanJson.startsWith('```')) {
            cleanJson = cleanJson.substringAfter('```').substringBefore('```').trim();
        }
        
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);
        System.debug('✅ JSON PARSED SUCCESSFULLY');
        System.debug('Keys: ' + parsed.keySet());
    } catch (Exception e) {
        System.debug('❌ JSON PARSE FAILED');
        System.debug('Error: ' + e.getMessage());
        System.debug('Clean JSON (first 200 chars): ' + cleanJson.substring(0, Math.min(200, cleanJson.length())));
    }
}

// Helper method (copied from Stage02)
private static String buildProfilingPrompt(String businessContext, String rootObject, String outputFormat, String companyIntelligence) {
    String prompt = 'You are a strategic business analyst. Based on the following business context, extract:\n\n';
    prompt += '1. The target persona (who will use this)\n';
    prompt += '2. The primary business objectives (what they want to achieve)\n\n';
    
    if (String.isNotBlank(companyIntelligence)) {
        prompt += 'COMPANY CONTEXT:\n' + companyIntelligence + '\n\n';
    }
    
    prompt += 'BUSINESS CONTEXT:\n' + businessContext + '\n\n';
    prompt += 'ROOT OBJECT: ' + rootObject + '\n';
    prompt += 'OUTPUT FORMAT: ' + outputFormat + '\n\n';
    prompt += 'Respond ONLY with a JSON object in this format:\n';
    prompt += '{\n';
    prompt += '  "targetPersona": "string",\n';
    prompt += '  "businessObjectives": ["string", "string"],\n';
    prompt += '  "companyProfile": "string (optional)",\n';
    prompt += '  "industryContext": "string (optional)",\n';
    prompt += '  "strategicInsights": ["string", "string"] (optional)\n';
    prompt += '}';
    
    return prompt;
}
