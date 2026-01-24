/**
 * @description Shared utility class for Stage Job classes
 * Provides consistent sanitization, size checking, and serialization
 * across all pipeline Job classes (Stage05-12).
 *
 * STACK OVERFLOW PREVENTION:
 * This class centralizes the sanitization logic to ensure all Job classes
 * handle large data structures safely without causing stack depth errors.
 */
public class StageJobHelper {

    // Constants for sanitization limits
    private static final Integer MAX_SANITIZE_DEPTH = 5;
    private static final Integer MAX_LIST_ITEMS = 200;
    private static final Integer MAX_STRING_LEN = 5000;
    private static final Integer MAX_OUTPUT_JSON_SIZE = 130000;

    // Keys that should be omitted to prevent stack overflow
    private static final Set<String> KEY_DENYLIST = new Set<String>{
        'recordData', 'recordDataJson',
        'fullRecord', 'fullRecordJson',
        'dataAvailability', 'allFieldsMetadata',
        'rawFieldsByObject', 'candidateFieldsRaw'
    };

    /**
     * @description Safely serializes stage outputs for storage
     * Includes size checking, sanitization, and truncation
     * @param outputs Map of stage outputs to serialize
     * @return JSON string safe for storage in Output_Data__c
     */
    public static String serializeOutputs(Map<String, Object> outputs) {
        if (outputs == null || outputs.isEmpty()) {
            return '{}';
        }

        try {
            // First, estimate size to avoid unnecessary processing
            String rawJson = JSON.serialize(outputs);
            if (rawJson.length() <= MAX_OUTPUT_JSON_SIZE) {
                return rawJson;
            }

            // Size exceeds limit - sanitize to reduce size
            Map<String, Object> sanitized = sanitizeMapForStorage(outputs, 0);
            String sanitizedJson = JSON.serialize(sanitized);

            // Truncate if still too large
            if (sanitizedJson.length() > MAX_OUTPUT_JSON_SIZE) {
                return truncateJson(sanitizedJson, MAX_OUTPUT_JSON_SIZE);
            }

            return sanitizedJson;

        } catch (Exception e) {
            // Serialization failed - return error indicator
            return '{"serializationError": true, "message": "' +
                String.valueOf(e.getMessage()).replace('"', '\\"').left(200) + '"}';
        }
    }

    /**
     * @description Sanitizes a map for safe JSON serialization/storage
     * Prevents stack depth errors from deep/recursive structures
     * @param source Source map to sanitize
     * @param depth Current recursion depth
     * @return Sanitized map safe for serialization
     */
    public static Map<String, Object> sanitizeMapForStorage(Map<String, Object> source, Integer depth) {
        Map<String, Object> out = new Map<String, Object>();

        if (source == null) {
            return out;
        }

        if (depth >= MAX_SANITIZE_DEPTH) {
            out.put('_note', '[DEPTH_LIMIT_REACHED]');
            return out;
        }

        for (String key : source.keySet()) {
            // Skip denylisted keys
            if (KEY_DENYLIST.contains(key)) {
                out.put(key, '[OMITTED_LARGE_DATA]');
                continue;
            }

            Object value = source.get(key);
            out.put(key, sanitizeValueForStorage(value, depth + 1));
        }

        return out;
    }

    /**
     * @description Sanitizes an arbitrary value for safe JSON serialization
     * @param value Value to sanitize
     * @param depth Current recursion depth
     * @return Sanitized value
     */
    public static Object sanitizeValueForStorage(Object value, Integer depth) {
        if (value == null) {
            return null;
        }

        if (depth >= MAX_SANITIZE_DEPTH) {
            return '[DEPTH_LIMIT_REACHED]';
        }

        // Preserve primitives with size limits
        if (value instanceof String) {
            String s = (String) value;
            return s.length() > MAX_STRING_LEN
                ? s.substring(0, MAX_STRING_LEN - 3) + '...'
                : s;
        }

        if (value instanceof Boolean || value instanceof Integer ||
            value instanceof Long || value instanceof Decimal ||
            value instanceof Double) {
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

        // Handle nested maps
        if (value instanceof Map<String, Object>) {
            return sanitizeMapForStorage((Map<String, Object>) value, depth);
        }

        // Handle lists with item limits
        if (value instanceof List<Object>) {
            List<Object> src = (List<Object>) value;
            List<Object> out = new List<Object>();

            Integer itemLimit = Math.min(src.size(), MAX_LIST_ITEMS);
            for (Integer i = 0; i < itemLimit; i++) {
                out.add(sanitizeValueForStorage(src[i], depth + 1));
            }

            if (src.size() > MAX_LIST_ITEMS) {
                out.add('[TRUNCATED:' + (src.size() - MAX_LIST_ITEMS) + '_items]');
            }

            return out;
        }

        // SObjects can create deep graphs - extract ID only
        if (value instanceof SObject) {
            SObject sob = (SObject) value;
            try {
                Object sobId = sob.get('Id');
                return sobId != null ? String.valueOf(sobId) : '[SObject_NO_ID]';
            } catch (Exception e) {
                return '[SObject]';
            }
        }

        // Blobs are not safe for logs
        if (value instanceof Blob) {
            return '[BLOB_OMITTED]';
        }

        // Fallback: stringified representation
        String stringVal = String.valueOf(value);
        return stringVal.length() > MAX_STRING_LEN
            ? stringVal.substring(0, MAX_STRING_LEN - 3) + '...'
            : stringVal;
    }

    /**
     * @description Truncates JSON string while trying to keep it valid
     * @param jsonStr JSON string to truncate
     * @param maxLength Maximum allowed length
     * @return Truncated JSON string
     */
    public static String truncateJson(String jsonStr, Integer maxLength) {
        if (jsonStr == null) {
            return '{}';
        }

        if (jsonStr.length() <= maxLength) {
            return jsonStr;
        }

        // Truncate and add indicator that JSON is incomplete
        return jsonStr.substring(0, maxLength - 25) + '..."_truncated": true}';
    }

    /**
     * @description Truncates a string to maximum length with ellipsis
     * @param str String to truncate
     * @param maxLength Maximum length
     * @return Truncated string
     */
    public static String truncate(String str, Integer maxLength) {
        if (str == null) {
            return null;
        }

        if (str.length() <= maxLength) {
            return str;
        }

        return str.substring(0, maxLength - 3) + '...';
    }

    /**
     * @description Loads inputs from PipelineState JSON file
     * V2.3: Now uses PipelineState for reliable state passing
     * Falls back to stage record if state file doesn't exist (legacy runs)
     * @param runId The PF_Run__c record ID
     * @param previousStageNumber The stage number (used for fallback only)
     * @return Map of input data, empty map if not found
     */
    public static Map<String, Object> loadInputsFromStage(Id runId, Integer previousStageNumber) {
        // V2.3: Primary method - read from PipelineState JSON file
        Map<String, Object> inputs = PipelineState.read(runId);

        if (!inputs.isEmpty()) {
            return inputs;
        }

        // Fallback: Legacy stage record loading for old runs without state file
        System.debug(LoggingLevel.WARN,
            'PipelineState file not found for run ' + runId + ', falling back to stage record');

        List<PF_Run_Stage__c> stages = [
            SELECT Output_Data__c
            FROM PF_Run_Stage__c
            WHERE Run__c = :runId AND Stage_Number__c = :previousStageNumber
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (stages.isEmpty() || String.isBlank(stages[0].Output_Data__c)) {
            return new Map<String, Object>();
        }

        try {
            Object parsed = JSON.deserializeUntyped(stages[0].Output_Data__c);
            if (parsed instanceof Map<String, Object>) {
                return (Map<String, Object>) parsed;
            }
            return new Map<String, Object>();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Failed to parse stage ' + previousStageNumber + ' outputs: ' + e.getMessage());
            return new Map<String, Object>();
        }
    }

    /**
     * @description Creates and inserts a PF_Run_Stage__c record with sanitized data
     * V2.3: Also writes outputs to PipelineState JSON file for reliable state passing
     * @param runId The PF_Run__c record ID
     * @param stageNumber Stage number (1-12)
     * @param result StageResult from execution
     */
    public static void saveStageResult(Id runId, Integer stageNumber, StageResult result) {
        // ========================================
        // V2.3: Write outputs to PipelineState JSON file
        // This is the primary mechanism for passing data between stages
        // ========================================
        if (result.outputs != null && !result.outputs.isEmpty()) {
            try {
                PipelineState.write(runId, result.outputs);
                PipelineState.markStageComplete(runId, stageNumber);
                PipelineState.log(runId, stageNumber, 'INFO',
                    'Stage ' + stageNumber + ' completed: ' + result.status);
            } catch (Exception e) {
                // Log but don't fail - stage records are still available as backup
                System.debug(LoggingLevel.WARN,
                    'Failed to write to PipelineState: ' + e.getMessage());
            }
        }

        // ========================================
        // Continue saving to stage record (for debugging/audit)
        // ========================================
        String outputsJson = serializeOutputs(result.outputs);

        PF_Run_Stage__c stageRecord = new PF_Run_Stage__c(
            Run__c = runId,
            Stage_Number__c = stageNumber,
            Stage_Name__c = result.stageName,
            Status__c = result.status,
            Input_Data__c = '{}',  // Inputs stored on previous stage's output
            Output_Data__c = outputsJson,
            AI_Reasoning__c = truncate(result.aiReasoning, 32000),
            Error_Message__c = truncate(result.errorMessage, 5000),
            Started_At__c = result.startedAt,
            Completed_At__c = System.now(),
            Duration_Seconds__c = result.getDurationSeconds()
        );

        insert stageRecord;

        // Bulk insert logs if any
        if (result.logs != null && !result.logs.isEmpty()) {
            insert result.logs;
        }
    }

    /**
     * @description Updates the current stage progress on the run record
     * @param runId The PF_Run__c record ID
     * @param stageNumber Current stage number
     */
    public static void updateProgress(Id runId, Integer stageNumber) {
        PF_Run__c run = [SELECT Id FROM PF_Run__c WHERE Id = :runId LIMIT 1];
        run.Current_Stage__c = stageNumber;
        update run;
    }

    /**
     * @description Marks a run as failed with an error message
     * @param runId The PF_Run__c record ID
     * @param errorMsg Error message to store
     */
    public static void markRunFailed(Id runId, String errorMsg) {
        try {
            PF_Run__c run = [SELECT Id FROM PF_Run__c WHERE Id = :runId LIMIT 1];
            run.Status__c = 'Failed';
            run.Error_Message__c = truncate(errorMsg, 5000);
            update run;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Failed to mark run as failed: ' + e.getMessage());
        }
    }

    /**
     * @description Checks if a stage result indicates success
     * @param result StageResult to check
     * @return True if stage completed successfully or with warning
     */
    public static Boolean isStageSuccess(StageResult result) {
        return result != null &&
            (result.status == 'Completed' || result.status == 'Warning');
    }
}