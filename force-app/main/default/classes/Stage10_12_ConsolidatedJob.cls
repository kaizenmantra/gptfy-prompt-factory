/**
 * @description Consolidated Queueable job for Stages 10-11
 *
 * Solves the DML-before-callout issue by running Stages 10-11 in a fresh
 * transaction, then enqueueing Stage 12 separately.
 *
 * NOTE: We cannot run Stage 12 (Claude callout) in the same transaction because
 * GPTfy's invocable does internal DML (creates ccai__AI_Response__c records).
 * This uncommitted DML blocks subsequent callouts.
 *
 * Flow:
 * 1. Stage 10: Call GPTfy API to execute the prompt (CALLOUT #1)
 *    - GPTfy invocable does internal DML (creates AI Response records)
 * 2. Stage 11: Safety validation (in-memory, no callout)
 * 3. Save Stage 10-11 results (DML)
 * 4. Enqueue Stage12_QualityAuditJob for Claude callout in fresh transaction
 *
 * Visual Feedback: Stages 10-11 update together, then Stage 12 updates separately.
 */
public class Stage10_12_ConsolidatedJob implements Queueable, Database.AllowsCallouts {

    private Id runId;
    private String promptRequestId;
    private Id sampleRecordId;
    private Id promptId;
    private Id dcmId;
    private String rootObject;
    private String businessContext;
    private String targetPersona;

    /**
     * @description Constructor with all required parameters
     */
    public Stage10_12_ConsolidatedJob(Id runId, String promptRequestId, Id sampleRecordId,
                                       Id promptId, Id dcmId, String rootObject,
                                       String businessContext, String targetPersona) {
        this.runId = runId;
        this.promptRequestId = promptRequestId;
        this.sampleRecordId = sampleRecordId;
        this.promptId = promptId;
        this.dcmId = dcmId;
        this.rootObject = rootObject;
        this.businessContext = businessContext;
        this.targetPersona = targetPersona;
    }

    /**
     * @description Simplified constructor - loads additional params from run record
     */
    public Stage10_12_ConsolidatedJob(Id runId, String promptRequestId, Id sampleRecordId) {
        this.runId = runId;
        this.promptRequestId = promptRequestId;
        this.sampleRecordId = sampleRecordId;
    }

    public void execute(QueueableContext context) {
        // Collect results in memory (no DML until GPTfy callout completes)
        List<Map<String, Object>> stageLogs = new List<Map<String, Object>>();
        String outputHtml = null;
        String stage10ResponseId = null;
        Boolean overallSuccess = false;
        String errorMessage = null;
        Integer failedAtStage = 0;

        try {
            // Load additional context if not provided via constructor
            if (this.promptId == null || this.dcmId == null) {
                loadContextFromRun();
            }

            System.debug('Stage10_12_ConsolidatedJob: Starting consolidated execution for Run ' + runId);
            System.debug('Stage10_12_ConsolidatedJob: promptRequestId=' + promptRequestId +
                        ', sampleRecordId=' + sampleRecordId);

            // ═══════════════════════════════════════════════════════════════════
            // STAGE 10: Execute GPTfy Prompt (CALLOUT #1)
            // ═══════════════════════════════════════════════════════════════════
            stageLogs.add(createLog(10, 'Started', 'Calling GPTfy API'));

            ccai.AIPromptProcessingInvokable.RequestWrapper wrap =
                new ccai.AIPromptProcessingInvokable.RequestWrapper();
            wrap.promptRequestId = this.promptRequestId;
            wrap.recordId = String.valueOf(this.sampleRecordId);
            wrap.customPromptCommand = '';

            List<ccai.AIPromptProcessingInvokable.ResponseWrapper> responses =
                ccai.AIPromptProcessingInvokable.processRequest(
                    new List<ccai.AIPromptProcessingInvokable.RequestWrapper>{wrap}
                );

            if (responses == null || responses.isEmpty()) {
                throw new ConsolidatedJobException('Stage 10: No response from GPTfy API');
            }

            ccai.AIPromptProcessingInvokable.ResponseWrapper gptfyResponse = responses[0];
            stage10ResponseId = gptfyResponse.responseId;

            // Check for error response
            if (gptfyResponse.responseBody == null ||
                gptfyResponse.responseBody.length() < 100 ||
                gptfyResponse.responseBody.contains('"error"')) {

                String errDetail = gptfyResponse.responseBody != null ?
                    gptfyResponse.responseBody.left(200) : 'null response';
                throw new ConsolidatedJobException('Stage 10: GPTfy returned error: ' + errDetail);
            }

            outputHtml = gptfyResponse.responseBody;
            stageLogs.add(createLog(10, 'Completed', 'HTML length: ' + outputHtml.length() + ' chars'));
            System.debug('Stage10_12_ConsolidatedJob: Stage 10 complete. HTML length: ' + outputHtml.length());

            // ═══════════════════════════════════════════════════════════════════
            // STAGE 11: Safety Validation (IN-MEMORY - no callout)
            // ═══════════════════════════════════════════════════════════════════
            stageLogs.add(createLog(11, 'Started', 'Validating output safety'));

            Boolean safetyPassed = validateSafety(outputHtml);

            if (!safetyPassed) {
                throw new ConsolidatedJobException('Stage 11: Safety validation failed - prohibited content detected');
            }

            stageLogs.add(createLog(11, 'Completed', 'Safety validation passed'));
            System.debug('Stage10_12_ConsolidatedJob: Stage 11 complete. Safety passed.');

            // NOTE: We cannot run Stage 12 here because GPTfy invocable did internal DML.
            // Stage 12 (Claude callout) will be enqueued as a separate job after we save
            // the Stage 10-11 results.

            // Stages 10-11 completed successfully
            overallSuccess = true;

        } catch (ConsolidatedJobException cje) {
            errorMessage = cje.getMessage();
            failedAtStage = determineFailedStage(stageLogs);
            stageLogs.add(createLog(failedAtStage, 'Failed', errorMessage));
            System.debug('Stage10_12_ConsolidatedJob: Failed at Stage ' + failedAtStage + ': ' + errorMessage);

        } catch (Exception e) {
            errorMessage = e.getTypeName() + ': ' + e.getMessage();
            failedAtStage = determineFailedStage(stageLogs);
            stageLogs.add(createLog(failedAtStage, 'Exception', errorMessage));
            System.debug('Stage10_12_ConsolidatedJob: Exception at Stage ' + failedAtStage + ': ' + errorMessage);
            System.debug('Stack trace: ' + e.getStackTraceString());
        }

        // ═══════════════════════════════════════════════════════════════════
        // FINAL DML: Update PF_Run__c with all results (AFTER all callouts)
        // ═══════════════════════════════════════════════════════════════════
        try {
            updateRunWithResults(stageLogs, outputHtml, stage10ResponseId,
                                overallSuccess, errorMessage, failedAtStage);
        } catch (Exception dmlEx) {
            System.debug('Stage10_12_ConsolidatedJob: DML Exception: ' + dmlEx.getMessage());
            // Last resort - try to mark run as failed
            try {
                StageJobHelper.markRunFailed(runId, 'Consolidated job DML failed: ' + dmlEx.getMessage());
            } catch (Exception ex) {
                System.debug('Stage10_12_ConsolidatedJob: Could not mark run failed: ' + ex.getMessage());
            }
        }
    }

    /**
     * @description Load context from PF_Run__c and previous stage results
     */
    private void loadContextFromRun() {
        try {
            Map<String, Object> stage9Inputs = StageJobHelper.loadInputsFromStage(runId, 9);

            this.promptId = (Id) stage9Inputs.get('promptId');
            this.dcmId = (Id) stage9Inputs.get('dcmId');
            this.rootObject = (String) stage9Inputs.get('rootObject');
            this.businessContext = (String) stage9Inputs.get('businessContext');
            this.targetPersona = (String) stage9Inputs.get('targetPersona');

            // If promptRequestId wasn't provided, try to get it
            if (String.isBlank(this.promptRequestId)) {
                this.promptRequestId = (String) stage9Inputs.get('promptRequestId');
            }

            // If sampleRecordId wasn't provided, try to get it
            if (this.sampleRecordId == null) {
                this.sampleRecordId = (Id) stage9Inputs.get('sampleRecordId');
            }

            System.debug('Stage10_12_ConsolidatedJob: Loaded context - promptId=' + promptId +
                        ', dcmId=' + dcmId + ', rootObject=' + rootObject);

        } catch (Exception e) {
            System.debug('Stage10_12_ConsolidatedJob: Error loading context: ' + e.getMessage());
            // Continue with what we have - some fields may be null
        }
    }

    /**
     * @description Validate output safety (Stage 11 logic)
     */
    private Boolean validateSafety(String html) {
        if (String.isBlank(html)) {
            return false;
        }

        // Check for prohibited content patterns
        List<String> prohibitedPatterns = new List<String>{
            '<script', 'javascript:', 'onclick=', 'onerror=',
            'document.cookie', 'eval(', 'innerHTML'
        };

        String lowerHtml = html.toLowerCase();
        for (String pattern : prohibitedPatterns) {
            if (lowerHtml.contains(pattern.toLowerCase())) {
                System.debug('Stage10_12_ConsolidatedJob: Safety check failed - found: ' + pattern);
                return false;
            }
        }

        // Check minimum content length
        if (html.length() < 200) {
            System.debug('Stage10_12_ConsolidatedJob: Safety check warning - output very short: ' + html.length());
        }

        return true;
    }

    /**
     * @description Create a log entry for tracking
     */
    private Map<String, Object> createLog(Integer stage, String status, String details) {
        return new Map<String, Object>{
            'stage' => stage,
            'status' => status,
            'details' => details,
            'timestamp' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')
        };
    }

    /**
     * @description Determine which stage failed based on logs
     */
    private Integer determineFailedStage(List<Map<String, Object>> logs) {
        Integer lastStartedStage = 10;
        for (Map<String, Object> log : logs) {
            if (log.get('status') == 'Started') {
                lastStartedStage = (Integer) log.get('stage');
            }
        }
        return lastStartedStage;
    }

    /**
     * @description Update PF_Run__c with results from Stages 10-11, then enqueue Stage 12
     */
    private void updateRunWithResults(List<Map<String, Object>> stageLogs, String outputHtml,
                                       String responseId, Boolean success, String errorMessage,
                                       Integer failedAtStage) {

        // Create stage results for Stages 10-11
        if (success) {
            // Stage 10 result
            StageResult stage10Result = new StageResult('Stage 10: Test Execution');
            stage10Result.outputs.put('outputHtml', outputHtml);
            stage10Result.outputs.put('aiResponseId', responseId);
            stage10Result.outputs.put('promptId', this.promptId);
            stage10Result.outputs.put('sampleRecordId', this.sampleRecordId);
            stage10Result.outputs.put('rootObject', this.rootObject);
            stage10Result.outputs.put('dcmId', this.dcmId);
            stage10Result.outputs.put('businessContext', this.businessContext);
            stage10Result.outputs.put('targetPersona', this.targetPersona);
            stage10Result.markCompleted();
            StageJobHelper.saveStageResult(runId, 10, stage10Result);
            StageJobHelper.updateProgress(runId, 10);

            // Stage 11 result
            StageResult stage11Result = new StageResult('Stage 11: Safety Validation');
            stage11Result.outputs.put('safetyPassed', true);
            stage11Result.outputs.put('outputHtml', outputHtml);
            stage11Result.outputs.put('promptId', this.promptId);
            stage11Result.outputs.put('dcmId', this.dcmId);
            stage11Result.outputs.put('rootObject', this.rootObject);
            stage11Result.outputs.put('businessContext', this.businessContext);
            stage11Result.outputs.put('targetPersona', this.targetPersona);
            stage11Result.markCompleted();
            StageJobHelper.saveStageResult(runId, 11, stage11Result);
            StageJobHelper.updateProgress(runId, 11);

            // Enqueue Stage 12 as separate job (fresh transaction for Claude callout)
            System.debug('Stage10_12_ConsolidatedJob: Enqueueing Stage12_QualityAuditJob');
            System.enqueueJob(new Stage12_QualityAuditJob(runId));

        } else {
            // Save partial results up to failure point
            if (failedAtStage >= 10 && outputHtml != null) {
                StageResult stage10Result = new StageResult('Stage 10: Test Execution');
                stage10Result.outputs.put('outputHtml', outputHtml);
                stage10Result.outputs.put('aiResponseId', responseId);
                if (failedAtStage == 10) {
                    stage10Result.markFailed(errorMessage);
                } else {
                    stage10Result.markCompleted();
                }
                StageJobHelper.saveStageResult(runId, 10, stage10Result);
                StageJobHelper.updateProgress(runId, 10);
            }

            if (failedAtStage >= 11 && failedAtStage > 10) {
                StageResult stage11Result = new StageResult('Stage 11: Safety Validation');
                if (failedAtStage == 11) {
                    stage11Result.markFailed(errorMessage);
                } else {
                    stage11Result.outputs.put('safetyPassed', true);
                    stage11Result.markCompleted();
                }
                StageJobHelper.saveStageResult(runId, 11, stage11Result);
                StageJobHelper.updateProgress(runId, 11);
            }

            // Mark run as failed
            StageJobHelper.markRunFailed(runId, 'Failed at Stage ' + failedAtStage + ': ' + errorMessage);
        }

        // Log the consolidated execution summary
        System.debug('Stage10_12_ConsolidatedJob: Execution complete. Success=' + success +
                    ', Stages logged=' + stageLogs.size());
    }

    /**
     * @description Custom exception for consolidated job failures
     */
    public class ConsolidatedJobException extends Exception {}
}
