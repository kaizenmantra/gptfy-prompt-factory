/**
 * @description Queueable wrapper for Stage 11 Safety Validation
 * Uses StageJobHelper for consistent sanitization and stack overflow prevention.
 * Uses ChainBreaker after completion to reset chain depth for Stage 12.
 */
public class Stage11_SafetyValidationJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private static final Integer STAGE_NUM = 11;

    public Stage11_SafetyValidationJob(Id runId) {
        this.runId = runId;
    }

    public void execute(QueueableContext context) {
        Boolean stageCompleted = false;

        try {
            // Load inputs from Stage 10 using helper
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 10);

            // Execute Stage 11
            IStage stage = new Stage11_SafetyValidation();
            StageResult result = stage.execute(runId, inputs);

            // Save result using helper (handles sanitization)
            StageJobHelper.saveStageResult(runId, STAGE_NUM, result);

            // Update progress
            StageJobHelper.updateProgress(runId, STAGE_NUM);

            // Check if stage succeeded
            stageCompleted = StageJobHelper.isStageSuccess(result);

            if (!stageCompleted) {
                StageJobHelper.markRunFailed(runId, result.errorMessage);
            }

        } catch (Exception e) {
            StageJobHelper.markRunFailed(runId, 'Stage ' + STAGE_NUM + ' exception: ' + e.getMessage());
            return;
        }

        // Chain to Stage 12 using ChainBreaker to reset chain depth
        // This is an additional safety measure since we're at chain depth ~4
        if (stageCompleted) {
            try {
                PromptFactoryChainBreaker.scheduleStage(runId, 12);
            } catch (Exception e) {
                // Fallback to direct enqueue if scheduling fails
                System.enqueueJob(new Stage12_QualityAuditJob(runId));
            }
        }
    }
}