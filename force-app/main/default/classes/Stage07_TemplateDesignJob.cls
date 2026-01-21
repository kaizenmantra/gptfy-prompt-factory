/**
 * @description Queueable wrapper for Stage 7 Template Design
 * Uses StageJobHelper for consistent sanitization and stack overflow prevention.
 */
public class Stage07_TemplateDesignJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private static final Integer STAGE_NUM = 7;

    public Stage07_TemplateDesignJob(Id runId) {
        this.runId = runId;
    }

    public void execute(QueueableContext context) {
        Boolean stageCompleted = false;

        try {
            // Load inputs from Stage 6 using helper
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 6);

            // Execute Stage 7
            IStage stage = new Stage07_TemplateDesign();
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

        // Chain to Stage 8
        if (stageCompleted) {
            System.enqueueJob(new Stage08_PromptAssemblyJob(runId));
        }
    }
}