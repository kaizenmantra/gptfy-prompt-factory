/**
 * @description Queueable wrapper for Stage 10 Test Execution.
 * Coordinates between readiness checks and the Clean Callout Job.
 *
 * IMPORTANT: Enforces a minimum 30-second propagation delay before executing
 * the GPTfy REST API. Even after a prompt shows as Active with a Prompt Request ID,
 * GPTfy's backend needs additional time to fully register the prompt configuration.
 */
public class Stage10_TestExecutionJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private Integer retryCount;
    private static final Integer STAGE_NUM = 10;
    private static final Integer MAX_RETRIES = 18; // 18 retries * 20s = 6 minutes total

    // Minimum retry count before attempting callout (30 seconds = ~1.5 retry cycles at 20s each)
    // This gives GPTfy backend time to fully propagate the prompt after activation
    private static final Integer MIN_RETRIES_BEFORE_CALLOUT = 2; // 2 retries * 20s = 40 seconds minimum wait

    public Stage10_TestExecutionJob(Id runId) {
        this(runId, 0);
    }

    public Stage10_TestExecutionJob(Id runId, Integer retryCount) {
        this.runId = runId;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        try {
            // Load inputs from Stage 9
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 9);

            // PHASE 1: READINESS CHECK
            IStage stage = new Stage10_TestExecution();
            StageResult result = stage.execute(runId, inputs);

            // Handle "Retry" status (Prompt not ready yet)
            if (result.status == 'Retry') {
                if (retryCount < MAX_RETRIES) {
                    System.debug('Stage10: Prompt not ready. Scheduling retry #' + (retryCount + 1));
                    Stage10_RetryHandler.scheduleRetry(runId, retryCount + 1);
                    return;
                } else {
                    StageJobHelper.markRunFailed(runId, 'Prompt failed to become ready after 6 minutes.');
                    return;
                }
            }

            // Handle "ReadyForCallout" status
            if (result.status == 'ReadyForCallout') {
                // CRITICAL: Enforce minimum propagation delay before callout
                // GPTfy backend needs time to fully register the prompt even after it shows Active
                if (retryCount < MIN_RETRIES_BEFORE_CALLOUT) {
                    System.debug('Stage10: Prompt is ready but enforcing propagation delay. Retry #' + retryCount +
                                 ' of minimum ' + MIN_RETRIES_BEFORE_CALLOUT + ' required before callout.');
                    Stage10_RetryHandler.scheduleRetry(runId, retryCount + 1);
                    return;
                }

                String reqId = (String) result.outputs.get('promptRequestId');

                System.debug('Stage10: Prompt is ready and propagation delay complete. Handing off to Clean Callout Job.');
                System.enqueueJob(new Stage10_RestCalloutJob(runId, reqId, inputs));
                return;
            }

            // Handle direct failure in check logic
            if (result.status == 'Failed') {
                StageJobHelper.saveStageResult(runId, STAGE_NUM, result);
                StageJobHelper.markRunFailed(runId, result.errorMessage);
                return;
            }

        } catch (Exception e) {
            System.debug('Stage10_TestExecutionJob: Exception: ' + e.getMessage());
            StageJobHelper.markRunFailed(runId, 'Stage 10 Exception: ' + e.getMessage());
        }
    }
}