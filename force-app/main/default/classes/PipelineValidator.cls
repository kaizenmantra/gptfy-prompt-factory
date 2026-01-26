/**
 * @description Reusable validation methods for Pipeline Integration Testing
 *
 * Purpose: Centralize all validation logic for DCM structure, prompt templates,
 * merge field syntax, and output quality. Used by PipelineIntegrationTest.cls
 * and validation scripts.
 *
 * Validation Methods:
 * - validateDCM(): Check DCM structure (objects, fields, relationships)
 * - validatePrompt(): Check prompt template (merge fields, no hardcoded values)
 * - validateOutputQuality(): Check output visual components and data accuracy
 * - validateConsistency(): Compare two runs for structural consistency
 * - validateStage05Output(): Smoke test Stage 5 (field selection)
 * - validateStage07Output(): Smoke test Stage 7 (analysis brief)
 * - validateStage08Output(): Smoke test Stage 8 (prompt assembly)
 * - validateStage09Output(): Smoke test Stage 9 (DCM creation)
 * - validateMergeFieldSyntax(): Check merge field format
 * - validateNoHardcodedValues(): Check for hardcoded sample data
 *
 * @author Sonnet (Phase 5A.5 - Automated Testing)
 * @date 2026-01-25
 */
public class PipelineValidator {

    /**
     * Custom exception for validation failures
     */
    public class ValidationException extends Exception {}

    // ========================================================================
    // PUBLIC VALIDATION METHODS
    // ========================================================================

    /**
     * Validate DCM structure includes expected objects, fields, and relationships
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if DCM structure is invalid
     */
    public static void validateDCM(Id runId) {
        // Query DCM for this run
        List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
            SELECT Id, ccai__Object_Name__c, Name
            FROM ccai__AI_Data_Extraction_Mapping__c
            WHERE ccai__Run__c = :runId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (dcms.isEmpty()) {
            throw new ValidationException('No DCM found for run: ' + runId);
        }

        ccai__AI_Data_Extraction_Mapping__c dcm = dcms[0];

        // Validate root object
        if (String.isBlank(dcm.ccai__Object_Name__c)) {
            throw new ValidationException('DCM root object is blank');
        }

        // Query detail records
        List<ccai__AI_Data_Extraction_Detail__c> details = [
            SELECT ccai__Object_Name__c, ccai__Type__c, ccai__Relationship_Name__c
            FROM ccai__AI_Data_Extraction_Detail__c
            WHERE ccai__DCM__c = :dcm.Id
        ];

        if (details.isEmpty()) {
            throw new ValidationException('DCM has no detail records (child/grandchild objects)');
        }

        // Count child vs grandchild records
        Integer childCount = 0;
        Integer grandchildCount = 0;
        Set<String> childObjects = new Set<String>();

        for (ccai__AI_Data_Extraction_Detail__c detail : details) {
            if (detail.ccai__Type__c == 'CHILD') {
                childCount++;
                childObjects.add(detail.ccai__Object_Name__c);
            } else if (detail.ccai__Type__c == 'GRANDCHILD') {
                grandchildCount++;
            }
        }

        if (childCount == 0) {
            throw new ValidationException('DCM has no CHILD objects');
        }

        // Query field records
        Integer fieldCount = [
            SELECT COUNT()
            FROM ccai__DCM_Field__c
            WHERE ccai__DCM__c = :dcm.Id
        ];

        if (fieldCount == 0) {
            throw new ValidationException('DCM has no fields');
        }

        // Success - log summary
        System.debug('✅ DCM Validation Passed: ' + childCount + ' children, ' +
                    grandchildCount + ' grandchildren, ' + fieldCount + ' fields');
    }

    /**
     * Validate prompt template uses merge fields and has no hardcoded values
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if prompt template is invalid
     */
    public static void validatePrompt(Id runId) {
        // Query prompt for this run
        List<ccai__AI_Prompt__c> prompts = [
            SELECT Id, Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE ccai__Run__c = :runId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (prompts.isEmpty()) {
            throw new ValidationException('No prompt found for run: ' + runId);
        }

        ccai__AI_Prompt__c prompt = prompts[0];
        String template = prompt.ccai__Prompt_Command__c;

        if (String.isBlank(template)) {
            throw new ValidationException('Prompt template is blank');
        }

        if (template.length() < 500) {
            throw new ValidationException('Prompt template too short: ' + template.length() + ' chars');
        }

        // Validate merge field syntax
        if (!template.contains('{{{') || !template.contains('}}}')) {
            throw new ValidationException('Prompt template missing merge field syntax {{{ }}}');
        }

        // Validate iteration blocks
        if (!template.contains('{{#') || !template.contains('{{/')) {
            throw new ValidationException('Prompt template missing iteration blocks {{# }} and {{/ }}');
        }

        // Count merge fields and iterations
        Integer mergeFieldCount = template.countMatches('{{{');
        Integer iterationCount = template.countMatches('{{#');

        if (mergeFieldCount < 10) {
            throw new ValidationException('Too few merge fields: ' + mergeFieldCount + ' (expected 10+)');
        }

        if (iterationCount < 1) {
            throw new ValidationException('Too few iteration blocks: ' + iterationCount + ' (expected 1+)');
        }

        // Success - log summary
        System.debug('✅ Prompt Validation Passed: ' + template.length() + ' chars, ' +
                    mergeFieldCount + ' merge fields, ' + iterationCount + ' iterations');
    }

    /**
     * Validate output has expected visual components and data accuracy
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if output quality is insufficient
     */
    public static void validateOutputQuality(Id runId) {
        // Query prompt output for this run
        List<ccai__AI_Prompt__c> prompts = [
            SELECT Id, ccai__Last_Result__c
            FROM ccai__AI_Prompt__c
            WHERE ccai__Run__c = :runId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (prompts.isEmpty() || String.isBlank(prompts[0].ccai__Last_Result__c)) {
            throw new ValidationException('No prompt output found for run: ' + runId);
        }

        String output = prompts[0].ccai__Last_Result__c;

        // Validate output is HTML
        if (!output.startsWith('<')) {
            throw new ValidationException('Output is not HTML');
        }

        // Validate visual components are present
        Boolean hasHealthScore = output.contains('font-size:36px') || output.contains('font-size: 36px');
        Boolean hasRedAlert = output.contains('#BA0517');
        Boolean hasOrangeAlert = output.contains('#DD7A01');
        Boolean hasBlueAlert = output.contains('#0176D3');
        Boolean hasTable = output.contains('<table');

        List<String> missingComponents = new List<String>();
        if (!hasHealthScore) missingComponents.add('Health score');
        if (!hasRedAlert) missingComponents.add('Red critical alert');
        if (!hasOrangeAlert) missingComponents.add('Orange warning alert');
        if (!hasBlueAlert) missingComponents.add('Blue info alert');
        if (!hasTable) missingComponents.add('Data table');

        if (!missingComponents.isEmpty()) {
            throw new ValidationException('Missing visual components: ' + String.join(missingComponents, ', '));
        }

        // Success - log summary
        System.debug('✅ Output Quality Validation Passed: ' + output.length() + ' chars, all visual components present');
    }

    /**
     * Validate two pipeline runs produce consistent structure
     *
     * @param runId1 First pipeline run ID
     * @param runId2 Second pipeline run ID
     * @throws ValidationException if structure differs
     */
    public static void validateConsistency(Id runId1, Id runId2) {
        // Query DCMs for both runs
        List<ccai__AI_Data_Extraction_Mapping__c> dcms1 = [
            SELECT Id, ccai__Object_Name__c,
                (SELECT ccai__Object_Name__c, ccai__Type__c FROM ccai__AI_Data_Extraction_Details__r)
            FROM ccai__AI_Data_Extraction_Mapping__c
            WHERE ccai__Run__c = :runId1
            LIMIT 1
        ];

        List<ccai__AI_Data_Extraction_Mapping__c> dcms2 = [
            SELECT Id, ccai__Object_Name__c,
                (SELECT ccai__Object_Name__c, ccai__Type__c FROM ccai__AI_Data_Extraction_Details__r)
            FROM ccai__AI_Data_Extraction_Mapping__c
            WHERE ccai__Run__c = :runId2
            LIMIT 1
        ];

        if (dcms1.isEmpty() || dcms2.isEmpty()) {
            throw new ValidationException('One or both runs missing DCM');
        }

        // Compare root objects
        if (dcms1[0].ccai__Object_Name__c != dcms2[0].ccai__Object_Name__c) {
            throw new ValidationException('Root objects differ: ' +
                dcms1[0].ccai__Object_Name__c + ' vs ' + dcms2[0].ccai__Object_Name__c);
        }

        // Compare detail record count
        Integer detailCount1 = dcms1[0].ccai__AI_Data_Extraction_Details__r.size();
        Integer detailCount2 = dcms2[0].ccai__AI_Data_Extraction_Details__r.size();

        if (detailCount1 != detailCount2) {
            throw new ValidationException('Detail counts differ: ' + detailCount1 + ' vs ' + detailCount2);
        }

        // Compare child object names
        Set<String> childObjects1 = new Set<String>();
        Set<String> childObjects2 = new Set<String>();

        for (ccai__AI_Data_Extraction_Detail__c detail : dcms1[0].ccai__AI_Data_Extraction_Details__r) {
            childObjects1.add(detail.ccai__Object_Name__c);
        }

        for (ccai__AI_Data_Extraction_Detail__c detail : dcms2[0].ccai__AI_Data_Extraction_Details__r) {
            childObjects2.add(detail.ccai__Object_Name__c);
        }

        if (childObjects1 != childObjects2) {
            throw new ValidationException('Child objects differ');
        }

        // Success - log summary
        System.debug('✅ Consistency Validation Passed: Both runs have identical DCM structure');
    }

    /**
     * Validate Stage 5 output (field selection)
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if Stage 5 output is invalid
     */
    public static void validateStage05Output(Id runId) {
        // Query pipeline state for selectedFields
        Map<String, Object> state = PipelineState.read(runId);

        if (!state.containsKey('selectedFields')) {
            throw new ValidationException('Stage 5 did not output selectedFields');
        }

        Object selectedFieldsObj = state.get('selectedFields');
        if (selectedFieldsObj == null) {
            throw new ValidationException('selectedFields is null');
        }

        // Success
        System.debug('✅ Stage 5 Validation Passed: selectedFields present');
    }

    /**
     * Validate Stage 7 output (analysis brief)
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if Stage 7 output is invalid
     */
    public static void validateStage07Output(Id runId) {
        // Query pipeline state for analysisBrief
        Map<String, Object> state = PipelineState.read(runId);

        if (!state.containsKey('analysisBrief')) {
            throw new ValidationException('Stage 7 did not output analysisBrief');
        }

        Object analysisBriefObj = state.get('analysisBrief');
        if (analysisBriefObj == null) {
            throw new ValidationException('analysisBrief is null');
        }

        // Success
        System.debug('✅ Stage 7 Validation Passed: analysisBrief present');
    }

    /**
     * Validate Stage 8 output (prompt assembly)
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if Stage 8 output is invalid
     */
    public static void validateStage08Output(Id runId) {
        // Query pipeline state for promptConfig
        Map<String, Object> state = PipelineState.read(runId);

        if (!state.containsKey('promptConfig')) {
            throw new ValidationException('Stage 8 did not output promptConfig');
        }

        Object promptConfigObj = state.get('promptConfig');
        if (promptConfigObj == null) {
            throw new ValidationException('promptConfig is null');
        }

        // Success
        System.debug('✅ Stage 8 Validation Passed: promptConfig present');
    }

    /**
     * Validate Stage 9 output (DCM creation)
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if Stage 9 output is invalid
     */
    public static void validateStage09Output(Id runId) {
        // Query for created DCM
        List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
            SELECT Id
            FROM ccai__AI_Data_Extraction_Mapping__c
            WHERE ccai__Run__c = :runId
            LIMIT 1
        ];

        if (dcms.isEmpty()) {
            throw new ValidationException('Stage 9 did not create DCM');
        }

        // Success
        System.debug('✅ Stage 9 Validation Passed: DCM created');
    }

    /**
     * Validate merge field syntax in prompt template
     *
     * @param runId The pipeline run ID
     * @throws ValidationException if merge field syntax is invalid
     */
    public static void validateMergeFieldSyntax(Id runId) {
        // Query prompt
        List<ccai__AI_Prompt__c> prompts = [
            SELECT ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE ccai__Run__c = :runId
            LIMIT 1
        ];

        if (prompts.isEmpty()) {
            throw new ValidationException('No prompt found');
        }

        String template = prompts[0].ccai__Prompt_Command__c;

        // Check for invalid merge field patterns
        if (template.contains('{{{{') || template.contains('}}}}')) {
            throw new ValidationException('Invalid merge field syntax: too many braces');
        }

        if (template.contains('{ {{') || template.contains('}} }')) {
            throw new ValidationException('Invalid merge field syntax: spaces in braces');
        }

        // Check iteration blocks are properly closed
        Integer openCount = template.countMatches('{{#');
        Integer closeCount = template.countMatches('{{/');

        if (openCount != closeCount) {
            throw new ValidationException('Unmatched iteration blocks: ' + openCount + ' open, ' + closeCount + ' close');
        }

        // Success
        System.debug('✅ Merge Field Syntax Validation Passed');
    }

    /**
     * Validate prompt template has no hardcoded values from sample data
     *
     * @param runId The pipeline run ID
     * @param sampleRecordId The sample record ID used in pipeline
     * @throws ValidationException if hardcoded values found
     */
    public static void validateNoHardcodedValues(Id runId, String sampleRecordId) {
        // Query prompt
        List<ccai__AI_Prompt__c> prompts = [
            SELECT ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE ccai__Run__c = :runId
            LIMIT 1
        ];

        if (prompts.isEmpty()) {
            throw new ValidationException('No prompt found');
        }

        String template = prompts[0].ccai__Prompt_Command__c;

        // Get sample record data to check for hardcoded values
        // For now, check for common patterns that indicate hardcoded data

        List<String> suspiciousPatterns = new List<String>{
            'Employee Health Insurance',
            'McD Franchise',
            'Lisa Martinez',
            'Sarah Johnson',
            'Michael Chen',
            'Robert Taylor',
            'HealthSystem Partners',
            '1500000',
            '$1,500,000'
        };

        List<String> foundHardcoded = new List<String>();

        for (String pattern : suspiciousPatterns) {
            if (template.contains(pattern)) {
                foundHardcoded.add(pattern);
            }
        }

        if (!foundHardcoded.isEmpty()) {
            throw new ValidationException('Found hardcoded values: ' + String.join(foundHardcoded, ', '));
        }

        // Success
        System.debug('✅ No Hardcoded Values Validation Passed');
    }
}
