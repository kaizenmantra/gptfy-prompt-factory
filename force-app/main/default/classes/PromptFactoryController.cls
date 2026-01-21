/**
 * @description API gateway for LWC components to interact with Prompt Factory
 * Provides AuraEnabled methods for starting pipeline, monitoring status, and managing runs
 */
public with sharing class PromptFactoryController {

    private static final String COMPONENT_NAME = 'PromptFactoryController';

    /**
     * @description Starts a new pipeline run with provided inputs
     * Creates PF_Run__c record and enqueues first stage
     * @param promptName Name for the generated prompt
     * @param rootObject Root Salesforce object (e.g., Opportunity)
     * @param sampleRecordId Optional sample record ID for testing
     * @param businessContext Business context description
     * @param outputFormat Desired output format
     * @return Id of the created PF_Run__c record
     * @throws AuraHandledException for validation or execution errors
     */
    /**
     * @description Gets available AI Models (GPTfy Connections) for dropdown
     * @return List of AI Connection options with Id and Name
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAIModelOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        try {
            // Query GPTfy AI Connections
            List<ccai__AI_Connection__c> connections = [
                SELECT Id, Name
                FROM ccai__AI_Connection__c
                ORDER BY Name ASC
                LIMIT 50
            ];

            for (ccai__AI_Connection__c conn : connections) {
                options.add(new Map<String, String>{
                    'label' => conn.Name,
                    'value' => conn.Id
                });
            }
        } catch (Exception e) {
            // If GPTfy is not installed or query fails, return empty list
            System.debug(LoggingLevel.WARN, 'Could not query AI Connections: ' + e.getMessage());
        }

        return options;
    }

    @AuraEnabled
    public static Id startPipelineRun(String promptName, String rootObject,
                                       String sampleRecordId, String businessContext,
                                       String outputFormat, String aiModelId,
                                       String companyUrl) {
        try {
            // Validate required fields
            if (String.isBlank(rootObject)) {
                throw new ControllerException('Root Object is required');
            }
            if (String.isBlank(businessContext)) {
                throw new ControllerException('Business Context is required');
            }
            if (String.isBlank(outputFormat)) {
                throw new ControllerException('Output Format is required');
            }
            if (String.isBlank(promptName)) {
                throw new ControllerException('Prompt Name is required');
            }

            String targetPromptName = promptName;

            // Create run record (Current_Stage__c = 1 to pass validation rule)
            PF_Run__c run = new PF_Run__c(
                Root_Object__c = rootObject,
                Sample_Record_Id__c = sampleRecordId,
                Business_Context__c = businessContext,
                Output_Format__c = outputFormat,
                Prompt_Name__c = targetPromptName,
                AI_Model__c = aiModelId,
                Company_Website__c = companyUrl,
                Status__c = 'Queued',
                Current_Stage__c = 1
            );

            insert run;

            // Log pipeline start
            String modelInfo = String.isNotBlank(aiModelId) ? ' with AI Model: ' + aiModelId : '';
            PromptFactoryLogger.info(run.Id, null,
                'Pipeline run created and queued for: ' + rootObject + modelInfo);

            // Enqueue first stage
            System.enqueueJob(new PromptFactoryPipeline(run.Id, 1));

            PromptFactoryLogger.info(run.Id, 1,
                'Stage 1 enqueued successfully');

            return run.Id;

        } catch (Exception e) {
            throw createAuraException('Failed to start pipeline: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Gets current status of pipeline run
     * @param runId ID of the PF_Run__c record
     * @return Map containing status, currentStage, stages array, qualityScore
     * @throws AuraHandledException if run not found
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getPipelineStatus(Id runId) {
        try {
            // Query run record
            List<PF_Run__c> runs = [
                SELECT Id, Name, Status__c, Current_Stage__c, Overall_Quality_Score__c,
                       Root_Object__c, Sample_Record_Id__c, Prompt_Name__c,
                       Started_At__c, Completed_At__c, Error_Message__c,
                       CreatedById
                FROM PF_Run__c
                WHERE Id = :runId
                LIMIT 1
            ];

            if (runs.isEmpty()) {
                throw new ControllerException('Run not found: ' + runId);
            }

            PF_Run__c run = runs[0];

            // Query stage records
            List<PF_Run_Stage__c> stages = [
                SELECT Id, Stage_Number__c, Stage_Name__c, Status__c,
                       Started_At__c, Completed_At__c, Duration_Seconds__c,
                       Error_Message__c
                FROM PF_Run_Stage__c
                WHERE Run__c = :runId
                ORDER BY Stage_Number__c ASC
            ];

            // Build stages array
            List<Map<String, Object>> stagesArray = new List<Map<String, Object>>();
            for (PF_Run_Stage__c stage : stages) {
                stagesArray.add(new Map<String, Object>{
                    'stageNumber' => stage.Stage_Number__c,
                    'stageName' => stage.Stage_Name__c,
                    'status' => stage.Status__c,
                    'startedAt' => stage.Started_At__c,
                    'completedAt' => stage.Completed_At__c,
                    'durationSeconds' => stage.Duration_Seconds__c,
                    'errorMessage' => stage.Error_Message__c
                });
            }

            // Query activity logs for the run
            List<PF_Run_Log__c> logRecords = PromptFactoryLogger.getLogs(runId, 100);
            List<Map<String, Object>> logsArray = new List<Map<String, Object>>();
            // Reverse to show oldest first (chronological order)
            for (Integer i = logRecords.size() - 1; i >= 0; i--) {
                PF_Run_Log__c logRec = logRecords[i];
                logsArray.add(new Map<String, Object>{
                    'timestamp' => logRec.Timestamp__c,
                    'stage' => logRec.Stage_Number__c != null ? 'Stage ' + String.valueOf(logRec.Stage_Number__c.intValue()) : 'Pipeline',
                    'level' => logRec.Log_Level__c,
                    'message' => logRec.Log_Message__c
                });
            }

            // Query quality score record if run is completed
            Map<String, Object> qualityScorecard = null;
            if (run.Status__c == 'Completed') {
                List<PF_Quality_Score__c> qualityScores = [
                    SELECT Id, Visual_Quality__c, Data_Accuracy__c, Persona_Fit__c,
                           Actionability__c, Business_Value__c, Pass_Threshold__c,
                           Overall_Score__c, AI_Feedback__c
                    FROM PF_Quality_Score__c
                    WHERE Run__c = :runId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (!qualityScores.isEmpty()) {
                    PF_Quality_Score__c qs = qualityScores[0];
                    qualityScorecard = new Map<String, Object>{
                        'visualQuality' => qs.Visual_Quality__c,
                        'dataAccuracy' => qs.Data_Accuracy__c,
                        'personaFit' => qs.Persona_Fit__c,
                        'actionability' => qs.Actionability__c,
                        'businessValue' => qs.Business_Value__c,
                        'overallScore' => qs.Overall_Score__c,
                        'threshold' => qs.Pass_Threshold__c
                    };
                }
            }

            // Build response
            Map<String, Object> response = new Map<String, Object>{
                'runId' => run.Id,
                'runName' => run.Name,
                'status' => run.Status__c,
                'currentStage' => run.Current_Stage__c,
                'qualityScore' => run.Overall_Quality_Score__c,
                'qualityScorecard' => qualityScorecard,
                'rootObject' => run.Root_Object__c,
                'sampleRecordId' => run.Sample_Record_Id__c,
                'targetPromptName' => run.Prompt_Name__c,
                'startedAt' => run.Started_At__c,
                'completedAt' => run.Completed_At__c,
                'errorMessage' => run.Error_Message__c,
                'createdByUser' => run.CreatedById,
                'stages' => stagesArray,
                'logs' => logsArray
            };

            return response;

        } catch (Exception e) {
            throw createAuraException('Failed to get pipeline status: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Gets detailed information for a specific stage
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number (1-12)
     * @return Map containing stage details including inputs, outputs, AI reasoning
     * @throws AuraHandledException if stage not found
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getStageDetails(Id runId, Integer stageNumber) {
        try {
            // Query stage record
            List<PF_Run_Stage__c> stages = [
                SELECT Id, Stage_Number__c, Stage_Name__c, Status__c,
                       Input_Data__c, Output_Data__c, AI_Reasoning__c,
                       Started_At__c, Completed_At__c, Duration_Seconds__c,
                       Error_Message__c
                FROM PF_Run_Stage__c
                WHERE Run__c = :runId
                AND Stage_Number__c = :stageNumber
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (stages.isEmpty()) {
                throw new ControllerException('Stage not found: Stage ' + stageNumber +
                    ' for Run ' + runId);
            }

            PF_Run_Stage__c stage = stages[0];

            // Parse JSON fields
            Map<String, Object> inputs = parseJSON(stage.Input_Data__c);
            Map<String, Object> outputs = parseJSON(stage.Output_Data__c);

            // Get stage logs
            List<PF_Run_Log__c> logs = PromptFactoryLogger.getStageLog(runId, stageNumber);
            List<Map<String, Object>> logsArray = new List<Map<String, Object>>();
            for (PF_Run_Log__c log : logs) {
                logsArray.add(new Map<String, Object>{
                    'timestamp' => log.Timestamp__c,
                    'logLevel' => log.Log_Level__c,
                    'logMessage' => log.Log_Message__c,
                    'component' => log.Component__c
                });
            }

            // Build response
            Map<String, Object> response = new Map<String, Object>{
                'stageNumber' => stage.Stage_Number__c,
                'stageName' => stage.Stage_Name__c,
                'status' => stage.Status__c,
                'inputs' => inputs,
                'outputs' => outputs,
                'aiReasoning' => stage.AI_Reasoning__c,
                'startedAt' => stage.Started_At__c,
                'completedAt' => stage.Completed_At__c,
                'durationSeconds' => stage.Duration_Seconds__c,
                'errorMessage' => stage.Error_Message__c,
                'logs' => logsArray
            };

            return response;

        } catch (Exception e) {
            throw createAuraException('Failed to get stage details: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Gets recent activity logs for a run
     * @param runId ID of the PF_Run__c record
     * @param lastCount Number of recent logs to retrieve (default 50)
     * @return List of log entries
     * @throws AuraHandledException on error
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getActivityLogs(Id runId, Integer lastCount) {
        try {
            if (lastCount == null || lastCount <= 0) {
                lastCount = 50;
            }

            // Get logs
            List<PF_Run_Log__c> logs = PromptFactoryLogger.getLogs(runId, lastCount);

            // Convert to map format
            List<Map<String, Object>> logsArray = new List<Map<String, Object>>();
            for (PF_Run_Log__c log : logs) {
                logsArray.add(new Map<String, Object>{
                    'timestamp' => log.Timestamp__c,
                    'stageNumber' => log.Stage_Number__c,
                    'logLevel' => log.Log_Level__c,
                    'logMessage' => log.Log_Message__c,
                    'component' => log.Component__c
                });
            }

            return logsArray;

        } catch (Exception e) {
            throw createAuraException('Failed to get activity logs: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Aborts a running pipeline
     * @param runId ID of the PF_Run__c record to abort
     * @throws AuraHandledException if run not found or already completed
     */
    @AuraEnabled
    public static void abortPipeline(Id runId) {
        try {
            // Query run record
            List<PF_Run__c> runs = [
                SELECT Id, Status__c
                FROM PF_Run__c
                WHERE Id = :runId
                LIMIT 1
            ];

            if (runs.isEmpty()) {
                throw new ControllerException('Run not found: ' + runId);
            }

            PF_Run__c run = runs[0];

            // Check if already completed or failed
            if (run.Status__c == 'Completed' || run.Status__c == 'Failed') {
                throw new ControllerException('Cannot abort a pipeline that is ' +
                    run.Status__c);
            }

            // Update status to Aborted
            run.Status__c = 'Aborted';
            update run;

            PromptFactoryLogger.info(runId, null,
                'Pipeline aborted by user');

        } catch (Exception e) {
            throw createAuraException('Failed to abort pipeline: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Retries pipeline from a specific stage
     * @param runId ID of the PF_Run__c record
     * @param stageNumber Stage number to retry from (1-12)
     * @throws AuraHandledException if run not found or validation fails
     */
    @AuraEnabled
    public static void retryStage(Id runId, Integer stageNumber) {
        try {
            // Validate stage number
            if (stageNumber == null || stageNumber < 1 || stageNumber > 12) {
                throw new ControllerException('Invalid stage number: ' + stageNumber);
            }

            // Query run record
            List<PF_Run__c> runs = [
                SELECT Id, Status__c
                FROM PF_Run__c
                WHERE Id = :runId
                LIMIT 1
            ];

            if (runs.isEmpty()) {
                throw new ControllerException('Run not found: ' + runId);
            }

            PF_Run__c run = runs[0];

            // Update run status
            run.Status__c = 'In Progress';
            run.Current_Stage__c = stageNumber;
            run.Error_Message__c = null;
            update run;

            PromptFactoryLogger.info(runId, stageNumber,
                'Retrying pipeline from Stage ' + stageNumber);

            // Enqueue stage
            System.enqueueJob(new PromptFactoryPipeline(runId, stageNumber));

        } catch (Exception e) {
            throw createAuraException('Failed to retry stage: ' + e.getMessage(), e);
        }
    }


    /**
     * @description Safely parses JSON string to Map
     * @param jsonString JSON string to parse
     * @return Map of parsed data, or empty map if null/invalid
     */
    private static Map<String, Object> parseJSON(String jsonString) {
        if (String.isBlank(jsonString)) {
            return new Map<String, Object>();
        }

        try {
            Object parsed = JSON.deserializeUntyped(jsonString);
            if (parsed instanceof Map<String, Object>) {
                return (Map<String, Object>) parsed;
            }
            return new Map<String, Object>();
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'Failed to parse JSON: ' + e.getMessage());
            return new Map<String, Object>();
        }
    }

    /**
     * @description Creates AuraHandledException with proper error message
     * @param message User-friendly error message
     * @param ex Original exception
     * @return AuraHandledException to throw
     */
    private static AuraHandledException createAuraException(String message, Exception ex) {
        AuraHandledException auraEx = new AuraHandledException(message);
        auraEx.setMessage(message);
        System.debug(LoggingLevel.ERROR, message + ' | ' + ex.getMessage());
        System.debug(LoggingLevel.ERROR, 'Stack trace: ' + ex.getStackTraceString());
        return auraEx;
    }

    /**
     * @description Gets recent pipeline runs for the history panel
     * @param recordLimit Maximum number of runs to return
     * @return List of recent runs with key information
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecentRuns(Integer recordLimit) {
        try {
            if (recordLimit == null || recordLimit <= 0) {
                recordLimit = 10;
            }

            List<PF_Run__c> runs = [
                SELECT Id, Name, Prompt_Name__c, Root_Object__c, Status__c,
                       Current_Stage__c, Overall_Quality_Score__c,
                       Started_At__c, Completed_At__c, CreatedDate,
                       CreatedBy.Name
                FROM PF_Run__c
                ORDER BY CreatedDate DESC
                LIMIT :recordLimit
            ];

            List<Map<String, Object>> results = new List<Map<String, Object>>();
            for (PF_Run__c run : runs) {
                results.add(new Map<String, Object>{
                    'id' => run.Id,
                    'name' => run.Name,
                    'promptName' => run.Prompt_Name__c,
                    'rootObject' => run.Root_Object__c,
                    'status' => run.Status__c,
                    'currentStage' => run.Current_Stage__c,
                    'qualityScore' => run.Overall_Quality_Score__c,
                    'startedAt' => run.Started_At__c,
                    'completedAt' => run.Completed_At__c,
                    'createdDate' => run.CreatedDate,
                    'createdByName' => run.CreatedBy.Name
                });
            }

            return results;

        } catch (Exception e) {
            throw createAuraException('Failed to get recent runs: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Custom exception for controller errors
     */
    public class ControllerException extends Exception {}
}