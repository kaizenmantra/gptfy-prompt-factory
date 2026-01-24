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

    /**
     * @description Reads the current state for a run
     * @param runId ID of the PF_Run__c record
     * @return Map containing the state, or empty map if no file exists
     */
    public static Map<String, Object> read(Id runId) {
        if (runId == null) {
            return new Map<String, Object>();
        }

        try {
            ContentVersion cv = getLatestVersion(runId);
            if (cv == null || cv.VersionData == null) {
                return new Map<String, Object>();
            }

            String jsonContent = cv.VersionData.toString();
            if (String.isBlank(jsonContent)) {
                return new Map<String, Object>();
            }

            return (Map<String, Object>) JSON.deserializeUntyped(jsonContent);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PipelineState.read error: ' + e.getMessage());
            return new Map<String, Object>();
        }
    }

    /**
     * @description Writes state for a run (creates file if needed, updates if exists)
     * Merges provided data with existing state
     * @param runId ID of the PF_Run__c record
     * @param data Map of key-value pairs to merge into state
     */
    public static void write(Id runId, Map<String, Object> data) {
        if (runId == null || data == null) {
            return;
        }

        // Read existing state and merge
        Map<String, Object> currentState = read(runId);
        for (String key : data.keySet()) {
            currentState.put(key, data.get(key));
        }

        // Update metadata
        currentState.put('runId', runId);
        currentState.put('lastUpdatedAt', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));

        // Serialize to JSON
        String jsonContent = JSON.serializePretty(currentState);

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
     * @description Initializes a new state file for a run
     * Creates the file with initial metadata. Call this at the start of pipeline.
     * @param runId ID of the PF_Run__c record
     * @param initialData Optional initial data to include
     * @return True if file was created, false if it already existed
     */
    public static Boolean initialize(Id runId, Map<String, Object> initialData) {
        if (runId == null) {
            return false;
        }

        // Check if file already exists
        ContentVersion existingCv = getLatestVersion(runId);
        if (existingCv != null) {
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

        // Create the file
        String jsonContent = JSON.serializePretty(state);
        createNewFile(runId, jsonContent);

        return true;
    }

    /**
     * @description Checks if a state file exists for the run
     * @param runId ID of the PF_Run__c record
     * @return True if file exists
     */
    public static Boolean exists(Id runId) {
        return getLatestVersion(runId) != null;
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
