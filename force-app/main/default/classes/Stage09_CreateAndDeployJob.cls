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

        // Chain to Stages 10-12 (consolidated job)
        if (stageCompleted) {
            // Get promptRequestId and sampleRecordId from Stage 9 outputs
            Map<String, Object> stage9Outputs = StageJobHelper.loadInputsFromStage(runId, 9);
            String promptRequestId = (String) stage9Outputs.get('promptRequestId');
            Id sampleRecordId = (Id) stage9Outputs.get('sampleRecordId');

            System.debug('Stage09_CreateAndDeployJob: Enqueueing consolidated job for Stages 10-12');
            System.debug('Stage09_CreateAndDeployJob: promptRequestId=' + promptRequestId +
                        ', sampleRecordId=' + sampleRecordId);

            // Use consolidated job that handles Stages 10, 11, 12 in one transaction
            // This avoids DML-before-callout issues
            System.enqueueJob(new Stage10_12_ConsolidatedJob(runId, promptRequestId, sampleRecordId));
        }
    }
}