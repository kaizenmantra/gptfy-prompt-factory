/**
 * @description Stage 9: Create and Deploy
 * Creates Data Context Mapping (DCM) and AI Prompt records, links them, and activates both
 *
 * CRITICAL: This stage must:
 * 1. Fetch and persist the Prompt Request Id (ccai__Prompt_Request_Id__c) after activation
 * 2. Check ccai__Message__c for activation errors and FAIL (not warn) if present
 * 3. Pass the promptRequestId to Stage 10 for execution
 * 4. Revert prompt to Draft if activation fails with errors
 */
public with sharing class Stage09_CreateAndDeploy implements IStage {

    private static final Integer STAGE_NUMBER = 9;

    /**
     * @description Executes Stage 9: Create and Deploy
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing DCM config, prompt config from previous stages
     * @return StageResult with created DCM ID and Prompt ID
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 9: Create and Deploy');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            PromptFactoryLogger.info(runId, STAGE_NUMBER, 'Starting DCM and Prompt creation');

            // Extract inputs from previous stages
            Map<String, Object> dcmConfigMap = (Map<String, Object>) inputs.get('dcmConfig');
            Map<String, Object> promptConfigMap = (Map<String, Object>) inputs.get('promptConfig');
            String rootObject = (String) inputs.get('rootObject');
            String promptName = (String) inputs.get('promptName');

            if (dcmConfigMap == null || promptConfigMap == null) {
                throw new StageException('DCM config and prompt config are required');
            }

            // Load user-selected AI Model from run record
            Id aiModelId = getAIModelFromRun(runId);
            if (aiModelId != null) {
                PromptFactoryLogger.info(runId, STAGE_NUMBER, 'Using user-selected AI Model: ' + aiModelId);
            } else {
                PromptFactoryLogger.info(runId, STAGE_NUMBER, 'No AI Model specified, will use default');
            }

            // Step 1: Create DCM with grandchild support
            PromptFactoryLogger.info(runId, STAGE_NUMBER, 'Creating Data Context Mapping (with grandchild support)');
            DCMBuilder.DCMConfig dcmConfig = buildDCMConfig(dcmConfigMap);
            Id dcmId = DCMBuilder.createDCMWithGrandchildren(dcmConfig);

            PromptFactoryLogger.info(runId, STAGE_NUMBER,
                'DCM created successfully: ' + dcmId);

            // Step 2: Create Prompt linked to DCM
            PromptFactoryLogger.info(runId, STAGE_NUMBER, 'Creating AI Prompt record');
            PromptBuilder.PromptConfig promptConfig = buildPromptConfig(promptConfigMap, dcmId, aiModelId);
            Id promptId = PromptBuilder.createPrompt(promptConfig);

            PromptFactoryLogger.info(runId, STAGE_NUMBER,
                'AI Prompt created successfully: ' + promptId);

            // Step 3: Link DCM External_Id to Prompt ID (bidirectional link)
            linkDCMToPrompt(dcmId, promptId);
            PromptFactoryLogger.info(runId, STAGE_NUMBER,
                'DCM linked to Prompt via External_Id');

            // Step 4: Activate DCM
            Boolean dcmActivated = false;
            String dcmActivationError = null;
            try {
                activateDCM(dcmId);
                dcmActivated = true;
                PromptFactoryLogger.info(runId, STAGE_NUMBER, 'DCM activated successfully');
            } catch (Exception e) {
                dcmActivationError = e.getMessage();
                PromptFactoryLogger.warning(runId, STAGE_NUMBER,
                    'DCM activation failed: ' + dcmActivationError);
            }

            // Step 5: Activate Prompt
            // CRITICAL: This is a HARD GATE - activation errors MUST fail the stage
            Boolean promptActivated = false;
            String promptActivationError = null;
            String promptRequestId = null;
            String activationMessage = null;
            Long activationTimestamp = null; // Track when activation occurred for Stage 10 timing

            try {
                // Capture timestamp BEFORE activation
                activationTimestamp = System.currentTimeMillis();
                PromptFactoryLogger.info(runId, STAGE_NUMBER, 'Activating AI Prompt...');
                PromptBuilder.activatePrompt(promptId);
                promptActivated = true;
                PromptFactoryLogger.info(runId, STAGE_NUMBER, 'AI Prompt activated at ' +
                    DateTime.newInstance(activationTimestamp).format());

                // CRITICAL: Check ccai__Message__c for activation errors AND wait for Prompt Request ID
                // GPTfy writes validation/activation errors to this field
                // The Prompt Request ID is generated asynchronously - we must poll for it
                PromptFactoryLogger.info(runId, STAGE_NUMBER,
                    'Waiting for GPTfy to generate Prompt Request ID (polling up to ' +
                    ACTIVATION_POLL_ATTEMPTS + ' times, ' + ACTIVATION_POLL_INTERVAL_MS + 'ms interval)...');
                ActivationValidationResult validationResult = validatePromptActivation(promptId, runId);

                if (!validationResult.isValid) {
                    // Activation failed with errors - revert to Draft and FAIL
                    PromptFactoryLogger.error(runId, STAGE_NUMBER,
                        'GPTfy activation validation FAILED: ' + validationResult.errorMessage);

                    // Revert prompt to Draft status (mirrors shell script behavior)
                    revertPromptToDraft(promptId);
                    PromptFactoryLogger.info(runId, STAGE_NUMBER,
                        'Prompt reverted to Draft due to activation errors');

                    throw new StageException(
                        'Prompt activation validation failed. GPTfy reported: ' + validationResult.errorMessage +
                        '. The prompt has been reverted to Draft status.');
                }

                // Activation successful - capture the Prompt Request ID
                promptRequestId = validationResult.promptRequestId;
                activationMessage = validationResult.message;

                if (String.isNotBlank(promptRequestId)) {
                    PromptFactoryLogger.info(runId, STAGE_NUMBER,
                        'Prompt Request ID captured: ' + promptRequestId);
                } else {
                    // No Prompt Request ID is a critical failure - execution won't work
                    PromptFactoryLogger.error(runId, STAGE_NUMBER,
                        'CRITICAL: Prompt Request ID is blank after activation - Stage 10 execution will fail');
                    throw new StageException(
                        'Prompt activated but no Prompt Request ID generated. ' +
                        'Check GPTfy configuration and ccai__Prompt_Request_Id__c field.');
                }

                if (String.isNotBlank(activationMessage)) {
                    PromptFactoryLogger.info(runId, STAGE_NUMBER,
                        'GPTfy activation message: ' + activationMessage);
                }

            } catch (StageException se) {
                // Re-throw StageExceptions (these are our controlled failures)
                throw se;
            } catch (Exception e) {
                promptActivationError = e.getMessage();
                // CRITICAL: Prompt activation failure is a HARD STOP, not a warning
                // Without proper activation, Stage 10 cannot execute
                PromptFactoryLogger.error(runId, STAGE_NUMBER,
                    'Prompt activation FAILED: ' + promptActivationError);
                throw new StageException('Prompt activation failed: ' + promptActivationError);
            }

            // Step 6: Update PF_Run__c with created record IDs
            updateRunRecord(runId, dcmId, promptId);

            // Build outputs
            result.outputs.put('dcmId', dcmId);
            result.outputs.put('promptId', promptId);
            result.outputs.put('promptRequestId', promptRequestId); // CRITICAL: For Stage 10 execution
            result.outputs.put('activationTimestamp', activationTimestamp); // CRITICAL: For Stage 10 timing check
            result.outputs.put('dcmActivated', dcmActivated);
            result.outputs.put('promptActivated', promptActivated);
            result.outputs.put('dcmActivationError', dcmActivationError);
            result.outputs.put('promptActivationError', promptActivationError);
            result.outputs.put('activationMessage', activationMessage);

            // PHASE 2F FIX: Removed manual pass-throughs.
            // Outputs only: dcmId, promptId, promptRequestId, activation details.

            // Determine final status - DCM warning is OK, but prompt MUST be active
            if (dcmActivated && promptActivated) {
                result.markCompleted();
                PromptFactoryLogger.info(runId, STAGE_NUMBER,
                    'Deployment completed successfully. DCM and Prompt are active. Ready for execution.');
            } else if (!dcmActivated && promptActivated) {
                // DCM warning is acceptable - prompt can still execute
                String warningMsg = 'Deployment completed with DCM warning: ' + dcmActivationError;
                result.markWarning(warningMsg);
                PromptFactoryLogger.warning(runId, STAGE_NUMBER, warningMsg);
            } else {
                // This shouldn't be reached due to exceptions above, but just in case
                throw new StageException('Deployment failed: Prompt activation is required for execution');
            }

        } catch (Exception e) {
            String errorMsg = 'Failed to create and deploy: ' + e.getMessage();
            result.markFailed(errorMsg);
            PromptFactoryLogger.logException(runId, STAGE_NUMBER, 'Stage execution failed', e);
        }

        return result;
    }

    /**
     * @description Builds DCMConfig from map representation
     * Now supports grandchild objects with parentObject field
     * @param dcmConfigMap Map representation of DCM configuration
     * @return DCMBuilder.DCMConfig object
     */
    private DCMBuilder.DCMConfig buildDCMConfig(Map<String, Object> dcmConfigMap) {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();

        config.name = (String) dcmConfigMap.get('name');
        config.rootObject = (String) dcmConfigMap.get('rootObject');

        // Parse child objects (including grandchildren with parentObject)
        List<Object> childObjectsList = (List<Object>) dcmConfigMap.get('childObjects');
        if (childObjectsList != null) {
            for (Object childObj : childObjectsList) {
                Map<String, Object> childMap = (Map<String, Object>) childObj;
                String objectName = (String) childMap.get('objectName');
                String relationshipName = (String) childMap.get('relationshipName');
                String relationshipField = (String) childMap.get('relationshipField');
                String parentObject = (String) childMap.get('parentObject'); // For grandchildren

                DCMBuilder.ObjectConfig objectConfig;
                if (String.isNotBlank(parentObject)) {
                    // Grandchild object - use constructor with parentObject
                    objectConfig = new DCMBuilder.ObjectConfig(
                        objectName, relationshipName, relationshipField, parentObject
                    );
                } else {
                    // Direct child object
                    objectConfig = new DCMBuilder.ObjectConfig(
                        objectName, relationshipName, relationshipField
                    );
                }

                if (childMap.containsKey('maxRecords')) {
                    Object maxRecordsVal = childMap.get('maxRecords');
                    if (maxRecordsVal instanceof Integer) {
                        objectConfig.maxRecords = (Integer) maxRecordsVal;
                    } else if (maxRecordsVal instanceof Decimal) {
                        objectConfig.maxRecords = ((Decimal) maxRecordsVal).intValue();
                    }
                }

                config.childObjects.add(objectConfig);
            }
        }

        // Parse fields by object
        Map<String, Object> fieldsByObjectMap = (Map<String, Object>) dcmConfigMap.get('fieldsByObject');
        if (fieldsByObjectMap != null) {
            for (String objectName : fieldsByObjectMap.keySet()) {
                List<Object> fieldsList = (List<Object>) fieldsByObjectMap.get(objectName);
                List<String> fields = new List<String>();
                for (Object field : fieldsList) {
                    fields.add((String) field);
                }
                config.fieldsByObject.put(objectName, fields);
            }
        }

        // V2.2 Task 2.11: Parse parent fields by object
        Map<String, Object> selectedParentFieldsMap = (Map<String, Object>) dcmConfigMap.get('selectedParentFields');
        if (selectedParentFieldsMap != null) {
            for (String objectName : selectedParentFieldsMap.keySet()) {
                List<Object> parentFieldsList = (List<Object>) selectedParentFieldsMap.get(objectName);
                List<String> parentFields = new List<String>();
                for (Object parentField : parentFieldsList) {
                    parentFields.add((String) parentField);
                }
                config.selectedParentFields.put(objectName, parentFields);
            }
        }

        return config;
    }

    /**
     * @description Builds PromptConfig from map representation
     * @param promptConfigMap Map representation of prompt configuration
     * @param dcmId ID of the created DCM
     * @param aiModelId User-selected AI Connection/Model ID (can be null)
     * @return PromptBuilder.PromptConfig object
     */
    private PromptBuilder.PromptConfig buildPromptConfig(Map<String, Object> promptConfigMap, Id dcmId, Id aiModelId) {
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();

        config.name = (String) promptConfigMap.get('name');
        config.label = (String) promptConfigMap.get('label');
        config.description = (String) promptConfigMap.get('description');
        config.howItWorks = (String) promptConfigMap.get('howItWorks'); // V2.0: End-user documentation
        config.dcmId = dcmId; // Link to newly created DCM
        config.aiConnectionId = aiModelId; // User-selected AI Model (if provided)
        config.promptCommand = (String) promptConfigMap.get('promptCommand');
        config.htmlTemplate = (String) promptConfigMap.get('htmlTemplate');
        config.groundingRules = (String) promptConfigMap.get('groundingRules');
        config.targetObject = (String) promptConfigMap.get('targetObject');
        config.promptType = (String) promptConfigMap.get('promptType');
        config.modelName = (String) promptConfigMap.get('modelName');

        if (promptConfigMap.containsKey('maxTokens')) {
            config.maxTokens = (Integer) promptConfigMap.get('maxTokens');
        }
        if (promptConfigMap.containsKey('temperature')) {
            Object tempObj = promptConfigMap.get('temperature');
            config.temperature = tempObj instanceof Decimal ?
                (Decimal) tempObj : Decimal.valueOf(String.valueOf(tempObj));
        }

        config.autoActivate = false; // We'll activate manually with error handling

        return config;
    }

    /**
     * @description Gets the user-selected AI Model from the run record
     * @param runId ID of the PF_Run__c record
     * @return AI Model ID or null if not set
     */
    private Id getAIModelFromRun(Id runId) {
        try {
            List<PF_Run__c> runs = [
                SELECT AI_Model__c
                FROM PF_Run__c
                WHERE Id = :runId
                LIMIT 1
            ];
            if (!runs.isEmpty() && String.isNotBlank(runs[0].AI_Model__c)) {
                return Id.valueOf(runs[0].AI_Model__c);
            }
        } catch (Exception e) {
            // Log but don't fail - will fall back to default
            System.debug(LoggingLevel.WARN, 'Could not load AI Model from run: ' + e.getMessage());
        }
        return null;
    }

    /**
     * @description Activates a DCM record
     * @param dcmId ID of the DCM to activate
     * @throws StageException if activation fails
     */
    private void activateDCM(Id dcmId) {
        try {
            ccai__AI_Data_Extraction_Mapping__c dcm = [
                SELECT Id, ccai__Status__c
                FROM ccai__AI_Data_Extraction_Mapping__c
                WHERE Id = :dcmId
            ];

            dcm.ccai__Status__c = 'Active';
            update dcm;

        } catch (Exception e) {
            throw new StageException('DCM activation failed: ' + e.getMessage());
        }
    }

    /**
     * @description Updates PF_Run__c record with created DCM and Prompt IDs
     * @param runId ID of the PF_Run__c record
     * @param dcmId ID of the created DCM
     * @param promptId ID of the created Prompt
     */
    private void updateRunRecord(Id runId, Id dcmId, Id promptId) {
        try {
            PF_Run__c run = new PF_Run__c(
                Id = runId,
                Created_DCM_Id__c = dcmId,
                Created_Prompt_Id__c = promptId
            );
            update run;

            PromptFactoryLogger.info(runId, STAGE_NUMBER,
                'Updated run record with DCM and Prompt IDs');

        } catch (Exception e) {
            // Log but don't fail stage
            PromptFactoryLogger.warning(runId, STAGE_NUMBER,
                'Failed to update run record: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for activation validation results
     */
    private class ActivationValidationResult {
        public Boolean isValid = true;
        public String errorMessage;
        public String message;
        public String promptRequestId;
    }

    // Polling configuration for waiting on Prompt Request ID generation
    // GPTfy generates this asynchronously after activation
    private static final Integer ACTIVATION_POLL_ATTEMPTS = 15;
    private static final Integer ACTIVATION_POLL_INTERVAL_MS = 2000; // 2 seconds (total max wait: ~30 seconds)

    /**
     * @description Validates prompt activation by checking ccai__Message__c for errors
     * and polls for the Prompt Request ID to be generated.
     *
     * CRITICAL: GPTfy generates the Prompt Request ID asynchronously after activation.
     * This method polls to wait for it, matching the shell script's behavior where
     * it proceeds even if the ID isn't immediately available.
     *
     * @param promptId ID of the ccai__AI_Prompt__c record
     * @param runId ID of the PF_Run__c record for logging
     * @return ActivationValidationResult with validation status and details
     */
    private ActivationValidationResult validatePromptActivation(Id promptId, Id runId) {
        ActivationValidationResult result = new ActivationValidationResult();
        Integer attemptCount = 0;

        while (attemptCount < ACTIVATION_POLL_ATTEMPTS) {
            attemptCount++;

            try {
                ccai__AI_Prompt__c prompt = [
                    SELECT ccai__Prompt_Request_Id__c, ccai__Message__c, ccai__Status__c
                    FROM ccai__AI_Prompt__c
                    WHERE Id = :promptId
                    LIMIT 1
                ];

                result.message = prompt.ccai__Message__c;

                // Check for activation errors in ccai__Message__c FIRST
                // GPTfy writes validation errors like merge field mismatches here
                // These are immediate failures - don't poll further
                if (String.isNotBlank(prompt.ccai__Message__c)) {
                    String msgLower = prompt.ccai__Message__c.toLowerCase();

                    // Check for error indicators
                    if (msgLower.contains('error') ||
                        msgLower.contains('invalid') ||
                        msgLower.contains('failed') ||
                        msgLower.contains('not found') ||
                        msgLower.contains('mismatch') ||
                        msgLower.contains('cannot') ||
                        msgLower.contains('unable')) {

                        result.isValid = false;
                        result.errorMessage = prompt.ccai__Message__c;
                        PromptFactoryLogger.error(runId, STAGE_NUMBER,
                            'Activation error detected in ccai__Message__c: ' + prompt.ccai__Message__c);
                        return result; // Immediate failure - no need to poll further
                    }
                }

                // Also check if status is not Active
                if (prompt.ccai__Status__c != 'Active') {
                    result.isValid = false;
                    result.errorMessage = 'Prompt status is ' + prompt.ccai__Status__c + ', expected Active';
                    PromptFactoryLogger.error(runId, STAGE_NUMBER,
                        'Prompt status is not Active: ' + prompt.ccai__Status__c);
                    return result; // Immediate failure
                }

                // Check if Prompt Request ID has been generated
                if (String.isNotBlank(prompt.ccai__Prompt_Request_Id__c)) {
                    result.promptRequestId = prompt.ccai__Prompt_Request_Id__c;
                    PromptFactoryLogger.info(runId, STAGE_NUMBER,
                        'Prompt Request ID captured after ' + attemptCount + ' poll attempt(s): ' + result.promptRequestId);
                    return result; // Success!
                }

                // Prompt Request ID not yet generated - continue polling
                if (attemptCount == 1 || Math.mod(attemptCount, 5) == 0) {
                    // Log first attempt and every 5th attempt to avoid log spam
                    PromptFactoryLogger.info(runId, STAGE_NUMBER,
                        'Poll attempt ' + attemptCount + '/' + ACTIVATION_POLL_ATTEMPTS +
                        ' - Prompt Request ID not yet generated by GPTfy, waiting...');
                }
                System.debug('Stage09: Poll attempt ' + attemptCount + '/' + ACTIVATION_POLL_ATTEMPTS +
                    ' - Prompt Request ID not yet generated by GPTfy');

                // Wait before next poll (except on last attempt)
                if (attemptCount < ACTIVATION_POLL_ATTEMPTS) {
                    Long waitUntil = System.currentTimeMillis() + ACTIVATION_POLL_INTERVAL_MS;
                    while (System.currentTimeMillis() < waitUntil) {
                        // Busy wait - Apex doesn't have Thread.sleep()
                    }
                }

            } catch (Exception e) {
                result.isValid = false;
                result.errorMessage = 'Failed to validate activation: ' + e.getMessage();
                PromptFactoryLogger.error(runId, STAGE_NUMBER,
                    'Exception during activation validation: ' + e.getMessage());
                return result;
            }
        }

        // Polling exhausted - Prompt Request ID was never generated
        // This is now a real failure after waiting ~30 seconds
        result.isValid = false;
        result.errorMessage = 'Prompt Request ID not generated by GPTfy after ' + ACTIVATION_POLL_ATTEMPTS +
            ' attempts (~' + (ACTIVATION_POLL_ATTEMPTS * ACTIVATION_POLL_INTERVAL_MS / 1000) + ' seconds). ' +
            'GPTfy may be experiencing issues or the prompt configuration is invalid.';
        PromptFactoryLogger.error(runId, STAGE_NUMBER, result.errorMessage);
        return result;
    }

    /**
     * @description Reverts a prompt to Draft status after activation failure
     * Mirrors the shell script's behavior of reverting on activation errors
     * @param promptId ID of the ccai__AI_Prompt__c record
     */
    private void revertPromptToDraft(Id promptId) {
        try {
            ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
                Id = promptId,
                ccai__Status__c = 'Draft'
            );
            update prompt;
        } catch (Exception e) {
            // Log but don't throw - the main error is the activation failure
            System.debug(LoggingLevel.ERROR, 'Failed to revert prompt to Draft: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves the Prompt Request ID after activation
     * This is the critical identifier GPTfy uses for prompt execution
     * @param promptId ID of the ccai__AI_Prompt__c record
     * @return The ccai__Prompt_Request_Id__c value, or null if not found
     */
    private String getPromptRequestId(Id promptId) {
        try {
            ccai__AI_Prompt__c prompt = [
                SELECT ccai__Prompt_Request_Id__c
                FROM ccai__AI_Prompt__c
                WHERE Id = :promptId
                LIMIT 1
            ];
            return prompt.ccai__Prompt_Request_Id__c;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to get Prompt Request ID: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Links DCM to Prompt by setting External_Id to Prompt ID
     * This creates bidirectional linkage for GPTfy to properly associate them
     * @param dcmId ID of the DCM record
     * @param promptId ID of the Prompt record
     */
    private void linkDCMToPrompt(Id dcmId, Id promptId) {
        try {
            ccai__AI_Data_Extraction_Mapping__c dcm = new ccai__AI_Data_Extraction_Mapping__c(
                Id = dcmId,
                ccai__External_Id__c = String.valueOf(promptId)
            );
            update dcm;
        } catch (Exception e) {
            // Log but don't fail - this is a nice-to-have link
            PromptFactoryLogger.warning(null, STAGE_NUMBER,
                'Failed to link DCM to Prompt: ' + e.getMessage());
        }
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}