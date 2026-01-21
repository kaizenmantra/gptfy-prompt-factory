/**
 * @description Stage 4: Data Profiling
 * Performs COUNT queries for each selected object with parent-specific filtering.
 * Now uses proper relationship filtering to count only records related to the sample record.
 */
public with sharing class Stage04_DataProfiling implements IStage {

    private static final Integer STAGE_NUMBER = 4;
    private static final Integer MIN_RECORD_COUNT = 1;

    /**
     * @description Executes Stage 4: Data Profiling
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing selectedObjects and other stage data
     * @return StageResult with data availability map in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 4: Data Profiling');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            // Use deferred logging to avoid DML before potential callouts
            result.queueInfo(runId, STAGE_NUMBER, 'Starting data profiling');

            // Extract inputs
            String rootObject = (String) inputs.get('rootObject');
            String sampleRecordId = (String) inputs.get('sampleRecordId');

            List<Object> selectedObjectsRaw = (List<Object>) inputs.get('selectedObjects');
            if (selectedObjectsRaw == null || selectedObjectsRaw.isEmpty()) {
                throw new StageException('No selected objects provided for data profiling');
            }

            // Convert to List<String>
            List<String> selectedObjects = new List<String>();
            for (Object obj : selectedObjectsRaw) {
                selectedObjects.add(String.valueOf(obj));
            }

            // Get selected grandchildren from Stage 3 (includes parentObject info)
            List<Map<String, String>> selectedGrandchildren = new List<Map<String, String>>();
            Object gcRaw = inputs.get('selectedGrandchildren');
            if (gcRaw != null && gcRaw instanceof List<Object>) {
                for (Object gcObj : (List<Object>) gcRaw) {
                    if (gcObj instanceof Map<String, Object>) {
                        Map<String, Object> gcMap = (Map<String, Object>) gcObj;
                        selectedGrandchildren.add(new Map<String, String>{
                            'objectName' => (String) gcMap.get('objectName'),
                            'parentObject' => (String) gcMap.get('parentObject'),
                            'relationshipField' => (String) gcMap.get('relationshipField')
                        });
                    }
                }
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Profiling data for ' + selectedObjects.size() + ' objects (including ' +
                selectedGrandchildren.size() + ' grandchildren)');

            // Perform PARENT-SPECIFIC COUNT queries for each object
            // This mirrors the shell script approach: count records related to the sample record
            Map<String, Integer> dataAvailability = performParentSpecificCountQueries(
                rootObject, sampleRecordId, selectedObjects, selectedGrandchildren, runId, result);

            // Filter to objects with available data
            List<String> objectsWithData = new List<String>();
            Map<String, Integer> filteredAvailability = new Map<String, Integer>();

            for (String objectName : dataAvailability.keySet()) {
                Integer count = dataAvailability.get(objectName);
                if (count >= MIN_RECORD_COUNT) {
                    objectsWithData.add(objectName);
                    filteredAvailability.put(objectName, count);
                }
            }

            result.queueInfo(runId, STAGE_NUMBER,
                objectsWithData.size() + ' objects have data for this record (filtered from ' +
                selectedObjects.size() + ' selected objects)');

            // Log data availability summary
            String summary = buildDataSummary(filteredAvailability);
            result.queueDebug(runId, STAGE_NUMBER, 'Data availability: ' + summary);

            // Build outputs
            result.outputs.put('objectsWithData', objectsWithData);
            result.outputs.put('dataAvailability', filteredAvailability);
            result.outputs.put('totalRecordsCounted', calculateTotalRecords(filteredAvailability));
            result.outputs.put('dataSummary', summary);

            // Pass through critical inputs (avoid large data to prevent serialization issues)
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', inputs.get('businessContext'));
            result.outputs.put('targetPersona', inputs.get('targetPersona'));
            result.outputs.put('businessObjectives', inputs.get('businessObjectives'));
            result.outputs.put('selectedObjects', selectedObjects);
            result.outputs.put('selectedGrandchildren', selectedGrandchildren);
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', sampleRecordId);
            result.outputs.put('outputFormat', inputs.get('outputFormat'));

            result.markCompleted();
            result.queueInfo(runId, STAGE_NUMBER,
                'Data profiling completed successfully');

        } catch (Exception e) {
            String errorMsg = 'Failed to complete data profiling: ' + e.getMessage();
            result.markFailed(errorMsg);
            result.queueError(runId, STAGE_NUMBER, 'Stage execution failed: ' + e.getMessage());
        }

        return result;
    }
    
    /**
     * @description Performs parent-specific COUNT queries for each object
     * Mirrors shell script approach: count only records related to the sample record
     * @param rootObject The root object (e.g., Account)
     * @param sampleRecordId ID of the sample record
     * @param objectNames List of object API names (children + grandchildren)
     * @param grandchildren List of grandchild objects with parentObject info
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return Map of object name to record count
     */
    private Map<String, Integer> performParentSpecificCountQueries(
            String rootObject, String sampleRecordId,
            List<String> objectNames, List<Map<String, String>> grandchildren,
            Id runId, StageResult result) {

        Map<String, Integer> results = new Map<String, Integer>();

        // Build grandchild lookup map for subquery construction
        Map<String, Map<String, String>> grandchildLookup = new Map<String, Map<String, String>>();
        for (Map<String, String> gc : grandchildren) {
            grandchildLookup.put(gc.get('objectName'), gc);
        }

        for (String objectName : objectNames) {
            try {
                // Check if object is accessible
                if (!SchemaHelper.isObjectAccessible(objectName)) {
                    result.queueWarning(runId, STAGE_NUMBER,
                        'Object not accessible: ' + objectName);
                    results.put(objectName, 0);
                    continue;
                }

                Integer count = 0;

                if (objectName == rootObject) {
                    // Root object: just count 1 (the sample record itself)
                    count = 1;
                } else if (grandchildLookup.containsKey(objectName)) {
                    // Grandchild: use subquery through parent
                    // e.g., SELECT COUNT() FROM OpportunityContactRole
                    //       WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE AccountId = '001xxx')
                    Map<String, String> gcInfo = grandchildLookup.get(objectName);
                    String parentObject = gcInfo.get('parentObject');
                    String gcRelationshipField = gcInfo.get('relationshipField');

                    // Find the relationship field from parent to root
                    DCMBuilder.RelationshipDetectionResult parentRelation =
                        DCMBuilder.detectRelationshipField(parentObject, rootObject);

                    if (parentRelation != null && String.isNotBlank(gcRelationshipField)) {
                        String subquery = 'SELECT Id FROM ' + parentObject +
                            ' WHERE ' + parentRelation.relationshipField + ' = \'' + sampleRecordId + '\'';
                        String countQuery = 'SELECT COUNT() FROM ' + objectName +
                            ' WHERE ' + gcRelationshipField + ' IN (' + subquery + ')';

                        try {
                            count = Database.countQuery(countQuery);
                            result.queueDebug(runId, STAGE_NUMBER,
                                objectName + ' (grandchild via ' + parentObject + '): ' + count + ' records');
                        } catch (Exception subE) {
                            result.queueWarning(runId, STAGE_NUMBER,
                                'Grandchild query failed for ' + objectName + ': ' + subE.getMessage());
                        }
                    } else {
                        result.queueWarning(runId, STAGE_NUMBER,
                            'Cannot determine relationship for grandchild: ' + objectName);
                    }
                } else {
                    // Direct child: use simple parent filter
                    // e.g., SELECT COUNT() FROM Contact WHERE AccountId = '001xxx'
                    DCMBuilder.RelationshipDetectionResult relation =
                        DCMBuilder.detectRelationshipField(objectName, rootObject);

                    if (relation != null) {
                        String countQuery = 'SELECT COUNT() FROM ' + objectName +
                            ' WHERE ' + relation.relationshipField + ' = \'' + sampleRecordId + '\'';
                        count = Database.countQuery(countQuery);
                        result.queueDebug(runId, STAGE_NUMBER,
                            objectName + ': ' + count + ' records (via ' + relation.relationshipField + ')');
                    } else {
                        // CRITICAL: Do NOT fall back to org-wide count.
                        // Shell script behavior: if we can't detect a relationship to the root,
                        // this object should not be configured in the DCM for this run.
                        count = 0;
                        result.queueWarning(runId, STAGE_NUMBER,
                            objectName + ': Skipping - no detectable relationship to ' + rootObject);
                    }
                }

                results.put(objectName, count);

            } catch (Exception e) {
                // Log error but continue with other objects
                result.queueWarning(runId, STAGE_NUMBER,
                    'Failed to query ' + objectName + ': ' + e.getMessage());
                results.put(objectName, 0);
            }
        }

        return results;
    }
    
    /**
     * @description Builds a human-readable summary of data availability
     * @param dataAvailability Map of object to record count
     * @return Formatted summary string
     */
    private String buildDataSummary(Map<String, Integer> dataAvailability) {
        List<String> summaryParts = new List<String>();
        
        for (String objectName : dataAvailability.keySet()) {
            Integer count = dataAvailability.get(objectName);
            summaryParts.add(objectName + ' (' + count + ')');
        }
        
        return String.join(summaryParts, ', ');
    }
    
    /**
     * @description Calculates total records across all objects
     * @param dataAvailability Map of object to record count
     * @return Total record count
     */
    private Integer calculateTotalRecords(Map<String, Integer> dataAvailability) {
        Integer total = 0;
        for (Integer count : dataAvailability.values()) {
            total += count;
        }
        return total;
    }
    
    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}