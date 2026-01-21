/**
 * @description Stage 7: Template Design
 * Calls Claude AI to generate HTML template using inline styles (GPTfy compatible),
 * validates HTML safety (no script tags), and returns template string.
 * Uses UI patterns and styles from PF_UIPatterns static resource.
 */
public with sharing class Stage07_TemplateDesign implements IStage {

    private static final Integer STAGE_NUMBER = 7;

    // Cached UI patterns and styles
    private Map<String, Object> uiPatterns;
    private Map<String, Object> commonStyles;
    private Map<String, Object> colorSchemes;

    // Field whitelist for merge field validation
    private Set<String> fieldWhitelist;

    /**
     * @description Executes Stage 7: Template Design
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing selected fields and business context from previous stages
     * @return StageResult with HTML template in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 7: Template Design');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            // Use deferred logging (no DML) - logs will be inserted AFTER callout completes
            result.queueInfo(runId, STAGE_NUMBER, 'Starting template design');

            // Load UI patterns and styles from static resource
            loadUIPatterns();
            result.queueInfo(runId, STAGE_NUMBER, 'Loaded UI patterns from static resource');

            // Extract inputs
            Map<String, Object> selectedFieldsRaw = (Map<String, Object>) inputs.get('selectedFields');
            if (selectedFieldsRaw == null || selectedFieldsRaw.isEmpty()) {
                throw new StageException('No selected fields provided for template design');
            }

            String rootObject = (String) inputs.get('rootObject');
            String businessContext = (String) inputs.get('businessContext');
            String targetPersona = (String) inputs.get('targetPersona');
            String outputFormat = (String) inputs.get('outputFormat');
            
            // NEW: Extract enriched context from Stage 2 for higher quality output
            String companyIntelligence = (String) inputs.get('companyIntelligence');
            String industryContext = (String) inputs.get('industryContext');
            String companyProfile = (String) inputs.get('companyProfile');
            List<Object> strategicInsightsRaw = (List<Object>) inputs.get('strategicInsights');
            List<String> strategicInsights = new List<String>();
            if (strategicInsightsRaw != null) {
                for (Object insight : strategicInsightsRaw) {
                    strategicInsights.add(String.valueOf(insight));
                }
            }

            // CRITICAL: Build field whitelist BEFORE calling Claude
            // This mirrors the shell script approach: Stage 7.1 builds whitelist first
            fieldWhitelist = buildFieldWhitelist(selectedFieldsRaw, rootObject);
            result.queueInfo(runId, STAGE_NUMBER,
                'Built field whitelist with ' + fieldWhitelist.size() + ' allowed fields');
            result.queueDebug(runId, STAGE_NUMBER, 'Whitelist: ' + String.join(new List<String>(fieldWhitelist), ', '));

            result.queueInfo(runId, STAGE_NUMBER, 'Generating HTML template for ' + rootObject);

            // Call Claude AI to generate template with enriched context
            String htmlTemplate = generateTemplateWithAIDeferred(
                selectedFieldsRaw, rootObject, businessContext, targetPersona, outputFormat,
                companyIntelligence, industryContext, strategicInsights, runId, result);

            // Validate HTML safety
            List<String> safetyIssues = validateHTMLSafety(htmlTemplate);

            if (!safetyIssues.isEmpty()) {
                result.queueError(runId, STAGE_NUMBER,
                    'HTML safety issues detected: ' + String.join(safetyIssues, ', '));

                // Attempt to sanitize
                htmlTemplate = sanitizeHTML(htmlTemplate);
                result.queueInfo(runId, STAGE_NUMBER, 'HTML template sanitized');
            }

            // Extract merge fields from template
            List<MergeFieldValidator.MergeField> mergeFields =
                MergeFieldValidator.extractMergeFields(htmlTemplate);

            result.queueInfo(runId, STAGE_NUMBER,
                'Template contains ' + mergeFields.size() + ' merge fields');

            // CRITICAL: Validate merge fields against whitelist BEFORE passing to Stage 8
            // This catches any fields Claude hallucinated that aren't in the selected fields
            // Mirrors shell script Stage 7.4 exact-match whitelist validation
            List<String> invalidFields = validateMergeFieldsAgainstWhitelist(mergeFields, rootObject);

            if (!invalidFields.isEmpty()) {
                result.queueError(runId, STAGE_NUMBER,
                    'Template contains ' + invalidFields.size() + ' fields NOT in whitelist: ' +
                    String.join(invalidFields, ', '));

                // STAGE 7.4b: Attempt to regenerate template with explicit feedback about invalid fields
                // This mirrors the shell script's retry behavior
                result.queueInfo(runId, STAGE_NUMBER, 'Attempting template regeneration without invalid fields (Stage 7.4b)...');

                String regenTemplate = regenerateTemplateWithoutInvalidFields(
                    selectedFieldsRaw, rootObject, businessContext, targetPersona,
                    outputFormat, invalidFields, runId, result);

                if (regenTemplate != null) {
                    // Re-validate regenerated template
                    htmlTemplate = regenTemplate;
                    mergeFields = MergeFieldValidator.extractMergeFields(htmlTemplate);
                    invalidFields = validateMergeFieldsAgainstWhitelist(mergeFields, rootObject);

                    if (!invalidFields.isEmpty()) {
                        // Regenerated template still has invalid fields - fail
                        result.queueError(runId, STAGE_NUMBER,
                            'Regenerated template still has invalid fields: ' + String.join(invalidFields, ', '));
                        throw new StageException(
                            'Template regeneration failed: still contains ' + invalidFields.size() +
                            ' invalid merge field(s): ' + String.join(invalidFields, ', ') +
                            '. Cannot proceed with template that uses non-whitelisted fields.');
                    } else {
                        result.queueInfo(runId, STAGE_NUMBER,
                            'Regenerated template passes whitelist validation');
                    }
                } else {
                    // Regeneration failed
                    throw new StageException(
                        'Template validation failed: ' + invalidFields.size() +
                        ' merge field(s) not in whitelist. Invalid fields: ' + String.join(invalidFields, ', ') +
                        '. Regeneration attempt also failed.');
                }
            }
            result.queueInfo(runId, STAGE_NUMBER, 'All merge fields validated against whitelist');

            // Build template summary
            String templateSummary = buildTemplateSummary(htmlTemplate, mergeFields);

            // Build outputs
            result.outputs.put('htmlTemplate', htmlTemplate);
            result.outputs.put('mergeFields', mergeFields);
            result.outputs.put('mergeFieldCount', mergeFields.size());
            result.outputs.put('templateSummary', templateSummary);
            result.outputs.put('safetyIssues', safetyIssues);

            // Pass through critical inputs (avoid large data to prevent serialization issues)
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('targetPersona', targetPersona);
            result.outputs.put('businessObjectives', inputs.get('businessObjectives'));
            // recordData omitted - causes stack overflow during serialization
            result.outputs.put('objectsWithData', inputs.get('objectsWithData'));
            result.outputs.put('selectedFields', selectedFieldsRaw);
            result.outputs.put('outputFormat', outputFormat);
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            // Pass through selectedGrandchildren for DCM creation in Stage 8/9
            result.outputs.put('selectedGrandchildren', inputs.get('selectedGrandchildren'));
            // Pass through selectedObjects - needed for DCM creation even if objects have no data
            result.outputs.put('selectedObjects', inputs.get('selectedObjects'));

            result.markCompleted();
            result.queueInfo(runId, STAGE_NUMBER, 'Template design completed successfully');

        } catch (Exception e) {
            String errorMsg = 'Failed to complete template design: ' + e.getMessage();
            result.markFailed(errorMsg);
            result.queueError(runId, STAGE_NUMBER, 'Stage execution failed: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Calls Claude AI to generate HTML template with merge fields (deferred logging)
     * Enhanced to include company intelligence and strategic insights for higher quality output
     * @param selectedFieldsRaw Map of object to field list
     * @param rootObject The root Salesforce object
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @param outputFormat Desired output format
     * @param companyIntelligence AI-researched company information
     * @param industryContext Industry-specific context and terminology
     * @param strategicInsights List of strategic insights from profiling
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return Generated HTML template string
     */
    private String generateTemplateWithAIDeferred(
            Map<String, Object> selectedFieldsRaw,
            String rootObject,
            String businessContext,
            String targetPersona,
            String outputFormat,
            String companyIntelligence,
            String industryContext,
            List<String> strategicInsights,
            Id runId,
            StageResult result) {

        // Build prompt for template generation with enriched context
        String prompt = buildTemplatePrompt(selectedFieldsRaw, rootObject,
                                           businessContext, targetPersona, outputFormat,
                                           companyIntelligence, industryContext, strategicInsights);

        result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for template generation');

        // Call AI (HTTP callout - no DML before this!)
        AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 8192, 0.7);

        if (!aiResponse.success) {
            throw new StageException('AI call failed: ' + aiResponse.errorMessage);
        }

        result.queueInfo(runId, STAGE_NUMBER,
            'Claude AI response received (Tokens: ' + aiResponse.inputTokens + '/' +
            aiResponse.outputTokens + ')');

        // Parse and extract HTML from response
        String htmlTemplate = extractHTMLFromResponse(aiResponse.content);

        return htmlTemplate;
    }

    /**
     * @description Regenerates the template after validation found invalid fields
     * Mirrors shell script Stage 7.4b: retry with explicit "invalid fields you used" feedback
     *
     * @param selectedFieldsRaw Map of object to field list
     * @param rootObject The root Salesforce object
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @param outputFormat Desired output format
     * @param invalidFields List of invalid field references found in first attempt
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return Regenerated HTML template, or null if regeneration failed
     */
    private String regenerateTemplateWithoutInvalidFields(
            Map<String, Object> selectedFieldsRaw,
            String rootObject,
            String businessContext,
            String targetPersona,
            String outputFormat,
            List<String> invalidFields,
            Id runId,
            StageResult result) {

        try {
            // Build regeneration prompt with explicit feedback about invalid fields
            // This mirrors shell script Stage 7.4b exactly
            String prompt = 'CRITICAL ERROR: Your previous template used merge fields NOT in the whitelist.\n\n';

            prompt += '=== INVALID FIELDS YOU USED (THESE DO NOT EXIST) ===\n';
            for (String invalidField : invalidFields) {
                prompt += '- ' + invalidField + '\n';
            }
            prompt += '\n=== ALLOWED MERGE FIELDS (USE ONLY THESE) ===\n';
            if (fieldWhitelist != null) {
                for (String whitelistField : fieldWhitelist) {
                    prompt += '- {{{' + whitelistField + '}}}\n';
                }
            }
            prompt += '=== END WHITELIST ===\n\n';

            prompt += 'INSTRUCTIONS:\n';
            prompt += '1. Regenerate the HTML template using ONLY fields from the whitelist above\n';
            prompt += '2. Copy the merge field syntax EXACTLY as shown\n';
            prompt += '3. If you need a field that is NOT in the whitelist, REMOVE that section entirely\n';
            prompt += '4. DO NOT try to use alternative field names - they do not exist\n\n';

            prompt += 'Remember: SINGLE LINE HTML, inline styles only, no CSS classes, NO EMOJIS.\n\n';

            prompt += 'BUSINESS CONTEXT:\n' + businessContext + '\n\n';
            prompt += 'TARGET PERSONA: ' + targetPersona + '\n';
            prompt += 'ROOT OBJECT: ' + rootObject + '\n';
            prompt += 'OUTPUT FORMAT: ' + (outputFormat != null ? outputFormat : 'HTML') + '\n\n';

            prompt += 'Output ONLY raw HTML starting with <div - no markdown, no backticks, no explanation:';

            result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for template regeneration (Stage 7.4b)');

            // Use lower temperature for more deterministic regeneration
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 8192, 0.5);

            if (!aiResponse.success) {
                result.queueError(runId, STAGE_NUMBER, 'Regeneration failed: ' + aiResponse.errorMessage);
                return null;
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Regeneration response received (Tokens: ' + aiResponse.inputTokens + '/' +
                aiResponse.outputTokens + ')');

            // Parse and extract HTML from response
            String regenTemplate = extractHTMLFromResponse(aiResponse.content);
            result.queueInfo(runId, STAGE_NUMBER,
                'Regenerated template: ' + (regenTemplate != null ? regenTemplate.length() : 0) + ' chars');

            return regenTemplate;

        } catch (Exception e) {
            result.queueError(runId, STAGE_NUMBER, 'Regeneration exception: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Builds the prompt for Claude AI to generate HTML template
     * ENHANCED: Now includes content quality requirements for AI-powered insights
     * @param selectedFieldsRaw Map of object to field list
     * @param rootObject The root Salesforce object
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @param outputFormat Desired output format
     * @param companyIntelligence AI-researched company information
     * @param industryContext Industry-specific context and terminology
     * @param strategicInsights List of strategic insights from profiling
     * @return Formatted prompt string
     */
    private String buildTemplatePrompt(
            Map<String, Object> selectedFieldsRaw,
            String rootObject,
            String businessContext,
            String targetPersona,
            String outputFormat,
            String companyIntelligence,
            String industryContext,
            List<String> strategicInsights) {

        String prompt = 'You are an expert AI content designer creating INTELLIGENT, ANALYTICAL output for GPTfy Salesforce integration.\n\n';
        
        prompt += '=== CRITICAL: THIS IS NOT A DATA REPORT ===\n';
        prompt += 'You are NOT just displaying Salesforce data. You are creating AI-POWERED INSIGHTS.\n';
        prompt += 'The AI model running this prompt will ANALYZE the data and provide INTELLIGENT INTERPRETATION.\n';
        prompt += 'Your template must INSTRUCT the AI on HOW to analyze, not just WHAT to display.\n\n';
        
        prompt += 'BUSINESS CONTEXT:\n' + businessContext + '\n\n';
        prompt += 'TARGET PERSONA: ' + targetPersona + '\n';
        prompt += 'ROOT OBJECT: ' + rootObject + '\n';
        prompt += 'OUTPUT FORMAT: ' + (outputFormat != null ? outputFormat : 'HTML') + '\n\n';
        
        // Add company intelligence if available
        if (String.isNotBlank(companyIntelligence)) {
            prompt += '=== COMPANY INTELLIGENCE (Incorporate this context) ===\n';
            prompt += companyIntelligence + '\n\n';
        }
        
        // Add industry context if available
        if (String.isNotBlank(industryContext)) {
            prompt += '=== INDUSTRY CONTEXT ===\n';
            prompt += industryContext + '\n\n';
        }
        
        // Add strategic insights if available
        if (strategicInsights != null && !strategicInsights.isEmpty()) {
            prompt += '=== STRATEGIC INSIGHTS TO INCORPORATE ===\n';
            for (String insight : strategicInsights) {
                prompt += '- ' + insight + '\n';
            }
            prompt += '\n';
        }
        
        prompt += '=== CONTENT QUALITY REQUIREMENTS (CRITICAL) ===\n\n';
        
        prompt += '1. ACTIONABLE INSIGHTS - Not just data display:\n';
        prompt += '   - Tell the user what to DO, not just what IS\n';
        prompt += '   - Include recommendations like "Consider following up..." or "This pattern suggests..."\n';
        prompt += '   - Highlight what needs attention and why\n';
        prompt += '   - Provide next best actions based on the data\n\n';
        
        prompt += '2. CONTEXTUAL ANALYSIS - Interpret the data:\n';
        prompt += '   - For dates: Calculate and show relative time (e.g., "Open for 45 days - getting stale")\n';
        prompt += '   - For amounts: Show trends and comparisons (e.g., "Above average deal size")\n';
        prompt += '   - For status fields: Indicate health (e.g., "3 open cases - elevated support activity")\n';
        prompt += '   - For activities: Analyze patterns (e.g., "Last contact 30 days ago - re-engage needed")\n\n';
        
        prompt += '3. BUSINESS VALUE - Answer "so what?":\n';
        prompt += '   - Connect data points to business outcomes\n';
        prompt += '   - Highlight risks and opportunities\n';
        prompt += '   - Provide scoring or health indicators where appropriate\n';
        prompt += '   - Make the output actionable for ' + targetPersona + '\n\n';
        
        prompt += '4. INDUSTRY/COMPANY CONTEXT:\n';
        prompt += '   - Use terminology relevant to the company/industry\n';
        prompt += '   - Reference the company\'s products, services, or business model if known\n';
        prompt += '   - Tailor recommendations to the specific business context\n\n';
        
        prompt += '5. ANALYTICAL DEPTH:\n';
        prompt += '   - Go beyond surface-level data display\n';
        prompt += '   - Include trend analysis where data supports it\n';
        prompt += '   - Identify patterns across related records\n';
        prompt += '   - Provide risk assessments and priority indicators\n\n';
        
        prompt += '=== EXAMPLE OF GOOD vs BAD CONTENT ===\n\n';
        prompt += 'BAD (just data display):\n';
        prompt += '  "Cases: 5 open, 12 closed"\n\n';
        prompt += 'GOOD (intelligent analysis):\n';
        prompt += '  "Support Activity: 5 open cases (2 high priority, oldest open 45 days - escalation risk). ';
        prompt += 'Consider prioritizing the aging tickets to maintain customer satisfaction."\n\n';
        
        prompt += 'BAD (just data display):\n';
        prompt += '  "Last Activity: 2024-01-15"\n\n';
        prompt += 'GOOD (contextual insight):\n';
        prompt += '  "Engagement Status: No contact in 30 days. This account may be going cold - ';
        prompt += 'schedule a check-in call to maintain relationship."\n\n';

        prompt += '=== STRICT FIELD WHITELIST ===\n';
        prompt += 'You MUST ONLY use fields from this whitelist. Any other fields will cause a validation failure.\n\n';

        prompt += 'AVAILABLE FIELDS BY OBJECT:\n';
        for (String objectName : selectedFieldsRaw.keySet()) {
            prompt += '\nObject: ' + objectName + '\n';
            List<Object> fieldsRaw = (List<Object>) selectedFieldsRaw.get(objectName);
            for (Object field : fieldsRaw) {
                prompt += '- ' + String.valueOf(field) + '\n';
            }
        }

        // Include the actual whitelist for clarity
        prompt += '\nCOMPLETE FIELD WHITELIST (only these are allowed):\n';
        if (fieldWhitelist != null) {
            for (String whitelistField : fieldWhitelist) {
                prompt += '- ' + whitelistField + '\n';
            }
        }

        prompt += '\n=== CRITICAL CONSTRAINT - OBJECTS AND FIELDS ===\n';
        prompt += 'DO NOT invent or hallucinate any field names OR object names.\n';
        prompt += 'Use ONLY the fields listed above. If an object is not listed, DO NOT reference it.\n';
        prompt += 'FORBIDDEN: Do NOT use objects like Contact, Opportunity, Case, Task, or any other objects\n';
        prompt += 'unless they appear in the "AVAILABLE FIELDS BY OBJECT" section above.\n';
        prompt += 'If you use a field or object not in the whitelist, the template will FAIL validation.\n\n';

        prompt += 'TASK:\n';
        prompt += 'Generate a professional HTML template using ONLY the fields from the whitelist above.\n\n';

        prompt += 'CRITICAL REQUIREMENTS (GPTfy Compatibility):\n';
        prompt += '1. The ENTIRE template MUST be on a SINGLE LINE - no line breaks or newlines\n';
        prompt += '2. Use ONLY inline styles (style="...") - NO CSS classes allowed\n';
        prompt += '3. NO <style> blocks or external stylesheets\n';
        prompt += '4. NO <script> tags, inline JavaScript, or event handlers\n';
        prompt += '5. Must start with <div style=" and end with </div>\n';
        prompt += '6. Maximum length: 131072 characters\n';
        prompt += '7. NO EMOJIS - Do NOT use any emoji characters. Professional enterprise content must not contain emojis.\n';
        prompt += '8. NO markdown code blocks or backticks - output raw HTML only\n';
        prompt += '9. NO placeholders, TBD, TODO, or [X] markers\n';
        prompt += '10. NO null or undefined values - use proper empty states instead\n\n';

        prompt += 'MERGE FIELD SYNTAX (Mustache-style with triple braces):\n';
        prompt += '- Primary object fields: {{{FieldName}}} (e.g., {{{Name}}}, {{{Industry}}})\n';
        prompt += '- Lookup/relationship fields: {{{Relationship.FieldName}}} (e.g., {{{Owner.Name}}})\n';
        prompt += '- Child collection iteration: {{#ChildCollection}}...{{/ChildCollection}}\n';
        prompt += '- Fields within iteration: {{{FieldName}}} (no prefix needed inside iteration)\n';
        prompt += '- Empty collection check: {{^ChildCollection}}No items{{/ChildCollection}}\n\n';

        prompt += 'FORBIDDEN PATTERNS - Do NOT use:\n';
        prompt += '- {{{Object.Field}}} for primary object (use {{{Field}}} only)\n';
        prompt += '- Double braces {{Field}} for values (always use triple {{{Field}}})\n';
        prompt += '- Any CSS class="..." attributes\n';
        prompt += '- Any placeholder text like [INSERT], TODO, TBD\n\n';

        // Add color scheme from static resource
        prompt += 'COLOR SCHEME TO USE:\n';
        prompt += getColorSchemePrompt() + '\n';

        // Add style examples from static resource
        prompt += 'STYLE PATTERNS TO USE:\n';
        prompt += getStylePatternsPrompt() + '\n';

        // Add pattern-specific guidance if available
        // CRITICAL: Only include guidance for objects that are actually in selectedFieldsRaw
        // This prevents Claude from hallucinating fields for objects not in the DCM
        String patternGuidance = getPatternGuidance(rootObject, selectedFieldsRaw);
        if (String.isNotBlank(patternGuidance)) {
            prompt += 'LAYOUT PATTERN FOR ' + rootObject.toUpperCase() + ':\n';
            prompt += patternGuidance + '\n';
        }

        prompt += 'EXAMPLE OF VALID GPTfy TEMPLATE (single line, inline styles, Salesforce brand):\n';
        prompt += '<div style="font-family:\'Salesforce Sans\',-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,Arial,sans-serif;max-width:100%;background:#F3F3F3;color:#181818;font-size:14px;line-height:1.5;padding:16px;"><div style="background:linear-gradient(135deg,#0176D3,#014486);color:white;padding:20px;border-radius:8px 8px 0 0;"><h1 style="margin:0 0 4px 0;font-size:20px;font-weight:600;">{{{Name}}}</h1><p style="margin:0;font-size:12px;opacity:0.9;">{{{Industry}}} | {{{Type}}}</p></div><div style="display:flex;gap:16px;justify-content:space-around;flex-wrap:wrap;background:white;padding:16px;border-radius:0 0 8px 8px;margin-bottom:12px;"><div style="text-align:center;min-width:80px;"><div style="font-size:28px;font-weight:700;line-height:1.2;color:#2E844A;">{{{AnnualRevenue}}}</div><div style="font-size:11px;color:#706E6B;text-transform:uppercase;letter-spacing:0.5px;margin-top:4px;">Revenue</div></div><div style="text-align:center;min-width:80px;"><div style="font-size:28px;font-weight:700;line-height:1.2;color:#0176D3;">{{{NumberOfEmployees}}}</div><div style="font-size:11px;color:#706E6B;text-transform:uppercase;letter-spacing:0.5px;margin-top:4px;">Employees</div></div></div><div style="background:white;margin:12px 0;padding:16px;border-radius:8px;border:1px solid #DDDBDA;"><h2 style="font-size:14px;font-weight:600;color:#181818;margin:0 0 12px 0;padding-bottom:8px;border-bottom:1px solid #DDDBDA;">Contacts</h2><table style="width:100%;border-collapse:collapse;font-size:13px;">{{#Contacts}}<tr><td style="padding:10px 12px;border-bottom:1px solid #DDDBDA;vertical-align:top;"><strong>{{{Name}}}</strong></td><td style="padding:10px 12px;border-bottom:1px solid #DDDBDA;vertical-align:top;">{{{Title}}}</td><td style="padding:10px 12px;border-bottom:1px solid #DDDBDA;vertical-align:top;">{{{Email}}}</td></tr>{{/Contacts}}{{^Contacts}}<tr><td style="color:#A8A8A8;font-style:italic;text-align:center;padding:20px;" colspan="3">No contacts found</td></tr>{{/Contacts}}</table></div></div>\n\n';

        prompt += 'LAYOUT QUALITY REQUIREMENTS:\n';
        prompt += '=== CRITICAL - Full Width Usage ===\n';
        prompt += '1. All sections MUST use 100% width - NEVER leave 50% of the space empty\n';
        prompt += '2. For two-column content, use: display:grid;grid-template-columns:1fr 1fr; (NOT side-by-side divs)\n';
        prompt += '3. Tables MUST have width:100% to fill container\n';
        prompt += '4. Child record sections (Contacts, Cases, etc.) must fill the full width\n';
        prompt += '5. NO excessive whitespace - if a section has data, display it compactly\n\n';

        prompt += '=== Data-Driven Layout ===\n';
        prompt += '1. If child collection is EMPTY, show a single compact line: "No [items] found"\n';
        prompt += '2. Empty collections should NOT show empty tables with headers - just the empty message\n';
        prompt += '3. Use {{#Collection}}...{{/Collection}} for iteration and {{^Collection}}empty state{{/Collection}} for empty check\n';
        prompt += '4. Consolidate related info - Account Details and Description should be side-by-side in a grid\n\n';

        prompt += 'VISUAL QUALITY CHECKLIST:\n';
        prompt += '- Header: full-width gradient background (linear-gradient #0176D3 to #014486)\n';
        prompt += '- Stats strip: full-width flexbox with large numbers (28px) and uppercase labels (11px)\n';
        prompt += '- Info sections: USE 2-column grid (display:grid;grid-template-columns:1fr 1fr;gap:16px;)\n';
        prompt += '- Tables: full-width (width:100%) with styled headers and proper cell padding\n';
        prompt += '- Status badges: semantic colors (success=#2E844A, warning=#DD7A01, error=#BA0517)\n';
        prompt += '- Empty states: single italic line, no empty table structure\n';
        prompt += '- Typography: Salesforce Sans font family with proper hierarchy\n\n';

        prompt += 'Generate the complete single-line HTML template now. Output ONLY raw HTML starting with <div - no markdown, no backticks, no explanation:';

        return prompt;
    }

    // Context-aware validation maps - built alongside whitelist
    private Map<String, String> objectToRelationshipName = new Map<String, String>();
    private Map<String, Set<String>> objectToFields = new Map<String, Set<String>>();

    /**
     * @description Builds a STRICT whitelist of allowed merge fields from selected fields
     * CRITICAL: This mirrors the shell script's exact-match whitelist behavior (Stage 7.1)
     *
     * Key differences from previous "permissive" implementation:
     * 1. Uses ACTUAL relationship names from schema (not naive objectName + 's')
     * 2. Tracks which fields belong to which object for context-aware validation
     * 3. Validates loop tokens against real relationship names
     *
     * Format: "FieldName" for root object, "Object.Field" for children
     *
     * @param selectedFieldsRaw Map of object to field list
     * @param rootObject The root Salesforce object
     * @return Set of allowed field references
     */
    private Set<String> buildFieldWhitelist(Map<String, Object> selectedFieldsRaw, String rootObject) {
        Set<String> whitelist = new Set<String>();
        objectToRelationshipName = new Map<String, String>();
        objectToFields = new Map<String, Set<String>>();

        for (String objectName : selectedFieldsRaw.keySet()) {
            List<Object> fieldsRaw = (List<Object>) selectedFieldsRaw.get(objectName);
            Set<String> fieldSet = new Set<String>();

            for (Object fieldObj : fieldsRaw) {
                String fieldName = String.valueOf(fieldObj);
                fieldSet.add(fieldName);

                if (objectName == rootObject) {
                    // Root object fields: just the field name (no prefix)
                    whitelist.add(fieldName);
                } else {
                    // Child object fields: Object.Field format
                    whitelist.add(objectName + '.' + fieldName);
                }
            }

            objectToFields.put(objectName, fieldSet);

            // Get ACTUAL relationship name from schema (not naive pluralization)
            // This fixes: Opportunity -> Opportunities (not Opportunitys)
            if (objectName != rootObject) {
                String relationshipName = getRelationshipNameFromSchema(rootObject, objectName);
                if (String.isNotBlank(relationshipName)) {
                    objectToRelationshipName.put(objectName, relationshipName);
                    // Also map relationship name back to object for context validation
                    objectToRelationshipName.put(relationshipName, objectName);
                }
            }
        }

        // Add common system fields that are always available
        whitelist.add('Id');
        whitelist.add('Name');

        return whitelist;
    }

    /**
     * @description Gets the actual relationship name from Salesforce schema
     * This fixes the naive pluralization issue (e.g., Opportunity -> Opportunities, not Opportunitys)
     * @param parentObject The parent object API name
     * @param childObject The child object API name
     * @return The relationship name, or a fallback plural if not found
     */
    private String getRelationshipNameFromSchema(String parentObject, String childObject) {
        try {
            List<SchemaHelper.ChildRelationship> relationships = SchemaHelper.getChildRelationships(parentObject);
            for (SchemaHelper.ChildRelationship rel : relationships) {
                if (rel.childObject == childObject && rel.relationshipName != null) {
                    return rel.relationshipName;
                }
            }
        } catch (Exception e) {
            System.debug('Stage07: Could not get relationship name for ' + childObject + ': ' + e.getMessage());
        }

        // Fallback: use standard plural rules (but this should be rare with proper schema)
        if (childObject.endsWith('y') && !childObject.endsWith('ay') &&
            !childObject.endsWith('ey') && !childObject.endsWith('oy') && !childObject.endsWith('uy')) {
            return childObject.substring(0, childObject.length() - 1) + 'ies';
        } else if (childObject.endsWith('s') || childObject.endsWith('x') ||
                   childObject.endsWith('z') || childObject.endsWith('ch') || childObject.endsWith('sh')) {
            return childObject + 'es';
        }
        return childObject + 's';
    }

    /**
     * @description Validates extracted merge fields against the whitelist with STRICT context awareness
     * CRITICAL: This is the key fix - previous implementation was too permissive.
     *
     * Key changes from permissive implementation:
     * 1. Fields without prefix are ONLY valid if they exist on root object
     * 2. Fields inside iteration blocks must match the context (we track loop context)
     * 3. Does NOT accept "field exists anywhere" as valid
     *
     * @param mergeFields List of extracted merge fields from template
     * @param rootObject The root Salesforce object
     * @return List of invalid field references (empty if all valid)
     */
    private List<String> validateMergeFieldsAgainstWhitelist(
            List<MergeFieldValidator.MergeField> mergeFields,
            String rootObject) {

        List<String> invalidFields = new List<String>();

        // Get root object fields for strict validation
        Set<String> rootObjectFields = objectToFields.get(rootObject);
        if (rootObjectFields == null) {
            rootObjectFields = new Set<String>();
        }

        // CRITICAL: Build a context map of all fields (for iteration block validation)
        // But we use it carefully - only matching within known loop contexts
        Set<String> allChildFieldNames = new Set<String>();
        for (String objectName : objectToFields.keySet()) {
            if (objectName != rootObject) {
                allChildFieldNames.addAll(objectToFields.get(objectName));
            }
        }

        for (MergeFieldValidator.MergeField field : mergeFields) {
            String fieldRef;
            Boolean isValid = false;

            if (field.objectName == null) {
                // No object prefix - this should be a root object field OR inside an iteration block
                fieldRef = field.fieldName;

                // STRICT validation (unlike previous permissive approach):
                // 1. Check if it's directly on the root object whitelist
                if (fieldWhitelist.contains(fieldRef)) {
                    isValid = true;
                }
                // 2. Check if it's a common system field (Id, Name)
                else if (fieldRef == 'Id' || fieldRef == 'Name') {
                    isValid = true;
                }
                // 3. For fields that could be inside iteration blocks, we need to check
                //    if the field exists on ANY child object (GPTfy resolves these at runtime)
                //    But we log a warning since we can't verify the context statically
                else if (allChildFieldNames.contains(fieldRef)) {
                    // This is potentially valid if inside a {{#Collection}}...{{/Collection}} block
                    // We allow it but note that GPTfy will validate at runtime
                    isValid = true;
                    System.debug('Stage07: Field "' + fieldRef + '" appears to be inside iteration block - will be validated by GPTfy at runtime');
                }
            } else {
                // Has object prefix (Object.Field format)
                fieldRef = field.objectName + '.' + field.fieldName;

                // Check exact match in whitelist
                if (fieldWhitelist.contains(fieldRef)) {
                    isValid = true;
                }
                // Also check if object exists and field exists on that object
                else if (objectToFields.containsKey(field.objectName)) {
                    Set<String> objectFields = objectToFields.get(field.objectName);
                    if (objectFields.contains(field.fieldName)) {
                        isValid = true;
                    }
                }
            }

            if (!isValid) {
                invalidFields.add(fieldRef);
            }
        }

        return invalidFields;
    }

    /**
     * @description Loads UI patterns from static resource
     */
    private void loadUIPatterns() {
        uiPatterns = PromptFactoryRulesLoader.getUIPatterns();
        commonStyles = PromptFactoryRulesLoader.getCommonStyles();
        colorSchemes = PromptFactoryRulesLoader.getColorScheme('salesforce');
    }

    /**
     * @description Gets color scheme prompt section from static resource
     * @return Color scheme string for prompt
     */
    private String getColorSchemePrompt() {
        Map<String, Object> colorPalette = PromptFactoryRulesLoader.getColorPalette();

        if (colorPalette == null || colorPalette.isEmpty()) {
            return getSalesforceBrandColors();
        }

        String result = '';

        // Primary colors
        if (colorPalette.containsKey('primary')) {
            Map<String, Object> primary = (Map<String, Object>) colorPalette.get('primary');
            result += '### Primary Colors (Salesforce Brand)\n';
            result += '- Main Blue: ' + primary.get('main') + ' (headers, links, primary actions)\n';
            result += '- Dark Blue: ' + primary.get('dark') + ' (hover states, gradients)\n';
            result += '- Light Blue: ' + primary.get('light') + ' (highlights)\n\n';
        }

        // Semantic colors
        if (colorPalette.containsKey('semantic')) {
            Map<String, Object> semantic = (Map<String, Object>) colorPalette.get('semantic');
            result += '### Semantic Colors (Status Indicators)\n';
            result += '- Success: ' + semantic.get('success') + ' (positive, complete)\n';
            result += '- Success Background: ' + semantic.get('successBg') + '\n';
            result += '- Warning: ' + semantic.get('warning') + ' (caution, attention)\n';
            result += '- Warning Background: ' + semantic.get('warningBg') + '\n';
            result += '- Error: ' + semantic.get('error') + ' (critical, failed)\n';
            result += '- Error Background: ' + semantic.get('errorBg') + '\n';
            result += '- Info: ' + semantic.get('info') + '\n';
            result += '- Info Background: ' + semantic.get('infoBg') + '\n\n';
        }

        // Neutral colors
        if (colorPalette.containsKey('neutral')) {
            Map<String, Object> neutral = (Map<String, Object>) colorPalette.get('neutral');
            result += '### Neutral Colors\n';
            result += '- Text Primary: ' + neutral.get('textPrimary') + ' (main text)\n';
            result += '- Text Secondary: ' + neutral.get('textSecondary') + ' (labels, secondary)\n';
            result += '- Text Tertiary: ' + neutral.get('textTertiary') + ' (placeholder, disabled)\n';
            result += '- Background: ' + neutral.get('background') + ' (page background)\n';
            result += '- Background Alt: ' + neutral.get('backgroundAlt') + ' (cards, sections)\n';
            result += '- Border: ' + neutral.get('border') + ' (borders, dividers)\n\n';
        }

        return result;
    }

    /**
     * @description Returns default Salesforce brand colors
     */
    private String getSalesforceBrandColors() {
        return '### Primary Colors (Salesforce Brand)\n' +
               '- Main Blue: #0176D3 (headers, links, primary actions)\n' +
               '- Dark Blue: #014486 (hover states, gradients)\n' +
               '- Light Blue: #1B96FF (highlights)\n\n' +
               '### Semantic Colors\n' +
               '- Success: #2E844A, Background: #EAF5EC\n' +
               '- Warning: #DD7A01, Background: #FEF3E0\n' +
               '- Error: #BA0517, Background: #FDE8E8\n' +
               '- Info: #0176D3, Background: #EEF4FF\n\n' +
               '### Neutral Colors\n' +
               '- Text: #181818, Secondary: #706E6B, Tertiary: #A8A8A8\n' +
               '- Background: #F3F3F3, Cards: #FFFFFF, Border: #DDDBDA\n\n';
    }

    /**
     * @description Gets style patterns prompt section from static resource
     * Returns ready-to-use inline style strings
     * @return Style patterns string for prompt
     */
    private String getStylePatternsPrompt() {
        Map<String, Object> inlineStyles = PromptFactoryRulesLoader.getInlineStyles();

        if (inlineStyles == null || inlineStyles.isEmpty()) {
            return getDefaultInlineStyles();
        }

        String result = '### Ready-to-Use Inline Styles (copy these exactly)\n\n';

        // Core layout styles
        result += '#### Container & Layout\n';
        if (inlineStyles.containsKey('container')) {
            result += '- Container: style="' + inlineStyles.get('container') + '"\n';
        }
        if (inlineStyles.containsKey('header')) {
            result += '- Header: style="' + inlineStyles.get('header') + '"\n';
        }
        if (inlineStyles.containsKey('headerTitle')) {
            result += '- Header Title: style="' + inlineStyles.get('headerTitle') + '"\n';
        }
        if (inlineStyles.containsKey('section')) {
            result += '- Section: style="' + inlineStyles.get('section') + '"\n';
        }
        if (inlineStyles.containsKey('sectionTitle')) {
            result += '- Section Title: style="' + inlineStyles.get('sectionTitle') + '"\n';
        }

        // Stats
        result += '\n#### Statistics & Metrics\n';
        if (inlineStyles.containsKey('statsStrip')) {
            result += '- Stats Strip: style="' + inlineStyles.get('statsStrip') + '"\n';
        }
        if (inlineStyles.containsKey('statItem')) {
            result += '- Stat Item: style="' + inlineStyles.get('statItem') + '"\n';
        }
        if (inlineStyles.containsKey('statValue')) {
            result += '- Stat Value (neutral): style="' + inlineStyles.get('statValue') + '"\n';
        }
        if (inlineStyles.containsKey('statValuePositive')) {
            result += '- Stat Value (positive): style="' + inlineStyles.get('statValuePositive') + '"\n';
        }
        if (inlineStyles.containsKey('statValueWarning')) {
            result += '- Stat Value (warning): style="' + inlineStyles.get('statValueWarning') + '"\n';
        }
        if (inlineStyles.containsKey('statLabel')) {
            result += '- Stat Label: style="' + inlineStyles.get('statLabel') + '"\n';
        }

        // Cards
        result += '\n#### Cards (with status borders)\n';
        if (inlineStyles.containsKey('card')) {
            result += '- Card (neutral): style="' + inlineStyles.get('card') + '"\n';
        }
        if (inlineStyles.containsKey('cardSuccess')) {
            result += '- Card (success): style="' + inlineStyles.get('cardSuccess') + '"\n';
        }
        if (inlineStyles.containsKey('cardWarning')) {
            result += '- Card (warning): style="' + inlineStyles.get('cardWarning') + '"\n';
        }
        if (inlineStyles.containsKey('cardError')) {
            result += '- Card (error): style="' + inlineStyles.get('cardError') + '"\n';
        }
        if (inlineStyles.containsKey('cardInfo')) {
            result += '- Card (info): style="' + inlineStyles.get('cardInfo') + '"\n';
        }

        // Tables
        result += '\n#### Tables\n';
        if (inlineStyles.containsKey('table')) {
            result += '- Table: style="' + inlineStyles.get('table') + '"\n';
        }
        if (inlineStyles.containsKey('tableHeader')) {
            result += '- Table Header (th): style="' + inlineStyles.get('tableHeader') + '"\n';
        }
        if (inlineStyles.containsKey('tableCell')) {
            result += '- Table Cell (td): style="' + inlineStyles.get('tableCell') + '"\n';
        }

        // Badges
        result += '\n#### Badges (status indicators)\n';
        if (inlineStyles.containsKey('badgeSuccess')) {
            result += '- Badge (success): style="' + inlineStyles.get('badgeSuccess') + '"\n';
        }
        if (inlineStyles.containsKey('badgeWarning')) {
            result += '- Badge (warning): style="' + inlineStyles.get('badgeWarning') + '"\n';
        }
        if (inlineStyles.containsKey('badgeError')) {
            result += '- Badge (error): style="' + inlineStyles.get('badgeError') + '"\n';
        }
        if (inlineStyles.containsKey('badgeInfo')) {
            result += '- Badge (info): style="' + inlineStyles.get('badgeInfo') + '"\n';
        }
        if (inlineStyles.containsKey('badgeNeutral')) {
            result += '- Badge (neutral): style="' + inlineStyles.get('badgeNeutral') + '"\n';
        }

        // Alerts
        result += '\n#### Alerts/Banners\n';
        if (inlineStyles.containsKey('alertSuccess')) {
            result += '- Alert (success): style="' + inlineStyles.get('alertSuccess') + '"\n';
        }
        if (inlineStyles.containsKey('alertWarning')) {
            result += '- Alert (warning): style="' + inlineStyles.get('alertWarning') + '"\n';
        }
        if (inlineStyles.containsKey('alertError')) {
            result += '- Alert (error): style="' + inlineStyles.get('alertError') + '"\n';
        }
        if (inlineStyles.containsKey('alertInfo')) {
            result += '- Alert (info): style="' + inlineStyles.get('alertInfo') + '"\n';
        }

        // Utility
        result += '\n#### Utility Styles\n';
        if (inlineStyles.containsKey('textMuted')) {
            result += '- Text Muted: style="' + inlineStyles.get('textMuted') + '"\n';
        }
        if (inlineStyles.containsKey('emptyState')) {
            result += '- Empty State: style="' + inlineStyles.get('emptyState') + '"\n';
        }
        if (inlineStyles.containsKey('grid2col')) {
            result += '- 2-Column Grid: style="' + inlineStyles.get('grid2col') + '"\n';
        }
        if (inlineStyles.containsKey('flexRow')) {
            result += '- Flex Row: style="' + inlineStyles.get('flexRow') + '"\n';
        }

        return result;
    }

    /**
     * @description Returns default inline styles when static resource is not available
     */
    private String getDefaultInlineStyles() {
        return '### Ready-to-Use Inline Styles (copy these exactly)\n\n' +
               '#### Container & Layout\n' +
               '- Container: style="font-family:\'Salesforce Sans\',-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,Arial,sans-serif;max-width:100%;background:#F3F3F3;color:#181818;font-size:14px;line-height:1.5;padding:16px;"\n' +
               '- Header: style="background:linear-gradient(135deg,#0176D3,#014486);color:white;padding:20px;border-radius:8px 8px 0 0;"\n' +
               '- Header Title: style="margin:0 0 4px 0;font-size:20px;font-weight:600;"\n' +
               '- Section: style="background:white;margin:12px 0;padding:16px;border-radius:8px;border:1px solid #DDDBDA;"\n' +
               '- Section Title: style="font-size:14px;font-weight:600;color:#181818;margin:0 0 12px 0;padding-bottom:8px;border-bottom:1px solid #DDDBDA;"\n\n' +
               '#### Statistics & Metrics\n' +
               '- Stats Strip: style="display:flex;gap:16px;justify-content:space-around;flex-wrap:wrap;background:white;padding:16px;border-radius:8px;margin:12px 0;"\n' +
               '- Stat Item: style="text-align:center;min-width:80px;"\n' +
               '- Stat Value: style="font-size:28px;font-weight:700;line-height:1.2;color:#0176D3;"\n' +
               '- Stat Value (positive): style="font-size:28px;font-weight:700;line-height:1.2;color:#2E844A;"\n' +
               '- Stat Label: style="font-size:11px;color:#706E6B;text-transform:uppercase;letter-spacing:0.5px;margin-top:4px;"\n\n' +
               '#### Cards\n' +
               '- Card: style="background:white;border-radius:8px;border:1px solid #DDDBDA;padding:16px;margin:8px 0;"\n' +
               '- Card (success): style="background:white;border-radius:8px;border:1px solid #DDDBDA;border-left:4px solid #2E844A;padding:16px;margin:8px 0;"\n' +
               '- Card (warning): style="background:white;border-radius:8px;border:1px solid #DDDBDA;border-left:4px solid #DD7A01;padding:16px;margin:8px 0;"\n\n' +
               '#### Tables\n' +
               '- Table: style="width:100%;border-collapse:collapse;font-size:13px;"\n' +
               '- Table Header: style="background:#F3F3F3;color:#706E6B;font-weight:600;text-align:left;padding:10px 12px;border-bottom:2px solid #DDDBDA;font-size:11px;text-transform:uppercase;letter-spacing:0.5px;"\n' +
               '- Table Cell: style="padding:10px 12px;border-bottom:1px solid #DDDBDA;vertical-align:top;"\n\n' +
               '#### Badges\n' +
               '- Badge (success): style="display:inline-block;padding:4px 12px;border-radius:12px;font-weight:600;font-size:12px;background:#EAF5EC;color:#2E844A;"\n' +
               '- Badge (warning): style="display:inline-block;padding:4px 12px;border-radius:12px;font-weight:600;font-size:12px;background:#FEF3E0;color:#DD7A01;"\n' +
               '- Badge (error): style="display:inline-block;padding:4px 12px;border-radius:12px;font-weight:600;font-size:12px;background:#FDE8E8;color:#BA0517;"\n';
    }

    /**
     * @description Gets pattern-specific guidance for a root object
     * CRITICAL FIX (Jan 2026): Only includes guidance for objects that are actually
     * in the selectedFields. This prevents Claude from hallucinating fields for objects
     * like Contact, Opportunity, Case, Task that aren't in the DCM.
     *
     * @param rootObject The root Salesforce object
     * @param selectedFieldsRaw Map of object to field list (to filter guidance)
     * @return Pattern guidance string or empty string
     */
    private String getPatternGuidance(String rootObject, Map<String, Object> selectedFieldsRaw) {
        // Get set of available objects from selectedFields
        Set<String> availableObjects = selectedFieldsRaw != null ? selectedFieldsRaw.keySet() : new Set<String>();

        if (uiPatterns == null) {
            return getDefaultPatternGuidance(rootObject, availableObjects);
        }

        // Map object names to pattern names
        Map<String, String> objectToPattern = new Map<String, String>{
            'Account' => 'accountSummary',
            'Opportunity' => 'opportunitySummary',
            'Case' => 'caseSummary',
            'Lead' => 'leadSummary'
        };

        String patternName = objectToPattern.get(rootObject);
        if (patternName == null) {
            return '';
        }

        Map<String, Object> pattern = PromptFactoryRulesLoader.getUIPattern(patternName);
        if (pattern == null || pattern.isEmpty()) {
            return getDefaultPatternGuidance(rootObject, availableObjects);
        }

        String guidance = '';
        if (pattern.containsKey('name')) {
            guidance += 'Pattern: ' + String.valueOf(pattern.get('name')) + '\n';
        }
        if (pattern.containsKey('description')) {
            guidance += 'Description: ' + String.valueOf(pattern.get('description')) + '\n';
        }
        if (pattern.containsKey('layout')) {
            guidance += 'Layout: ' + String.valueOf(pattern.get('layout')) + '\n\n';
        }

        if (pattern.containsKey('components')) {
            List<Object> components = (List<Object>) pattern.get('components');
            guidance += 'Recommended Components:\n';
            for (Object compObj : components) {
                Map<String, Object> comp = (Map<String, Object>) compObj;
                String compName = String.valueOf(comp.get('name'));
                String purpose = comp.containsKey('purpose') ? String.valueOf(comp.get('purpose')) : '';
                String styling = comp.containsKey('styling') ? String.valueOf(comp.get('styling')) : '';

                guidance += '- ' + compName + ': ' + purpose;
                if (String.isNotBlank(styling)) {
                    guidance += ' (Style: ' + styling + ')';
                }
                guidance += '\n';
            }
        }

        // Add color scheme from pattern if available
        if (pattern.containsKey('colorScheme')) {
            Map<String, Object> colors = (Map<String, Object>) pattern.get('colorScheme');
            guidance += '\nPattern-specific colors:\n';
            for (String colorName : colors.keySet()) {
                guidance += '- ' + colorName + ': ' + String.valueOf(colors.get(colorName)) + '\n';
            }
        }

        return guidance;
    }

    /**
     * @description Returns default pattern guidance when static resource doesn't have the pattern
     * CRITICAL FIX (Jan 2026): Only includes child object sections if those objects
     * are actually in availableObjects. This prevents Claude from hallucinating fields
     * for objects that aren't in the DCM.
     *
     * @param rootObject The root Salesforce object
     * @param availableObjects Set of objects that have fields selected (from selectedFieldsRaw)
     */
    private String getDefaultPatternGuidance(String rootObject, Set<String> availableObjects) {
        if (rootObject == 'Account') {
            String guidance = 'Pattern: Account 360 Dashboard\n' +
                   'Description: Comprehensive account overview\n' +
                   'Layout: dashboard\n\n' +
                   'Recommended Components:\n' +
                   '- header: Account identification with gradient background (Name, Industry, Type, Owner.Name)\n' +
                   '- keyMetrics: Stats strip with AnnualRevenue, NumberOfEmployees\n';

            // ONLY include child object guidance if they're in availableObjects
            if (availableObjects.contains('Contact')) {
                guidance += '- contacts: Table of Contacts (Name, Title, Email, Phone)\n';
            }
            if (availableObjects.contains('Opportunity')) {
                guidance += '- opportunities: Table of Opportunities (Name, StageName, Amount, CloseDate) with stage badges\n';
            }
            if (availableObjects.contains('Case')) {
                guidance += '- cases: Table of Cases (CaseNumber, Subject, Priority, Status) with priority badges\n';
            }
            if (availableObjects.contains('Task')) {
                guidance += '- tasks: Table of Tasks (Subject, Type, Status, ActivityDate)\n';
            }

            guidance += '- footer: Account health summary with LastActivityDate\n';

            // Add note about available child objects
            Set<String> childObjects = new Set<String>(availableObjects);
            childObjects.remove(rootObject);
            if (!childObjects.isEmpty()) {
                guidance += '\nNOTE: You have access to these child objects: ' + String.join(new List<String>(childObjects), ', ') + '\n';
            } else {
                guidance += '\nNOTE: No child objects are available. Focus on root Account fields only.\n';
            }

            return guidance;
        } else if (rootObject == 'Opportunity') {
            String guidance = 'Pattern: Opportunity Summary\n' +
                   'Description: Deal overview with stakeholders and products\n' +
                   'Layout: scorecard\n\n' +
                   'Recommended Components:\n' +
                   '- header: Deal identification with gradient (Name, Account.Name, StageName badge, Amount, CloseDate)\n' +
                   '- dealMetrics: Stats strip (Amount, Probability, ExpectedRevenue)\n';

            if (availableObjects.contains('OpportunityContactRole')) {
                guidance += '- contacts: OpportunityContactRoles with role badges (Contact.Name, Role, IsPrimary)\n';
            }
            if (availableObjects.contains('OpportunityLineItem')) {
                guidance += '- products: OpportunityLineItems table (Product2.Name, Quantity, TotalPrice)\n';
            }

            return guidance;
        } else if (rootObject == 'Case') {
            String guidance = 'Pattern: Case Summary Card\n' +
                   'Description: Case overview with timeline and resolution\n' +
                   'Layout: vertical-stack\n\n' +
                   'Recommended Components:\n' +
                   '- header: Case identification with gradient (CaseNumber, Subject, Status badge, Priority badge)\n' +
                   '- details: Info card with Description, Type, Origin, CreatedDate\n';

            if (availableObjects.contains('CaseComment')) {
                guidance += '- timeline: CaseComments as timeline with dots and connecting line\n';
            }

            guidance += '- resolution: Success card if resolved (Resolution, ClosedDate)\n';
            return guidance;
        } else if (rootObject == 'Lead') {
            return 'Pattern: Lead Scoring Card\n' +
                   'Description: Lead qualification with engagement indicators\n' +
                   'Layout: scorecard\n\n' +
                   'Recommended Components:\n' +
                   '- header: Lead identification with gradient (Name, Company, Title, Status)\n' +
                   '- contact: Contact info section (Email, Phone, MobilePhone)\n' +
                   '- qualification: Metric tiles (LeadSource, Rating with badge, Industry, AnnualRevenue)\n';
        }
        return '';
    }

    /**
     * @description Extracts HTML from Claude AI response (removes markdown if present)
     * AGGRESSIVE handling - strips ALL markdown artifacts regardless of position.
     * @param aiContent Raw response from Claude
     * @return Clean HTML template string (single line, no markdown)
     */
    private String extractHTMLFromResponse(String aiContent) {
        String html = aiContent.trim();

        // STEP 1: Remove ALL instances of ```html and ``` (regardless of position)
        // This is more aggressive than the previous approach
        html = html.replace('```html', '');
        html = html.replace('```HTML', '');
        html = html.replace('```Html', '');
        html = html.replace('```', '');

        // STEP 2: Remove backtick characters that might be standalone
        html = html.replace('`', '');

        // STEP 3: If content doesn't start with <div, find and extract the <div> content
        html = html.trim();
        if (!html.startsWith('<div')) {
            Integer divStart = html.indexOf('<div');
            Integer divEnd = html.lastIndexOf('</div>');
            if (divStart >= 0 && divEnd > divStart) {
                html = html.substring(divStart, divEnd + 6); // +6 for '</div>'
            }
        }

        // STEP 4: Remove any text before the first < (e.g., "Here's the HTML:" or "html")
        if (!html.startsWith('<')) {
            Integer firstTag = html.indexOf('<');
            if (firstTag > 0) {
                html = html.substring(firstTag);
            }
        }

        // STEP 5: Remove any text after the last > (e.g., trailing explanations)
        if (!html.endsWith('>')) {
            Integer lastTag = html.lastIndexOf('>');
            if (lastTag > 0) {
                html = html.substring(0, lastTag + 1);
            }
        }

        // STEP 6: ALWAYS enforce single line - convert newlines to empty string
        html = html.replaceAll('\\r\\n|\\r|\\n', '');

        // STEP 7: Remove extra whitespace between tags
        html = html.replaceAll('>\\s+<', '><');

        // STEP 8: Remove any emojis (common Unicode ranges for emojis)
        html = removeEmojis(html);

        // STEP 9: Final cleanup - ensure no stray markdown artifacts
        html = html.replace('html', '').trim(); // Remove stray 'html' text at start
        if (!html.startsWith('<div')) {
            Integer divStart = html.indexOf('<div');
            if (divStart > 0) {
                html = html.substring(divStart);
            }
        }

        return html;
    }

    /**
     * @description Removes emoji characters from HTML
     * @param text Input text
     * @return Text with emojis removed
     */
    private String removeEmojis(String text) {
        if (String.isBlank(text)) {
            return text;
        }
        // Remove common emoji Unicode ranges
        // This covers most common emojis used in business content
        String result = text;
        // Remove emoji presentation selectors and common emoji ranges
        result = result.replaceAll('[\\x{1F300}-\\x{1F9FF}]', ''); // Misc symbols, emoticons, etc.
        result = result.replaceAll('[\\x{2600}-\\x{26FF}]', '');   // Misc symbols
        result = result.replaceAll('[\\x{2700}-\\x{27BF}]', '');   // Dingbats
        result = result.replaceAll('[\\x{FE00}-\\x{FE0F}]', '');   // Variation selectors
        result = result.replaceAll('[\\x{1F000}-\\x{1F02F}]', ''); // Mahjong tiles
        result = result.replaceAll('[\\x{1F0A0}-\\x{1F0FF}]', ''); // Playing cards
        return result;
    }

    /**
     * @description Validates HTML for security issues and GPTfy compatibility
     * @param html HTML template to validate
     * @return List of safety issue descriptions (empty if safe)
     */
    private List<String> validateHTMLSafety(String html) {
        List<String> issues = new List<String>();

        if (String.isBlank(html)) {
            return issues;
        }

        String lowercaseHtml = html.toLowerCase();

        // Check for script tags
        if (lowercaseHtml.contains('<script')) {
            issues.add('Contains <script> tags');
        }

        // Check for inline event handlers (using (?i) for case-insensitive matching in Apex)
        Pattern eventPattern = Pattern.compile('(?i)on\\w+\\s*=');
        if (eventPattern.matcher(html).find()) {
            issues.add('Contains inline event handlers (onclick, onload, etc.)');
        }

        // Check for javascript: protocol
        if (lowercaseHtml.contains('javascript:')) {
            issues.add('Contains javascript: protocol');
        }

        // Check for style tags (GPTfy requires inline styles only)
        if (lowercaseHtml.contains('<style')) {
            issues.add('Contains <style> tags (GPTfy requires inline styles only)');
        }

        // Check for CSS classes (GPTfy requires inline styles, no classes)
        Pattern classPattern = Pattern.compile('(?i)class\\s*=\\s*["\']');
        if (classPattern.matcher(html).find()) {
            issues.add('Contains CSS classes (GPTfy requires inline styles only, no class attributes)');
        }

        // Check for iframe tags
        if (lowercaseHtml.contains('<iframe')) {
            issues.add('Contains <iframe> tags');
        }

        // Check for multi-line template (GPTfy requires single line)
        if (html.contains('\n') || html.contains('\r')) {
            issues.add('Template contains line breaks (GPTfy requires single-line HTML)');
        }

        // Check for markdown code blocks
        if (html.contains('```')) {
            issues.add('Contains markdown code block markers (backticks)');
        }

        // Check for emojis (common patterns)
        Pattern emojiPattern = Pattern.compile('[\\x{1F300}-\\x{1F9FF}\\x{2600}-\\x{26FF}\\x{2700}-\\x{27BF}]');
        if (emojiPattern.matcher(html).find()) {
            issues.add('Contains emoji characters (professional content should not use emojis)');
        }

        return issues;
    }

    /**
     * @description Sanitizes HTML by removing unsafe elements and enforcing GPTfy compatibility
     * AGGRESSIVE sanitization - removes ALL markdown artifacts and ensures clean output.
     * @param html HTML template to sanitize
     * @return Sanitized HTML string
     */
    private String sanitizeHTML(String html) {
        String sanitized = html;

        // STEP 1: Remove ALL markdown code blocks and backticks (all variations)
        sanitized = sanitized.replace('```html', '');
        sanitized = sanitized.replace('```HTML', '');
        sanitized = sanitized.replace('```Html', '');
        sanitized = sanitized.replace('```', '');
        sanitized = sanitized.replace('`', '');

        // STEP 2: Remove script tags and content
        sanitized = sanitized.replaceAll('(?i)<script[^>]*>.*?</script>', '');

        // STEP 3: Remove style tags and content
        sanitized = sanitized.replaceAll('(?i)<style[^>]*>.*?</style>', '');

        // STEP 4: Remove iframe tags
        sanitized = sanitized.replaceAll('(?i)<iframe[^>]*>.*?</iframe>', '');

        // STEP 5: Remove inline event handlers
        sanitized = sanitized.replaceAll('(?i)\\son\\w+\\s*=\\s*["\'][^"\']*["\']', '');

        // STEP 6: Remove javascript: protocol
        sanitized = sanitized.replaceAll('(?i)javascript:', '');

        // STEP 7: Remove CSS class attributes (GPTfy requires inline styles only)
        sanitized = sanitized.replaceAll('(?i)\\sclass\\s*=\\s*["\'][^"\']*["\']', '');

        // STEP 8: Convert to single line (GPTfy requirement)
        sanitized = sanitized.replaceAll('\\r\\n|\\r|\\n', '');

        // STEP 9: Remove extra whitespace between tags
        sanitized = sanitized.replaceAll('>\\s+<', '><');

        // STEP 10: Remove emojis
        sanitized = removeEmojis(sanitized);

        // STEP 11: Extract only the <div> content if there's extra text
        sanitized = sanitized.trim();
        if (!sanitized.startsWith('<div')) {
            Integer divStart = sanitized.indexOf('<div');
            if (divStart > 0) {
                sanitized = sanitized.substring(divStart);
            }
        }
        if (!sanitized.endsWith('>')) {
            Integer lastTag = sanitized.lastIndexOf('>');
            if (lastTag > 0) {
                sanitized = sanitized.substring(0, lastTag + 1);
            }
        }

        return sanitized;
    }

    /**
     * @description Builds a human-readable template summary
     * @param html HTML template
     * @param mergeFields List of merge fields
     * @return Formatted summary string
     */
    private String buildTemplateSummary(String html, List<MergeFieldValidator.MergeField> mergeFields) {
        Integer lineCount = html.split('\n').size();
        Integer charCount = html.length();
        Integer fieldCount = mergeFields.size();

        return 'Template: ' + lineCount + ' lines, ' + charCount + ' characters, ' +
               fieldCount + ' merge fields';
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}