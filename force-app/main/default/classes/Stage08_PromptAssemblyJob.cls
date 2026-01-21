/**
 * @description Queueable wrapper for Stage 8 Prompt Assembly
 * Uses StageJobHelper for consistent sanitization and stack overflow prevention.
 * Uses ChainBreaker after completion to reset chain depth for Stage 9+.
 */
public class Stage08_PromptAssemblyJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private static final Integer STAGE_NUM = 8;

    public Stage08_PromptAssemblyJob(Id runId) {
        this.runId = runId;
    }

    public void execute(QueueableContext context) {
        Boolean stageCompleted = false;

        try {
            // Load inputs from Stage 7 using helper
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 7);

            // Execute Stage 8
            IStage stage = new Stage08_PromptAssembly();
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

        // Chain to Stage 9 using ChainBreaker to reset chain depth
        if (stageCompleted) {
            try {
                // Use ChainBreaker to reset Queueable chain depth
                // This ensures Stage 9+ can chain without hitting stack depth limits
                PromptFactoryChainBreaker.scheduleStage(runId, 9);
            } catch (Exception e) {
                StageJobHelper.markRunFailed(runId, 'Failed to chain to Stage 9: ' + e.getMessage());
            }
        }
    }
}