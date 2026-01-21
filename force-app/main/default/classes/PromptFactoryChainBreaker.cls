/**
 * @description Schedulable class that breaks the Queueable chain depth
 *
 * PROBLEM: Salesforce has an implicit limit on Queueable chain depth (~5 chains).
 * When the pipeline chains: Pipeline(1) -> Pipeline(2) -> Pipeline(3) -> Pipeline(4) -> Pipeline(5)
 * it hits "Maximum stack depth has been reached" when trying to enqueue Stage05_FieldSelectionJob.
 *
 * SOLUTION: After Stage 4 completes, schedule this class to run immediately (within 1 minute).
 * When the Schedulable executes, it's in a fresh context with chain depth = 0, allowing the
 * pipeline to continue with stages 5-12.
 *
 * Usage:
 * ```apex
 * // In PromptFactoryPipeline after Stage 4 completes:
 * PromptFactoryChainBreaker.scheduleStage5(runId);
 * ```
 */
public class PromptFactoryChainBreaker implements Schedulable {

    private Id runId;
    private Integer stageToRun;

    /**
     * @description Constructor for chain breaker
     * @param runId The PF_Run__c record ID
     * @param stageToRun The stage number to execute (5-12)
     */
    public PromptFactoryChainBreaker(Id runId, Integer stageToRun) {
        this.runId = runId;
        this.stageToRun = stageToRun;
    }

    /**
     * @description Scheduled execute method - enqueues the appropriate stage job
     */
    public void execute(SchedulableContext sc) {
        // Enqueue the appropriate stage job
        // This runs in a fresh context with chain depth = 0
        if (stageToRun == 5) {
            System.enqueueJob(new Stage05_FieldSelectionJob(runId));
        } else if (stageToRun == 6) {
            System.enqueueJob(new Stage06_ConfigurationValidationJob(runId));
        } else if (stageToRun == 7) {
            System.enqueueJob(new Stage07_TemplateDesignJob(runId));
        } else if (stageToRun == 8) {
            System.enqueueJob(new Stage08_PromptAssemblyJob(runId));
        } else if (stageToRun == 9) {
            System.enqueueJob(new Stage09_CreateAndDeployJob(runId));
        } else if (stageToRun == 10) {
            System.enqueueJob(new Stage10_TestExecutionJob(runId));
        } else if (stageToRun == 11) {
            System.enqueueJob(new Stage11_SafetyValidationJob(runId));
        } else if (stageToRun == 12) {
            System.enqueueJob(new Stage12_QualityAuditJob(runId));
        }

        // Abort this scheduled job after execution
        System.abortJob(sc.getTriggerId());
    }

    /**
     * @description Static helper to schedule Stage 5 execution
     * Schedules the job to run immediately (within 1 minute)
     * @param runId The PF_Run__c record ID
     * @return The scheduled job ID
     */
    public static String scheduleStage5(Id runId) {
        return scheduleStage(runId, 5);
    }

    /**
     * @description Static helper to schedule any stage execution
     * Schedules the job to run immediately (within 1 minute)
     * @param runId The PF_Run__c record ID
     * @param stageNumber The stage to execute
     * @return The scheduled job ID
     */
    public static String scheduleStage(Id runId, Integer stageNumber) {
        // Create a unique job name
        String jobName = 'PF_ChainBreak_' + runId + '_S' + stageNumber + '_' + System.currentTimeMillis();

        // Schedule to run as soon as possible (next minute)
        DateTime nextMinute = System.now().addSeconds(5);
        String cronExp = nextMinute.second() + ' ' +
                         nextMinute.minute() + ' ' +
                         nextMinute.hour() + ' ' +
                         nextMinute.day() + ' ' +
                         nextMinute.month() + ' ' +
                         '? ' +
                         nextMinute.year();

        PromptFactoryChainBreaker chainBreaker = new PromptFactoryChainBreaker(runId, stageNumber);
        return System.schedule(jobName, cronExp, chainBreaker);
    }
}