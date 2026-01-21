/**
 * @description Queueable wrapper for Stage 5 Field Selection
 * Uses StageJobHelper for consistent sanitization and stack overflow prevention.
 */
public class Stage05_FieldSelectionJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private static final Integer STAGE_NUM = 5;

    public Stage05_FieldSelectionJob(Id runId) {
        this.runId = runId;
    }

    /**
     * @description Executes Stage 5 in a fresh context, then chains to Stage 6
     */
    public void execute(QueueableContext context) {
        Boolean stageCompleted = false;

        try {
            // Load inputs from Stage 4 using helper
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 4);

            // Execute Stage 5
            IStage stage = new Stage05_FieldSelection();
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

        // Chain to Stage 6
        if (stageCompleted) {
            System.enqueueJob(new Stage06_ConfigurationValidationJob(runId));
        }
    }
}