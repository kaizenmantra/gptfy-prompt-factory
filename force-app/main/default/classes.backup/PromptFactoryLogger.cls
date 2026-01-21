/**
 * @description Centralized logging utility for Prompt Factory
 * Provides methods to create and retrieve activity logs
 */
public with sharing class PromptFactoryLogger {

    /**
     * @description Creates a log entry
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number (1-12, or null for pipeline-level logs)
     * @param logLevel DEBUG, INFO, WARNING, ERROR
     * @param logMessage The log message
     */
    public static void log(Id runId, Integer stageNumber, String logLevel, String logMessage) {
        log(runId, stageNumber, logLevel, logMessage, null, null);
    }

    /**
     * @description Creates a log entry with component and details
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number (1-12, or null for pipeline-level logs)
     * @param logLevel DEBUG, INFO, WARNING, ERROR
     * @param logMessage The log message
     * @param component Source component (class name)
     * @param details Additional context (JSON string)
     */
    public static void log(Id runId, Integer stageNumber, String logLevel,
                          String logMessage, String component, String details) {
        try {
            PF_Run_Log__c logEntry = new PF_Run_Log__c(
                Run__c = runId,
                Stage_Number__c = stageNumber,
                Log_Level__c = logLevel,
                Log_Message__c = truncate(logMessage, 10000),
                Timestamp__c = System.now(),
                Component__c = component,
                Details__c = truncate(details, 32000)
            );

            insert logEntry;
        } catch (Exception e) {
            // Log errors should not break the pipeline
            System.debug(LoggingLevel.ERROR, 'Failed to create log entry: ' + e.getMessage());
        }
    }

    /**
     * @description Bulk insert log entries (more efficient for multiple logs)
     * @param logEntries List of PF_Run_Log__c records to insert
     */
    public static void bulkLog(List<PF_Run_Log__c> logEntries) {
        try {
            if (logEntries != null && !logEntries.isEmpty()) {
                insert logEntries;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to bulk insert logs: ' + e.getMessage());
        }
    }

    /**
     * @description Creates a log entry record (without inserting)
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number (1-12, or null)
     * @param logLevel DEBUG, INFO, WARNING, ERROR
     * @param logMessage The log message
     * @param component Source component (class name)
     * @return PF_Run_Log__c record ready for insert
     */
    public static PF_Run_Log__c createLogEntry(Id runId, Integer stageNumber,
                                               String logLevel, String logMessage,
                                               String component) {
        return new PF_Run_Log__c(
            Run__c = runId,
            Stage_Number__c = stageNumber,
            Log_Level__c = logLevel,
            Log_Message__c = truncate(logMessage, 10000),
            Timestamp__c = System.now(),
            Component__c = component
        );
    }

    /**
     * @description Retrieves logs for a run
     * @param runId ID of the PF_Run__c record
     * @param maxCount Maximum number of logs to retrieve (ordered by timestamp desc)
     * @return List of log records
     */
    public static List<PF_Run_Log__c> getLogs(Id runId, Integer maxCount) {
        return [
            SELECT Id, Stage_Number__c, Log_Level__c, Log_Message__c,
                   Timestamp__c, Component__c, Details__c
            FROM PF_Run_Log__c
            WHERE Run__c = :runId
            ORDER BY Timestamp__c DESC
            LIMIT :maxCount
        ];
    }

    /**
     * @description Retrieves logs for a specific stage
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number to filter by
     * @return List of log records for that stage
     */
    public static List<PF_Run_Log__c> getStageLog(Id runId, Integer stageNumber) {
        return [
            SELECT Id, Stage_Number__c, Log_Level__c, Log_Message__c,
                   Timestamp__c, Component__c, Details__c
            FROM PF_Run_Log__c
            WHERE Run__c = :runId
            AND Stage_Number__c = :stageNumber
            ORDER BY Timestamp__c ASC
        ];
    }

    /**
     * @description Retrieves logs by level
     * @param runId ID of the PF_Run__c record
     * @param logLevel Level to filter by (ERROR, WARNING, etc.)
     * @return List of log records matching that level
     */
    public static List<PF_Run_Log__c> getLogsByLevel(Id runId, String logLevel) {
        return [
            SELECT Id, Stage_Number__c, Log_Level__c, Log_Message__c,
                   Timestamp__c, Component__c, Details__c
            FROM PF_Run_Log__c
            WHERE Run__c = :runId
            AND Log_Level__c = :logLevel
            ORDER BY Timestamp__c DESC
            LIMIT 100
        ];
    }

    /**
     * @description Truncates a string to a maximum length
     * @param str String to truncate
     * @param maxLength Maximum length
     * @return Truncated string
     */
    private static String truncate(String str, Integer maxLength) {
        if (str == null) {
            return null;
        }
        if (str.length() <= maxLength) {
            return str;
        }
        return str.substring(0, maxLength - 3) + '...';
    }

    /**
     * @description Convenience method to log INFO level
     */
    public static void info(Id runId, Integer stageNumber, String message) {
        log(runId, stageNumber, 'INFO', message);
    }

    /**
     * @description Convenience method to log DEBUG level
     */
    public static void debug(Id runId, Integer stageNumber, String message) {
        log(runId, stageNumber, 'DEBUG', message);
    }

    /**
     * @description Convenience method to log WARNING level
     */
    public static void warning(Id runId, Integer stageNumber, String message) {
        log(runId, stageNumber, 'WARNING', message);
    }

    /**
     * @description Convenience method to log ERROR level
     */
    public static void error(Id runId, Integer stageNumber, String message) {
        log(runId, stageNumber, 'ERROR', message);
    }

    /**
     * @description Logs an exception with full stack trace
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number
     * @param message Context message
     * @param ex The exception to log
     */
    public static void logException(Id runId, Integer stageNumber, String message, Exception ex) {
        String fullMessage = message + ': ' + ex.getMessage();
        String details = JSON.serialize(new Map<String, String>{
            'exceptionType' => ex.getTypeName(),
            'message' => ex.getMessage(),
            'stackTrace' => ex.getStackTraceString(),
            'lineNumber' => String.valueOf(ex.getLineNumber())
        });

        log(runId, stageNumber, 'ERROR', fullMessage, null, details);
    }
}