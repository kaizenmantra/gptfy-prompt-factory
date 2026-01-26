/**
 * @description Pipeline State Management using ContentVersion
 * Provides simple read/write access to a JSON state file attached to each PF_Run__c record.
 * Replaces complex stage-record-based data passing with a single source of truth.
 *
 * Benefits:
 * - Single source of truth - One file, not 12 stage records
 * - No size limits - ContentVersion supports up to 2GB
 * - Easy debugging - Download JSON, open in any editor
 * - Full history - Each write creates a new version
 * - No FLS issues - ContentVersion is standard Salesforce
 * - Simple code - Read, modify, write pattern
 *
 * @author Claude Opus 4.5
 * @date 2026-01-24
 */
public with sharing class PipelineState {

    private static final String FILE_PREFIX = 'pipeline_state_';
    private static final String FILE_EXTENSION = '.json';
    private static final String PATH_ON_CLIENT = 'pipeline_state.json';
    private static final String SHARE_TYPE = 'V'; // Viewer access

    // ============================================================================
    // IN-MEMORY STATE WITH OPTIONAL FILE LOGGING
    // ============================================================================
    // By default, state is kept in memory only and passed via PF_Run_Stage__c records.
    // File logging is DISABLED by default to avoid ContentPublication limits.
    // Set ENABLE_FILE_LOGGING = true for debugging (creates ~12 files per run).
    //
    // Stage records (Output_Data__c) have 131KB limit - our max usage is ~35KB (27%).
    // ============================================================================

    // Set to true to enable file logging for debugging (creates ~12 ContentVersions per run)
    @TestVisible
    private static final Boolean ENABLE_FILE_LOGGING = false;

    // In-memory buffer for state (keyed by runId) - primary state storage
    private static Map<Id, Map<String, Object>> stateBuffer = new Map<Id, Map<String, Object>>();

    // Track which runs have pending changes (for file logging when enabled)
    private static Set<Id> dirtyRuns = new Set<Id>();

    /**
     * @description Reads the current state for a run
     * Returns buffered state if available, otherwise reads from file
     * Fallback: Aggregates state from all completed PF_Run_Stage__c records (Distributed State)
     * @param runId ID of the PF_Run__c record
     * @return Map containing the state, or empty map if no state found
     */
    public static Map<String, Object> read(Id runId) {
        if (runId == null) {
            return new Map<String, Object>();
        }

        // Check buffer first (may have unflushed changes)
        if (stateBuffer.containsKey(runId)) {
            return stateBuffer.get(runId);
        }

        // Try reading from file first (if enabled/exists)
        try {
            ContentVersion cv = getLatestVersion(runId);
            if (cv != null && cv.VersionData != null) {
                String jsonContent = cv.VersionData.toString();
                if (String.isNotBlank(jsonContent)) {
                    Map<String, Object> state = (Map<String, Object>) JSON.deserializeUntyped(jsonContent);
                    stateBuffer.put(runId, state);
                    return state;
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PipelineState.read file error: ' + e.getMessage());
        }

        // Fallback: Distributed Read from PF_Run_Stage__c records
        // Aggregates Output_Data__c from all completed stages in order
        try {
            Map<String, Object> aggregatedState = new Map<String, Object>();
            
            List<PF_Run_Stage__c> stages = [
                SELECT Output_Data__c
                FROM PF_Run_Stage__c 
                WHERE Run__c = :runId 
                ORDER BY Stage_Number__c ASC
            ];

            for (PF_Run_Stage__c stage : stages) {
                if (String.isNotBlank(stage.Output_Data__c)) {
                    try {
                        Map<String, Object> stageOutputs = (Map<String, Object>) JSON.deserializeUntyped(stage.Output_Data__c);
                        aggregatedState.putAll(stageOutputs);
                    } catch (Exception jsonEx) {
                        System.debug(LoggingLevel.WARN, 'Failed to parse output for stage: ' + jsonEx.getMessage());
                    }
                }
            }

            if (!aggregatedState.isEmpty()) {
                // Cache aggregated state in buffer
                stateBuffer.put(runId, aggregatedState);
                return aggregatedState;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PipelineState.read distributed error: ' + e.getMessage());
        }

        return new Map<String, Object>();
    }

    /**
     * @description Writes state to buffer (does NOT write to file)
     * Call flush() to persist buffered changes to file.
     * Merges provided data with existing state
     * @param runId ID of the PF_Run__c record
     * @param data Map of key-value pairs to merge into state
     */
    public static void write(Id runId, Map<String, Object> data) {
        if (runId == null || data == null) {
            return;
        }

        // Read existing state (from buffer or file) and merge
        Map<String, Object> currentState = read(runId);
        for (String key : data.keySet()) {
            currentState.put(key, data.get(key));
        }

        // Update metadata
        currentState.put('runId', runId);
        currentState.put('lastUpdatedAt', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));

        // Store in buffer (NOT file) and mark dirty
        stateBuffer.put(runId, currentState);
        dirtyRuns.add(runId);
    }

    /**
     * @description Flushes buffered state to file (creates ONE ContentVersion)
     * Call this ONCE at the end of each stage to persist all changes.
     * @param runId ID of the PF_Run__c record
     * @return True if flush was successful, false otherwise
     */
    public static Boolean flush(Id runId) {
        if (runId == null || !dirtyRuns.contains(runId)) {
            return false; // Nothing to flush
        }

        // Clear dirty flag regardless of file logging
        dirtyRuns.remove(runId);

        // Skip file writes when file logging is disabled (default)
        if (!ENABLE_FILE_LOGGING) {
            return true; // State is in buffer, no file needed
        }

        Map<String, Object> state = stateBuffer.get(runId);
        if (state == null || state.isEmpty()) {
            return false;
        }

        try {
            String jsonContent = JSON.serializePretty(state);

            // Check if file already exists
            ContentVersion existingCv = getLatestVersion(runId);

            if (existingCv != null) {
                // Update existing file by creating new version
                ContentVersion newVersion = new ContentVersion(
                    ContentDocumentId = existingCv.ContentDocumentId,
                    Title = FILE_PREFIX + runId + FILE_EXTENSION,
                    PathOnClient = PATH_ON_CLIENT,
                    VersionData = Blob.valueOf(jsonContent),
                    Origin = 'H'
                );
                insert newVersion;
            } else {
                // Create new file
                createNewFile(runId, jsonContent);
            }

            System.debug('PipelineState: Flushed state to file for run ' + runId);
            return true;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PipelineState.flush error: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Convenience method to get a single value from state
     * @param runId ID of the PF_Run__c record
     * @param key Key to retrieve
     * @return Value for the key, or null if not found
     */
    public static Object get(Id runId, String key) {
        Map<String, Object> state = read(runId);
        return state.get(key);
    }

    /**
     * @description Convenience method to set a single value in state
     * @param runId ID of the PF_Run__c record
     * @param key Key to set
     * @param value Value to store
     */
    public static void put(Id runId, String key, Object value) {
        Map<String, Object> data = new Map<String, Object>();
        data.put(key, value);
        write(runId, data);
    }

    /**
     * @description Appends a log entry to the state's log array
     * @param runId ID of the PF_Run__c record
     * @param stage Stage number (1-12)
     * @param level Log level (INFO, DEBUG, WARNING, ERROR)
     * @param message Log message
     */
    public static void log(Id runId, Integer stage, String level, String message) {
        if (runId == null) {
            return;
        }

        Map<String, Object> state = read(runId);

        // Get or create logs array
        List<Object> logs = new List<Object>();
        if (state.containsKey('logs') && state.get('logs') != null) {
            logs = (List<Object>) state.get('logs');
        }

        // Create log entry
        Map<String, Object> logEntry = new Map<String, Object>{
            'stage' => stage,
            'ts' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),
            'level' => level,
            'msg' => message
        };

        logs.add(logEntry);
        state.put('logs', logs);

        // Write back
        write(runId, state);
    }

    /**
     * @description Gets the ContentVersion ID for the state file (for LWC display)
     * @param runId ID of the PF_Run__c record
     * @return ContentVersion ID, or null if no file exists
     */
    public static Id getFileId(Id runId) {
        ContentVersion cv = getLatestVersion(runId);
        return cv != null ? cv.Id : null;
    }

    /**
     * @description Gets the ContentDocumentId for the state file
     * @param runId ID of the PF_Run__c record
     * @return ContentDocumentId, or null if no file exists
     */
    public static Id getDocumentId(Id runId) {
        ContentVersion cv = getLatestVersion(runId);
        return cv != null ? cv.ContentDocumentId : null;
    }

    /**
     * @description Initializes state for a run (buffered, no file write)
     * Call flush() to persist to file.
     * @param runId ID of the PF_Run__c record
     * @param initialData Optional initial data to include
     * @return True if initialized, false if already existed
     */
    public static Boolean initialize(Id runId, Map<String, Object> initialData) {
        if (runId == null) {
            return false;
        }

        // Check if already in buffer
        if (stateBuffer.containsKey(runId)) {
            return false; // Already initialized
        }

        // Check if file already exists
        ContentVersion existingCv = getLatestVersion(runId);
        if (existingCv != null) {
            // Load existing state into buffer
            read(runId);
            return false; // File already exists
        }

        // Build initial state
        Map<String, Object> state = new Map<String, Object>{
            'runId' => runId,
            'createdAt' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),
            'lastUpdatedAt' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),
            'logs' => new List<Object>()
        };

        // Merge initial data if provided
        if (initialData != null) {
            for (String key : initialData.keySet()) {
                state.put(key, initialData.get(key));
            }
        }

        // Store in buffer and mark dirty
        stateBuffer.put(runId, state);
        dirtyRuns.add(runId);

        return true;
    }

    /**
     * @description Checks if state exists for the run (in buffer or file)
     * @param runId ID of the PF_Run__c record
     * @return True if state exists
     */
    public static Boolean exists(Id runId) {
        if (stateBuffer.containsKey(runId)) {
            return true;
        }
        return getLatestVersion(runId) != null;
    }

    /**
     * @description Check if there are unflushed changes for a run
     * @param runId ID of the PF_Run__c record
     * @return True if there are pending changes to flush
     */
    public static Boolean hasPendingChanges(Id runId) {
        return dirtyRuns.contains(runId);
    }

    /**
     * @description Gets the raw JSON content of the state file
     * Useful for debugging and LWC display
     * @param runId ID of the PF_Run__c record
     * @return JSON string, or null if no file exists
     */
    public static String getJson(Id runId) {
        ContentVersion cv = getLatestVersion(runId);
        if (cv == null || cv.VersionData == null) {
            return null;
        }
        return cv.VersionData.toString();
    }

    /**
     * @description Updates the lastUpdatedByStage field in state
     * Call this at the end of each stage to track progress
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number that just completed
     */
    public static void markStageComplete(Id runId, Integer stageNumber) {
        Map<String, Object> data = new Map<String, Object>();
        data.put('lastUpdatedByStage', stageNumber);
        write(runId, data);
    }

    // ==================== PRIVATE HELPER METHODS ====================

    /**
     * @description Gets the latest ContentVersion for a run's state file
     * @param runId ID of the PF_Run__c record
     * @return ContentVersion with VersionData, or null if not found
     */
    private static ContentVersion getLatestVersion(Id runId) {
        if (runId == null) {
            return null;
        }

        String fileName = FILE_PREFIX + runId + FILE_EXTENSION;

        // Find ContentDocumentLinks for this run
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :runId
            LIMIT 100
        ];

        if (links.isEmpty()) {
            return null;
        }

        // Get ContentDocument IDs
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : links) {
            docIds.add(cdl.ContentDocumentId);
        }

        // Find the state file by title
        List<ContentVersion> versions = [
            SELECT Id, ContentDocumentId, Title, VersionData, CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            AND Title = :fileName
            AND IsLatest = true
            LIMIT 1
        ];

        return versions.isEmpty() ? null : versions[0];
    }

    /**
     * @description Creates a new ContentVersion and links it to the run
     * @param runId ID of the PF_Run__c record
     * @param jsonContent JSON content to store
     */
    private static void createNewFile(Id runId, String jsonContent) {
        String fileName = FILE_PREFIX + runId + FILE_EXTENSION;

        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = PATH_ON_CLIENT,
            VersionData = Blob.valueOf(jsonContent),
            Origin = 'H'
        );
        insert cv;

        // Query back to get ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // Create link to the run record
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = runId,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = SHARE_TYPE
        );
        insert cdl;
    }

    /**
     * @description Custom exception for pipeline state errors
     */
    public class PipelineStateException extends Exception {}
}
