/**
 * @description Queueable wrapper for Stage 12 Quality Audit
 * Uses StageJobHelper for consistent sanitization and stack overflow prevention.
 * This is the final stage - it completes the pipeline.
 */
public class Stage12_QualityAuditJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private static final Integer STAGE_NUM = 12;

    public Stage12_QualityAuditJob(Id runId) {
        this.runId = runId;
    }

    public void execute(QueueableContext context) {
        try {
            // Load inputs from Stage 11 using helper
            Map<String, Object> inputs = StageJobHelper.loadInputsFromStage(runId, 11);

            // Execute Stage 12
            IStage stage = new Stage12_QualityAudit();
            StageResult result = stage.execute(runId, inputs);

            // Save result using helper (handles sanitization)
            StageJobHelper.saveStageResult(runId, STAGE_NUM, result);

            // Stage 12 is the final stage - complete the pipeline
            completePipeline(result);

        } catch (Exception e) {
            StageJobHelper.markRunFailed(runId, 'Stage ' + STAGE_NUM + ' exception: ' + e.getMessage());
        }
    }

    /**
     * @description Completes the pipeline by updating the run record
     * @param result The final stage result
     */
    private void completePipeline(StageResult result) {
        PF_Run__c run = [SELECT Id FROM PF_Run__c WHERE Id = :runId LIMIT 1];
        run.Current_Stage__c = STAGE_NUM;
        run.Completed_At__c = System.now();

        if (StageJobHelper.isStageSuccess(result)) {
            run.Status__c = 'Completed';

            // Extract quality score if available
            if (result.outputs != null && result.outputs.containsKey('overallScore')) {
                Object score = result.outputs.get('overallScore');
                if (score instanceof Decimal) {
                    run.Overall_Quality_Score__c = (Decimal) score;
                } else if (score instanceof Integer) {
                    run.Overall_Quality_Score__c = Decimal.valueOf((Integer) score);
                }
            }
        } else {
            run.Status__c = 'Failed';
            run.Error_Message__c = StageJobHelper.truncate(result.errorMessage, 5000);
        }

        update run;
    }
}