/**
 * @description Schedulable helper to re-enqueue Stage 10 readiness check after a delay.
 */
public class Stage10_RetryHandler implements Schedulable {
    private Id runId;
    private Integer retryCount;

    public Stage10_RetryHandler(Id runId, Integer retryCount) {
        this.runId = runId;
        this.retryCount = retryCount;
    }

    public void execute(SchedulableContext sc) {
        // Enqueue a new Job with the current retry count
        System.enqueueJob(new Stage10_TestExecutionJob(runId, retryCount));
        
        // Clean up the job after execution
        System.abortJob(sc.getTriggerId());
    }

    /**
     * @description Schedules a retry 20 seconds from now
     */
    public static void scheduleRetry(Id runId, Integer retryCount) {
        DateTime now = System.now().addSeconds(20);
        String cron = now.second() + ' ' + now.minute() + ' ' + now.hour() + ' ' + now.day() + ' ' + now.month() + ' ? ' + now.year();
        System.schedule('Stage10_Retry_' + runId + '_' + retryCount + '_' + System.currentTimeMillis(), cron, new Stage10_RetryHandler(runId, retryCount));
    }
}