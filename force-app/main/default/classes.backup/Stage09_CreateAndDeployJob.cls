/**
 * @description Queueable wrapper for Stage 9 Create and Deploy
 * Uses StageJobHelper for consistent sanitization and stack overflow prevention.
 */
public class Stage09_CreateAndDeployJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private static final Integer STAGE_NUM = 9;

    public Stage09_CreateAndDeployJob(Id runId) {
        this.runId = runId;
    }

    public void execute(QueueableContext context) {
        Boolean stageCompleted = false;

        try {
            // Load inputs from Stage 8 using helper
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 8);

            // Execute Stage 9
            IStage stage = new Stage09_CreateAndDeploy();
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

        // Chain to Stage 10
        if (stageCompleted) {
            System.enqueueJob(new Stage10_TestExecutionJob(runId));
        }
    }
}