/**
 * @description Stage 8: Prompt Assembly
 * Builds complete prompt command with AI instructions, integrates HTML template,
 * adds grounding rules, and validates all merge fields
 */
public without sharing class Stage08_PromptAssembly implements IStage {

    private static final Integer STAGE_NUMBER = 8;

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

            result.queueInfo(runId, STAGE_NUMBER, 'Assembling prompt for ' + rootObject);

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

            // Build AI instructions with REAL company research
            String aiInstructions = buildAIInstructions(
                businessContext, targetPersona, businessObjectivesRaw, rootObject,
                effectiveCompanyContext, strategicInsights, industryContext, runId);

            // Build grounding rules
            String groundingRules = buildGroundingRules(rootObject, targetPersona);

            // Assemble complete prompt configuration
            Map<String, Object> promptConfig = assemblePromptConfiguration(
                aiInstructions, htmlTemplate, groundingRules, rootObject);

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
            
            // TEMPORARY: Hardcode builder IDs to test if query is the issue
            List<Id> qualityRuleIds = new List<Id>{'a0DQH00000KYZxW2AX'}; // Evidence Binding Rules v2
            
            List<ccai__AI_Prompt__c> rules = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE Id IN :qualityRuleIds
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
            PromptFactoryLogger.error(runId, 8, '❌ Error loading Quality Rules: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            return '';
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
            
            // TEMPORARY: Hardcode builder IDs to test if query is the issue
            List<Id> patternIds = new List<Id>{'a0DQH00000KYaC12AL', 'a0DQH00000KYdD72AL'}; // Risk + Next Best Action
            
            List<ccai__AI_Prompt__c> patterns = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE Id IN :patternIds
                  AND ccai__Status__c = 'Active'
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
            PromptFactoryLogger.error(runId, 8, '❌ Error loading Patterns: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            return '';
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
            
            // TEMPORARY: Hardcode builder IDs to test if query is the issue
            List<Id> componentIds = new List<Id>{'a0DQH00000KYaFF2A1', 'a0DQH00000KYaLh2AL'}; // Stat Card + Alert Box
            
            List<ccai__AI_Prompt__c> components = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE Id IN :componentIds
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
            PromptFactoryLogger.error(runId, 8, '❌ Error loading UI Components: ' + e.getMessage());
            return '';
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
            
            // TEMPORARY: Hardcode builder IDs to test if query is the issue
            List<Id> templateIds = new List<Id>{'a0DQH00000KYaQX2A1'}; // Healthcare Payer Context
            
            List<ccai__AI_Prompt__c> templates = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE Id IN :templateIds
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
            PromptFactoryLogger.error(runId, 8, '❌ Error loading Context Templates: ' + e.getMessage());
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
     * @param rootObject The root Salesforce object
     * @param aiInstructions AI instructions section
     * @param htmlTemplate HTML template with merge fields
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

        return new Map<String, Object>{
            'name' => promptName,
            'label' => promptName,
            'description' => 'Auto-generated prompt for ' + rootObject + '. ' +
                           (String.isNotBlank(businessContext) ? businessContext.left(200) : ''),
            'promptCommand' => aiInstructions,
            'htmlTemplate' => htmlTemplate,
            'groundingRules' => groundingRules,
            'targetObject' => rootObject,
            'promptType' => 'Text',
            'modelName' => 'claude-sonnet-4.5',
            'maxTokens' => 4096,
            'temperature' => 1.0
        };
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}
