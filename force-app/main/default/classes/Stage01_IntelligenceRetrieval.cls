/**
 * @description Stage 1: Intelligence Retrieval
 * Fetches minimal sample record info and loads business context.
 *
 * NOTE ON STACK OVERFLOW:
 * Earlier iterations attempted to serialize/store full sample record data (many fields)
 * in stage outputs. Persisting large nested maps via JSON.serialize() can trigger
 * "Maximum stack depth has been reached" in Apex.
 *
 * For enterprise robustness, Stage 1 now:
 * - Validates the record exists and is accessible
 * - Captures only a small, stable summary (Id + Name when available)
 * - Passes the record Id forward for later stages
 */
public with sharing class Stage01_IntelligenceRetrieval implements IStage {
    
    private static final Integer STAGE_NUMBER = 1;
    private static final Integer MAX_SUMMARY_FIELDS = 5;
    
    /**
     * @description Executes Stage 1: Intelligence Retrieval
     * @param runId ID of the PF_Run__c record
     * @param inputs Map of input data (empty for first stage)
     * @return StageResult with record data as JSON in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 1: Intelligence Retrieval');
        // Don't store inputs - can cause stack overflow during serialization
        // result.inputs = inputs;

        try {
            // Use deferred logging to avoid DML issues
            result.queueInfo(runId, STAGE_NUMBER, 'Starting intelligence retrieval');

            // Retrieve run record with configuration
            PF_Run__c run = queryRunRecord(runId);

            if (run == null) {
                throw new StageException('Run record not found: ' + runId);
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Retrieved run configuration: ' + run.Root_Object__c + ', Sample ID: ' + run.Sample_Record_Id__c);

            // Fetch minimal sample record summary (avoids stack/serialization issues)
            Map<String, Object> sampleRecordSummary = fetchSampleRecordSummary(
                run.Root_Object__c,
                (Id) run.Sample_Record_Id__c
            );

            // Load business context
            String businessContext = run.Business_Context__c;

            result.queueInfo(runId, STAGE_NUMBER,
                'Successfully validated sample record. Summary keys: ' + sampleRecordSummary.keySet().size());

            // Build outputs
            result.outputs.put('rootObject', run.Root_Object__c);
            result.outputs.put('sampleRecordId', run.Sample_Record_Id__c);
            result.outputs.put('sampleRecordSummary', sampleRecordSummary);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('outputFormat', run.Output_Format__c);
            result.outputs.put('promptName', run.Prompt_Name__c);
            result.outputs.put('companyWebsite', run.Company_Website__c);

            result.markCompleted();
            result.queueInfo(runId, STAGE_NUMBER, 'Intelligence retrieval completed successfully');

        } catch (Exception e) {
            String errorMsg = 'Failed to retrieve intelligence: ' + e.getMessage();
            result.markFailed(errorMsg);
            result.queueError(runId, STAGE_NUMBER, 'Stage execution failed: ' + e.getMessage());
        }

        return result;
    }
    
    /**
     * @description Queries the run record with all necessary fields
     * @param runId ID of the run record
     * @return PF_Run__c record
     */
    private PF_Run__c queryRunRecord(Id runId) {
        List<PF_Run__c> runs = [
            SELECT Id, Prompt_Name__c, Root_Object__c, Sample_Record_Id__c, 
                   Business_Context__c, Output_Format__c, Company_Website__c
            FROM PF_Run__c
            WHERE Id = :runId
            LIMIT 1
        ];
        
        return runs.isEmpty() ? null : runs[0];
    }
    
    /**
     * @description Fetches a minimal sample record summary.
     * We intentionally avoid selecting/serializing many fields to prevent stack depth issues.
     * @param objectName API name of the object
     * @param recordId ID of the sample record
     * @return Map of summary fields to values (primitive/String-safe)
     */
    private Map<String, Object> fetchSampleRecordSummary(String objectName, Id recordId) {
        if (String.isBlank(objectName) || recordId == null) {
            throw new StageException('Object name and record ID are required');
        }
        
        // Get object describe to check accessibility and optional Name field
        Schema.DescribeSObjectResult objDescribe = SchemaHelper.getObjectDescribe(objectName);
        if (objDescribe == null) {
            throw new StageException('Object not found: ' + objectName);
        }

        // Build a minimal field list: Id + Name (if present and accessible)
        List<String> fields = new List<String>{ 'Id' };
        if (objDescribe.fields.getMap().containsKey('Name')) {
            Schema.DescribeFieldResult nameDescribe = objDescribe.fields.getMap().get('Name').getDescribe();
            if (nameDescribe != null && nameDescribe.isAccessible()) {
                fields.add('Name');
            }
        }

        String soql = 'SELECT ' + String.join(fields, ', ') +
                      ' FROM ' + objectName +
                      ' WHERE Id = :recordId LIMIT 1';

        List<SObject> records = Database.query(soql);
        if (records.isEmpty()) {
            throw new StageException('Record not found: ' + recordId);
        }

        SObject rec = records[0];
        Map<String, Object> summary = new Map<String, Object>();
        summary.put('Id', (Id) rec.get('Id'));
        if (fields.contains('Name')) {
            summary.put('Name', (String) rec.get('Name'));
        }
        summary.put('Object', objectName);

        // Defensive cap (future-proofing)
        if (summary.keySet().size() > MAX_SUMMARY_FIELDS) {
            summary.put('note', 'summary truncated');
        }

        return summary;
    }
    
    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}