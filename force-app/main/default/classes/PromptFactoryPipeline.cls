/**
 * @description Main orchestrator for the 12-stage Prompt Factory pipeline
 * Implements Queueable and Database.AllowsCallouts to execute stages asynchronously
 * Chains through all 12 stages, handling success/failure at each step
 * FORCE RECOMPILE: 2026-01-24 03:51 - Added accumulation logic with debug logging
 *
 * IMPORTANT: This class is structured to minimize stack depth when calling
 * System.enqueueJob() to avoid "Maximum stack depth has been reached" errors.
 * The enqueue call is made at the TOP LEVEL of execute() with minimal nesting.
 */
public class PromptFactoryPipeline implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private Integer currentStage;
    private static final Integer MAX_STAGES = 12;
    private static final String COMPONENT_NAME = 'PromptFactoryPipeline';
    private static final Integer MAX_SANITIZE_DEPTH = 5;
    private static final Integer MAX_LIST_ITEMS = 200;
    private static final Integer MAX_STRING_LEN = 5000;
    private static final Set<String> INPUT_OUTPUT_KEY_DENYLIST = new Set<String>{
        // High-risk / high-size keys observed to trigger stack depth issues
        'recordData', 'recordDataJson',
        // legacy keys from earlier iterations
        'fullRecord', 'fullRecordJson'
    };

    // Test control to prevent infinite chaining in unit tests
    @TestVisible private static Boolean stopChaining = false;

    /**
     * @description Simple enum-like class to track what action to take after stage execution
     * Using strings to avoid enum overhead
     */
    private class ExecutionDecision {
        public String action; // 'CHAIN', 'COMPLETE', 'FAIL', 'ABORT', 'ERROR'
        public String errorMessage;
        public Decimal qualityScore;
    }

    /**
     * @description Constructor for the pipeline orchestrator
     * @param runId ID of the PF_Run__c record
     * @param currentStage Current stage number (1-12)
     */
    public PromptFactoryPipeline(Id runId, Integer currentStage) {
        this.runId = runId;
        this.currentStage = currentStage;
    }

    /**
     * @description Main execution method for Queueable interface
     * Orchestrates stage execution and chaining
     *
     * CRITICAL ARCHITECTURE CHANGE (2026-01-11):
     * ALL stages from 5-12 now use dedicated Queueable wrappers to ensure each
     * stage executes in a completely fresh stack context. This prevents
     * "Maximum stack depth has been reached" errors.
     *
     * The pipeline now only handles stages 1-4 directly. After Stage 4 completes,
     * it chains to Stage05_FieldSelectionJob, which chains to Stage06, etc.
     * Each stage job chains to the next stage job.
     *
     * Stage Execution Model:
     * - Stages 1-4: Executed by PromptFactoryPipeline (direct chaining)
     * - Stages 5-12: Each has its own dedicated Queueable job class
     *
     * STACK OVERFLOW FIX (2026-01-11):
     * When chaining to Stage 5+, we must enqueue with MINIMAL stack.
     * If PromptFactoryPipeline is called directly with currentStage >= 5,
     * we route immediately (fresh stack). But if we're chaining AFTER executing
     * stages 1-4, the accumulated stack from executeStageAndGetDecision() can
     * cause issues when calling System.enqueueJob(). Solution: After Stage 4,
     * re-enqueue ourselves as a fresh Queueable to reset the stack, then that
     * fresh instance will route to Stage 5.
     *
     * @param context QueueableContext provided by platform
     */
    public void execute(QueueableContext context) {
        // Stage routing for stages 5+ to dedicated Queueable wrappers
        if (currentStage >= 5) {
            if (!stopChaining) routeToStageJobInline();
            return;
        }

        // Execute stages 1-4 with standard chaining
        ExecutionDecision decision = executeStageAndGetDecision();

        if (decision.action == 'CHAIN' && !stopChaining) {
            Integer nextStage = currentStage + 1;

            if (nextStage == 5) {
                // CHAIN BREAKER: Use Schedulable to reset chain depth before Stage 5
                // This prevents "Maximum stack depth has been reached" errors
                // that occur when Queueable chain depth exceeds ~5
                PromptFactoryChainBreaker.scheduleStage5(runId);
            } else {
                // Continue normal chaining for stages 1-4
                System.enqueueJob(new PromptFactoryPipeline(runId, nextStage));
            }
        }
    }

    /**
     * @description Routes to stage job - inline for minimal overhead
     */
    private void routeToStageJobInline() {
        if (currentStage == 5) System.enqueueJob(new Stage05_FieldSelectionJob(runId));
        else if (currentStage == 6) System.enqueueJob(new Stage06_ConfigurationValidationJob(runId));
        else if (currentStage == 7) System.enqueueJob(new Stage07_TemplateDesignJob(runId));
        else if (currentStage == 8) System.enqueueJob(new Stage08_PromptAssemblyJob(runId));
        /*
        else if (currentStage == 9) System.enqueueJob(new Stage09_CreateAndDeployJob(runId));
        else if (currentStage == 10) System.enqueueJob(new Stage10_TestExecutionJob(runId));
        else if (currentStage == 11) System.enqueueJob(new Stage11_SafetyValidationJob(runId));
        else if (currentStage == 12) System.enqueueJob(new Stage12_QualityAuditJob(runId));
        */
    }

    /**
     * @description Routes to the appropriate stage job class
     * Each stage 5-12 has its own dedicated Queueable wrapper for stack isolation.
     * @param stageNumber The stage number to route to (5-12)
     */
    private void routeToStageJob(Integer stageNumber) {
        switch on stageNumber {
            when 5 {
                System.enqueueJob(new Stage05_FieldSelectionJob(runId));
            }
            when 6 {
                System.enqueueJob(new Stage06_ConfigurationValidationJob(runId));
            }
            when 7 {
                System.enqueueJob(new Stage07_TemplateDesignJob(runId));
            }
            when 8 {
                System.enqueueJob(new Stage08_PromptAssemblyJob(runId));
            }
            /*
            when 9 {
                System.enqueueJob(new Stage09_CreateAndDeployJob(runId));
            }
            when 10 {
                System.enqueueJob(new Stage10_TestExecutionJob(runId));
            }
            when 11 {
                System.enqueueJob(new Stage11_SafetyValidationJob(runId));
            }
            when 12 {
                System.enqueueJob(new Stage12_QualityAuditJob(runId));
            }
            */
        }
    }

    /**
     * @description Executes the stage and returns a decision about what to do next
     * This method contains all the complex logic but does NOT call System.enqueueJob()
     * @return ExecutionDecision indicating what action to take
     */
    private ExecutionDecision executeStageAndGetDecision() {
        ExecutionDecision decision = new ExecutionDecision();
        decision.action = 'ERROR'; // Default to error

        StageResult result = null;
        PF_Run__c run = null;
        Boolean shouldUpdateToInProgress = false;

        // Enable log buffering to prevent "Uncommitted work pending" errors during input loading
        PromptFactoryLogger.enableBuffering();

        try {
            // Load run record (query only - no DML yet)
            run = loadRunRecord();

            if (run == null) {
                System.debug(LoggingLevel.ERROR, 'Run record not found: ' + runId);
                decision.action = 'ERROR';
                decision.errorMessage = 'Run record not found';
                return decision;
            }

            // Check if pipeline has been aborted
            if (run.Status__c == 'Aborted') {
                System.debug(LoggingLevel.INFO, 'Pipeline has been aborted. Stopping execution.');
                decision.action = 'ABORT';
                return decision;
            }

            // Track if we need to update status
            shouldUpdateToInProgress = (run.Status__c == 'Pending' || run.Status__c == 'Queued');

            // Get stage implementation
            IStage stage = StageFactory.getStage(currentStage);

            // Load inputs from previous stage
            Map<String, Object> inputs = loadStageInputs(currentStage);

            // ========================================
            // EXECUTE STAGE (this may make HTTP callouts)
            // NO DML has happened yet, so callouts are safe
            // ========================================
            result = stage.execute(runId, inputs);

            // ========================================
            // NOW WE CAN DO ALL DML (after callouts complete)
            // ========================================

            // Update run status to In Progress (if needed)
            if (shouldUpdateToInProgress) {
                updateRunStatus(run, 'In Progress', currentStage);
            } else {
                updateCurrentStage(run, currentStage);
            }

            // FLUSH LOGS: Write any logs accumulated during input loading (now that callouts are done)
            PromptFactoryLogger.flushLogs();

            PromptFactoryLogger.info(runId, currentStage,
                'Starting execution of Stage ' + currentStage);

            // Save stage result
            saveStageResult(result);

            // Determine what to do next based on result status
            if (result.status == 'Failed') {
                handleFailure(run, result);
                decision.action = 'FAIL';
                decision.errorMessage = result.errorMessage;
            } else if (result.status == 'Completed' || result.status == 'Warning') {
                PromptFactoryLogger.info(runId, currentStage,
                    'Stage ' + currentStage + ' completed successfully');

                if (currentStage >= MAX_STAGES) {
                    // Final stage - complete the pipeline
                    completePipeline(run, result);
                    decision.action = 'COMPLETE';
                    decision.qualityScore = extractQualityScore(result.outputs);
                } else {
                    // Need to chain to next stage
                    PromptFactoryLogger.info(runId, currentStage,
                        'Preparing to chain to Stage ' + (currentStage + 1));
                    decision.action = 'CHAIN';
                }
            } else {
                // Unexpected status
                PromptFactoryLogger.warning(runId, currentStage,
                    'Stage returned unexpected status: ' + result.status);
                handleFailure(run, result);
                decision.action = 'FAIL';
                decision.errorMessage = 'Unexpected status: ' + result.status;
            }

        } catch (Exception e) {
            handleException(e);
            PromptFactoryLogger.flushLogs(); // Ensure logs are flushed on error
            decision.action = 'ERROR';
            decision.errorMessage = e.getMessage();
        }

        return decision;
    }

    /**
     * @description Loads the PF_Run__c record
     * @return PF_Run__c record or null if not found
     */
    private PF_Run__c loadRunRecord() {
        List<PF_Run__c> runs = [
            SELECT Id, Name, Status__c, Current_Stage__c, Root_Object__c,
                   Sample_Record_Id__c, Business_Context__c, Output_Format__c,
                   Prompt_Name__c, Started_At__c, Overall_Quality_Score__c
            FROM PF_Run__c
            WHERE Id = :runId
            LIMIT 1
        ];

        return runs.isEmpty() ? null : runs[0];
    }

    /**
     * @description Loads inputs for the current stage from previous stages
     * PHASE 2F FIX: Accumulates outputs from ALL previous completed stages to prevent data loss (Ghost Data)
     * Includes conflict detection and size warnings.
     * @param stageNumber Current stage number
     * @return Map of input data
     */
    @TestVisible
    private Map<String, Object> loadStageInputs(Integer stageNumber) {
        Map<String, Object> inputs = new Map<String, Object>();

        // 1. [Safety Net] Always load base inputs from Run record first
        PF_Run__c run = loadRunRecord();
        if (run != null) {
            if (String.isNotBlank(run.Root_Object__c)) inputs.put('rootObject', run.Root_Object__c);
            if (run.Sample_Record_Id__c != null) inputs.put('sampleRecordId', run.Sample_Record_Id__c);
            if (String.isNotBlank(run.Business_Context__c)) inputs.put('businessContext', run.Business_Context__c);
            if (String.isNotBlank(run.Output_Format__c)) inputs.put('outputFormat', run.Output_Format__c);
            if (String.isNotBlank(run.Prompt_Name__c)) inputs.put('targetPromptName', run.Prompt_Name__c);
        }

        if (stageNumber == 1) {
            return inputs;
        }

        // 2. Query ALL previous completed stages
        // Order by Stage Number ASC (process order), then CreatedDate DESC (latest retry first)
        List<PF_Run_Stage__c> allStageRecords = [
            SELECT Stage_Number__c, Output_Data__c, CreatedDate
            FROM PF_Run_Stage__c
            WHERE Run__c = :runId
            AND Stage_Number__c < :stageNumber
            AND Status__c = 'Completed'
            ORDER BY Stage_Number__c ASC, CreatedDate DESC
        ];

        // 3. Deduplicate: Keep only the LATEST record for each stage number
        Map<Integer, String> latestOutputByStage = new Map<Integer, String>();
        for (PF_Run_Stage__c record : allStageRecords) {
            Integer stageNum = Integer.valueOf(record.Stage_Number__c);
            // Since we ordered by CreatedDate DESC, the first one we see is the latest
            if (!latestOutputByStage.containsKey(stageNum)) {
                latestOutputByStage.put(stageNum, record.Output_Data__c);
            }
        }

        // 4. Merge outputs in Stage Order (1, 2, 3...)
        // Later stages override earlier stages (Last Write Wins)
        List<Integer> stageNumbers = new List<Integer>(latestOutputByStage.keySet());
        stageNumbers.sort();

        PromptFactoryLogger.logDebug(runId, stageNumber, 
            'Accumulating inputs from ' + stageNumbers.size() + ' previous stages: ' + stageNumbers);

        for (Integer stageNum : stageNumbers) {
            String outputJson = latestOutputByStage.get(stageNum);
            if (String.isBlank(outputJson)) continue;
            
            // DEBUG: Check for truncation
            Boolean isTruncated = outputJson.contains('[TRUNCATED]');
            if (isTruncated) {
                 PromptFactoryLogger.logWarning(runId, stageNumber, 'Stage ' + stageNum + ' output is TRUNCATED. JSON parsing may fail.');
            }

            try {
                Object parsed = JSON.deserializeUntyped(outputJson);
                if (parsed instanceof Map<String, Object>) {
                    Map<String, Object> stageOutputs = (Map<String, Object>) parsed;
                    
                    // DEBUG: Log keys contributed by this stage
                    // PromptFactoryLogger.logDebug(runId, stageNumber, 'Stage ' + stageNum + ' keys: ' + stageOutputs.keySet());
                    
                    if (stageOutputs.containsKey('selectedFields')) {
                        PromptFactoryLogger.logInfo(runId, stageNumber, 'Stage ' + stageNum + ' provides selectedFields');
                    }

                    for (String key : stageOutputs.keySet()) {
                        Object value = stageOutputs.get(key);
                        
                        // Ignore nulls - they shouldn't wipe out existing data
                        if (value == null) continue;

                        // Task 2.21: Conflict Detection
                        if (inputs.containsKey(key)) {
                            Object existingValue = inputs.get(key);
                            // Simple check: if values differ (check string representation for simplicity)
                            String val1 = String.valueOf(existingValue);
                            String val2 = String.valueOf(value);
                            
                            if (val1 != val2 && val1.length() < 100 && val2.length() < 100) {
                                PromptFactoryLogger.logWarning(runId, stageNumber,
                                    'Conflict: Stage ' + stageNum + ' overwrote "' + key + '". ' +
                                    'Old: ' + val1 + ', New: ' + val2);
                            }
                        }

                        inputs.put(key, value);
                    }
                }
            } catch (Exception e) {
                PromptFactoryLogger.logWarning(runId, stageNumber,
                    'Failed to parse Stage ' + stageNum + ' outputs: ' + e.getMessage());
            }
        }
        
        // DEBUG: Trace selectedFields presence
        Boolean hasSelectedFields = inputs.containsKey('selectedFields');
        Map<String, Object> sfMap = hasSelectedFields ? (Map<String, Object>)inputs.get('selectedFields') : null;
        Integer sfSize = (sfMap != null) ? sfMap.size() : 0;
        
        PromptFactoryLogger.logDebug(runId, stageNumber, 
            'Final Inputs Assembly: selectedFields present=' + hasSelectedFields + 
            ', Objects=' + sfSize + 
            ', Keys=' + inputs.keySet());

        if (!hasSelectedFields && stageNumber >= 6) {
             PromptFactoryLogger.logError(runId, stageNumber, 'CRITICAL: selectedFields MISSING in Stage ' + stageNumber + ' inputs!');
        }

        // Task 2.23: Size Warning
        // Serialize inputs to check size
        try {
            String finalJson = JSON.serialize(inputs);
            if (finalJson.length() > 100000) {
                PromptFactoryLogger.logWarning(runId, stageNumber,
                    '⚠️ Accumulated inputs size is LARGE: ' + finalJson.length() + 
                    ' chars (Limit: 131072). Consider removing large fields from stage outputs.');
            }
        } catch(Exception e) {
            // ignore serialization errors here
        }

        return inputs;
    }

    /**
     * @description Saves stage result to PF_Run_Stage__c and logs
     * @param result StageResult from stage execution
     */
    private void saveStageResult(StageResult result) {
        try {
            // Safely serialize inputs/outputs:
            // - strip problematic keys (e.g., record snapshots)
            // - convert non-JSON-safe types (SObject, Blob, Schema types)
            // - enforce depth/size limits to prevent "Maximum stack depth has been reached"
            String inputsJson = '{}';
            try {
                if (result.inputs != null && !result.inputs.isEmpty()) {
                    Map<String, Object> sanitizedInputs = sanitizeMapForStorage(result.inputs, 0);
                    inputsJson = JSON.serialize(sanitizedInputs);
                }
            } catch (Exception e) {
                inputsJson = '{"error": "Serialization failed: ' + e.getMessage().replace('"', '\\"') + '"}';
            }

            // Safely serialize outputs
            String outputsJson = '{}';
            try {
                if (result.outputs != null && !result.outputs.isEmpty()) {
                    Map<String, Object> sanitizedOutputs = sanitizeMapForStorage(result.outputs, 0);
                    outputsJson = JSON.serialize(sanitizedOutputs);
                }
            } catch (Exception e) {
                outputsJson = '{"error": "Serialization failed: ' + e.getMessage().replace('"', '\\"') + '"}';
            }

            // Create stage record
            PF_Run_Stage__c stageRecord = new PF_Run_Stage__c(
                Run__c = runId,
                Stage_Number__c = currentStage,
                Stage_Name__c = result.stageName,
                Status__c = result.status,
                Input_Data__c = truncateJSON(inputsJson, 130000),
                Output_Data__c = truncateJSON(outputsJson, 130000),
                AI_Reasoning__c = truncate(result.aiReasoning, 32000),
                Error_Message__c = truncate(result.errorMessage, 5000),
                Started_At__c = result.startedAt,
                Completed_At__c = System.now(),
                Duration_Seconds__c = result.getDurationSeconds()
            );

            insert stageRecord;

            // Bulk insert logs if any
            if (result.logs != null && !result.logs.isEmpty()) {
                PromptFactoryLogger.bulkLog(result.logs);
            }

            PromptFactoryLogger.info(runId, currentStage,
                'Stage completed with status: ' + result.status +
                ' (Duration: ' + result.getDurationSeconds() + 's)');

        } catch (Exception e) {
            PromptFactoryLogger.logException(runId, currentStage,
                'Failed to save stage result', e);
            throw e;
        }
    }

    /**
     * @description Completes the pipeline after final stage
     * @param run PF_Run__c record
     * @param result Final stage result
     */
    private void completePipeline(PF_Run__c run, StageResult result) {
        try {
            // Calculate overall quality score from Stage 12 output
            Decimal qualityScore = extractQualityScore(result.outputs);

            run.Status__c = 'Completed';
            run.Current_Stage__c = MAX_STAGES;
            run.Completed_At__c = System.now();
            run.Overall_Quality_Score__c = qualityScore;

            update run;

            PromptFactoryLogger.info(runId, null,
                'Pipeline completed successfully. Quality Score: ' + qualityScore);

        } catch (Exception e) {
            PromptFactoryLogger.logException(runId, null,
                'Failed to complete pipeline', e);
            throw e;
        }
    }

    /**
     * @description Handles stage failure by updating run status
     * @param run PF_Run__c record
     * @param result Stage result with failure details
     */
    private void handleFailure(PF_Run__c run, StageResult result) {
        try {
            run.Status__c = 'Failed';
            run.Current_Stage__c = currentStage;
            run.Error_Message__c = truncate(result.errorMessage, 5000);

            update run;

            PromptFactoryLogger.error(runId, currentStage,
                'Pipeline failed at Stage ' + currentStage + ': ' + result.errorMessage);

        } catch (Exception e) {
            PromptFactoryLogger.logException(runId, null,
                'Failed to handle stage failure', e);
        }
    }

    /**
     * @description Handles exceptions during pipeline execution
     * @param e Exception that occurred
     */
    private void handleException(Exception e) {
        try {
            PromptFactoryLogger.logException(runId, currentStage,
                'Pipeline execution failed with exception', e);

            // Update run status
            List<PF_Run__c> runs = [
                SELECT Id, Status__c
                FROM PF_Run__c
                WHERE Id = :runId
                LIMIT 1
            ];

            if (!runs.isEmpty()) {
                runs[0].Status__c = 'Failed';
                runs[0].Error_Message__c = truncate(e.getMessage(), 5000);
                update runs[0];
            }

        } catch (Exception ex) {
            // Last resort - just log to debug
            System.debug(LoggingLevel.ERROR,
                'Critical failure in exception handler: ' + ex.getMessage());
        }
    }

    /**
     * @description Updates run status and current stage
     * @param run PF_Run__c record to update
     * @param status New status value
     * @param stage Current stage number
     */
    private void updateRunStatus(PF_Run__c run, String status, Integer stage) {
        run.Status__c = status;
        run.Current_Stage__c = stage;

        if (status == 'In Progress' && run.Started_At__c == null) {
            run.Started_At__c = System.now();
        }

        update run;
    }

    /**
     * @description Updates only the current stage field
     * @param run PF_Run__c record to update
     * @param stage Current stage number
     */
    private void updateCurrentStage(PF_Run__c run, Integer stage) {
        run.Current_Stage__c = stage;
        update run;
    }

    /**
     * @description Extracts quality score from Stage 12 outputs
     * @param outputs Map of stage outputs
     * @return Quality score as Decimal, or null if not found
     */
    private Decimal extractQualityScore(Map<String, Object> outputs) {
        if (outputs == null || !outputs.containsKey('qualityScore')) {
            return null;
        }

        Object score = outputs.get('qualityScore');
        if (score instanceof Decimal) {
            return (Decimal) score;
        } else if (score instanceof Integer) {
            return Decimal.valueOf((Integer) score);
        } else if (score instanceof String) {
            try {
                return Decimal.valueOf((String) score);
            } catch (Exception e) {
                return null;
            }
        }

        return null;
    }

    /**
     * @description Truncates a string to maximum length
     * @param str String to truncate
     * @param maxLength Maximum length
     * @return Truncated string
     */
    private String truncate(String str, Integer maxLength) {
        if (str == null) {
            return null;
        }
        if (str.length() <= maxLength) {
            return str;
        }
        return str.substring(0, maxLength - 3) + '...';
    }

    /**
     * @description Truncates JSON string smartly (tries to keep valid JSON)
     * @param jsonStr JSON string to truncate
     * @param maxLength Maximum length
     * @return Truncated string
     */
    private String truncateJSON(String jsonStr, Integer maxLength) {
        if (jsonStr == null) {
            return null;
        }
        if (jsonStr.length() <= maxLength) {
            return jsonStr;
        }
        // Truncate and add indicator
        return jsonStr.substring(0, maxLength - 20) + '..."[TRUNCATED]"}';
    }

    /**
     * @description Sanitizes a map for safe JSON serialization/storage.
     * This is defensive code to prevent stack depth errors from deep/recursive structures.
     */
    private Map<String, Object> sanitizeMapForStorage(Map<String, Object> source, Integer depth) {
        Map<String, Object> out = new Map<String, Object>();
        if (source == null) {
            return out;
        }
        if (depth >= MAX_SANITIZE_DEPTH) {
            out.put('note', '[DEPTH_LIMIT_REACHED]');
            return out;
        }

        for (String key : source.keySet()) {
            if (INPUT_OUTPUT_KEY_DENYLIST.contains(key)) {
                out.put(key, '[OMITTED]');
                continue;
            }
            Object value = source.get(key);
            out.put(key, sanitizeValueForStorage(value, depth + 1));
        }
        return out;
    }

    /**
     * @description Sanitizes an arbitrary value for safe JSON serialization/storage.
     */
    private Object sanitizeValueForStorage(Object value, Integer depth) {
        if (value == null) {
            return null;
        }
        if (depth >= MAX_SANITIZE_DEPTH) {
            return '[DEPTH_LIMIT_REACHED]';
        }

        // Preserve primitives
        if (value instanceof String) {
            String s = (String) value;
            return s.length() > MAX_STRING_LEN ? (s.substring(0, MAX_STRING_LEN - 3) + '...') : s;
        }
        if (value instanceof Boolean || value instanceof Integer || value instanceof Long ||
            value instanceof Decimal || value instanceof Double) {
            return value;
        }
        if (value instanceof Date) {
            return ((Date) value).format();
        }
        if (value instanceof DateTime) {
            return ((DateTime) value).format();
        }
        if (value instanceof Time) {
            return String.valueOf((Time) value);
        }
        if (value instanceof Id) {
            return (String) value;
        }

        // Collections
        if (value instanceof Map<String, Object>) {
            return sanitizeMapForStorage((Map<String, Object>) value, depth);
        }
        if (value instanceof List<Object>) {
            List<Object> src = (List<Object>) value;
            List<Object> out = new List<Object>();
            Integer itemLimit = (src.size() < MAX_LIST_ITEMS) ? src.size() : MAX_LIST_ITEMS;
            for (Integer i = 0; i < itemLimit; i++) {
                out.add(sanitizeValueForStorage(src[i], depth + 1));
            }
            if (src.size() > MAX_LIST_ITEMS) {
                out.add('[TRUNCATED_LIST_ITEMS:' + String.valueOf(src.size() - MAX_LIST_ITEMS) + ']');
            }
            return out;
        }

        // SObjects can create deep graphs; store an identifier only
        if (value instanceof SObject) {
            SObject sob = (SObject) value;
            try {
                return (sob.get('Id') != null) ? String.valueOf(sob.get('Id')) : String.valueOf(value);
            } catch (Exception e) {
                return String.valueOf(value);
            }
        }

        // Blobs are not safe/desired in logs
        if (value instanceof Blob) {
            return '[BLOB_OMITTED]';
        }

        // Fallback: stringified representation
        return String.valueOf(value);
    }

    /**
     * @description Custom exception for pipeline errors
     */
    public class PipelineException extends Exception {}
}