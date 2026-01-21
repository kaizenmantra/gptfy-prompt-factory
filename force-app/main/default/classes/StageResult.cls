/**
 * @description Wrapper class for stage execution results
 * Contains status, inputs/outputs, AI reasoning, and logs
 */
public class StageResult {
    @AuraEnabled public String stageName;
    @AuraEnabled public String status; // Completed, Failed, Warning, Skipped
    @AuraEnabled public Map<String, Object> inputs;
    @AuraEnabled public Map<String, Object> outputs;
    @AuraEnabled public String aiReasoning;
    @AuraEnabled public String errorMessage;
    @AuraEnabled public DateTime startedAt;
    @AuraEnabled public List<PF_Run_Log__c> logs;

    /**
     * @description Constructor initializes with stage name
     * @param stageName Name of the stage being executed
     */
    public StageResult(String stageName) {
        this.stageName = stageName;
        this.status = 'In Progress';
        this.inputs = new Map<String, Object>();
        this.outputs = new Map<String, Object>();
        this.logs = new List<PF_Run_Log__c>();
        this.startedAt = System.now();
    }

    /**
     * @description Marks the stage as successfully completed
     */
    public void markCompleted() {
        this.status = 'Completed';
    }

    /**
     * @description Marks the stage as failed with error message
     * @param errorMessage Error details
     */
    public void markFailed(String errorMessage) {
        this.status = 'Failed';
        this.errorMessage = errorMessage;
    }

    /**
     * @description Marks the stage as completed with warning
     * @param warningMessage Warning details
     */
    public void markWarning(String warningMessage) {
        this.status = 'Warning';
        this.errorMessage = warningMessage;
    }

    /**
     * @description Marks the stage as skipped
     * @param reason Reason for skipping
     */
    public void markSkipped(String reason) {
        this.status = 'Skipped';
        this.errorMessage = reason;
    }

    /**
     * @description Adds a log entry to the result
     * @param logEntry PF_Run_Log__c record to add
     */
    public void addLog(PF_Run_Log__c logEntry) {
        this.logs.add(logEntry);
    }

    /**
     * @description Queues an INFO log entry for deferred insert (no DML until after callouts)
     * @param runId ID of the run
     * @param stageNumber Stage number
     * @param message Log message
     */
    public void queueInfo(Id runId, Integer stageNumber, String message) {
        this.logs.add(PromptFactoryLogger.createLogEntry(runId, stageNumber, 'INFO', message, null));
    }

    /**
     * @description Queues a DEBUG log entry for deferred insert
     * @param runId ID of the run
     * @param stageNumber Stage number
     * @param message Log message
     */
    public void queueDebug(Id runId, Integer stageNumber, String message) {
        this.logs.add(PromptFactoryLogger.createLogEntry(runId, stageNumber, 'DEBUG', message, null));
    }

    /**
     * @description Queues a WARNING log entry for deferred insert
     * @param runId ID of the run
     * @param stageNumber Stage number
     * @param message Log message
     */
    public void queueWarning(Id runId, Integer stageNumber, String message) {
        this.logs.add(PromptFactoryLogger.createLogEntry(runId, stageNumber, 'WARNING', message, null));
    }

    /**
     * @description Queues an ERROR log entry for deferred insert
     * @param runId ID of the run
     * @param stageNumber Stage number
     * @param message Log message
     */
    public void queueError(Id runId, Integer stageNumber, String message) {
        this.logs.add(PromptFactoryLogger.createLogEntry(runId, stageNumber, 'ERROR', message, null));
    }

    /**
     * @description Calculates execution duration
     * @return Duration in seconds
     */
    public Decimal getDurationSeconds() {
        if (startedAt == null) {
            return 0;
        }
        Long milliseconds = System.now().getTime() - startedAt.getTime();
        return milliseconds / 1000.0;
    }
}