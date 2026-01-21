/**
 * @description Queueable wrapper for Stage 6 Configuration Validation
 * Uses StageJobHelper for consistent sanitization and stack overflow prevention.
 */
public class Stage06_ConfigurationValidationJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private static final Integer STAGE_NUM = 6;

    public Stage06_ConfigurationValidationJob(Id runId) {
        this.runId = runId;
    }

    public void execute(QueueableContext context) {
        Boolean stageCompleted = false;

        try {
            // Load inputs from Stage 5 using helper
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 5);

            // Execute Stage 6
            IStage stage = new Stage06_ConfigurationValidation();
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

        // Chain to Stage 7
        if (stageCompleted) {
            System.enqueueJob(new Stage07_TemplateDesignJob(runId));
        }
    }
}