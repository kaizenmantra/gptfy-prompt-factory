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

            // V2.0: Check for multi-sample support
            List<String> sampleIds = parseSampleIds(inputs);
            Boolean isMultiSample = sampleIds.size() > 1;

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

            // V2.0: Branch between single-sample and multi-sample execution
            Map<String, Integer> dataAvailability;

            if (isMultiSample) {
                // Multi-sample: profile across N samples and aggregate
                result.queueInfo(runId, STAGE_NUMBER,
                    'Multi-sample mode: Analyzing ' + sampleIds.size() + ' records');

                MultiSampleProfile profile = profileMultipleSamples(
                    rootObject, sampleIds, selectedObjects, selectedGrandchildren, runId, result);

                // Store multi-sample profile for downstream stages
                result.outputs.put('multiSampleProfile', profile);
                result.outputs.put('sampleCount', profile.sampleCount);

                // Provide legacy dataAvailability format for backward compatibility
                dataAvailability = profile.getLegacyDataAvailability();
            } else {
                // Single-sample: use existing logic (backward compatible)
                dataAvailability = performParentSpecificCountQueries(
                    rootObject, sampleRecordId, selectedObjects, selectedGrandchildren, runId, result);
            }

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
            result.outputs.put('sampleRecordIds', inputs.get('sampleRecordIds')); // V2.0 multi-sample
            result.outputs.put('outputFormat', inputs.get('outputFormat'));
            // Pass through enriched context from Stage 2 for downstream stages
            result.outputs.put('companyIntelligence', inputs.get('companyIntelligence'));
            result.outputs.put('industryContext', inputs.get('industryContext'));
            result.outputs.put('companyProfile', inputs.get('companyProfile'));
            result.outputs.put('strategicInsights', inputs.get('strategicInsights'));
            result.outputs.put('companyWebsite', inputs.get('companyWebsite'));

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
    
    // ========================================================================
    // MULTI-SAMPLE SUPPORT (V2.0)
    // ========================================================================

    /**
     * @description Parses sample IDs from inputs (supports V2.0 multi-sample)
     * @param inputs Map containing sampleRecordId or sampleRecordIds
     * @return List of sample IDs (single or multiple)
     */
    private List<String> parseSampleIds(Map<String, Object> inputs) {
        List<String> sampleIds = new List<String>();

        // Try sampleRecordIds first (V2.0 multi-sample)
        String sampleRecordIdsRaw = (String) inputs.get('sampleRecordIds');
        if (String.isNotBlank(sampleRecordIdsRaw)) {
            for (String id : sampleRecordIdsRaw.split(',')) {
                String trimmedId = id.trim();
                if (trimmedId.length() >= 15) {
                    sampleIds.add(trimmedId);
                }
            }
        }

        // Fall back to sampleRecordId (single sample, backward compatible)
        if (sampleIds.isEmpty()) {
            String singleId = (String) inputs.get('sampleRecordId');
            if (String.isNotBlank(singleId) && singleId.trim().length() >= 15) {
                sampleIds.add(singleId.trim());
            }
        }

        return sampleIds;
    }

    /**
     * @description Multi-sample profile with aggregated data
     */
    public class MultiSampleProfile {
        public Integer sampleCount;
        public String rootObject;
        public List<String> sampleIds;
        public List<SampleData> samples;
        public Map<String, ObjectAggregation> objectAggregations;
        public List<DataPattern> patterns;
        public String analysisSummary;

        public MultiSampleProfile() {
            this.samples = new List<SampleData>();
            this.objectAggregations = new Map<String, ObjectAggregation>();
            this.patterns = new List<DataPattern>();
        }

        /**
         * @description Converts to legacy dataAvailability format
         */
        public Map<String, Integer> getLegacyDataAvailability() {
            Map<String, Integer> legacy = new Map<String, Integer>();
            for (String objName : objectAggregations.keySet()) {
                ObjectAggregation agg = objectAggregations.get(objName);
                legacy.put(objName, Integer.valueOf(agg.avgCount));
            }
            return legacy;
        }
    }

    /**
     * @description Data from a single sample record
     */
    public class SampleData {
        public String recordId;
        public String recordName;
        public Map<String, Integer> childRecordCounts;

        public SampleData(String recordId) {
            this.recordId = recordId;
            this.childRecordCounts = new Map<String, Integer>();
        }
    }

    /**
     * @description Aggregated metrics for one object across samples
     */
    public class ObjectAggregation {
        public String objectName;
        public Integer samplesWithData;
        public Integer minCount;
        public Integer maxCount;
        public Decimal avgCount;
        public Integer totalCount;
        public Boolean isConsistent;

        public ObjectAggregation(String objectName) {
            this.objectName = objectName;
            this.samplesWithData = 0;
            this.totalCount = 0;
        }
    }

    /**
     * @description Detected cross-sample pattern
     */
    public class DataPattern {
        public String patternType;  // CONSISTENCY, VARIANCE, GAP
        public String description;
        public String objectName;
        public String severity;  // INFO, WARNING, INSIGHT

        public DataPattern(String type, String descText, String severityLevel) {
            this.patternType = type;
            this.description = descText;
            this.severity = severityLevel;
        }
    }

    /**
     * @description Profiles data across multiple sample records (V2.0)
     * @param rootObject The root object type
     * @param sampleIds List of sample record IDs
     * @param selectedObjects Objects to profile
     * @param grandchildren Grandchild object info
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return MultiSampleProfile with aggregated data
     */
    private MultiSampleProfile profileMultipleSamples(
        String rootObject,
        List<String> sampleIds,
        List<String> selectedObjects,
        List<Map<String, String>> grandchildren,
        Id runId,
        StageResult result
    ) {
        MultiSampleProfile profile = new MultiSampleProfile();
        profile.sampleCount = sampleIds.size();
        profile.rootObject = rootObject;
        profile.sampleIds = sampleIds;

        // Step 1: Query each sample individually
        for (String sampleId : sampleIds) {
            SampleData sample = querySampleData(
                rootObject, sampleId, selectedObjects, grandchildren, runId, result);
            profile.samples.add(sample);
        }

        // Step 2: Aggregate across samples
        profile.objectAggregations = aggregateObjectData(profile.samples, selectedObjects);

        // Step 3: Detect patterns
        profile.patterns = detectPatterns(profile);

        // Step 4: Build summary
        profile.analysisSummary = buildAnalysisSummary(profile);

        return profile;
    }

    /**
     * @description Queries data for a single sample
     */
    private SampleData querySampleData(
        String rootObject,
        String sampleId,
        List<String> selectedObjects,
        List<Map<String, String>> grandchildren,
        Id runId,
        StageResult result
    ) {
        SampleData sample = new SampleData(sampleId);

        // Use existing performParentSpecificCountQueries method
        Map<String, Integer> counts = performParentSpecificCountQueries(
            rootObject, sampleId, selectedObjects, grandchildren, runId, result);

        sample.childRecordCounts = counts;

        // Try to get record name
        try {
            String nameQuery = 'SELECT Name FROM ' + rootObject + ' WHERE Id = \'' + sampleId + '\' LIMIT 1';
            List<SObject> records = Database.query(nameQuery);
            if (!records.isEmpty()) {
                sample.recordName = String.valueOf(records[0].get('Name'));
            }
        } catch (Exception e) {
            sample.recordName = sampleId;  // Fall back to ID
        }

        return sample;
    }

    /**
     * @description Aggregates object data across samples
     */
    private Map<String, ObjectAggregation> aggregateObjectData(
        List<SampleData> samples,
        List<String> selectedObjects
    ) {
        Map<String, ObjectAggregation> aggregations = new Map<String, ObjectAggregation>();

        for (String objName : selectedObjects) {
            ObjectAggregation agg = new ObjectAggregation(objName);
            List<Integer> counts = new List<Integer>();

            // Collect counts from each sample
            for (SampleData sample : samples) {
                Integer count = sample.childRecordCounts.get(objName);
                if (count != null && count > 0) {
                    agg.samplesWithData++;
                    counts.add(count);
                    agg.totalCount += count;
                }
            }

            // Calculate min/max/avg
            if (!counts.isEmpty()) {
                counts.sort();
                agg.minCount = counts[0];
                agg.maxCount = counts[counts.size() - 1];
                agg.avgCount = (Decimal)agg.totalCount / samples.size();
                agg.isConsistent = (agg.minCount == agg.maxCount);
            } else {
                agg.minCount = 0;
                agg.maxCount = 0;
                agg.avgCount = 0;
                agg.isConsistent = true;
            }

            aggregations.put(objName, agg);
        }

        return aggregations;
    }

    /**
     * @description Detects cross-sample patterns
     */
    private List<DataPattern> detectPatterns(MultiSampleProfile profile) {
        List<DataPattern> patterns = new List<DataPattern>();

        for (String objName : profile.objectAggregations.keySet()) {
            ObjectAggregation agg = profile.objectAggregations.get(objName);

            // Pattern: GAP (missing in some samples)
            if (agg.samplesWithData < profile.sampleCount && agg.samplesWithData > 0) {
                patterns.add(new DataPattern(
                    'GAP',
                    objName + ' missing in ' + (profile.sampleCount - agg.samplesWithData) + '/' +
                    profile.sampleCount + ' samples',
                    'WARNING'
                ));
            }

            // Pattern: VARIANCE (inconsistent counts)
            if (!agg.isConsistent && agg.samplesWithData > 1) {
                patterns.add(new DataPattern(
                    'VARIANCE',
                    objName + ' count varies ' + agg.minCount + '-' + agg.maxCount +
                    ' across samples (avg ' + agg.avgCount.setScale(1) + ')',
                    'INFO'
                ));
            }

            // Pattern: CONSISTENCY (same across all)
            if (agg.isConsistent && agg.samplesWithData == profile.sampleCount && agg.totalCount > 0) {
                patterns.add(new DataPattern(
                    'CONSISTENCY',
                    objName + ' consistent: ' + agg.minCount + ' records in all ' +
                    profile.sampleCount + ' samples',
                    'INSIGHT'
                ));
            }
        }

        return patterns;
    }

    /**
     * @description Builds analysis summary
     */
    private String buildAnalysisSummary(MultiSampleProfile profile) {
        List<String> parts = new List<String>();
        parts.add('Analyzed ' + profile.sampleCount + ' ' + profile.rootObject + ' records');

        Integer objectsWithData = 0;
        for (ObjectAggregation agg : profile.objectAggregations.values()) {
            if (agg.samplesWithData > 0) {
                objectsWithData++;
            }
        }
        parts.add(objectsWithData + ' objects have data');

        return String.join(parts, '. ') + '.';
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}