/**
 * @description Dedicated Queueable job for performing the Stage 10 REST callout.
 * This class follows the "Clean Callout" pattern: no DML before the callout.
 */
public class Stage10_RestCalloutJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private String promptRequestId;
    private Map<String, Object> inputs;

    public Stage10_RestCalloutJob(Id runId, String promptRequestId, Map<String, Object> inputs) {
        this.runId = runId;
        this.promptRequestId = promptRequestId;
        this.inputs = inputs;
    }

    public void execute(QueueableContext context) {
        // PRE-CALLOUT: System.debug only, NO DML
        Id recordId = (Id) inputs.get('sampleRecordId');
        System.debug('Stage10_RestCalloutJob: Starting Clean Callout for Run ' + runId);
        System.debug('Stage10_RestCalloutJob: PromptRequestId=' + promptRequestId + ', RecordId=' + recordId);

        StageResult result = new StageResult('Stage 10: Test Execution (REST)');
        
        try {
            // THE CALLOUT (Fresh context, no DML pending)
            Stage10_RestExecutor.ExecutionResult restResult = 
                Stage10_RestExecutor.executePromptViaRest(promptRequestId, recordId);

            // POST-CALLOUT: DML is now safe
            if (restResult.success) {
                result.outputs.put('outputHtml', restResult.responseBody);
                result.outputs.put('aiResponseId', restResult.aiResponseId);
                
                // CRITICAL: Pass through metadata for Stage 11/12
                result.outputs.put('promptRequestId', promptRequestId);
                result.outputs.put('promptId', inputs.get('promptId'));
                result.outputs.put('sampleRecordId', recordId);
                result.outputs.put('rootObject', inputs.get('rootObject'));
                result.outputs.put('dcmId', inputs.get('dcmId'));

                result.markCompleted();
                System.debug('Stage10_RestCalloutJob: REST Callout Succeeded');
            } else {
                result.markFailed(restResult.errorMessage);
                System.debug('Stage10_RestCalloutJob: REST Callout Failed: ' + restResult.errorMessage);
                // Even on failure, pass through IDs for logging/context
                result.outputs.put('promptId', inputs.get('promptId'));
                result.outputs.put('sampleRecordId', recordId);
            }

            // Save result (Performs DML)
            StageJobHelper.saveStageResult(runId, 10, result);
            StageJobHelper.updateProgress(runId, 10);

            // Chain to Stage 11 on success
            if (result.status == 'Completed') {
                System.enqueueJob(new Stage11_SafetyValidationJob(runId));
            } else {
                StageJobHelper.markRunFailed(runId, result.errorMessage);
            }

        } catch (Exception e) {
            System.debug('Stage10_RestCalloutJob: Exception: ' + e.getMessage());
            StageJobHelper.markRunFailed(runId, 'ExecutionJob Failure: ' + e.getMessage());
        }
    }
}