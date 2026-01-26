/**
 * @description Stage 8: Prompt Assembly
 * Builds complete prompt command with AI instructions, integrates HTML template,
 * adds grounding rules, and validates all merge fields.
 *
 * BUILDER PROMPT INJECTION (Verified Working - 2026-01-23)
 * =========================================================
 * This stage loads and injects Builder Prompts from ccai__AI_Prompt__c records
 * with RecordType.DeveloperName = 'Builder'. Builder prompts are queried by
 * ccai__Type__c field and injected into the final prompt:
 *
 *   - Quality Rules     (ccai__Type__c = 'Quality Rule')
 *   - Patterns          (ccai__Type__c = 'Pattern')
 *   - UI Components     (ccai__Type__c = 'UI Component')
 *   - Context Templates (ccai__Type__c = 'Context Template')
 *   - Traversals        (ccai__Type__c = 'Traversal') - V2.1: Parent field mappings
 *   - Output Rules      (ccai__Type__c = 'Output Rules') - V2.4: Merge field syntax
 *
 * Requirements for Builder Prompts to be injected:
 *   1. RecordType must be 'Builder' (not 'Execution')
 *   2. ccai__Status__c must be 'Active'
 *   3. ccai__Type__c must match one of the above values
 *   4. For Patterns: ccai__Object__c should match rootObject or be null (global)
 *
 * Verification: Run ID a0gQH000005GHurYAG confirmed all 6 text-based builder
 * prompts were successfully injected into the final ccai__Prompt_Command__c.
 */
public without sharing class Stage08_PromptAssembly implements IStage {

    private static final Integer STAGE_NUMBER = 8;
    // Force recompilation: 2026-01-25-v2 (fix Map/String type issue)

    // V2.5: Feature flag for two-layer meta-prompt architecture
    // When true: Meta-prompt generates TEMPLATE → Template executes on data
    // When false: Falls back to V2.0 (LLM analyzes data directly) or V1.1 (legacy)
    // ENABLED: 2026-01-25 - Ready for testing
    private static final Boolean USE_META_PROMPT_V2_5 = true;

    /**
     * @description Executes Stage 8: Prompt Assembly
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing HTML template and configuration from previous stages
     * @return StageResult with assembled prompt configuration in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 8: Prompt Assembly');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            // Use deferred logging (no DML) - logs will be inserted later
            result.queueInfo(runId, STAGE_NUMBER, 'Starting prompt assembly');

            // Extract inputs
            String htmlTemplate = (String) inputs.get('htmlTemplate');
            if (String.isBlank(htmlTemplate)) {
                throw new StageException('No HTML template provided for prompt assembly');
            }

            String rootObject = (String) inputs.get('rootObject');
            String businessContext = (String) inputs.get('businessContext');
            String targetPersona = (String) inputs.get('targetPersona');
            Map<String, Object> selectedFieldsRaw = (Map<String, Object>) inputs.get('selectedFields');
            List<Object> businessObjectivesRaw = (List<Object>) inputs.get('businessObjectives');

            // V2.4: Extract selected parent fields (e.g., Owner.Name, Contact.Title)
            Map<String, Object> selectedParentFieldsRaw = (Map<String, Object>) inputs.get('selectedParentFields');
            if (selectedParentFieldsRaw == null) {
                selectedParentFieldsRaw = new Map<String, Object>();
            }

            // V2.4: Extract grandchild info for proper merge field path generation
            List<Object> selectedGrandchildrenRaw = (List<Object>) inputs.get('selectedGrandchildren');
            if (selectedGrandchildrenRaw == null) {
                selectedGrandchildrenRaw = new List<Object>();
            }

            // NEW: Extract Strategic Context from Stage 2
            // CRITICAL: Use companyIntelligence (actual research) over companyProfile (AI summary)
            String companyIntelligence = (String) inputs.get('companyIntelligence');
            String companyProfile = (String) inputs.get('companyProfile');
            String strategicInsights = (String) inputs.get('strategicInsights');
            String industryContext = (String) inputs.get('industryContext');
            
            // Prefer the actual company research over generic AI summary
            String effectiveCompanyContext = String.isNotBlank(companyIntelligence) ? companyIntelligence : companyProfile;
            
            // Log what company context we're using
            if (String.isNotBlank(companyIntelligence)) {
                String preview = companyIntelligence.length() > 100 ? companyIntelligence.substring(0, 100) + '...' : companyIntelligence;
                result.queueInfo(runId, STAGE_NUMBER, 'Using company research: ' + preview);
            } else if (String.isNotBlank(companyProfile)) {
                result.queueInfo(runId, STAGE_NUMBER, 'Using company profile (no direct research available)');
            }

            // =========================================================================
            // V2.5: TWO-LAYER META-PROMPT ARCHITECTURE
            // =========================================================================
            // If enabled, use meta-prompt to GENERATE a deterministic template
            // Then return that template (no execution yet - happens at DCM stage)
            // =========================================================================

            // DEBUG: Always log the flag value to confirm code deployment
            result.queueInfo(runId, STAGE_NUMBER, 'V2.5 flag value: ' + USE_META_PROMPT_V2_5);

            if (USE_META_PROMPT_V2_5) {
                result.queueInfo(runId, STAGE_NUMBER,
                    'V2.5: Using two-layer meta-prompt architecture');

                // Step 1: Load Meta-Prompt Builder
                String metaPromptBuilder;
                try {
                    metaPromptBuilder = loadMetaPromptBuilder();
                    result.queueInfo(runId, STAGE_NUMBER,
                        'V2.5: Loaded meta-prompt (' + metaPromptBuilder.length() + ' chars)');
                } catch (Exception e) {
                    throw new StageException('Failed to load meta-prompt Builder: ' + e.getMessage(), e);
                }

                // Step 2: Build DCM structure from available inputs
                // At Stage 8, DCM doesn't exist yet, but we have all the data to build its structure
                Map<String, Object> dcmConfigRaw = new Map<String, Object>{
                    'objectName' => rootObject,
                    'childRelationships' => getChildObjectNames(selectedFieldsRaw),
                    'parentLookups' => extractParentLookupNames(selectedParentFieldsRaw)
                };

                Map<String, Object> dcmAnalysis = analyzeDCMStructure(
                    dcmConfigRaw,
                    selectedFieldsRaw,
                    selectedParentFieldsRaw,
                    selectedGrandchildrenRaw
                );

                // Defensive: handle both String and Map types for 'json' key
                Object jsonValue = dcmAnalysis.get('json');
                String dcmAnalysisJson;
                if (jsonValue instanceof String) {
                    dcmAnalysisJson = (String) jsonValue;
                } else {
                    // Fallback: serialize if we got raw Map (handles deployment lag)
                    dcmAnalysisJson = JSON.serialize(jsonValue, true);
                }

                // Defensive: handle narrative which might be Map or String
                Object narrativeValue = dcmAnalysis.get('narrative');
                String narrative = (narrativeValue instanceof String) ? (String) narrativeValue : String.valueOf(narrativeValue);

                result.queueInfo(runId, STAGE_NUMBER,
                    'V2.5: Analyzed DCM structure: ' + narrative);

                // Step 3: Generate and iterate on template
                result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Starting template generation...');

                Map<String, Object> generationResult = iterateOnPromptGeneration(
                    metaPromptBuilder,
                    dcmAnalysisJson,
                    (Map<String, Object>) dcmAnalysis.get('structured'),
                    businessContext,
                    runId,
                    result,
                    10 // Max iterations
                );

                result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Template generation returned');

                Boolean success = (Boolean) generationResult.get('success');
                result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Success flag: ' + success);

                if (!success) {
                    throw new StageException('V2.5: Failed to generate valid template after max iterations');
                }

                result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Extracting generated template from result...');
                Object templateObj = generationResult.get('template');
                result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Template object type: ' + (templateObj != null ? 'exists' : 'null'));

                String generatedTemplate;
                if (templateObj instanceof String) {
                    generatedTemplate = (String) templateObj;
                } else {
                    result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Template is not String, converting...');
                    generatedTemplate = String.valueOf(templateObj);
                }

                Integer iterations = (Integer) generationResult.get('iterations');

                result.queueInfo(runId, STAGE_NUMBER,
                    'V2.5: Generated template (' + generatedTemplate.length() + ' chars, ' +
                    iterations + ' iteration' + (iterations > 1 ? 's' : '') + ')');

                // Step 4: Assemble prompt configuration with generated template
                Map<String, Object> promptConfig = new Map<String, Object>{
                    'promptCommand' => generatedTemplate,
                    'promptType' => 'V2.5_Meta_Generated',
                    'metaPromptUsed' => true,
                    'iterations' => iterations,
                    'dcmAnalysis' => dcmAnalysisJson,
                    'businessContext' => businessContext
                };

                // Return outputs
                result.outputs = promptConfig;
                result.queueInfo(runId, STAGE_NUMBER,
                    'V2.5: Prompt assembly complete (two-layer meta-prompt)');
                result.markCompleted();
                return result;
            }

            // =========================================================================
            // FALLBACK: V2.0 or V1.1 Architecture
            // =========================================================================

            // V2.0: Check if using meta-prompt architecture
            Boolean useMetaPrompt = (Boolean) inputs.get('useMetaPrompt');
            if (useMetaPrompt == null) {
                useMetaPrompt = false; // Default to legacy template approach
            }

            // V2.0: Extract multi-sample profile if available
            Object multiSampleProfileRaw = inputs.get('multiSampleProfile');

            result.queueInfo(runId, STAGE_NUMBER,
                'Assembling prompt for ' + rootObject +
                (useMetaPrompt ? ' (Meta-Prompt V2.0)' : ' (Template V1.1)'));

            // Validate merge fields against selected fields
            List<MergeFieldValidator.MergeField> validatedFields =
                validateMergeFieldsDeferred(htmlTemplate, selectedFieldsRaw, rootObject, runId, result);

            // Check for validation failures
            Integer invalidFieldCount = 0;
            List<String> validationErrors = new List<String>();
            for (MergeFieldValidator.MergeField field : validatedFields) {
                if (!field.isValid) {
                    invalidFieldCount++;
                    validationErrors.add(field.originalText + ': ' + field.errorMessage);
                }
            }

            if (invalidFieldCount > 0) {
                result.queueError(runId, STAGE_NUMBER,
                    invalidFieldCount + ' invalid merge fields detected');
                for (String error : validationErrors) {
                    result.queueError(runId, STAGE_NUMBER, error);
                }
            }

            // Build AI instructions - branch based on architecture version
            String aiInstructions;
            if (useMetaPrompt) {
                // V2.0: Build meta-prompt with 6 sections
                aiInstructions = buildMetaPrompt(
                    businessContext, targetPersona, businessObjectivesRaw, rootObject,
                    effectiveCompanyContext, strategicInsights, industryContext,
                    multiSampleProfileRaw, selectedFieldsRaw, runId, result);
            } else {
                // V1.1: Build traditional AI instructions (legacy)
                aiInstructions = buildAIInstructions(
                    businessContext, targetPersona, businessObjectivesRaw, rootObject,
                    effectiveCompanyContext, strategicInsights, industryContext, runId);
            }

            // Build grounding rules
            String groundingRules = buildGroundingRules(rootObject, targetPersona);

            // Assemble complete prompt configuration
            // V2.0: In meta-prompt mode, don't append the minimal validation template
            // The LLM generates HTML structure based on meta-prompt instructions
            Map<String, Object> promptConfig;
            if (useMetaPrompt) {
                promptConfig = assembleMetaPromptConfiguration(
                    aiInstructions, groundingRules, rootObject, selectedFieldsRaw,
                    selectedParentFieldsRaw, selectedGrandchildrenRaw);
            } else {
                promptConfig = assemblePromptConfiguration(
                    aiInstructions, htmlTemplate, groundingRules, rootObject);
            }

            // Build assembly summary
            String assemblySummary = buildAssemblySummary(
                aiInstructions, htmlTemplate, groundingRules, validatedFields);

            result.queueInfo(runId, STAGE_NUMBER, assemblySummary);

            // Build DCM config for Stage 9
            Map<String, Object> dcmConfig = buildDCMConfigForStage9(
                rootObject, selectedFieldsRaw, inputs);

            // Build Prompt config for Stage 9
            Map<String, Object> promptConfigForStage9 = buildPromptConfigForStage9(
                rootObject, aiInstructions, htmlTemplate, groundingRules, inputs);

            // V2.0: Validate prompt command size against field limit
            String finalPromptCommand = (String) promptConfigForStage9.get('promptCommand');
            if (String.isNotBlank(finalPromptCommand)) {
                Integer maxPromptLength = getPromptCommandMaxLength();
                Integer currentLength = finalPromptCommand.length();
                if (currentLength > maxPromptLength) {
                    String sizeError = 'Prompt command exceeds maximum field length of ' + maxPromptLength +
                        ' characters (current: ' + currentLength + '). ' +
                        'Try reducing builder prompts or selected fields.';
                    result.queueError(runId, STAGE_NUMBER, sizeError);
                    result.markFailed(sizeError);
                    return result;
                } else {
                    result.queueInfo(runId, STAGE_NUMBER, 'Prompt size: ' + currentLength + '/' + maxPromptLength + ' chars (' +
                        Math.round((Decimal.valueOf(currentLength) / Decimal.valueOf(maxPromptLength)) * 100) + '%)');
                }
            }

            // Build outputs - include dcmConfig and promptConfig for Stage 9
            result.outputs.put('dcmConfig', dcmConfig);
            result.outputs.put('promptConfig', promptConfigForStage9);
            result.outputs.put('promptConfiguration', promptConfig);
            result.outputs.put('aiInstructions', aiInstructions);
            result.outputs.put('groundingRules', groundingRules);
            result.outputs.put('validatedFields', validatedFields);
            result.outputs.put('invalidFieldCount', invalidFieldCount);
            result.outputs.put('validationErrors', validationErrors);
            result.outputs.put('assemblySummary', assemblySummary);

            // Pass through critical inputs for downstream stages
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('targetPersona', targetPersona);
            result.outputs.put('businessObjectives', businessObjectivesRaw);
            result.outputs.put('htmlTemplate', htmlTemplate);
            result.outputs.put('selectedFields', selectedFieldsRaw);
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            // Pass through selectedGrandchildren - already used in buildDCMConfigForStage9
            result.outputs.put('selectedGrandchildren', inputs.get('selectedGrandchildren'));

            // CRITICAL: Fail if ANY invalid merge fields detected
            // This prevents creating DCM/Prompt with mismatched field references
            // Mirrors the shell script behavior: fail fast if whitelist validation fails
            if (invalidFieldCount > 0) {
                String errorMsg = 'VALIDATION FAILED: ' + invalidFieldCount + ' invalid merge field(s) detected. ' +
                    'The HTML template references fields not in the selected fields list. ' +
                    'Fix: Re-run Stage 7 with proper field whitelist or adjust selected fields.';
                result.markFailed(errorMsg);
                result.queueError(runId, STAGE_NUMBER, errorMsg);
                result.queueError(runId, STAGE_NUMBER, 'Invalid fields: ' + String.join(validationErrors, '; '));
                return result;
            }

            result.markCompleted();
            result.queueInfo(runId, STAGE_NUMBER, 'Prompt assembly completed successfully - all merge fields validated');

        } catch (Exception e) {
            String errorMsg = 'Failed to complete prompt assembly: ' + e.getMessage();
            result.markFailed(errorMsg);
            result.queueError(runId, STAGE_NUMBER, 'Stage execution failed: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Validates merge fields in template against selected fields (deferred logging)
     * @param htmlTemplate HTML template containing merge fields
     * @param selectedFieldsRaw Map of object to field list
     * @param rootObject The root Salesforce object
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return List of validated merge field objects
     */
    private List<MergeFieldValidator.MergeField> validateMergeFieldsDeferred(
            String htmlTemplate,
            Map<String, Object> selectedFieldsRaw,
            String rootObject,
            Id runId,
            StageResult result) {

        // Build DCM-like configuration for validation
        Map<String, Object> dcmConfig = buildDCMConfig(selectedFieldsRaw, rootObject);

        // Validate merge fields
        List<MergeFieldValidator.MergeField> validatedFields =
            MergeFieldValidator.validateAgainstDCM(htmlTemplate, dcmConfig);

        result.queueDebug(runId, STAGE_NUMBER,
            'Validated ' + validatedFields.size() + ' merge fields');

        return validatedFields;
    }

    /**
     * @description Builds a DCM-like configuration for merge field validation
     * @param selectedFieldsRaw Map of object to field list
     * @param rootObject The root Salesforce object
     * @return Map with rootObject, childObjects, and fieldsByObject
     */
    private Map<String, Object> buildDCMConfig(
            Map<String, Object> selectedFieldsRaw,
            String rootObject) {

        List<String> childObjects = new List<String>();
        Map<String, List<String>> fieldsByObject = new Map<String, List<String>>();

        for (String objectName : selectedFieldsRaw.keySet()) {
            List<Object> fieldsRaw = (List<Object>) selectedFieldsRaw.get(objectName);
            List<String> fields = new List<String>();

            for (Object field : fieldsRaw) {
                fields.add(String.valueOf(field));
            }

            fieldsByObject.put(objectName, fields);

            if (objectName != rootObject) {
                childObjects.add(objectName);
            }
        }

        return new Map<String, Object>{
            'rootObject' => rootObject,
            'childObjects' => childObjects,
            'fieldsByObject' => fieldsByObject
        };
    }

    /**
     * @description Builds AI instructions for the prompt
     * Includes comprehensive GPTfy output rules, styling requirements, and data handling
     * Matches the shell script prompt structure for consistent, high-quality output
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @param businessObjectivesRaw List of business objectives
     * @param rootObject The root Salesforce object
     * @return Formatted AI instructions string
     */
    private String buildAIInstructions(
            String businessContext,
            String targetPersona,
            List<Object> businessObjectivesRaw,
            String rootObject,
            String companyProfile,
            String strategicInsights,
            String industryContext,
            Id runId) {

        String instructions = 'You are a Salesforce AI assistant generating HTML content for GPTfy.\n\n';

        // === CRITICAL OUTPUT RULES ===
        instructions += '=== CRITICAL OUTPUT RULES (GPTfy Runtime Validation) ===\n\n';

        instructions += 'Rule 1 - SINGLE LINE: Output MUST be a single line with NO newline characters.\n';
        instructions += '  WHY: GPTfy stores output as a single field value. Line breaks cause parsing issues.\n\n';

        instructions += 'Rule 2 - NO STYLE BLOCKS: Do NOT include any style tags.\n';
        instructions += '  WHY: GPTfy renders in Salesforce Lightning which strips style blocks. Only inline styles work.\n\n';

        instructions += 'Rule 3 - NO CSS CLASSES: Do NOT use class attributes.\n';
        instructions += '  WHY: Without style blocks, CSS classes have no definitions and elements remain unstyled.\n\n';

        instructions += 'Rule 4 - NO SCRIPT TAGS: Do NOT include any JavaScript.\n';
        instructions += '  WHY: Scripts are a security risk and are stripped by Salesforce Lightning.\n\n';

        instructions += 'Rule 5 - NO MARKDOWN: Do NOT wrap output in code blocks or use markdown formatting.\n';
        instructions += '  WHY: Output must be raw HTML, not markdown.\n\n';

        instructions += 'Rule 6 - START WITH DIV STYLE: Output MUST begin with a div element with inline style attribute.\n';
        instructions += '  WHY: Ensures proper container structure with inline styles.\n\n';

        instructions += 'Rule 7 - END WITH DIV: Output MUST end with a closing div tag.\n';
        instructions += '  WHY: Ensures HTML structure is complete and properly closed.\n\n';

        instructions += 'Rule 8 - NO PLACEHOLDERS: Never output bracket-X patterns, placeholder text, TBD, TODO, or similar.\n';
        instructions += '  WHY: Indicates the prompt didn\'t properly integrate real data.\n\n';

        instructions += 'Rule 9 - NO NULL VALUES: Never output null, undefined, or Not Available in visible text.\n';
        instructions += '  WHY: Missing data should be handled gracefully by omitting the section.\n\n';

        instructions += 'Rule 10 - NO EMOJIS: Do NOT use any emoji characters.\n';
        instructions += '  WHY: Professional business content should not contain emojis.\n\n';

        // === STYLING REQUIREMENTS ===
        instructions += '=== STYLING REQUIREMENTS (Salesforce Brand) ===\n\n';

        instructions += 'Font: \'Salesforce Sans\', -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Arial, sans-serif\n';
        instructions += 'Base Size: 14px\n\n';

        instructions += 'Colors:\n';
        instructions += '- Primary Blue: #0176D3\n';
        instructions += '- Dark Blue: #014486\n';
        instructions += '- Success Green: #2E844A\n';
        instructions += '- Warning Orange: #DD7A01\n';
        instructions += '- Error Red: #BA0517\n';
        instructions += '- Text Primary: #181818\n';
        instructions += '- Text Secondary: #706E6B\n';
        instructions += '- Background: #F3F3F3\n';
        instructions += '- Card Background: #FFFFFF\n';
        instructions += '- Border: #DDDBDA\n\n';

        instructions += 'Components:\n';
        instructions += '- Cards: white background, 8px border-radius, 1px solid border in DDDBDA color, 16px padding\n';
        instructions += '- Headers: linear gradient from Primary Blue to Dark Blue, white text, 16px padding\n';
        instructions += '- Progress bars: 8px height, DDDBDA background, colored fill based on score\n';
        instructions += '- Status badges: 4px 12px padding, 4px border-radius, semantic color background\n';
        instructions += '- Tables: border-collapse, F3F3F3 header background, 10px 12px cell padding\n\n';

        // === DATA HANDLING ===
        instructions += '=== DATA HANDLING ===\n\n';
        instructions += '- If a merge field returns empty or null, OMIT that section entirely - do not show empty labels\n';
        instructions += '- Use relative timeframes in recommendations (this week, within 3 days) not absolute dates\n';
        instructions += '- All merge fields are provided using triple-brace syntax and will be substituted by GPTfy at runtime\n';

        // === BUSINESS CONTEXT ===
        instructions += 'Generate a premium, executive-style dashboard for: ' + targetPersona + '\n\n';

        // === STRATEGIC CONTEXT (Account 360) ===
        if (String.isNotBlank(companyProfile) || String.isNotBlank(strategicInsights) || String.isNotBlank(industryContext)) {
             instructions += '=== STRATEGIC CONTEXT (Account 360) ===\n';
             instructions += 'Use this intelligence to make the content highly relevant and personalized.\n\n';
             
             if (String.isNotBlank(companyProfile)) {
                 instructions += 'COMPANY PROFILE:\n' + companyProfile + '\n\n';
             }
             if (String.isNotBlank(industryContext)) {
                 instructions += 'INDUSTRY CONTEXT:\n' + industryContext + '\n\n';
             }
             if (String.isNotBlank(strategicInsights)) {
                 instructions += 'STRATEGIC INSIGHTS:\n' + strategicInsights + '\n\n';
             }
        }

        // Include full business context from user input
        if (String.isNotBlank(businessContext)) {
            instructions += 'SPECIFIC REQUIREMENTS:\n' + businessContext + '\n\n';
        }

        if (businessObjectivesRaw != null && !businessObjectivesRaw.isEmpty()) {
            instructions += 'Business Goals: ';
            List<String> objectives = new List<String>();
            for (Object obj : businessObjectivesRaw) {
                objectives.add(String.valueOf(obj));
            }
            instructions += String.join(objectives, ', ') + '\n\n';
        }

        // === CRITICAL: ANALYSIS REQUIREMENTS ===
        instructions += '=== CRITICAL: ANALYSIS REQUIREMENTS ===\n\n';
        instructions += 'You are NOT just displaying data - you are providing INTELLIGENT BUSINESS ANALYSIS.\n';
        instructions += 'The template below contains merge fields that will be replaced with real Salesforce data.\n';
        instructions += 'Your job is to ANALYZE this data and provide ACTIONABLE INSIGHTS.\n\n';
        
        instructions += 'ANALYSIS YOU MUST PERFORM:\n\n';
        
        instructions += '1. OPPORTUNITY HEALTH ANALYSIS:\n';
        instructions += '   - Identify stale opportunities (close dates in the past or soon)\n';
        instructions += '   - Flag deals stuck in early stages for too long\n';
        instructions += '   - Calculate total pipeline value and weighted pipeline\n';
        instructions += '   - Recommend next steps for each opportunity\n\n';
        
        instructions += '2. CASE/SUPPORT RISK ANALYSIS:\n';
        instructions += '   - Flag high-priority open cases that need attention\n';
        instructions += '   - Identify aging cases (open for extended periods)\n';
        instructions += '   - Calculate customer satisfaction risk based on case patterns\n';
        instructions += '   - Recommend resolution priorities\n\n';
        
        instructions += '3. ENGAGEMENT PATTERN ANALYSIS:\n';
        instructions += '   - Identify last contact date and engagement gaps\n';
        instructions += '   - Flag accounts with no recent activity (going cold)\n';
        instructions += '   - Analyze contact coverage (do we have the right stakeholders?)\n';
        instructions += '   - Recommend engagement actions\n\n';
        
        instructions += '4. EXECUTIVE SUMMARY:\n';
        instructions += '   - Provide an overall account health score or assessment\n';
        instructions += '   - List top 3 priorities for this account\n';
        instructions += '   - Identify the biggest risk and biggest opportunity\n';
        instructions += '   - Recommend immediate actions\n\n';
        
        instructions += 'OUTPUT STRUCTURE:\n';
        instructions += 'Your output should include BOTH the templated data AND your analytical sections.\n';
        instructions += 'Add analysis sections with headers like "Executive Summary", "Key Risks", "Recommended Actions".\n';
        instructions += 'Do NOT just render tables - add CONTEXT and INTERPRETATION before/after data sections.\n\n';
        
        instructions += 'The output should be visually stunning, data-rich, and immediately actionable.\n';
        instructions += 'Use ONLY the merge field embeddings provided in the template below. Do not add or modify merge fields.\n';
        instructions += 'Merge fields use triple-brace syntax and will be substituted by GPTfy at runtime.\n\n';

        PromptFactoryLogger.info(runId, 8, '🏗️ BUILD AI INSTRUCTIONS: Starting builder injection');
        Integer initialLength = instructions.length();
        
        // NEW: Load and inject Builder Prompts
        PromptFactoryLogger.info(runId, 8, '📋 Step 1: Loading Quality Rules');
        String qualityRules = loadQualityRules(runId);
        if (String.isNotBlank(qualityRules)) {
            instructions += qualityRules + '\n\n';
            PromptFactoryLogger.info(runId, 8, '✅ Injected Quality Rules: +' + qualityRules.length() + ' chars');
        } else {
            PromptFactoryLogger.warning(runId, 8, '⚠️ No Quality Rules to inject');
        }

        PromptFactoryLogger.info(runId, 8, '📋 Step 2: Loading Patterns');
        String patterns = loadPatterns(rootObject, runId);
        if (String.isNotBlank(patterns)) {
            instructions += patterns + '\n\n';
            PromptFactoryLogger.info(runId, 8, '✅ Injected Patterns: +' + patterns.length() + ' chars');
        } else {
            PromptFactoryLogger.warning(runId, 8, '⚠️ No Patterns to inject');
        }

        // NEW: Load and inject UI Components
        PromptFactoryLogger.info(runId, 8, '📋 Step 3: Loading UI Components');
        String uiComponents = loadUIComponents(runId);
        if (String.isNotBlank(uiComponents)) {
            instructions += uiComponents + '\n\n';
            PromptFactoryLogger.info(runId, 8, '✅ Injected UI Components: +' + uiComponents.length() + ' chars');
        } else {
            PromptFactoryLogger.warning(runId, 8, '⚠️ No UI Components to inject');
        }

        // NEW: Load and inject Context Templates
        PromptFactoryLogger.info(runId, 8, '📋 Step 4: Loading Context Templates');
        String contextTemplates = loadContextTemplates(runId);
        if (String.isNotBlank(contextTemplates)) {
            instructions += contextTemplates + '\n\n';
            PromptFactoryLogger.info(runId, 8, '✅ Injected Context Templates: +' + contextTemplates.length() + ' chars');
        } else {
            PromptFactoryLogger.warning(runId, 8, '⚠️ No Context Templates to inject');
        }
        
        Integer finalLength = instructions.length();
        Integer addedContent = finalLength - initialLength;
        PromptFactoryLogger.info(runId, 8, '📊 BUILDER INJECTION COMPLETE: Added ' + addedContent + ' chars from builders');
        PromptFactoryLogger.info(runId, 8, '📊 Total instruction length: ' + finalLength + ' chars');

        return instructions;
    }

    /**
     * @description Load active Quality Rules from Builder Prompts
     * @param runId PF_Run__c ID for logging
     * @return Combined quality rules content
     */
    private String loadQualityRules(Id runId) {
        try {
            PromptFactoryLogger.info(runId, 8, '🔍 loadQualityRules() called - using HARDCODED IDs as test');
            
            // FIXED: Use RecordTypeId directly to avoid visibility issues in some org contexts
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
            
            List<ccai__AI_Prompt__c> rules = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND ccai__Type__c = 'Quality Rule'
                  AND ccai__Status__c = 'Active'
                ORDER BY Name
            ];
            
            PromptFactoryLogger.info(runId, 8, '📊 Query returned: ' + rules.size() + ' Quality Rules');
            
            if (rules.isEmpty()) {
                PromptFactoryLogger.warning(runId, 8, '⚠️ No Quality Rules found - returning empty');
                return '';
            }
            
            String allRules = '';
            for (ccai__AI_Prompt__c rule : rules) {
                PromptFactoryLogger.info(runId, 8, '✅ Loading: ' + rule.Name + ' (' + rule.ccai__Prompt_Command__c.length() + ' chars)');
                allRules += '\n\n=== ' + rule.Name + ' ===\n\n';
                allRules += rule.ccai__Prompt_Command__c;
            }
            
            PromptFactoryLogger.info(runId, 8, '✅ Loaded ' + rules.size() + ' Quality Rules (' + allRules.length() + ' total chars)');
            return allRules;
            
        } catch (Exception e) {
            // DON'T silently return empty - fail loudly so we can see the error!
            String errorMsg = 'Failed to load Quality Rules: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new StageException(errorMsg);
        }
    }

    /**
     * @description Load active Patterns from Builder Prompts for specific object
     * @param rootObject The Salesforce object (e.g., 'Opportunity')
     * @param runId PF_Run__c ID for logging
     * @return Combined pattern content
     */
    private String loadPatterns(String rootObject, Id runId) {
        try {
            PromptFactoryLogger.info(runId, 8, '🔍 loadPatterns() called - using HARDCODED IDs as test');
            
            // FIXED: Use RecordTypeId directly
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
            
            List<ccai__AI_Prompt__c> patterns = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND ccai__Type__c = 'Pattern'
                  AND ccai__Status__c = 'Active'
                  AND (ccai__Object__c = :rootObject OR ccai__Object__c = null)
                ORDER BY Name
            ];
            
            PromptFactoryLogger.info(runId, 8, '📊 Query returned: ' + patterns.size() + ' Patterns');
            
            if (patterns.isEmpty()) {
                PromptFactoryLogger.warning(runId, 8, '⚠️ No Patterns found for ' + rootObject);
                return '';
            }
            
            String allPatterns = '';
            for (ccai__AI_Prompt__c pattern : patterns) {
                PromptFactoryLogger.info(runId, 8, '✅ Loading: ' + pattern.Name + ' (' + pattern.ccai__Prompt_Command__c.length() + ' chars)');
                allPatterns += '\n\n=== ' + pattern.Name + ' ===\n\n';
                allPatterns += pattern.ccai__Prompt_Command__c;
            }
            
            PromptFactoryLogger.info(runId, 8, '✅ Loaded ' + patterns.size() + ' Patterns (' + allPatterns.length() + ' total chars)');
            return allPatterns;
            
        } catch (Exception e) {
            // DON'T silently return empty - fail loudly so we can see the error!
            String errorMsg = 'Failed to load Patterns: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new StageException(errorMsg);
        }
    }

    /**
     * @description Load active UI Components from Builder Prompts
     * @param runId PF_Run__c ID for logging
     * @return Combined UI component content
     */
    private String loadUIComponents(Id runId) {
        try {
            PromptFactoryLogger.info(runId, 8, '🔍 loadUIComponents() called - using HARDCODED IDs as test');
            
            // FIXED: Use RecordTypeId directly
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
            
            List<ccai__AI_Prompt__c> components = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND ccai__Type__c = 'UI Component'
                  AND ccai__Status__c = 'Active'
                ORDER BY Name
            ];
            
            PromptFactoryLogger.info(runId, 8, '📊 Query returned: ' + components.size() + ' UI Components');
            
            if (components.isEmpty()) {
                PromptFactoryLogger.warning(runId, 8, '⚠️ No UI Components found');
                return '';
            }
            
            String allComponents = '';
            for (ccai__AI_Prompt__c component : components) {
                PromptFactoryLogger.info(runId, 8, '✅ Loading: ' + component.Name);
                allComponents += '\n\n=== ' + component.Name + ' ===\n\n';
                allComponents += component.ccai__Prompt_Command__c;
            }
            
            PromptFactoryLogger.info(runId, 8, '✅ Loaded ' + components.size() + ' UI Components (' + allComponents.length() + ' total chars)');
            return allComponents;
            
        } catch (Exception e) {
            // DON'T silently return empty - fail loudly so we can see the error!
            String errorMsg = 'Failed to load UI Components: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new StageException(errorMsg);
        }
    }

    /**
     * @description Load active Context Templates from Builder Prompts
     * @param runId PF_Run__c ID for logging
     * @return Combined context template content
     */
    private String loadContextTemplates(Id runId) {
        try {
            PromptFactoryLogger.info(runId, 8, '🔍 loadContextTemplates() called - using HARDCODED IDs as test');
            
            // FIXED: Use RecordTypeId directly
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
            
            List<ccai__AI_Prompt__c> templates = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND ccai__Type__c = 'Context Template'
                  AND ccai__Status__c = 'Active'
                ORDER BY Name
            ];
            
            PromptFactoryLogger.info(runId, 8, '📊 Query returned: ' + templates.size() + ' Context Templates');
            
            if (templates.isEmpty()) {
                PromptFactoryLogger.warning(runId, 8, '⚠️ No Context Templates found');
                return '';
            }
            
            String allTemplates = '';
            for (ccai__AI_Prompt__c template : templates) {
                PromptFactoryLogger.info(runId, 8, '✅ Loading: ' + template.Name);
                allTemplates += '\n\n=== ' + template.Name + ' ===\n\n';
                allTemplates += template.ccai__Prompt_Command__c;
            }
            
            PromptFactoryLogger.info(runId, 8, '✅ Loaded ' + templates.size() + ' Context Templates (' + allTemplates.length() + ' total chars)');
            return allTemplates;
            
        } catch (Exception e) {
            // DON'T silently return empty - fail loudly so we can see the error!
            String errorMsg = 'Failed to load Context Templates: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new StageException(errorMsg);
        }
    }

    /**
     * @description Load active Traversals from Builder Prompts (V2.1)
     * Traversals define parent field mappings (e.g., ContactId → Contact.Name)
     * @param runId PF_Run__c ID for logging
     * @param rootObject The root object to filter traversals (optional)
     * @return Combined traversal definitions as JSON array
     */
    private String loadTraversals(Id runId, String rootObject) {
        try {
            PromptFactoryLogger.info(runId, 8, '🔍 loadTraversals() called for ' + rootObject);

            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();

            List<ccai__AI_Prompt__c> traversals = [
                SELECT Id, Name, ccai__Prompt_Command__c, ccai__Object__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND ccai__Type__c = 'Traversal'
                  AND ccai__Status__c = 'Active'
                  AND (ccai__Object__c = :rootObject OR ccai__Object__c = null)
                ORDER BY Name
            ];

            PromptFactoryLogger.info(runId, 8, '📊 Query returned: ' + traversals.size() + ' Traversals');

            if (traversals.isEmpty()) {
                PromptFactoryLogger.warning(runId, 8, '⚠️ No Traversals found for ' + rootObject);
                return '[]';
            }

            // Build JSON array of traversal definitions
            List<String> traversalJsons = new List<String>();
            for (ccai__AI_Prompt__c traversal : traversals) {
                PromptFactoryLogger.info(runId, 8, '✅ Loading: ' + traversal.Name);
                traversalJsons.add(traversal.ccai__Prompt_Command__c);
            }

            PromptFactoryLogger.info(runId, 8, '✅ Loaded ' + traversals.size() + ' Traversals');
            return '[' + String.join(traversalJsons, ',') + ']';

        } catch (Exception e) {
            String errorMsg = 'Failed to load Traversals: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, errorMsg);
            // Return empty array on error (non-critical)
            return '[]';
        }
    }

    /**
     * @description V2.4: Load Output Rules from Builder Prompts
     * Contains GPTfy merge field syntax rules for prompt generation
     * @param runId PF_Run__c ID for logging
     * @return Output rules content or empty string if not found
     */
    private String loadOutputRules(Id runId) {
        try {
            PromptFactoryLogger.info(runId, 8, 'Loading Output Rules builder');

            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();

            List<ccai__AI_Prompt__c> outputRules = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND ccai__Type__c = 'Output Rules'
                  AND ccai__Status__c = 'Active'
                ORDER BY Name
                LIMIT 1
            ];

            if (outputRules.isEmpty()) {
                PromptFactoryLogger.warning(runId, 8, 'No Output Rules builder found');
                return '';
            }

            PromptFactoryLogger.info(runId, 8, 'Loaded Output Rules: ' + outputRules[0].Name + ' (' + outputRules[0].ccai__Prompt_Command__c.length() + ' chars)');
            return outputRules[0].ccai__Prompt_Command__c;

        } catch (Exception e) {
            String errorMsg = 'Failed to load Output Rules: ' + e.getMessage();
            System.debug(LoggingLevel.WARN, errorMsg);
            return '';
        }
    }

    /**
     * @description Builds grounding rules for consistent AI behavior
     * Simplified since main rules are now in AI instructions
     * @param rootObject The root Salesforce object
     * @param targetPersona Target user persona
     * @return Formatted grounding rules string
     */
    private String buildGroundingRules(String rootObject, String targetPersona) {
        // NOTE: GPTfy substitutes all merge fields BEFORE sending to AI.
        // The AI receives the prompt with real data values already filled in.
        // Main output rules are in AI instructions - these are supplementary behavioral rules.
        String rules = '--- GROUNDING RULES ---\n';
        rules += '**Grounding Rules:**\n\n';

        rules += '1. **Accuracy:** Use ONLY data from the provided ' + rootObject + ' record. Never fabricate company names or contact details.\n';
        rules += '2. **Tone:** Maintain a professional, enterprise-appropriate tone for ' + targetPersona + '.\n';
        rules += '3. **Format:** Preserve the HTML structure with inline styles. Do NOT use CSS classes.\n';
        rules += '4. **Consistency:** Use consistent date formats (MM/DD/YYYY), currency formats ($X,XXX), and terminology.\n';
        rules += '5. **Relevance:** Focus on insights that align with the business objectives.\n';
        rules += '6. **ANALYZE AND INTERPRET:** Go beyond raw data display. Identify patterns, risks, opportunities, and provide actionable recommendations.\n';

        return rules;
    }

    /**
     * @description Assembles the complete prompt configuration
     * Mirrors shell script structure: AI Instructions → Grounding Rules → HTML Template
     * @param aiInstructions AI instructions section
     * @param htmlTemplate HTML template with merge fields
     * @param groundingRules Grounding rules for AI behavior
     * @param rootObject The root Salesforce object
     * @return Map containing the complete prompt configuration
     */
    private Map<String, Object> assemblePromptConfiguration(
            String aiInstructions,
            String htmlTemplate,
            String groundingRules,
            String rootObject) {

        // Build the complete prompt text matching shell script structure:
        // 1. AI Instructions (with output rules, styling, data handling)
        // 2. Grounding Rules
        // 3. HTML Template section
        String completePrompt = aiInstructions;
        completePrompt += '\n\n' + groundingRules;
        completePrompt += '\n\n--- HTML TEMPLATE ---\n';
        completePrompt += htmlTemplate;

        Map<String, Object> config = new Map<String, Object>{
            'promptText' => completePrompt,
            'aiInstructions' => aiInstructions,
            'groundingRules' => groundingRules,
            'htmlTemplate' => htmlTemplate,
            'rootObject' => rootObject,
            'version' => '1.0',
            'createdDate' => System.now().format()
        };

        return config;
    }

    /**
     * @description Assembles meta-prompt configuration (V2.0)
     * In meta-prompt mode, the LLM generates the HTML structure - we provide
     * merge field references so it knows what data is available.
     * @param aiInstructions Meta-prompt with 6 sections
     * @param groundingRules Grounding rules for AI behavior
     * @param rootObject The root Salesforce object
     * @param selectedFieldsRaw Map of object to field list
     * @param selectedParentFieldsRaw V2.4: Map of object to parent lookup fields
     * @param selectedGrandchildrenRaw V2.4: List of grandchild configs for proper path generation
     * @return Map containing the complete prompt configuration
     */
    private Map<String, Object> assembleMetaPromptConfiguration(
            String aiInstructions,
            String groundingRules,
            String rootObject,
            Map<String, Object> selectedFieldsRaw,
            Map<String, Object> selectedParentFieldsRaw,
            List<Object> selectedGrandchildrenRaw) {

        // Build merge field reference section (V2.4: includes parent lookup fields and grandchildren)
        String mergeFieldReference = buildMergeFieldReference(rootObject, selectedFieldsRaw,
            selectedParentFieldsRaw, selectedGrandchildrenRaw);

        // Build complete meta-prompt:
        // 1. Meta-prompt (6 sections with role, data, principles, toolkit, rules, directive)
        // 2. Grounding Rules
        // 3. Available Merge Fields (so LLM knows what data to reference)
        String completePrompt = aiInstructions;
        completePrompt += '\n\n' + groundingRules;
        completePrompt += '\n\n' + mergeFieldReference;

        // For meta-prompt, htmlTemplate is the LLM-generated output
        // We don't have a fixed template - the LLM creates it
        Map<String, Object> config = new Map<String, Object>{
            'promptText' => completePrompt,
            'aiInstructions' => aiInstructions,
            'groundingRules' => groundingRules,
            'htmlTemplate' => '', // LLM will generate this
            'rootObject' => rootObject,
            'version' => '2.0',
            'createdDate' => System.now().format()
        };

        return config;
    }

    /**
     * @description Builds merge field reference for meta-prompt mode
     * Shows LLM what fields are available and how to reference them
     * V2.4: Enhanced to include parent lookup fields and proper grandchild chained paths
     */
    private String buildMergeFieldReference(String rootObject, Map<String, Object> selectedFieldsRaw,
            Map<String, Object> selectedParentFieldsRaw, List<Object> selectedGrandchildrenRaw) {

        // Build grandchild lookup maps from selectedGrandchildrenRaw
        // Maps: objectName -> parentObject (e.g., OpportunityContactRole -> Opportunity)
        Map<String, String> grandchildParentMap = new Map<String, String>();
        Map<String, String> grandchildRelNameMap = new Map<String, String>(); // objectName -> relationshipName on parent
        if (selectedGrandchildrenRaw != null) {
            for (Object gcObj : selectedGrandchildrenRaw) {
                if (gcObj instanceof Map<String, Object>) {
                    Map<String, Object> gcMap = (Map<String, Object>) gcObj;
                    String objName = (String) gcMap.get('objectName');
                    String parentObj = (String) gcMap.get('parentObject');
                    String relName = (String) gcMap.get('relationshipName');
                    if (String.isNotBlank(objName) && String.isNotBlank(parentObj)) {
                        grandchildParentMap.put(objName, parentObj);
                        if (String.isNotBlank(relName)) {
                            grandchildRelNameMap.put(objName, relName);
                        }
                    }
                }
            }
        }

        String ref = '=== AVAILABLE MERGE FIELDS ===\n\n';
        ref += 'Use these merge fields to reference Salesforce data in your HTML output.\n';
        ref += 'GPTfy will substitute these with actual values at runtime.\n\n';

        // Root object fields
        if (selectedFieldsRaw.containsKey(rootObject)) {
            ref += rootObject.toUpperCase() + ' (Root Object) - use {{{FieldName}}}:\n';
            List<Object> fields = (List<Object>) selectedFieldsRaw.get(rootObject);
            for (Object field : fields) {
                ref += '  {{{' + String.valueOf(field) + '}}}\n';
            }

            // V2.4: Add parent lookup fields for root object (e.g., Owner.Name, Owner.Email)
            if (selectedParentFieldsRaw != null && selectedParentFieldsRaw.containsKey(rootObject)) {
                ref += '  -- Parent Lookups --\n';
                List<Object> parentFields = (List<Object>) selectedParentFieldsRaw.get(rootObject);
                for (Object pf : parentFields) {
                    // Convert OwnerId.Name → Owner.Name, ContactId.Title → Contact.Title
                    String convertedPath = convertLookupToRelationship(String.valueOf(pf));
                    ref += '  {{{' + convertedPath + '}}}\n';
                }
            }
            ref += '\n';
        }

        // Child and grandchild object fields
        for (String objName : selectedFieldsRaw.keySet()) {
            if (objName != rootObject) {
                List<Object> fields = (List<Object>) selectedFieldsRaw.get(objName);
                Boolean isGrandchild = grandchildParentMap.containsKey(objName);

                if (isGrandchild) {
                    // GRANDCHILD: Needs chained path like Opportunities.OpportunityContactRoles
                    String parentObjName = grandchildParentMap.get(objName);
                    String parentRelName = getRelationshipNameForObject(parentObjName, rootObject);
                    String gcRelName = grandchildRelNameMap.containsKey(objName)
                        ? grandchildRelNameMap.get(objName)
                        : getRelationshipNameForObject(objName, parentObjName);
                    String chainedPath = parentRelName + '.' + gcRelName;

                    ref += objName.toUpperCase() + ' (Grandchild of ' + parentObjName + '):\n';
                    ref += '  Nested iteration: {{#' + parentRelName + '}}{{#' + chainedPath + '}}...{{/' + chainedPath + '}}{{/' + parentRelName + '}}\n';
                    ref += '  Fields use chained path: {{{' + chainedPath + '.FieldName}}}\n';
                    for (Object field : fields) {
                        String fieldName = String.valueOf(field);
                        ref += '    {{{' + chainedPath + '.' + fieldName + '}}}\n';
                    }

                    // V2.4: Add parent lookup fields for grandchild (e.g., Contact.Name via ContactId)
                    if (selectedParentFieldsRaw != null && selectedParentFieldsRaw.containsKey(objName)) {
                        ref += '    -- Parent Lookups --\n';
                        List<Object> parentFields = (List<Object>) selectedParentFieldsRaw.get(objName);
                        for (Object pf : parentFields) {
                            String convertedPath = convertLookupToRelationship(String.valueOf(pf));
                            ref += '    {{{' + chainedPath + '.' + convertedPath + '}}}\n';
                        }
                    }
                    ref += '\n';
                } else {
                    // DIRECT CHILD: Simple relationship name
                    String relationshipName = getRelationshipNameForObject(objName, rootObject);

                    ref += objName.toUpperCase() + ' (Child) - iterate with {{#' + relationshipName + '}}...{{/' + relationshipName + '}}:\n';
                    ref += '  Start iteration: {{#' + relationshipName + '}}\n';
                    for (Object field : fields) {
                        String fieldName = String.valueOf(field);
                        ref += '    {{{' + relationshipName + '.' + fieldName + '}}}\n';
                    }

                    // V2.4: Add parent lookup fields for child object (e.g., Contact.Name via ContactId)
                    if (selectedParentFieldsRaw != null && selectedParentFieldsRaw.containsKey(objName)) {
                        ref += '    -- Parent Lookups --\n';
                        List<Object> parentFields = (List<Object>) selectedParentFieldsRaw.get(objName);
                        for (Object pf : parentFields) {
                            String convertedPath = convertLookupToRelationship(String.valueOf(pf));
                            ref += '    {{{' + relationshipName + '.' + convertedPath + '}}}\n';
                        }
                    }

                    ref += '  End iteration: {{/' + relationshipName + '}}\n';
                    ref += '  Empty check: {{^' + relationshipName + '}}No ' + objName + ' records{{/' + relationshipName + '}}\n';
                    ref += '\n';
                }
            }
        }

        // Generate dynamic example based on actual selected objects
        ref += 'EXAMPLE USAGE:\n';
        ref += '<div style="..."><h1>{{{Name}}}</h1>';

        // Use first child object for example, if available
        String exampleChild = null;
        String exampleField = null;
        for (String objName : selectedFieldsRaw.keySet()) {
            if (objName != rootObject) {
                exampleChild = getRelationshipNameForObject(objName, rootObject);
                List<Object> fields = (List<Object>) selectedFieldsRaw.get(objName);
                if (fields != null && !fields.isEmpty()) {
                    exampleField = String.valueOf(fields[0]);
                }
                break;
            }
        }

        if (String.isNotBlank(exampleChild) && String.isNotBlank(exampleField)) {
            // GPTfy requires relationship prefix: {{{Events.Subject}}} not {{{Subject}}}
            ref += '{{#' + exampleChild + '}}<div>{{{' + exampleChild + '.' + exampleField + '}}}</div>{{/' + exampleChild + '}}';
            ref += '{{^' + exampleChild + '}}<div>No records</div>{{/' + exampleChild + '}}';
        }
        ref += '</div>\n\n';

        // CRITICAL: Enforce that ONLY listed merge fields can be used
        ref += 'CRITICAL RESTRICTION:\n';
        ref += 'You may ONLY use merge fields that are explicitly listed above.\n';
        ref += 'Do NOT invent or guess merge fields. Do NOT use relationships not shown above.\n';
        ref += 'If a field or relationship is not listed, you cannot use it.\n\n';

        return ref;
    }

    /**
     * @description Gets the maximum character length for the Prompt_Command__c field
     * Uses Schema describe API to get the actual field limit
     * @return Maximum field length (typically 131072 for long text area)
     */
    private Integer getPromptCommandMaxLength() {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get('ccai__AI_Prompt__c');
            if (objType != null) {
                Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
                Schema.SObjectField field = objDescribe.fields.getMap().get('ccai__Prompt_Command__c');
                if (field != null) {
                    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                    return fieldDescribe.getLength();
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not describe ccai__AI_Prompt__c.ccai__Prompt_Command__c: ' + e.getMessage());
        }
        // Default to 131072 (128KB) for long text areas if describe fails
        return 131072;
    }

    /**
     * @description Gets relationship name for a child object
     */
    private String getRelationshipNameForObject(String childObject, String parentObject) {
        String relName = getChildRelationshipName(childObject, parentObject);
        if (String.isNotBlank(relName)) {
            return relName;
        }
        // Fallback: simple pluralization
        if (childObject.endsWith('y')) {
            return childObject.substring(0, childObject.length() - 1) + 'ies';
        }
        return childObject + 's';
    }

    /**
     * @description Builds a human-readable assembly summary
     * @param aiInstructions AI instructions section
     * @param htmlTemplate HTML template
     * @param groundingRules Grounding rules section
     * @param validatedFields List of validated merge fields
     * @return Formatted summary string
     */
    private String buildAssemblySummary(
            String aiInstructions,
            String htmlTemplate,
            String groundingRules,
            List<MergeFieldValidator.MergeField> validatedFields) {

        Integer instructionsLength = aiInstructions.length();
        Integer templateLength = htmlTemplate.length();
        Integer rulesLength = groundingRules.length();
        Integer totalLength = instructionsLength + templateLength + rulesLength;

        Integer validFieldCount = 0;
        for (MergeFieldValidator.MergeField field : validatedFields) {
            if (field.isValid) {
                validFieldCount++;
            }
        }

        String summary = 'Prompt assembled: ';
        summary += totalLength + ' characters total (';
        summary += 'Instructions: ' + instructionsLength + ', ';
        summary += 'Template: ' + templateLength + ', ';
        summary += 'Rules: ' + rulesLength + '), ';
        summary += validFieldCount + ' of ' + validatedFields.size() + ' merge fields validated';

        return summary;
    }

    /**
     * @description Builds DCM configuration for Stage 9
     * Now supports grandchildren with parentObject field
     * IMPORTANT: Uses selectedObjects (from Stage 3) to ensure ALL child relationships
     * are included in DCM, even if they don't have data for the specific sample record.
     * This ensures DCM Detail records are created for all potential child relationships.
     * @param rootObject The root Salesforce object
     * @param selectedFieldsRaw Map of object to field list
     * @param inputs Full inputs for additional context
     * @return Map with DCM configuration
     */
    private Map<String, Object> buildDCMConfigForStage9(
            String rootObject,
            Map<String, Object> selectedFieldsRaw,
            Map<String, Object> inputs) {

        // Get prompt name from run record or inputs
        String promptName = (String) inputs.get('promptName');
        if (String.isBlank(promptName)) {
            promptName = rootObject + ' Summary DCM';
        }

        // Get grandchild info from inputs (passed from Stage 3 -> Stage 4 -> Stage 5...)
        Set<String> grandchildObjectNames = new Set<String>();
        Map<String, String> grandchildParentMap = new Map<String, String>(); // objectName -> parentObject
        Map<String, String> grandchildRelFieldMap = new Map<String, String>(); // objectName -> relationshipField

        Object gcRaw = inputs.get('selectedGrandchildren');
        if (gcRaw != null && gcRaw instanceof List<Object>) {
            for (Object gcObj : (List<Object>) gcRaw) {
                if (gcObj instanceof Map<String, Object>) {
                    Map<String, Object> gcMap = (Map<String, Object>) gcObj;
                    String objName = (String) gcMap.get('objectName');
                    grandchildObjectNames.add(objName);
                    grandchildParentMap.put(objName, (String) gcMap.get('parentObject'));
                    grandchildRelFieldMap.put(objName, (String) gcMap.get('relationshipField'));
                }
            }
        }

        // Build child objects list with relationship detection
        List<Map<String, Object>> childObjects = new List<Map<String, Object>>();

        // Build fields by object from selectedFieldsRaw
        Map<String, List<String>> fieldsByObject = new Map<String, List<String>>();
        for (String objectName : selectedFieldsRaw.keySet()) {
            List<Object> fieldsRaw = (List<Object>) selectedFieldsRaw.get(objectName);
            List<String> fields = new List<String>();
            for (Object field : fieldsRaw) {
                fields.add(String.valueOf(field));
            }
            // CRITICAL: Skip objects that have no meaningful fields.
            // Prevents creating DCM details that provide no context (e.g., objects with only Id / *Id fields).
            if (objectName != rootObject && !hasMinimumMeaningfulFields(fields)) {
                continue;
            }
            fieldsByObject.put(objectName, fields);
        }

        // NOTE: selectedParentFields are NOT added to DCM fieldsByObject.
        // Parent lookup syntax (e.g., {{{Owner.Name}}}, {{{Contact.Name}}}) is only for the prompt template.
        // GPTfy resolves parent lookups at runtime from Salesforce schema - no DCM configuration needed.
        // The parent fields are used in buildMergeFieldReference() for the prompt, not here.

        // Build child objects ONLY from selectedFields (objects that actually have usable context).
        // This mirrors the shell script behavior: Stage 4 filters to non-empty objects, and DCM config
        // should not include empty/low-signal objects.
        Set<String> processedObjects = new Set<String>();
        Set<String> skippedObjects = new Set<String>();

        // First, add objects from selectedFieldsRaw (they have fields selected)
        for (String objectName : selectedFieldsRaw.keySet()) {
            if (objectName != rootObject && !processedObjects.contains(objectName)) {
                // Skip if Stage 5 produced only ID-like fields (no meaningful context)
                if (!fieldsByObject.containsKey(objectName)) {
                    skippedObjects.add(objectName);
                    continue;
                }
                Map<String, Object> childConfig = buildChildObjectConfig(
                    objectName, rootObject, grandchildObjectNames,
                    grandchildParentMap, grandchildRelFieldMap);

                // Only add if valid relationship exists (buildChildObjectConfig returns null if not)
                if (childConfig != null) {
                    childObjects.add(childConfig);
                    processedObjects.add(objectName);
                } else {
                    skippedObjects.add(objectName);
                }
            }
        }

        // Log skipped objects for debugging
        if (!skippedObjects.isEmpty()) {
            System.debug('Stage8: Skipped objects without valid relationships: ' + skippedObjects);
        }

        return new Map<String, Object>{
            'name' => promptName + ' DCM',
            'rootObject' => rootObject,
            'childObjects' => childObjects,
            'fieldsByObject' => fieldsByObject
        };
    }

    /**
     * @description Builds configuration for a single child object
     * @param objectName Name of the child object
     * @param rootObject Name of the root object
     * @param grandchildObjectNames Set of grandchild object names
     * @param grandchildParentMap Map of grandchild to parent object
     * @param grandchildRelFieldMap Map of grandchild to relationship field
     * @return Configuration map for the child object
     */
    private Map<String, Object> buildChildObjectConfig(
            String objectName,
            String rootObject,
            Set<String> grandchildObjectNames,
            Map<String, String> grandchildParentMap,
            Map<String, String> grandchildRelFieldMap) {

        // Determine the parent for this object (root or intermediate parent for grandchildren)
        String parentForRelationship = rootObject;
        Boolean isGrandchild = grandchildObjectNames.contains(objectName);
        if (isGrandchild) {
            parentForRelationship = grandchildParentMap.get(objectName);
        }

        // Get the ACTUAL relationship name from Salesforce schema
        String actualRelationshipName = getChildRelationshipName(objectName, parentForRelationship);

        // If no valid relationship found, return null to skip this object
        if (String.isBlank(actualRelationshipName)) {
            System.debug('Stage8: Skipping object ' + objectName + ' - no valid relationship to ' + parentForRelationship);
            return null;
        }

        Map<String, Object> childConfig = new Map<String, Object>{
            'objectName' => objectName,
            'relationshipName' => actualRelationshipName,
            'maxRecords' => 10
        };

        // Check if this is a grandchild (has parentObject)
        if (isGrandchild) {
            childConfig.put('parentObject', grandchildParentMap.get(objectName));
            childConfig.put('relationshipField', grandchildRelFieldMap.get(objectName));
        } else {
            // Direct child - relationship to root
            childConfig.put('relationshipField', getRelationshipField(objectName, rootObject));
        }

        return childConfig;
    }

    /**
     * @description Gets the relationship field for a child object to the parent
     * @param childObject The child object API name
     * @param parentObject The parent object API name
     * @return The relationship field name (e.g., AccountId)
     */
    private String getRelationshipField(String childObject, String parentObject) {
        // Use DCMBuilder's auto-detection if available
        DCMBuilder.RelationshipDetectionResult detection =
            DCMBuilder.detectRelationshipField(childObject, parentObject);
        if (detection != null) {
            return detection.relationshipField;
        }

        // Fallback to standard pattern
        return parentObject + 'Id';
    }

    /**
     * @description Gets the ACTUAL child relationship name from Salesforce schema
     * @param childObject The child object API name
     * @param parentObject The parent object API name
     * @return The relationship name from schema, or null if no valid relationship exists
     */
    private String getChildRelationshipName(String childObject, String parentObject) {
        // Get actual relationship name from Salesforce schema
        List<SchemaHelper.ChildRelationship> childRels = SchemaHelper.getChildRelationships(parentObject);

        for (SchemaHelper.ChildRelationship rel : childRels) {
            if (rel.childObject == childObject && String.isNotBlank(rel.relationshipName)) {
                return rel.relationshipName;
            }
        }

        // Return null if no valid relationship found - caller should handle this
        return null;
    }

    /**
     * @description Checks if a child object has a valid queryable relationship to the parent
     * @param childObject The child object API name
     * @param parentObject The parent object API name
     * @return true if a valid relationship exists
     */
    private Boolean hasValidRelationship(String childObject, String parentObject) {
        List<SchemaHelper.ChildRelationship> childRels = SchemaHelper.getChildRelationships(parentObject);

        for (SchemaHelper.ChildRelationship rel : childRels) {
            if (rel.childObject == childObject && String.isNotBlank(rel.relationshipName)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Converts lookup field path to relationship name path
     * V2.4: Used for parent field integration from Stage 5 traversals
     * Examples:
     *   "ContactId.Name" -> "Contact.Name"
     *   "OwnerId.Email" -> "Owner.Email"
     *   "Custom_Lookup__c.Name" -> "Custom_Lookup__r.Name"
     * @param fieldPath The lookup field path (e.g., "ContactId.Name")
     * @return The relationship name path (e.g., "Contact.Name")
     */
    private String convertLookupToRelationship(String fieldPath) {
        if (String.isBlank(fieldPath) || !fieldPath.contains('.')) {
            return fieldPath;
        }

        List<String> parts = fieldPath.split('\\.');
        if (parts.size() < 2) {
            return fieldPath;
        }

        String lookupField = parts[0];
        String relationshipName;

        // Convert lookup field to relationship name
        if (lookupField.endsWith('__c')) {
            // Custom lookup: My_Lookup__c -> My_Lookup__r
            relationshipName = lookupField.removeEnd('__c') + '__r';
        } else if (lookupField.endsWith('Id')) {
            // Standard lookup: ContactId -> Contact, OwnerId -> Owner
            relationshipName = lookupField.removeEnd('Id');
        } else {
            // Already a relationship name or unknown format
            relationshipName = lookupField;
        }

        // Rebuild the path with relationship name
        parts[0] = relationshipName;
        return String.join(parts, '.');
    }

    /**
     * @description Returns true if the object has minimum meaningful fields.
     * "Meaningful" excludes Id and all *Id / *ById fields, since those do not provide LLM context.
     */
    private Boolean hasMinimumMeaningfulFields(List<String> fields) {
        if (fields == null || fields.isEmpty()) {
            return false;
        }
        Integer meaningful = 0;
        for (String f : fields) {
            if (String.isBlank(f)) continue;
            if (f == 'Id') continue;
            if (f.endsWith('Id')) continue;
            if (f.endsWith('ById')) continue;
            meaningful++;
        }
        // Keep this aligned with Stage05_FieldSelection.MIN_MEANINGFUL_FIELDS
        return meaningful >= 3;
    }

    /**
     * @description Builds Prompt configuration for Stage 9
     * V2.0: In meta-prompt mode, the promptCommand contains the full meta-prompt
     * and htmlTemplate is empty (LLM generates the HTML structure)
     * @param rootObject The root Salesforce object
     * @param aiInstructions AI instructions section (or full meta-prompt in V2.0)
     * @param htmlTemplate HTML template with merge fields (empty in V2.0 meta-prompt mode)
     * @param groundingRules Grounding rules for AI behavior
     * @param inputs Full inputs for additional context
     * @return Map with Prompt configuration
     */
    private Map<String, Object> buildPromptConfigForStage9(
            String rootObject,
            String aiInstructions,
            String htmlTemplate,
            String groundingRules,
            Map<String, Object> inputs) {

        // Get prompt name from run record or inputs
        String promptName = (String) inputs.get('promptName');
        if (String.isBlank(promptName)) {
            promptName = rootObject + ' Summary';
        }

        String businessContext = (String) inputs.get('businessContext');

        // V2.0: Check if using meta-prompt mode
        Boolean useMetaPrompt = (Boolean) inputs.get('useMetaPrompt');
        if (useMetaPrompt == null) {
            useMetaPrompt = false;
        }

        // In meta-prompt mode, the promptCommand IS the complete prompt
        // (includes merge field reference at the end)
        // htmlTemplate is not used - LLM generates structure from instructions
        String finalPromptCommand;
        String finalHtmlTemplate;

        if (useMetaPrompt) {
            // V2.0: Full meta-prompt with merge field reference
            // V2.4: Include parent lookup fields and grandchildren for merge field documentation
            Map<String, Object> selectedFieldsRaw = (Map<String, Object>) inputs.get('selectedFields');
            Map<String, Object> selectedParentFieldsRaw = (Map<String, Object>) inputs.get('selectedParentFields');
            if (selectedParentFieldsRaw == null) {
                selectedParentFieldsRaw = new Map<String, Object>();
            }
            List<Object> selectedGrandchildrenRaw = (List<Object>) inputs.get('selectedGrandchildren');
            if (selectedGrandchildrenRaw == null) {
                selectedGrandchildrenRaw = new List<Object>();
            }
            finalPromptCommand = aiInstructions + '\n\n' + groundingRules + '\n\n' +
                                buildMergeFieldReference(rootObject, selectedFieldsRaw, selectedParentFieldsRaw, selectedGrandchildrenRaw);
            // Empty template - LLM generates the HTML
            finalHtmlTemplate = '';
        } else {
            // V1.1: Traditional approach with fixed template
            finalPromptCommand = aiInstructions;
            finalHtmlTemplate = htmlTemplate;
        }

        // V2.0: Extract LLM-generated metadata from analysisBrief (Stage 7)
        String promptDescription;
        String promptHowItWorks;

        if (useMetaPrompt) {
            Map<String, Object> analysisBrief = (Map<String, Object>) inputs.get('analysisBrief');
            if (analysisBrief != null) {
                promptDescription = (String) analysisBrief.get('promptDescription');
                promptHowItWorks = (String) analysisBrief.get('promptHowItWorks');
            }
        }

        // Fallback descriptions if not provided by LLM
        if (String.isBlank(promptDescription)) {
            promptDescription = 'AI-powered ' + rootObject + ' analysis providing actionable insights';
            if (String.isNotBlank(businessContext) && promptDescription.length() + businessContext.length() < 250) {
                promptDescription += ': ' + businessContext.left(200);
            }
            promptDescription += '.';
        }

        // Ensure description fits in 255 chars (final safety check)
        if (promptDescription.length() > 255) {
            promptDescription = promptDescription.substring(0, 252) + '...';
        }

        Map<String, Object> config = new Map<String, Object>{
            'name' => promptName,
            'label' => promptName,
            'description' => promptDescription,
            'promptCommand' => finalPromptCommand,
            'htmlTemplate' => finalHtmlTemplate,
            // V2.0: In meta-prompt mode, grounding rules are already embedded in promptCommand
            // Don't pass separately to avoid duplication in PromptBuilder
            'groundingRules' => useMetaPrompt ? '' : groundingRules,
            'targetObject' => rootObject,
            'promptType' => 'Text',
            'modelName' => 'claude-sonnet-4.5',
            'maxTokens' => 4096,
            'temperature' => 1.0
        };

        // V2.0: Add howItWorks if available
        if (String.isNotBlank(promptHowItWorks)) {
            config.put('howItWorks', promptHowItWorks);
        }

        return config;
    }

    // ========================================================================
    // META-PROMPT ASSEMBLY (V2.0)
    // ========================================================================

    /**
     * @description Builds meta-prompt with 6 sections (V2.0 architecture)
     * Transforms LLM from "template filler" to "business analyst"
     */
    private String buildMetaPrompt(
            String businessContext,
            String targetPersona,
            List<Object> businessObjectivesRaw,
            String rootObject,
            String companyProfile,
            String strategicInsights,
            String industryContext,
            Object multiSampleProfileRaw,
            Map<String, Object> selectedFieldsRaw,
            Id runId,
            StageResult result) {

        result.queueInfo(runId, STAGE_NUMBER, 'Building meta-prompt (V2.0)');

        String metaPrompt = '';

        // Section 1: ROLE
        metaPrompt += buildRoleSection(targetPersona);

        // Section 2: DATA PAYLOAD
        metaPrompt += buildDataPayloadSection(multiSampleProfileRaw, rootObject, selectedFieldsRaw);

        // Section 3: ANALYSIS PRINCIPLES
        metaPrompt += buildAnalysisPrinciplesSection(rootObject, runId);

        // Section 4: UI TOOLKIT
        metaPrompt += buildUIToolkitSection();

        // Section 5: OUTPUT RULES (V2.4: Load from builder)
        metaPrompt += buildOutputRulesSection(runId);

        // Section 6: DIRECTIVE
        metaPrompt += buildDirectiveSection(rootObject, businessContext);

        result.queueInfo(runId, STAGE_NUMBER,
            'Meta-prompt built: ' + metaPrompt.length() + ' chars');

        return metaPrompt;
    }

    /**
     * @description Section 1: ROLE - Defines LLM as business analyst
     */
    private String buildRoleSection(String targetPersona) {
        String section = '=== YOUR ROLE ===\n\n';
        section += 'You are an expert business analyst creating an executive dashboard for ' + targetPersona + '.\n\n';
        section += 'Your job is NOT to display data tables. Your job is to:\n';
        section += '- ANALYZE the Salesforce data provided\n';
        section += '- IDENTIFY patterns, risks, and opportunities\n';
        section += '- PRESENT insights that drive action\n';
        section += '- RECOMMEND specific next steps\n\n';
        section += 'Think like a consultant presenting to a senior executive.\n\n';
        return section;
    }

    /**
     * @description Section 2: DATA PAYLOAD - Multi-sample context and patterns
     */
    private String buildDataPayloadSection(
            Object multiSampleProfileRaw,
            String rootObject,
            Map<String, Object> selectedFieldsRaw) {

        String section = '=== DATA CONTEXT ===\n\n';

        if (multiSampleProfileRaw != null) {
            // Multi-sample: show patterns
            Map<String, Object> profile = (Map<String, Object>) multiSampleProfileRaw;
            Integer sampleCount = (Integer) profile.get('sampleCount');

            section += 'Analyzed ' + sampleCount + ' ' + rootObject + ' records to understand data patterns.\n\n';

            // Add patterns if available
            List<Object> patterns = (List<Object>) profile.get('patterns');
            if (patterns != null && !patterns.isEmpty()) {
                section += 'KEY PATTERNS DETECTED:\n';
                for (Object patternObj : patterns) {
                    Map<String, Object> pattern = (Map<String, Object>) patternObj;
                    String severity = (String) pattern.get('severity');
                    String description = (String) pattern.get('description');
                    section += '- [' + severity + '] ' + description + '\n';
                }
                section += '\n';
            }

            // Add object aggregations
            Map<String, Object> aggregations = (Map<String, Object>) profile.get('objectAggregations');
            if (aggregations != null && !aggregations.isEmpty()) {
                section += 'OBJECT AVAILABILITY:\n';
                for (String objName : aggregations.keySet()) {
                    Map<String, Object> agg = (Map<String, Object>) aggregations.get(objName);
                    Integer samplesWithData = (Integer) agg.get('samplesWithData');
                    Decimal avgCount = (Decimal) agg.get('avgCount');
                    section += '- ' + objName + ': Present in ' + samplesWithData + '/' + sampleCount +
                              ' samples (avg ' + avgCount.setScale(1) + ' records)\n';
                }
                section += '\n';
            }
        } else {
            // Single sample: simplified context
            section += 'Analyzing ' + rootObject + ' record data.\n\n';
        }

        // Add available fields summary
        if (selectedFieldsRaw != null && !selectedFieldsRaw.isEmpty()) {
            section += 'DATA FIELDS AVAILABLE:\n';
            for (String objName : selectedFieldsRaw.keySet()) {
                List<Object> fields = (List<Object>) selectedFieldsRaw.get(objName);
                if (fields != null && !fields.isEmpty()) {
                    section += '- ' + objName + ': ' + fields.size() + ' fields\n';
                }
            }
            section += '\n';
        }

        return section;
    }

    /**
     * @description Section 3: ANALYSIS PRINCIPLES - Compressed builders
     */
    private String buildAnalysisPrinciplesSection(String rootObject, Id runId) {
        String section = '=== ANALYSIS PRINCIPLES ===\n\n';
        section += 'Apply these principles when analyzing the data:\n\n';

        // Load compressed builders
        String qualityRules = loadCompressedQualityRules(runId);
        if (String.isNotBlank(qualityRules)) {
            section += qualityRules + '\n\n';
        }

        String patterns = loadCompressedPatterns(rootObject, runId);
        if (String.isNotBlank(patterns)) {
            section += patterns + '\n\n';
        }

        return section;
    }

    /**
     * @description Section 4: UI TOOLKIT - Available components
     * V2.1: Now queries UI Component builders for actual HTML snippets
     */
    private String buildUIToolkitSection() {
        String section = '=== UI TOOLKIT ===\n\n';
        section += 'You have these components available. Use them strategically.\n\n';

        // V2.1: Query UI Component builders for actual HTML templates
        List<ccai__AI_Prompt__c> uiComponents = queryUIComponentBuilders();

        if (!uiComponents.isEmpty()) {
            // Use dynamic components from database
            section += 'AVAILABLE COMPONENTS (use these HTML patterns):\n\n';
            for (ccai__AI_Prompt__c component : uiComponents) {
                section += '--- ' + component.Name + ' ---\n';
                if (String.isNotBlank(component.ccai__Description__c)) {
                    section += 'When to use: ' + component.ccai__Description__c + '\n';
                }
                section += 'HTML Pattern:\n';
                section += component.ccai__Prompt_Command__c + '\n\n';
            }
        } else {
            // Fallback to actual HTML patterns if no components in database
            section += 'LAYOUT COMPONENTS:\n\n';

            section += '--- Stats Strip (use at top for key metrics) ---\n';
            section += '<div style="display:flex;gap:16px;margin-bottom:20px;"><div style="flex:1;background:white;border-radius:6px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="font-size:28px;font-weight:700;color:#0176D3;margin-bottom:4px;">{{{Value}}}</div><div style="font-size:13px;color:#706E6B;">Label</div></div></div>\n\n';

            section += '--- Section Card ---\n';
            section += '<div style="background:white;border-radius:8px;padding:20px;margin-bottom:16px;box-shadow:0 2px 4px rgba(0,0,0,0.1);"><h2 style="margin:0 0 16px 0;font-size:18px;font-weight:600;color:#181818;">Section Title</h2><!-- Content here --></div>\n\n';

            section += 'INSIGHT COMPONENTS:\n\n';

            section += '--- Critical Alert (RED) ---\n';
            section += '<div style="background:#FED7D7;border-left:4px solid #BA0517;padding:12px 16px;border-radius:4px;margin-bottom:12px;"><div style="font-weight:600;color:#BA0517;margin-bottom:4px;">Critical Issue</div><div style="color:#54514C;">Description with evidence</div></div>\n\n';

            section += '--- Warning Alert (ORANGE) ---\n';
            section += '<div style="background:#FEF3CD;border-left:4px solid #DD7A01;padding:12px 16px;border-radius:4px;margin-bottom:12px;"><div style="font-weight:600;color:#DD7A01;margin-bottom:4px;">Warning</div><div style="color:#54514C;">Description with evidence</div></div>\n\n';

            section += '--- Info Alert (BLUE) ---\n';
            section += '<div style="background:#D7E9FC;border-left:4px solid #0176D3;padding:12px 16px;border-radius:4px;margin-bottom:12px;"><div style="font-weight:600;color:#0176D3;margin-bottom:4px;">Information</div><div style="color:#54514C;">Description with evidence</div></div>\n\n';

            section += '--- Insight Card ---\n';
            section += '<div style="background:white;border-radius:6px;padding:16px;margin-bottom:12px;border:1px solid #DDDBDA;"><div style="font-weight:600;color:#181818;margin-bottom:8px;">Finding Title</div><div style="color:#706E6B;margin-bottom:12px;line-height:1.5;">Analysis with evidence</div><div style="font-size:12px;color:#706E6B;"><strong>Evidence:</strong> specific data points</div></div>\n\n';

            section += '--- Recommendation Card ---\n';
            section += '<div style="background:#FFFFFF;border-left:4px solid #2E844A;border-radius:6px;padding:16px;margin-bottom:12px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;"><div style="font-weight:600;color:#181818;">Action</div><div style="background:#DD7A01;color:white;padding:4px 12px;border-radius:12px;font-size:11px;font-weight:600;">URGENT</div></div><div style="color:#706E6B;margin-bottom:12px;line-height:1.5;">Specific action description</div><div style="font-size:12px;color:#706E6B;"><strong>Why:</strong> Rationale</div></div>\n\n';

            section += '--- Health Score ---\n';
            section += '<div style="display:flex;align-items:center;gap:12px;"><div style="font-size:36px;font-weight:700;color:#2E844A;">85</div><div><div style="font-size:14px;font-weight:600;color:#181818;">Health Score</div><div style="width:200px;height:8px;background:#E0E0E0;border-radius:4px;overflow:hidden;"><div style="width:85%;height:100%;background:#2E844A;"></div></div></div></div>\n\n';
        }

        section += 'COMPONENT USAGE RULES:\n';
        section += '- Lead with insights (Alert Boxes, Insight Cards) not tables\n';
        section += '- Use Stats Strip for key metrics at the top\n';
        section += '- Tables should be LAST, not first - and only if data warrants\n';
        section += '- Every section should have analysis text, not just data\n\n';

        return section;
    }

    /**
     * @description Query UI Component builders from database
     * @return List of active UI Component builder prompts with HTML templates
     */
    private List<ccai__AI_Prompt__c> queryUIComponentBuilders() {
        try {
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();

            return [
                SELECT Id, Name, ccai__Prompt_Command__c, ccai__Description__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND ccai__Type__c = 'UI Component'
                  AND ccai__Status__c = 'Active'
                ORDER BY Name
                LIMIT 20
            ];
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to query UI Component builders: ' + e.getMessage());
            return new List<ccai__AI_Prompt__c>();
        }
    }

    /**
     * @description Section 5: OUTPUT RULES - GPTfy compliance
     * V2.4: Now loads merge field syntax from Output Rules builder
     */
    private String buildOutputRulesSection(Id runId) {
        String section = '=== OUTPUT RULES ===\n\n';
        section += 'CRITICAL GPTfy REQUIREMENTS:\n';
        section += '1. **SINGLE-LINE HTML ONLY** - Your ENTIRE output must be ONE continuous line with NO newlines, line breaks, or \\n characters. Compress all HTML into a single line.\n';
        section += '2. Inline styles only - no CSS classes or style blocks\n';
        section += '3. No scripts or event handlers\n';
        section += '4. Start with <div style="..." and end with </div>\n';
        section += '5. No emojis or special characters\n';
        section += '6. No placeholders, TBD, TODO markers\n\n';
        section += 'SINGLE-LINE HTML ENFORCEMENT:\n';
        section += '- Remove ALL newlines and line breaks from your HTML\n';
        section += '- Use single spaces between tags: </div><div> NOT </div>\\n<div>\n';
        section += '- Do NOT format for readability - format for GPTfy compliance\n';
        section += '- Example: <div style="padding:20px;"><h2>Title</h2><p>Content</p></div>\n\n';

        // V2.4: Load merge field syntax from Output Rules builder
        String outputRules = loadOutputRules(runId);
        if (String.isNotBlank(outputRules)) {
            section += outputRules + '\n\n';
        } else {
            // Fallback to hardcoded syntax if builder not found
            section += 'MERGE FIELD SYNTAX:\n';
            section += '- Root object fields: {{{FieldName}}}\n';
            section += '- Parent lookup fields: {{{Relationship.Field}}} (e.g., {{{Account.Name}}})\n';
            section += '- Child iteration: {{#Collection}}...{{/Collection}}\n';
            section += '- Child fields (inside iteration): {{{Collection.FieldName}}} (e.g., {{{Events.Subject}}})\n';
            section += '- Empty check: {{^Collection}}No items{{/Collection}}\n\n';
        }

        section += 'STYLING:\n';
        section += '- Font: Salesforce Sans, system fonts fallback\n';
        section += '- Colors: Primary #0176D3, Success #2E844A, Warning #DD7A01, Error #BA0517\n';
        section += '- Background: #F3F3F3, Cards: #FFFFFF, Border: #DDDBDA\n\n';

        return section;
    }

    /**
     * @description Section 6: DIRECTIVE - Analysis instructions
     */
    private String buildDirectiveSection(String rootObject, String businessContext) {
        String section = '=== YOUR DIRECTIVE ===\n\n';
        section += 'Analyze the ' + rootObject + ' data and generate an executive dashboard.\n\n';

        if (String.isNotBlank(businessContext)) {
            section += 'SPECIFIC REQUIREMENTS:\n' + businessContext + '\n\n';
        }

        section += 'STRUCTURE YOUR OUTPUT AS:\n';
        section += '1. EXECUTIVE SUMMARY (2-3 sentences)\n';
        section += '   - Overall health/status assessment\n';
        section += '   - Biggest risk and biggest opportunity\n';
        section += '   - Recommended immediate action\n\n';

        section += '2. KEY INSIGHTS (3-5 findings)\n';
        section += '   - Use Insight Cards with evidence citations\n';
        section += '   - Prioritize by business impact\n';
        section += '   - Include specific data points\n\n';

        section += '3. RECOMMENDED ACTIONS (2-4 items)\n';
        section += '   - Use Recommendation Cards\n';
        section += '   - Be specific: "Schedule call with {{{Contact.Name}}}" not "Follow up"\n';
        section += '   - Include urgency indicator\n\n';

        section += '4. SUPPORTING DATA (if warranted)\n';
        section += '   - Tables for detailed records ONLY if adds value\n';
        section += '   - ONLY use child objects listed in AVAILABLE MERGE FIELDS section\n';
        section += '   - Do NOT create tables for objects not in the merge field reference\n';
        section += '   - Keep tables compact (5-7 rows max)\n';
        section += '   - Add context paragraph before each table\n\n';

        section += 'VISUAL DIVERSITY REQUIREMENT:\n';
        section += '- MUST use colored components (red/orange/blue alerts, colored borders)\n';
        section += '- MUST use Stats Strip at the top for key metrics\n';
        section += '- MUST vary component types (mix alerts, insight cards, recommendation cards)\n';
        section += '- Avoid repetitive layouts - use visual hierarchy\n\n';

        section += 'PERSONALIZATION REQUIREMENT:\n';
        section += '- Always use actual names, not titles or roles\n';
        section += '- Say "Sarah Johnson" not "the CFO"\n';
        section += '- Say "John Smith at Acme Corp" not "the customer"\n';
        section += '- Use merge fields: {{{Contact.Name}}}, {{{Account.Name}}}, {{{Owner.Name}}}\n\n';

        section += 'QUALITY CHECKLIST:\n';
        section += '[ ] Does the summary capture the key story?\n';
        section += '[ ] Does every insight cite specific evidence?\n';
        section += '[ ] Are recommendations specific and actionable?\n';
        section += '[ ] Is the layout insight-first, not table-first?\n';
        section += '[ ] Did I use colored alerts and stats strip?\n';
        section += '[ ] Did I use actual names instead of titles?\n';
        section += '[ ] Did I ONLY use merge fields from the AVAILABLE MERGE FIELDS list?\n';
        section += '[ ] Would an executive find this valuable?\n\n';

        section += 'Generate the dashboard now. Output raw HTML only.\n\n';

        return section;
    }

    /**
     * @description Load compressed quality rules (principles only)
     */
    private String loadCompressedQualityRules(Id runId) {
        // For MVP, look for compressed builders and prefer them over verbose ones
        // Query all active quality rules, order by name so compressed versions appear first
        List<ccai__AI_Prompt__c> builders = [
            SELECT ccai__Prompt_Command__c, Name
            FROM ccai__AI_Prompt__c
            WHERE RecordType.DeveloperName = 'Builder'
              AND ccai__Type__c = 'Quality Rule'
              AND ccai__Status__c = 'Active'
            ORDER BY Name ASC
            LIMIT 10
        ];

        if (builders.isEmpty()) {
            return '';
        }

        String content = 'QUALITY RULES:\n';
        // Prefer compressed versions - use first one found with (Compressed) in name
        for (ccai__AI_Prompt__c builder : builders) {
            if (builder.Name.contains('Compressed')) {
                content += builder.ccai__Prompt_Command__c + '\n\n';
                return content; // Return early with compressed version
            }
        }

        // No compressed version found - use first available
        content += builders[0].ccai__Prompt_Command__c + '\n\n';
        return content;
    }

    /**
     * @description Load compressed patterns (principles only)
     */
    private String loadCompressedPatterns(String rootObject, Id runId) {
        // For MVP, look for compressed patterns matching rootObject or global (null Object)
        // Query all active patterns and filter in Apex for null handling
        List<ccai__AI_Prompt__c> builders = [
            SELECT ccai__Prompt_Command__c, Name, ccai__Object__c
            FROM ccai__AI_Prompt__c
            WHERE RecordType.DeveloperName = 'Builder'
              AND ccai__Type__c = 'Pattern'
              AND ccai__Status__c = 'Active'
            ORDER BY Name ASC
            LIMIT 10
        ];

        if (builders.isEmpty()) {
            return '';
        }

        String content = '';
        // First pass: look for compressed version matching rootObject or global
        for (ccai__AI_Prompt__c builder : builders) {
            Boolean isMatchingObject = (builder.ccai__Object__c == rootObject || builder.ccai__Object__c == null);
            if (isMatchingObject && builder.Name.contains('Compressed')) {
                content += builder.ccai__Prompt_Command__c + '\n\n';
                return content; // Return early with first compressed match
            }
        }

        // Second pass: if no compressed found, use first non-compressed matching object
        for (ccai__AI_Prompt__c builder : builders) {
            Boolean isMatchingObject = (builder.ccai__Object__c == rootObject || builder.ccai__Object__c == null);
            if (isMatchingObject) {
                content += builder.ccai__Prompt_Command__c + '\n\n';
                return content;
            }
        }

        return content;
    }

    // =========================================================================
    // V2.5: TWO-LAYER META-PROMPT ARCHITECTURE
    // =========================================================================
    // These methods implement the two-layer approach where:
    // - Layer 1 (Meta-Prompt): Generates deterministic TEMPLATE with merge fields
    // - Layer 2 (Execution): Fills template with actual data
    //
    // This differs from V2.0 which has LLM analyze data directly to generate HTML.
    // =========================================================================

    /**
     * @description Load Meta-Prompt Builder record for V2.5 architecture
     * Queries ccai__AI_Prompt__c with RecordType='Builder' and Type='Meta Prompt'
     * @return String The meta-prompt content from Builder record
     */
    private String loadMetaPromptBuilder() {
        List<ccai__AI_Prompt__c> builders = [
            SELECT ccai__Prompt_Command__c, Name, ccai__Description__c
            FROM ccai__AI_Prompt__c
            WHERE RecordType.DeveloperName = 'Builder'
              AND ccai__Type__c = 'Context Template' // TODO: Change to 'Meta Prompt' after picklist value added
              AND Name = 'GPTfy Prompt Generation Framework v2.5'
              AND ccai__Status__c = 'Active'
            LIMIT 1
        ];

        if (builders.isEmpty()) {
            throw new StageException('Meta-Prompt Builder not found. Expected: GPTfy Prompt Generation Framework v2.5');
        }

        return builders[0].ccai__Prompt_Command__c;
    }

    /**
     * @description Analyze DCM structure and format for meta-prompt injection
     * Categorizes fields by type (metrics, dates, statuses, identifiers, parentFields)
     * and creates narrative description for LLM context
     *
     * @param dcmConfig Map containing DCM configuration from Stage 9
     * @param selectedFields Map of object -> field list
     * @param selectedParentFields Map of object -> parent field list
     * @param selectedGrandchildren List of grandchild objects
     * @return Map<String, Object> with keys: 'json' (structured analysis), 'narrative' (text description)
     */
    private Map<String, Object> analyzeDCMStructure(
            Map<String, Object> dcmConfig,
            Map<String, Object> selectedFields,
            Map<String, Object> selectedParentFields,
            List<Object> selectedGrandchildren) {

        // Extract DCM metadata
        String rootObject = (String) dcmConfig.get('objectName');
        List<Object> childObjectsRaw = (List<Object>) dcmConfig.get('childRelationships');

        // Build structured JSON analysis
        Map<String, Object> analysis = new Map<String, Object>();
        analysis.put('rootObject', rootObject);
        analysis.put('childObjects', childObjectsRaw != null ? childObjectsRaw : new List<Object>());
        analysis.put('grandchildObjects', selectedGrandchildren != null ? selectedGrandchildren : new List<Object>());
        analysis.put('parentLookups', extractParentLookupNames(selectedParentFields));

        // Categorize fields by object
        Map<String, Object> fieldsByObject = new Map<String, Object>();
        for (String objName : selectedFields.keySet()) {
            Map<String, List<String>> categorized = categorizeFields(
                objName,
                (List<Object>) selectedFields.get(objName),
                selectedParentFields.get(objName) != null ? (List<Object>) selectedParentFields.get(objName) : new List<Object>()
            );
            fieldsByObject.put(objName, categorized);
        }
        analysis.put('fields', fieldsByObject);

        // Build narrative description
        String narrative = buildDCMNarrative(
            rootObject,
            (List<Object>) analysis.get('childObjects'),
            (List<Object>) analysis.get('grandchildObjects'),
            (List<String>) analysis.get('parentLookups'),
            fieldsByObject
        );
        analysis.put('narrative', narrative);

        // Return both JSON and narrative
        Map<String, Object> result = new Map<String, Object>();
        result.put('json', JSON.serialize(analysis, true)); // Pretty-print JSON
        result.put('narrative', narrative);
        result.put('structured', analysis); // For validation later

        return result;
    }

    /**
     * @description Get child object names from selectedFields
     * Example: {'Opportunity': [...], 'Task': [...], 'Event': [...]} → ['Task', 'Event']
     * Returns List<Object> for compatibility with analyzeDCMStructure
     */
    private List<Object> getChildObjectNames(Map<String, Object> selectedFields) {
        List<Object> childObjects = new List<Object>();

        if (selectedFields != null) {
            for (String objName : selectedFields.keySet()) {
                // Include all objects as children (root will be identified separately)
                childObjects.add(objName);
            }
        }

        return childObjects;
    }

    /**
     * @description Extract parent lookup names from selectedParentFields
     * Example: {'Opportunity': ['Account.Name', 'Owner.Name']} → ['Account', 'Owner']
     */
    private List<String> extractParentLookupNames(Map<String, Object> selectedParentFields) {
        Set<String> parentNames = new Set<String>();

        if (selectedParentFields != null) {
            for (String objName : selectedParentFields.keySet()) {
                List<Object> parentFieldsRaw = (List<Object>) selectedParentFields.get(objName);
                if (parentFieldsRaw != null) {
                    for (Object fieldObj : parentFieldsRaw) {
                        String field = (String) fieldObj;
                        if (field.contains('.')) {
                            String parentName = field.substringBefore('.');
                            parentNames.add(parentName);
                        }
                    }
                }
            }
        }

        return new List<String>(parentNames);
    }

    /**
     * @description Categorize fields by type (metrics, dates, statuses, identifiers, parentFields)
     * Uses field name patterns and Salesforce schema describe to determine category
     */
    private Map<String, List<String>> categorizeFields(
            String objectName,
            List<Object> fieldsRaw,
            List<Object> parentFieldsRaw) {

        Map<String, List<String>> categories = new Map<String, List<String>>{
            'metrics' => new List<String>(),
            'dates' => new List<String>(),
            'statuses' => new List<String>(),
            'identifiers' => new List<String>(),
            'parentFields' => new List<String>()
        };

        // Categorize regular fields
        for (Object fieldObj : fieldsRaw) {
            String field = (String) fieldObj;

            // Heuristic categorization (can be enhanced with schema describe)
            if (isMetricField(field)) {
                categories.get('metrics').add(field);
            } else if (isDateField(field)) {
                categories.get('dates').add(field);
            } else if (isStatusField(field)) {
                categories.get('statuses').add(field);
            } else {
                categories.get('identifiers').add(field);
            }
        }

        // Add parent fields
        for (Object parentFieldObj : parentFieldsRaw) {
            categories.get('parentFields').add((String) parentFieldObj);
        }

        return categories;
    }

    /**
     * @description Check if field is a metric (Amount, Count, Probability, Revenue, etc.)
     */
    private Boolean isMetricField(String field) {
        String lowerField = field.toLowerCase();
        return lowerField.contains('amount')
            || lowerField.contains('count')
            || lowerField.contains('revenue')
            || lowerField.contains('probability')
            || lowerField.contains('value')
            || lowerField.contains('total')
            || lowerField.contains('sum');
    }

    /**
     * @description Check if field is a date/datetime field
     */
    private Boolean isDateField(String field) {
        String lowerField = field.toLowerCase();
        return lowerField.contains('date')
            || lowerField.contains('time')
            || lowerField.equals('createdat')
            || lowerField.equals('updatedat');
    }

    /**
     * @description Check if field is a status/picklist field
     */
    private Boolean isStatusField(String field) {
        String lowerField = field.toLowerCase();
        return lowerField.contains('status')
            || lowerField.contains('stage')
            || lowerField.contains('priority')
            || lowerField.contains('type')
            || lowerField.contains('category')
            || lowerField.equals('isclosed')
            || lowerField.equals('isactive');
    }

    /**
     * @description Build narrative description of DCM for LLM context
     */
    private String buildDCMNarrative(
            String rootObject,
            List<Object> childObjects,
            List<Object> grandchildObjects,
            List<String> parentLookups,
            Map<String, Object> fieldsByObject) {

        String narrative = 'This DCM includes ' + rootObject + ' as root';

        // Describe child relationships
        if (!childObjects.isEmpty()) {
            narrative += ' with ' + childObjects.size() + ' child relationship';
            if (childObjects.size() > 1) {
                narrative += 's';
            }
            narrative += ' (' + String.join(objectListToStringList(childObjects), ', ') + ')';
        }

        // Describe grandchild relationships
        if (!grandchildObjects.isEmpty()) {
            narrative += ' and ' + grandchildObjects.size() + ' grandchild';
            if (grandchildObjects.size() > 1) {
                narrative += 'ren';
            }
            narrative += ' (' + String.join(objectListToStringList(grandchildObjects), ', ') + ')';
        }

        // Describe parent lookups
        if (!parentLookups.isEmpty()) {
            narrative += '. Parent lookups to ' + String.join(parentLookups, ' and ') + ' are included';
        }

        // Describe available metrics, dates, statuses
        Map<String, Object> rootFields = (Map<String, Object>) fieldsByObject.get(rootObject);
        if (rootFields != null) {
            List<String> metrics = (List<String>) rootFields.get('metrics');
            List<String> dates = (List<String>) rootFields.get('dates');
            List<String> statuses = (List<String>) rootFields.get('statuses');

            if (metrics != null && !metrics.isEmpty()) {
                narrative += '. Available metrics: ' + String.join(metrics, ', ') + ' for pipeline analysis';
            }

            if (dates != null && !dates.isEmpty()) {
                narrative += '. Available dates: ' + String.join(dates, ', ') + ' for time-based alerts';
            }

            if (statuses != null && !statuses.isEmpty()) {
                narrative += '. Status fields: ' + String.join(statuses, ', ') + ' for severity assessment';
            }
        }

        narrative += '.';
        return narrative;
    }

    /**
     * @description Convert List<Object> to List<String>
     */
    private List<String> objectListToStringList(List<Object> objList) {
        List<String> strList = new List<String>();
        for (Object obj : objList) {
            strList.add((String) obj);
        }
        return strList;
    }

    /**
     * @description Validate generated prompt template for V2.5 quality requirements
     * Checks for:
     * - All dynamic values use {{{MergeField}}} syntax
     * - No hardcoded values from sample data (names, amounts, dates)
     * - Iteration blocks properly closed
     * - Required components present (health score, alerts, tables)
     *
     * @param generatedPrompt The prompt template generated by meta-prompt
     * @param dcmAnalysis The DCM analysis structure
     * @return Map<String, Object> with keys: 'isValid' (Boolean), 'errors' (List<String>), 'warnings' (List<String>)
     */
    private Map<String, Object> validatePromptTemplate(String generatedPrompt, Map<String, Object> dcmAnalysis) {
        Map<String, Object> validation = new Map<String, Object>();
        List<String> errors = new List<String>();
        List<String> warnings = new List<String>();

        // Check 1: Must contain merge field syntax {{{...}}}
        if (!generatedPrompt.contains('{{{')) {
            errors.add('No merge fields detected. Template must use {{{FieldName}}} syntax for dynamic values.');
        }

        // Check 2: Iteration blocks must be properly closed
        Integer openBlocks = countOccurrences(generatedPrompt, '{{#');
        Integer closeBlocks = countOccurrences(generatedPrompt, '{{/');
        if (openBlocks != closeBlocks) {
            errors.add('Iteration blocks not properly closed: ' + openBlocks + ' open blocks, ' + closeBlocks + ' close blocks');
        }

        // Check 3: No hardcoded values - look for common patterns
        if (detectHardcodedValues(generatedPrompt)) {
            errors.add('Hardcoded values detected in template. All dynamic values must use merge field syntax.');
        }

        // Check 4: Required visual components
        if (!generatedPrompt.containsIgnoreCase('background') && !generatedPrompt.containsIgnoreCase('style=')) {
            warnings.add('No inline CSS styling detected. Template should use inline styles for visual components.');
        }

        if (!generatedPrompt.containsIgnoreCase('table')) {
            warnings.add('No data table detected. Templates should include at least one table with iteration block.');
        }

        // Check 5: Component count heuristics
        Integer redAlerts = countOccurrences(generatedPrompt.toLowerCase(), '#ba0517') +
                            countOccurrences(generatedPrompt.toLowerCase(), '#dc3545');
        Integer orangeAlerts = countOccurrences(generatedPrompt.toLowerCase(), '#dd7a01') +
                               countOccurrences(generatedPrompt.toLowerCase(), '#ff9800');
        Integer blueAlerts = countOccurrences(generatedPrompt.toLowerCase(), '#0176d3') +
                             countOccurrences(generatedPrompt.toLowerCase(), '#2e844a');

        if (redAlerts == 0 && orangeAlerts == 0 && blueAlerts == 0) {
            warnings.add('No color-coded alerts detected. Template should include at least 1 red, 1 orange, 1 blue alert.');
        }

        // Build result
        validation.put('isValid', errors.isEmpty());
        validation.put('errors', errors);
        validation.put('warnings', warnings);
        validation.put('errorCount', errors.size());
        validation.put('warningCount', warnings.size());

        return validation;
    }

    /**
     * @description Detect hardcoded values in template (sample data that should be merge fields)
     * Looks for patterns like:
     * - Currency amounts: $1,500,000
     * - Dates: 2026-01-25, 01/25/2026
     * - Email addresses: name@example.com
     * - Phone numbers: (555) 123-4567
     * - Common names: "John Smith", "Acme Corp"
     */
    private Boolean detectHardcodedValues(String template) {
        // Currency pattern: $X,XXX,XXX or $XXX.XX
        Pattern currencyPattern = Pattern.compile('\\$[0-9,]+\\.?[0-9]*');
        if (currencyPattern.matcher(template).find()) {
            return true;
        }

        // Date patterns: YYYY-MM-DD, MM/DD/YYYY, Jan 25, 2026
        Pattern datePattern = Pattern.compile('\\d{4}-\\d{2}-\\d{2}|\\d{2}/\\d{2}/\\d{4}|[A-Z][a-z]{2}\\s+\\d{1,2},?\\s+\\d{4}');
        Matcher dateMatcher = datePattern.matcher(template);
        // Allow a few dates for examples, but too many suggests hardcoded data
        Integer dateCount = 0;
        while (dateMatcher.find()) {
            dateCount++;
            if (dateCount > 3) { // More than 3 specific dates suggests sample data
                return true;
            }
        }

        // Email pattern: name@domain.com
        Pattern emailPattern = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
        if (emailPattern.matcher(template).find()) {
            return true;
        }

        // Phone pattern: (555) 123-4567 or 555-123-4567
        Pattern phonePattern = Pattern.compile('\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}');
        if (phonePattern.matcher(template).find()) {
            return true;
        }

        // Common placeholder names that shouldn't be in templates
        List<String> suspiciousNames = new List<String>{'John Smith', 'Jane Doe', 'Acme Corp', 'Example Inc', 'Test Account'};
        for (String suspiciousName : suspiciousNames) {
            if (template.containsIgnoreCase(suspiciousName)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Count occurrences of a substring in a string
     */
    private Integer countOccurrences(String text, String substring) {
        if (String.isBlank(text) || String.isBlank(substring)) {
            return 0;
        }

        Integer count = 0;
        Integer index = 0;
        while ((index = text.indexOf(substring, index)) != -1) {
            count++;
            index += substring.length();
        }
        return count;
    }

    /**
     * @description Generate specific prompt template using meta-prompt + DCM analysis
     * Uses existing AIServiceClient (auto-detects Azure OpenAI, Claude, or DeepSeek)
     *
     * @param metaPrompt The meta-prompt Builder content
     * @param dcmAnalysisJson The DCM analysis JSON string
     * @param businessContext The user's business context/requirements
     * @return String The generated prompt template with merge fields
     * @throws StageException If API call fails
     */
    private String generateSpecificPromptTemplate(
            String metaPrompt,
            String dcmAnalysisJson,
            String businessContext) {

        // Replace placeholders in meta-prompt with actual values
        String finalMetaPrompt = metaPrompt
            .replace('{{DCM_ANALYSIS}}', dcmAnalysisJson)
            .replace('{{BUSINESS_CONTEXT}}', businessContext);

        // Call AI API using existing credentials (Azure OpenAI, Claude, or DeepSeek)
        // System prompt = meta-prompt with DCM/context injected
        // User message = minimal trigger
        AIServiceClient.AIResponse response = AIServiceClient.callAI(
            finalMetaPrompt,            // System prompt (meta-prompt with injected values)
            'Generate the template.',   // User message (trigger)
            8192,                       // Max tokens (templates can be large)
            0.7                         // Temperature
        );

        if (!response.success) {
            throw new StageException('AI API call failed: ' + response.errorMessage);
        }

        return response.content;
    }

    /**
     * @description Iterate on prompt generation with validation feedback
     * Generates prompt template, validates quality, and iterates up to maxIterations if needed
     *
     * @param metaPrompt The meta-prompt Builder content
     * @param dcmAnalysisJson The DCM analysis JSON string
     * @param dcmAnalysisStructured The DCM analysis Map (for validation)
     * @param businessContext The user's business context
     * @param runId The run ID for logging
     * @param result The StageResult for queuing logs
     * @param maxIterations Maximum iteration attempts (default: 10)
     * @return Map<String, Object> with keys: 'template' (String), 'validation' (Map), 'iterations' (Integer)
     */
    private Map<String, Object> iterateOnPromptGeneration(
            String metaPrompt,
            String dcmAnalysisJson,
            Map<String, Object> dcmAnalysisStructured,
            String businessContext,
            Id runId,
            StageResult result,
            Integer maxIterations) {

        if (maxIterations == null || maxIterations <= 0) {
            maxIterations = 10;
        }

        String generatedTemplate;
        Map<String, Object> validation;
        Integer iteration = 0;

        while (iteration < maxIterations) {
            iteration++;

            result.queueInfo(runId, STAGE_NUMBER,
                'V2.5: Generating prompt template (iteration ' + iteration + ')');

            // Generate template
            try {
                generatedTemplate = generateSpecificPromptTemplate(
                    metaPrompt,
                    dcmAnalysisJson,
                    businessContext
                );
            } catch (Exception e) {
                result.queueError(runId, STAGE_NUMBER,
                    'V2.5: Template generation failed (iteration ' + iteration + '): ' + e.getMessage());

                // If first iteration fails, rethrow
                if (iteration == 1) {
                    throw new StageException('Failed to generate prompt template: ' + e.getMessage(), e);
                }

                // Otherwise, continue to next iteration
                continue;
            }

            // Validate template
            validation = validatePromptTemplate(generatedTemplate, dcmAnalysisStructured);

            Boolean isValid = (Boolean) validation.get('isValid');
            Integer errorCount = (Integer) validation.get('errorCount');
            Integer warningCount = (Integer) validation.get('warningCount');

            result.queueInfo(runId, STAGE_NUMBER,
                'V2.5: Template validation (iteration ' + iteration + '): ' +
                'Valid=' + isValid + ', Errors=' + errorCount + ', Warnings=' + warningCount);

            // Log validation errors/warnings
            List<String> errors = (List<String>) validation.get('errors');
            if (errors != null && !errors.isEmpty()) {
                for (String error : errors) {
                    result.queueError(runId, STAGE_NUMBER, 'Validation error: ' + error);
                }
            }

            List<String> warnings = (List<String>) validation.get('warnings');
            if (warnings != null && !warnings.isEmpty()) {
                for (String warning : warnings) {
                    result.queueInfo(runId, STAGE_NUMBER, 'Validation warning: ' + warning);
                }
            }

            // If valid, return result
            if (isValid) {
                result.queueInfo(runId, STAGE_NUMBER,
                    'V2.5: Template generation successful after ' + iteration + ' iteration(s)');

                return new Map<String, Object>{
                    'template' => generatedTemplate,
                    'validation' => validation,
                    'iterations' => iteration,
                    'success' => true
                };
            }

            // If not valid and not last iteration, log and continue
            if (iteration < maxIterations) {
                result.queueInfo(runId, STAGE_NUMBER,
                    'V2.5: Template invalid. Retrying (iteration ' + (iteration + 1) + ')...');

                // TODO: Add validation feedback to meta-prompt for next iteration
                // For MVP, just retry without feedback
            }
        }

        // Max iterations reached without success
        result.queueError(runId, STAGE_NUMBER,
            'V2.5: Failed to generate valid template after ' + maxIterations + ' iterations');

        return new Map<String, Object>{
            'template' => generatedTemplate, // Return last attempt
            'validation' => validation,
            'iterations' => iteration,
            'success' => false
        };
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}