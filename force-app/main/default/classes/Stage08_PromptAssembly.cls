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

    /**
     * V2.5 Enhancement: Include actual data values in prompt
     * When enabled, queries the sample record and includes real data in the prompt
     * so the thinking model can make informed visualization decisions.
     */
    private static final Boolean USE_V2_5_ACTUAL_DATA = true;

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

            // V2.5: Extract sample record ID for actual data query
            Id sampleRecordId = (Id) inputs.get('sampleRecordId');

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
                // V2.0/V2.5: Build meta-prompt with 6+ sections
                aiInstructions = buildMetaPrompt(
                    businessContext, targetPersona, businessObjectivesRaw, rootObject,
                    effectiveCompanyContext, strategicInsights, industryContext,
                    multiSampleProfileRaw, selectedFieldsRaw, selectedParentFieldsRaw,
                    sampleRecordId, runId, result);
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
            ref += rootObject.toUpperCase() + ' (Root Object) - use triple braces:\n';
            List<Object> fields = (List<Object>) selectedFieldsRaw.get(rootObject);
            for (Object field : fields) {
                ref += '  {{{' + String.valueOf(field) + '}}}\n';
            }

            // NOTE: Parent lookup fields removed from merge field reference
            // GPTfy validates merge fields against DCM - only include fields that are in DCM field mapping
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
                    ref += '  Use chained path prefix ' + chainedPath + ' for these fields:\n';
                    for (Object field : fields) {
                        String fieldName = String.valueOf(field);
                        ref += '    {{{' + chainedPath + '.' + fieldName + '}}}\n';
                    }

                    // NOTE: Parent lookup fields removed - GPTfy validates against DCM field mapping
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

                    // NOTE: Parent lookup fields removed - GPTfy validates against DCM field mapping

                    ref += '  End iteration: {{/' + relationshipName + '}}\n';
                    ref += '  Empty check: {{^' + relationshipName + '}}No ' + objName + ' records{{/' + relationshipName + '}}\n';
                    ref += '\n';
                }
            }
        }

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
     * @description Builds meta-prompt with 6+ sections (V2.0/V2.5 architecture)
     * Transforms LLM from "template filler" to "business analyst"
     * V2.5: Includes actual data values so thinking model makes informed decisions
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
            Map<String, Object> selectedParentFieldsRaw,
            Id sampleRecordId,
            Id runId,
            StageResult result) {

        String version = USE_V2_5_ACTUAL_DATA && sampleRecordId != null ? 'V2.5' : 'V2.0';
        result.queueInfo(runId, STAGE_NUMBER, 'Building meta-prompt (' + version + ')');

        String metaPrompt = '';

        // Section 1: ROLE
        metaPrompt += buildRoleSection(targetPersona);

        // Section 2: DATA PAYLOAD (schema patterns)
        metaPrompt += buildDataPayloadSection(multiSampleProfileRaw, rootObject, selectedFieldsRaw);

        // V2.5: Section 2.5: ACTUAL DATA VALUES
        if (USE_V2_5_ACTUAL_DATA && sampleRecordId != null) {
            metaPrompt += buildActualDataSection(
                sampleRecordId, rootObject, selectedFieldsRaw, selectedParentFieldsRaw, runId, result);
        }

        // Section 3: ANALYSIS PRINCIPLES
        metaPrompt += buildAnalysisPrinciplesSection(rootObject, runId);

        // Section 3.5: INFORMATION HIERARCHY (V2.5)
        metaPrompt += buildInformationHierarchySection();

        // V2.6: Section 3.6: DATA-DRIVEN DESIGN GUIDANCE
        metaPrompt += buildDataDrivenDesignSection();

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

        // Add current date for date calculations (critical for overdue/stale analysis)
        String todayFormatted = Date.today().format();
        section += 'TODAY\'S DATE: ' + todayFormatted + '\n';
        section += 'Use this date to calculate if dates are PAST (overdue) or FUTURE.\n\n';

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
     * @description V2.5: Section 2.5 - ACTUAL DATA VALUES
     * Queries the sample record and includes real data values so the thinking model
     * can make informed visualization decisions based on actual content.
     */
    private String buildActualDataSection(
            Id sampleRecordId,
            String rootObject,
            Map<String, Object> selectedFieldsRaw,
            Map<String, Object> selectedParentFieldsRaw,
            Id runId,
            StageResult result) {

        String section = '=== ACTUAL DATA VALUES (Sample Record) ===\n\n';
        section += 'Below is the actual data from the sample record. Use these values to:\n';
        section += '- Understand the data scale and formats\n';
        section += '- Identify which fields have meaningful data\n';
        section += '- Make informed visualization decisions\n\n';

        try {
            // Build field list for root object
            List<String> rootFields = new List<String>{'Id'};
            if (selectedFieldsRaw != null && selectedFieldsRaw.containsKey(rootObject)) {
                List<Object> fields = (List<Object>) selectedFieldsRaw.get(rootObject);
                if (fields != null) {
                    for (Object f : fields) {
                        String fieldName = String.valueOf(f);
                        if (!rootFields.contains(fieldName)) {
                            rootFields.add(fieldName);
                        }
                    }
                }
            }

            // Add parent lookup fields (e.g., Owner.Name, CreatedBy.Email)
            // Only include UNIVERSAL parent lookups that work on all standard objects
            // Child objects like Contact/Opportunity are handled separately via subqueries
            Set<String> universalParentLookups = new Set<String>{
                'Owner', 'CreatedBy', 'LastModifiedBy', 'RecordType'
            };
            if (selectedParentFieldsRaw != null) {
                for (String parentKey : selectedParentFieldsRaw.keySet()) {
                    // Only add if this is a universal parent lookup relationship
                    if (!universalParentLookups.contains(parentKey)) {
                        continue; // Skip child objects and ambiguous relationships
                    }
                    List<Object> parentFields = (List<Object>) selectedParentFieldsRaw.get(parentKey);
                    if (parentFields != null) {
                        for (Object pf : parentFields) {
                            String parentField = parentKey + '.' + String.valueOf(pf);
                            if (!rootFields.contains(parentField)) {
                                rootFields.add(parentField);
                            }
                        }
                    }
                }
            }

            // Build and execute query for root object
            String rootQuery = 'SELECT ' + String.join(rootFields, ', ') +
                              ' FROM ' + rootObject +
                              ' WHERE Id = :sampleRecordId';

            result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Querying sample record: ' + rootObject);

            List<SObject> rootRecords = Database.query(rootQuery);
            if (rootRecords.isEmpty()) {
                section += 'Note: Sample record not found (ID: ' + sampleRecordId + ')\n\n';
                return section;
            }

            SObject rootRecord = rootRecords[0];

            // Format root object data
            section += '--- ' + rootObject + ' ---\n';
            for (String fieldName : rootFields) {
                if (fieldName == 'Id') continue;
                Object value = getFieldValue(rootRecord, fieldName);
                String displayValue = formatFieldValue(value);
                section += fieldName + ': ' + displayValue + '\n';
            }
            section += '\n';

            // Query and format child objects
            for (String objName : selectedFieldsRaw.keySet()) {
                if (objName == rootObject) continue;

                List<Object> fields = (List<Object>) selectedFieldsRaw.get(objName);
                if (fields == null || fields.isEmpty()) continue;

                // Build field list for child
                List<String> childFields = new List<String>{'Id'};
                for (Object f : fields) {
                    String fieldName = String.valueOf(f);
                    if (!childFields.contains(fieldName)) {
                        childFields.add(fieldName);
                    }
                }

                // Find relationship name
                String relationshipName = findRelationshipName(rootObject, objName);
                if (String.isBlank(relationshipName)) {
                    result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Could not find relationship for ' + objName);
                    continue;
                }

                // Build subquery
                String childQuery = 'SELECT ' + String.join(childFields, ', ') +
                                   ' FROM ' + relationshipName;

                // Query with subquery
                String fullQuery = 'SELECT Id, (' + childQuery + ') FROM ' + rootObject +
                                  ' WHERE Id = :sampleRecordId';

                try {
                    List<SObject> parentWithChildren = Database.query(fullQuery);
                    if (!parentWithChildren.isEmpty()) {
                        SObject parent = parentWithChildren[0];
                        List<SObject> children = parent.getSObjects(relationshipName);

                        if (children != null && !children.isEmpty()) {
                            section += '--- ' + objName + ' (' + children.size() + ' records) ---\n';
                            Integer displayLimit = Math.min(children.size(), 5);
                            for (Integer i = 0; i < displayLimit; i++) {
                                SObject child = children[i];
                                section += 'Record ' + (i + 1) + ':\n';
                                for (String fieldName : childFields) {
                                    if (fieldName == 'Id') continue;
                                    Object value = child.get(fieldName);
                                    String displayValue = formatFieldValue(value);
                                    section += '  ' + fieldName + ': ' + displayValue + '\n';
                                }
                            }
                            if (children.size() > displayLimit) {
                                section += '... and ' + (children.size() - displayLimit) + ' more records\n';
                            }
                            section += '\n';
                        }
                    }
                } catch (Exception e) {
                    result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Could not query ' + objName + ': ' + e.getMessage());
                }
            }

            result.queueInfo(runId, STAGE_NUMBER, 'V2.5: Actual data section built (' + section.length() + ' chars)');

        } catch (Exception e) {
            section += 'Error querying data: ' + e.getMessage() + '\n\n';
            result.queueError(runId, STAGE_NUMBER, 'V2.5: Error querying actual data: ' + e.getMessage());
        }

        return section;
    }

    /**
     * @description Gets field value from SObject, handling dot notation for parent lookups
     */
    private Object getFieldValue(SObject record, String fieldPath) {
        if (!fieldPath.contains('.')) {
            return record.get(fieldPath);
        }

        // Handle dot notation (e.g., Owner.Name)
        List<String> parts = fieldPath.split('\\.');
        SObject current = record;
        for (Integer i = 0; i < parts.size() - 1; i++) {
            current = current.getSObject(parts[i]);
            if (current == null) return null;
        }
        return current.get(parts[parts.size() - 1]);
    }

    /**
     * @description Formats field value for display in prompt
     */
    private String formatFieldValue(Object value) {
        if (value == null) return '(empty)';
        if (value instanceof Decimal) {
            Decimal d = (Decimal) value;
            // Format currency-like values
            if (d >= 1000) {
                return '$' + d.format();
            }
            return String.valueOf(d);
        }
        if (value instanceof Date) {
            return ((Date) value).format();
        }
        if (value instanceof DateTime) {
            return ((DateTime) value).format();
        }
        String strValue = String.valueOf(value);
        // Truncate very long values
        if (strValue.length() > 200) {
            return strValue.substring(0, 200) + '...';
        }
        return strValue;
    }

    /**
     * @description Finds the relationship name for a child object from parent
     */
    private String findRelationshipName(String parentObject, String childObject) {
        // Common relationship mappings
        Map<String, Map<String, String>> relationships = new Map<String, Map<String, String>>{
            'Account' => new Map<String, String>{
                'Contact' => 'Contacts',
                'Opportunity' => 'Opportunities',
                'Case' => 'Cases',
                'Task' => 'Tasks',
                'Event' => 'Events',
                'Note' => 'Notes',
                'Attachment' => 'Attachments',
                'AccountContactRelation' => 'AccountContactRelations'
            },
            'Opportunity' => new Map<String, String>{
                'OpportunityLineItem' => 'OpportunityLineItems',
                'OpportunityContactRole' => 'OpportunityContactRoles',
                'Task' => 'Tasks',
                'Event' => 'Events'
            },
            'Contact' => new Map<String, String>{
                'Case' => 'Cases',
                'Task' => 'Tasks',
                'Event' => 'Events',
                'OpportunityContactRole' => 'OpportunityContactRoles'
            },
            'Case' => new Map<String, String>{
                'CaseComment' => 'CaseComments',
                'Task' => 'Tasks',
                'Event' => 'Events'
            },
            'Lead' => new Map<String, String>{
                'Task' => 'Tasks',
                'Event' => 'Events',
                'CampaignMember' => 'CampaignMembers'
            }
        };

        if (relationships.containsKey(parentObject)) {
            Map<String, String> childRelations = relationships.get(parentObject);
            if (childRelations.containsKey(childObject)) {
                return childRelations.get(childObject);
            }
        }

        // Fallback: try pluralizing the child object name
        if (childObject.endsWith('y')) {
            return childObject.substring(0, childObject.length() - 1) + 'ies';
        } else if (childObject.endsWith('s')) {
            return childObject + 'es';
        }
        return childObject + 's';
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
     * @description Section 3.5: INFORMATION HIERARCHY (V2.5)
     * Guides the AI on how to structure information - what to lead with, what to minimize
     */
    private String buildInformationHierarchySection() {
        String section = '=== INFORMATION HIERARCHY ===\n\n';
        section += 'Structure your output following the inverted pyramid - most important first:\n\n';

        section += '1. LEAD WITH INSIGHTS (top 20% of output)\n';
        section += '   - Open with the single most important finding or recommendation\n';
        section += '   - Use attention-grabbing metrics or alerts for critical issues\n';
        section += '   - If there\'s a problem, say it immediately - don\'t bury it\n\n';

        section += '2. KEY METRICS (next 20%)\n';
        section += '   - 3-5 most important numbers in stat cards at the top\n';
        section += '   - These should answer "what do I need to know at a glance?"\n';
        section += '   - Use color coding: green (good), orange (warning), red (critical)\n\n';

        section += '3. ANALYSIS & PATTERNS (next 40%)\n';
        section += '   - Group related insights together\n';
        section += '   - Use cards for each major finding\n';
        section += '   - Include evidence (specific data points) with each insight\n';
        section += '   - Prioritize actionable findings over observations\n\n';

        section += '4. SUPPORTING DETAILS (bottom 20%)\n';
        section += '   - Raw data tables go LAST, if needed at all\n';
        section += '   - Consider: does the executive need to see every row?\n';
        section += '   - If showing tables, limit to 5-10 most relevant rows\n';
        section += '   - Tables should support your insights, not replace them\n\n';

        section += 'ANTI-PATTERNS TO AVOID:\n';
        section += '- Do NOT start with a data table and expect users to find insights\n';
        section += '- Do NOT show all data when a summary statistic would suffice\n';
        section += '- Do NOT use generic headers like "Overview" - be specific\n';
        section += '- Do NOT repeat the same information in different formats\n\n';

        return section;
    }

    /**
     * @description V2.6: DATA-DRIVEN DESIGN GUIDANCE
     * Tells LLM WHEN to use WHICH visualization based on data patterns
     */
    private String buildDataDrivenDesignSection() {
        String section = '=== DATA-DRIVEN DESIGN GUIDANCE ===\n\n';
        section += 'Choose visualization components based on what the DATA tells you:\n\n';

        // Pipeline pattern guidance (Task 6.13)
        section += '--- PIPELINE/FUNNEL PATTERN ---\n';
        section += 'When you see: 3+ opportunities at different stages, deals in various phases, or any multi-stage progression\n';
        section += 'Use: Pipeline Funnel component showing stage distribution with amounts\n';
        section += 'Visual impact: Immediately shows where deals are stuck or progressing\n\n';

        // Urgency pattern guidance (Task 6.14)
        section += '--- URGENCY/RISK PATTERN ---\n';
        section += 'When you see: Critical issues, overdue items, high-priority problems, or churn risk signals\n';
        section += 'Use: Featured Hero Card (gradient) for THE most critical issue, or Risk Priority Matrix for multiple risks\n';
        section += 'Visual impact: Red/orange colors demand immediate attention. Hero card should be used once per dashboard.\n\n';

        // Trend pattern guidance (Task 6.15)
        section += '--- TREND/CHANGE PATTERN ---\n';
        section += 'When you see: Revenue changes, growth metrics, before/after comparisons, or period-over-period data\n';
        section += 'Use: Trend Indicator for simple up/down, KPI Card with Trend for metrics with context, Comparison Card for side-by-side\n';
        section += 'Visual impact: Green arrows/values for positive trends, red for negative\n\n';

        // Comparison pattern guidance (Task 6.16)
        section += '--- COMPARISON PATTERN ---\n';
        section += 'When you see: Two time periods, A vs B scenarios, targets vs actuals, or any paired values\n';
        section += 'Use: Comparison Card for clear side-by-side, or Two-Column Layout for more complex comparisons\n';
        section += 'Visual impact: Visual contrast makes differences immediately obvious\n\n';

        // Progress/Score pattern
        section += '--- PROGRESS/SCORE PATTERN ---\n';
        section += 'When you see: Percentages, win probability, health scores, completion rates, or any 0-100 values\n';
        section += 'Use: Progress Ring for percentages, Gauge Meter for scores with zones\n';
        section += 'Visual impact: Circular graphics are attention-grabbing and easy to interpret\n\n';

        // Timeline pattern
        section += '--- TIMELINE/SEQUENCE PATTERN ---\n';
        section += 'When you see: Milestone dates, key events, activity history, or chronological sequences\n';
        section += 'Use: Timeline component to show progression with dates and status\n';
        section += 'Visual impact: Shows journey/progress at a glance\n\n';

        section += 'DESIGN PRINCIPLES:\n';
        section += '- Match the visualization to the data story, not vice versa\n';
        section += '- If data shows urgency, the visual should convey urgency (reds, bold, hero cards)\n';
        section += '- If data shows progress, use progressive visuals (funnels, timelines, gauges)\n';
        section += '- Use 2-3 different component types per dashboard for visual interest\n';
        section += '- The Featured Hero Card demands attention - use it for the ONE thing that matters most\n\n';

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
            section += '<div style="display:flex;gap:16px;margin-bottom:20px;"><div style="flex:1;background:white;border-radius:6px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="font-size:28px;font-weight:700;color:#0176D3;margin-bottom:4px;">$15M</div><div style="font-size:13px;color:#706E6B;">Annual Revenue</div></div></div>\n\n';

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
            // NOTE: Use text descriptions, NOT actual merge field examples (GPTfy validates all merge fields)
            section += 'MERGE FIELD SYNTAX:\n';
            section += '- Root object fields: Use triple braces with field name\n';
            section += '- Parent lookup fields: Use Relationship.Field pattern\n';
            section += '- Child iteration: Use hash-Collection syntax\n';
            section += '- Child fields: Must include Collection prefix inside iteration\n';
            section += '- Empty check: Use caret-Collection for empty state handling\n\n';
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
        section += 'Create a visually distinctive executive dashboard for this ' + rootObject + '.\n\n';

        if (String.isNotBlank(businessContext)) {
            section += 'SPECIFIC REQUIREMENTS:\n' + businessContext + '\n\n';
        }

        // V2.6: Story-driven layout instead of rigid structure
        section += 'TELL THE DATA\'S STORY:\n';
        section += 'Let the data guide your layout choices. Ask yourself:\n';
        section += '- What is the SINGLE most important thing the user needs to know? Lead with it.\n';
        section += '- Does the data show urgency or risk? Use dramatic visuals (Hero Card, red alerts).\n';
        section += '- Does the data show progress or pipeline? Use progression visuals (Funnel, Timeline).\n';
        section += '- Does the data show comparisons or trends? Use comparison visuals (Trend Indicator, Comparison Card).\n';
        section += '- What would make an executive stop scrolling and pay attention?\n\n';

        section += 'CREATIVE FREEDOM:\n';
        section += 'You are NOT limited to a fixed template. Choose from these layout approaches:\n\n';

        section += '- HERO + GRID: Lead with a Featured Hero Card for the key insight, then a grid of supporting cards\n';
        section += '- TWO-COLUMN: Side-by-side layout comparing two aspects (e.g., Opportunities vs Risks)\n';
        section += '- TIMELINE-DRIVEN: Chronological layout when sequence matters (milestones, activity history)\n';
        section += '- FUNNEL-FOCUSED: Pipeline/funnel visualization with supporting metrics when deals/stages are key\n';
        section += '- MATRIX + DETAILS: Risk/priority matrix followed by detailed cards for high-priority items\n\n';

        section += 'REQUIREMENTS (non-negotiable):\n';
        section += '- Use at least 3 DIFFERENT component types per dashboard\n';
        section += '- Include at least one data visualization (Progress Ring, Gauge, Funnel, or Trend Indicator)\n';
        section += '- Lead with insights, not tables - tables should support your analysis if used at all\n';
        section += '- Use colored elements strategically - red for critical, orange for warning, green for positive\n';
        section += '- Be specific: use actual names ("Sarah Johnson") not titles ("the CFO")\n';
        section += '- ONLY use merge fields from the AVAILABLE MERGE FIELDS section\n\n';

        section += 'QUALITY CHECKLIST:\n';
        section += '[ ] Did I lead with the most important finding (not bury it)?\n';
        section += '[ ] Did I match visualizations to data patterns (see DATA-DRIVEN DESIGN GUIDANCE)?\n';
        section += '[ ] Did I use at least 3 different component types?\n';
        section += '[ ] Does every insight cite specific evidence?\n';
        section += '[ ] Are recommendations specific and actionable with names?\n';
        section += '[ ] Did I ONLY use merge fields from the AVAILABLE MERGE FIELDS list?\n';
        section += '[ ] Would this dashboard make an executive take immediate action?\n\n';

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

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}