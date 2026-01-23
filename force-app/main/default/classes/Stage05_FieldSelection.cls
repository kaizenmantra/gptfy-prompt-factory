/**
 * @description Stage 5: Field Selection
 * Gets fields for each object from Stage 4 and uses Claude AI to select 10-15 most relevant fields per object
 *
 * CRITICAL: This stage now uses LLM-based field selection (mirroring the shell script approach)
 * instead of hardcoded candidate fields. The LLM selects fields based on:
 * - Business context and target persona
 * - Object relevance and data availability
 * - Field information value for AI-generated output
 *
 * V2.0: Enhanced with multi-sample awareness - uses cross-sample data patterns from Stage 4
 * to inform field selection. Objects with consistent data across samples are prioritized.
 *
 * V2.1: Enhanced with parent traversal suggestions - loads Traversal builder prompts to suggest
 * parent field candidates (e.g., Contact.Name via ContactId) for personalization.
 */
public with sharing class Stage05_FieldSelection implements IStage {

    private static final Integer STAGE_NUMBER = 5;
    private static final Integer MIN_FIELDS_PER_OBJECT = 5;  // Reduced to be more realistic
    private static final Integer MAX_FIELDS_PER_OBJECT = 20;
    private static final Integer MIN_MEANINGFUL_FIELDS = 3;   // Minimum non-ID fields required

    // Feature flag: Use LLM-based field selection (matches shell script behavior)
    private static final Boolean USE_LLM_SELECTION = true;

    // V2.1: Inner class to hold parsed traversal data
    public class TraversalDefinition {
        public String sourceObject;
        public String sourceField;
        public String targetObject;
        public Boolean isPolymorphic;
        public List<TraversalField> fields;
    }

    public class TraversalField {
        public String path;
        public String alias;
    }

    /**
     * @description Executes Stage 5: Field Selection
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing objectsWithData and business context from previous stages
     * @return StageResult with selected fields map in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 5: Field Selection');

        try {
            // Get inputs
            String rootObject = (String) inputs.get('rootObject');
            String businessContext = (String) inputs.get('businessContext');
            String targetPersona = (String) inputs.get('targetPersona');

            // V2.0: Check for multi-sample profile from Stage 4
            Stage04_DataProfiling.MultiSampleProfile multiSampleProfile = null;
            Object multiSampleRaw = inputs.get('multiSampleProfile');
            if (multiSampleRaw != null && multiSampleRaw instanceof Stage04_DataProfiling.MultiSampleProfile) {
                multiSampleProfile = (Stage04_DataProfiling.MultiSampleProfile) multiSampleRaw;
                result.queueInfo(runId, STAGE_NUMBER,
                    'Multi-sample mode: Using data from ' + multiSampleProfile.sampleCount + ' samples');
            }

            // Get objects that have data from Stage 4
            List<Object> rawObjectsWithData = (List<Object>) inputs.get('objectsWithData');
            List<String> objectsWithData = new List<String>();
            if (rawObjectsWithData != null) {
                for (Object obj : rawObjectsWithData) {
                    objectsWithData.add(String.valueOf(obj));
                }
            }
            if (objectsWithData.isEmpty()) {
                objectsWithData.add(rootObject);
            }

            Map<String, List<String>> selectedFields;
            Map<String, List<String>> selectedParentFields = new Map<String, List<String>>();
            List<String> validationWarnings = new List<String>();

            if (USE_LLM_SELECTION) {
                // LLM-BASED FIELD SELECTION (mirrors shell script Stage 5)
                // This is context-aware and profile-driven
                result.queueInfo(runId, STAGE_NUMBER,
                    'Using LLM-based field selection (shell script parity)');

                // Step 1: Get all available fields for each object from schema
                Map<String, List<SchemaHelper.FieldMetadata>> fieldsByObject =
                    getFieldsForObjectsDeferred(objectsWithData, runId, result);

                // Step 1.5 (V2.1): Load traversal builders for parent field suggestions
                Map<String, List<TraversalDefinition>> traversalsByObject =
                    loadTraversalsForObjects(objectsWithData, runId, result);

                // Step 2: Use Claude to select relevant fields based on context
                // V2.0: Pass multi-sample profile if available for enhanced field selection
                // V2.1: Pass traversals for parent field suggestions
                selectedFields = selectFieldsWithAIDeferred(
                    fieldsByObject, traversalsByObject, rootObject, businessContext, targetPersona,
                    multiSampleProfile, runId, result, selectedParentFields);

                // V2.2 FALLBACK: If LLM didn't return parent fields but traversals exist, add defaults
                if (selectedParentFields.isEmpty() && traversalsByObject != null && !traversalsByObject.isEmpty()) {
                    result.queueInfo(runId, STAGE_NUMBER,
                        'LLM did not return selectedParentFields - adding defaults from available traversals');
                    addDefaultParentFields(selectedParentFields, traversalsByObject, objectsWithData);
                    result.queueInfo(runId, STAGE_NUMBER,
                        'Default parent fields added: ' + JSON.serialize(selectedParentFields));
                }

                // Step 3: Validate AI-selected fields against schema
                Map<String, List<String>> validatedFields = new Map<String, List<String>>();
                for (String objectName : selectedFields.keySet()) {
                    List<String> fields = selectedFields.get(objectName);
                    SchemaHelper.FieldValidationResult validation =
                        SchemaHelper.validateFields(objectName, fields);

                    if (!validation.objectExists) {
                        throw new StageException('Object ' + objectName + ' does not exist in schema');
                    }

                    if (!validation.invalidFields.isEmpty()) {
                        validationWarnings.add(objectName + ' AI selected invalid fields: ' +
                            String.join(validation.invalidFields, ', '));
                    }

                    if (!validation.inaccessibleFields.isEmpty()) {
                        validationWarnings.add(objectName + ' AI selected inaccessible fields: ' +
                            String.join(validation.inaccessibleFields, ', '));
                    }

                    // Only use validated fields
                    validatedFields.put(objectName, validation.validFields);
                }

                // Step 4: CRITICAL - Enrich fields to ensure minimum meaningful fields per object
                // This prevents DCM from having objects with only ID fields
                selectedFields = validateAndEnrichFieldSelection(validatedFields, fieldsByObject, rootObject);

                // Log any enrichment that occurred
                for (String objectName : selectedFields.keySet()) {
                    Integer original = validatedFields.get(objectName).size();
                    Integer enriched = selectedFields.get(objectName).size();
                    if (enriched > original) {
                        result.queueInfo(runId, STAGE_NUMBER,
                            objectName + ': Enriched from ' + original + ' to ' + enriched + ' fields (added meaningful fields)');
                    }
                }

            } else {
                // FALLBACK: Hardcoded candidate field selection (less adaptive)
                result.queueInfo(runId, STAGE_NUMBER,
                    'Using hardcoded field selection (fallback mode)');

                Map<String, List<String>> candidateFields = buildCandidateFields(rootObject, objectsWithData);

                // CRITICAL: Validate fields against actual Salesforce schema
                selectedFields = new Map<String, List<String>>();

                for (String objectName : candidateFields.keySet()) {
                    List<String> fields = candidateFields.get(objectName);
                    SchemaHelper.FieldValidationResult validation =
                        SchemaHelper.validateFields(objectName, fields);

                    if (!validation.objectExists) {
                        throw new StageException('Object ' + objectName + ' does not exist in schema');
                    }

                    if (!validation.invalidFields.isEmpty()) {
                        validationWarnings.add(objectName + ' invalid fields: ' +
                            String.join(validation.invalidFields, ', '));
                    }

                    if (!validation.inaccessibleFields.isEmpty()) {
                        validationWarnings.add(objectName + ' inaccessible fields: ' +
                            String.join(validation.inaccessibleFields, ', '));
                    }

                    // Only use validated fields
                    selectedFields.put(objectName, validation.validFields);
                }
            }

            // Log validation results
            if (!validationWarnings.isEmpty()) {
                result.queueInfo(runId, STAGE_NUMBER,
                    'Schema validation warnings: ' + String.join(validationWarnings, '; '));
            }

            Integer totalFieldsSelected = 0;
            for (List<String> fields : selectedFields.values()) {
                totalFieldsSelected += fields.size();
            }

            // Verify we have at least some fields
            if (totalFieldsSelected == 0) {
                throw new StageException('No valid fields found for ' + rootObject +
                    ' after schema validation');
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Field selection complete: ' + totalFieldsSelected + ' valid fields across ' +
                selectedFields.keySet().size() + ' objects');

            // Build selection summary showing all objects
            String selectionSummary = buildSelectionSummary(selectedFields);

            // Update objectsWithData to match what we actually selected
            objectsWithData = new List<String>(selectedFields.keySet());

            // Build outputs - only pass essential data to avoid stack overflow
            result.outputs.put('selectedFields', selectedFields);
            result.outputs.put('totalFieldsSelected', totalFieldsSelected);
            result.outputs.put('selectionSummary', selectionSummary);
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('targetPersona', targetPersona);
            result.outputs.put('businessObjectives', inputs.get('businessObjectives'));
            result.outputs.put('objectsWithData', objectsWithData);
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            result.outputs.put('outputFormat', inputs.get('outputFormat'));
            // Pass through selectedGrandchildren for DCM creation in Stage 8/9
            result.outputs.put('selectedGrandchildren', inputs.get('selectedGrandchildren'));
            // Pass through selectedObjects - needed for DCM creation even if objects have no data
            // This ensures DCM Detail records are created for all child relationships
            result.outputs.put('selectedObjects', inputs.get('selectedObjects'));
            // Pass through enriched context from Stage 2 for downstream stages
            result.outputs.put('companyIntelligence', inputs.get('companyIntelligence'));
            result.outputs.put('industryContext', inputs.get('industryContext'));
            result.outputs.put('companyProfile', inputs.get('companyProfile'));
            result.outputs.put('strategicInsights', inputs.get('strategicInsights'));
            result.outputs.put('companyWebsite', inputs.get('companyWebsite'));

            // CRITICAL: Pass through data summary for template design
            result.outputs.put('dataSummary', inputs.get('dataSummary'));
            result.outputs.put('dataAvailability', inputs.get('dataAvailability'));
            // Don't pass dataAvailability - it can be large and causes stack overflow
            // Downstream stages can re-query if needed

            // V2.0: Pass through multi-sample data for downstream stages (Stage 7/8 meta-prompt)
            if (multiSampleProfile != null) {
                result.outputs.put('multiSampleProfile', multiSampleProfile);
                result.outputs.put('sampleCount', multiSampleProfile.sampleCount);
            }
            result.outputs.put('sampleRecordIds', inputs.get('sampleRecordIds'));

            // V2.1: Pass selected parent fields for DCM Builder
            if (selectedParentFields != null && !selectedParentFields.isEmpty()) {
                result.outputs.put('selectedParentFields', selectedParentFields);
                result.queueInfo(runId, STAGE_NUMBER,
                    'Parent fields selected: ' + JSON.serialize(selectedParentFields));
            }

            result.markCompleted();

        } catch (Exception e) {
            String errorMsg = 'Failed to complete field selection: ' + e.getMessage();
            result.markFailed(errorMsg);
        }

        return result;
    }

    /**
     * @description Builds candidate fields map for root and child objects
     * Mirrors the shell script's hardcoded field selection approach
     * @param rootObject The root Salesforce object
     * @param objectsWithData List of objects that have data
     * @return Map of object name to candidate field list
     */
    private Map<String, List<String>> buildCandidateFields(String rootObject, List<String> objectsWithData) {
        Map<String, List<String>> candidateFields = new Map<String, List<String>>();

        // Always include root object
        if (rootObject == 'Account') {
            candidateFields.put('Account', new List<String>{
                'Id', 'Name', 'Type', 'Industry', 'AnnualRevenue',
                'NumberOfEmployees', 'BillingCity', 'BillingState',
                'Phone', 'Website', 'OwnerId', 'CreatedDate', 'Description'
            });
        } else if (rootObject == 'Opportunity') {
            candidateFields.put('Opportunity', new List<String>{
                'Id', 'Name', 'StageName', 'Amount', 'CloseDate',
                'Probability', 'Type', 'LeadSource', 'AccountId',
                'OwnerId', 'CreatedDate', 'IsClosed', 'IsWon'
            });
        } else if (rootObject == 'Contact') {
            candidateFields.put('Contact', new List<String>{
                'Id', 'Name', 'FirstName', 'LastName', 'Email',
                'Phone', 'Title', 'Department', 'AccountId',
                'OwnerId', 'CreatedDate', 'MailingCity'
            });
        } else {
            // Generic fallback for root
            candidateFields.put(rootObject, new List<String>{
                'Id', 'Name', 'OwnerId', 'CreatedDate'
            });
        }

        // Add child objects that have data
        for (String objectName : objectsWithData) {
            if (objectName == rootObject || candidateFields.containsKey(objectName)) {
                continue; // Skip root object (already added)
            }

            // Add standard child object fields based on object type
            if (objectName == 'Contact') {
                candidateFields.put('Contact', new List<String>{
                    'Id', 'Name', 'FirstName', 'LastName', 'Email', 'Phone',
                    'Title', 'Department', 'AccountId', 'OwnerId', 'CreatedDate'
                });
            } else if (objectName == 'Opportunity') {
                candidateFields.put('Opportunity', new List<String>{
                    'Id', 'Name', 'StageName', 'Amount', 'CloseDate',
                    'Probability', 'Type', 'AccountId', 'OwnerId', 'IsClosed', 'IsWon'
                });
            } else if (objectName == 'Case') {
                candidateFields.put('Case', new List<String>{
                    'Id', 'CaseNumber', 'Subject', 'Status', 'Priority',
                    'Type', 'Origin', 'AccountId', 'OwnerId', 'CreatedDate', 'IsClosed'
                });
            } else if (objectName == 'Task') {
                candidateFields.put('Task', new List<String>{
                    'Id', 'Subject', 'Status', 'Priority', 'ActivityDate',
                    'WhatId', 'WhoId', 'OwnerId', 'CreatedDate', 'IsClosed', 'Description'
                });
            } else if (objectName == 'Event') {
                candidateFields.put('Event', new List<String>{
                    'Id', 'Subject', 'StartDateTime', 'EndDateTime',
                    'WhatId', 'WhoId', 'OwnerId', 'CreatedDate', 'Description'
                });
            } else if (objectName == 'Contract') {
                candidateFields.put('Contract', new List<String>{
                    'Id', 'ContractNumber', 'Status', 'StartDate', 'EndDate',
                    'ContractTerm', 'AccountId', 'OwnerId', 'CreatedDate'
                });
            } else if (objectName == 'Order') {
                candidateFields.put('Order', new List<String>{
                    'Id', 'OrderNumber', 'Status', 'TotalAmount', 'EffectiveDate',
                    'AccountId', 'OwnerId', 'CreatedDate'
                });
            } else if (objectName == 'Asset') {
                candidateFields.put('Asset', new List<String>{
                    'Id', 'Name', 'Status', 'Quantity', 'Price',
                    'AccountId', 'OwnerId', 'CreatedDate'
                });
            }
            // Skip unknown/custom objects to avoid issues
        }

        return candidateFields;
    }

    /**
     * @description Gets field metadata for all objects using SchemaHelper (deferred logging)
     * CRITICAL: Only includes ACCESSIBLE and QUERYABLE fields to prevent AI from selecting
     * fields that will cause runtime errors. This filters out:
     * - Inaccessible fields (user doesn't have FLS access)
     * - Non-queryable fields (e.g., some fields on ContentDocumentLink)
     * - System fields that aren't useful for prompts
     * @param objectNames List of object API names
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return Map of object name to list of field metadata (only accessible fields)
     */
    private Map<String, List<SchemaHelper.FieldMetadata>> getFieldsForObjectsDeferred(
            List<String> objectNames, Id runId, StageResult result) {

        Map<String, List<SchemaHelper.FieldMetadata>> fieldsByObject =
            new Map<String, List<SchemaHelper.FieldMetadata>>();

        // Limit fields per object to prevent stack overflow and large prompts
        Integer maxFieldsPerObject = 30; // Increased to give LLM more options

        for (String objectName : objectNames) {
            try {
                // CRITICAL: Check if object has queryability restrictions (e.g., ContentDocumentLink)
                Set<String> safeFields = SchemaHelper.getSafeQueryableFields(objectName);
                Boolean hasRestrictions = !safeFields.isEmpty();

                List<SchemaHelper.FieldMetadata> allFields = SchemaHelper.getFields(objectName);

                // V2.2 Task 2.8: Calculate field density and populate usagePercent
                try {
                    Map<String, Integer> fieldDensity = SchemaHelper.calculateFieldDensity(objectName, 100);
                    Integer fieldsWithDensity = 0;
                    for (SchemaHelper.FieldMetadata field : allFields) {
                        if (fieldDensity.containsKey(field.name)) {
                            field.usagePercent = fieldDensity.get(field.name);
                            fieldsWithDensity++;
                        }
                    }
                    result.queueDebug(runId, STAGE_NUMBER,
                        objectName + ': Calculated density for ' + fieldsWithDensity + ' fields');
                } catch (Exception densityEx) {
                    // Non-fatal: Continue without density data if calculation fails
                    result.queueDebug(runId, STAGE_NUMBER,
                        objectName + ': Density calculation skipped - ' + densityEx.getMessage());
                }

                List<SchemaHelper.FieldMetadata> accessibleFields = new List<SchemaHelper.FieldMetadata>();
                Integer skippedInaccessible = 0;

                for (SchemaHelper.FieldMetadata field : allFields) {
                    if (accessibleFields.size() >= maxFieldsPerObject) {
                        break;
                    }

                    // CRITICAL FIX: Filter out inaccessible fields BEFORE sending to AI
                    // This prevents the AI from selecting fields that will fail at runtime
                    if (!field.isAccessible) {
                        skippedInaccessible++;
                        continue; // Skip inaccessible fields entirely
                    }

                    // If object has restrictions (e.g., ContentDocumentLink), only include safe fields
                    if (hasRestrictions) {
                        if (safeFields.contains(field.name)) {
                            accessibleFields.add(field);
                        }
                    } else {
                        accessibleFields.add(field);
                    }
                }

                fieldsByObject.put(objectName, accessibleFields);

                // Log what was filtered
                String restrictionNote = hasRestrictions ? ' (RESTRICTED - only ' + safeFields.size() + ' queryable)' : '';
                String accessNote = skippedInaccessible > 0 ? ', skipped ' + skippedInaccessible + ' inaccessible' : '';
                result.queueDebug(runId, STAGE_NUMBER,
                    objectName + ': ' + accessibleFields.size() + ' accessible of ' + allFields.size() + ' total fields' + restrictionNote + accessNote);

            } catch (Exception e) {
                result.queueError(runId, STAGE_NUMBER,
                    'Failed to get fields for ' + objectName + ': ' + e.getMessage());
                // Continue with other objects
            }
        }

        return fieldsByObject;
    }

    /**
     * @description Calls Claude AI to select most relevant fields (deferred logging)
     * @param fieldsByObject Map of object to available fields
     * @param traversalsByObject V2.1: Map of object to available parent traversals
     * @param rootObject The root Salesforce object
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @param multiSampleProfile V2.0: Multi-sample profile from Stage 4 (can be null for single-sample)
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @param selectedParentFields V2.1: Output map to populate with selected parent fields
     * @return Map of object name to selected field list
     */
    private Map<String, List<String>> selectFieldsWithAIDeferred(
            Map<String, List<SchemaHelper.FieldMetadata>> fieldsByObject,
            Map<String, List<TraversalDefinition>> traversalsByObject,
            String rootObject,
            String businessContext,
            String targetPersona,
            Stage04_DataProfiling.MultiSampleProfile multiSampleProfile,
            Id runId,
            StageResult result,
            Map<String, List<String>> selectedParentFields) {

        // Build prompt for field selection (V2.0: multi-sample, V2.1: traversals)
        String prompt = buildFieldSelectionPrompt(fieldsByObject, traversalsByObject, rootObject,
                                                  businessContext, targetPersona, multiSampleProfile);

        result.queueDebug(runId, STAGE_NUMBER, 'Calling Claude AI for field selection');

        // Call AI (HTTP callout - no DML before this!)
        AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 4096, 0.5);

        if (!aiResponse.success) {
            throw new StageException('Claude AI call failed: ' + aiResponse.errorMessage);
        }

        result.queueInfo(runId, STAGE_NUMBER,
            'Claude AI response received (Tokens: ' + aiResponse.inputTokens + '/' +
            aiResponse.outputTokens + ')');

        // Parse AI response
        Map<String, Object> parsedResponse = parseFieldSelectionResponse(aiResponse.content);

        // Store AI reasoning
        if (parsedResponse.containsKey('reasoning')) {
            result.queueInfo(runId, STAGE_NUMBER,
                'AI Reasoning: ' + parsedResponse.get('reasoning'));
        }

        // Extract selected fields map and convert types properly
        // JSON deserialization returns Map<String, Object> where values are List<Object>
        Map<String, Object> rawSelectedFields = (Map<String, Object>) parsedResponse.get('selectedFields');
        Map<String, List<String>> selectedFields = new Map<String, List<String>>();

        for (String objectName : rawSelectedFields.keySet()) {
            List<Object> rawFieldList = (List<Object>) rawSelectedFields.get(objectName);
            List<String> fieldList = new List<String>();
            for (Object field : rawFieldList) {
                fieldList.add(String.valueOf(field));
            }
            selectedFields.put(objectName, fieldList);
        }

        // V2.1: Extract selected parent fields if present
        if (parsedResponse.containsKey('selectedParentFields') && selectedParentFields != null) {
            Object rawParentFields = parsedResponse.get('selectedParentFields');
            if (rawParentFields instanceof Map<String, Object>) {
                Map<String, Object> parentFieldsMap = (Map<String, Object>) rawParentFields;
                for (String objectName : parentFieldsMap.keySet()) {
                    List<Object> rawFieldList = (List<Object>) parentFieldsMap.get(objectName);
                    List<String> fieldList = new List<String>();
                    for (Object field : rawFieldList) {
                        fieldList.add(String.valueOf(field));
                    }
                    selectedParentFields.put(objectName, fieldList);
                }
            }
        }

        return selectedFields;
    }

    /**
     * @description Builds the prompt for Claude AI to select relevant fields
     * Uses List<String> and String.join() to avoid stack overflow from string concatenation
     * CRITICAL: Emphasizes selecting meaningful data fields, not just ID fields
     * V2.0: Enhanced with multi-sample context to inform field selection priorities
     * V2.1: Enhanced with parent traversal suggestions for personalization
     * @param fieldsByObject Map of object to available fields
     * @param traversalsByObject V2.1: Map of object to available parent traversals
     * @param rootObject The root Salesforce object
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @param multiSampleProfile V2.0: Multi-sample profile (can be null for single-sample)
     * @return Formatted prompt string
     */
    private String buildFieldSelectionPrompt(
            Map<String, List<SchemaHelper.FieldMetadata>> fieldsByObject,
            Map<String, List<TraversalDefinition>> traversalsByObject,
            String rootObject,
            String businessContext,
            String targetPersona,
            Stage04_DataProfiling.MultiSampleProfile multiSampleProfile) {

        // Use List<String> to avoid stack overflow from repeated string concatenation
        List<String> promptParts = new List<String>();

        promptParts.add('You are an expert Salesforce data architect specializing in field selection for AI prompts.');
        promptParts.add('');
        promptParts.add('BUSINESS CONTEXT:');
        promptParts.add(businessContext);
        promptParts.add('');
        promptParts.add('TARGET PERSONA: ' + targetPersona);
        promptParts.add('ROOT OBJECT: ' + rootObject);

        // V2.0: Add multi-sample context if available
        if (multiSampleProfile != null && multiSampleProfile.sampleCount > 1) {
            promptParts.add('');
            promptParts.add('=== MULTI-SAMPLE DATA ANALYSIS ===');
            promptParts.add('Analyzed ' + multiSampleProfile.sampleCount + ' ' + rootObject + ' records to understand data patterns.');
            promptParts.add('');

            // Add object availability summary
            promptParts.add('DATA AVAILABILITY ACROSS SAMPLES:');
            for (String objName : multiSampleProfile.objectAggregations.keySet()) {
                Stage04_DataProfiling.ObjectAggregation agg = multiSampleProfile.objectAggregations.get(objName);
                if (agg.samplesWithData > 0) {
                    String availabilityNote = objName + ': Present in ' + agg.samplesWithData + '/' +
                        multiSampleProfile.sampleCount + ' samples';
                    if (agg.avgCount > 0) {
                        availabilityNote += ' (avg ' + agg.avgCount.setScale(1) + ' records)';
                    }
                    if (agg.isConsistent) {
                        availabilityNote += ' [CONSISTENT]';
                    }
                    promptParts.add('- ' + availabilityNote);
                }
            }

            // Add detected patterns
            if (multiSampleProfile.patterns != null && !multiSampleProfile.patterns.isEmpty()) {
                promptParts.add('');
                promptParts.add('DETECTED DATA PATTERNS:');
                for (Stage04_DataProfiling.DataPattern pattern : multiSampleProfile.patterns) {
                    promptParts.add('- [' + pattern.severity + '] ' + pattern.description);
                }
            }

            promptParts.add('');
            promptParts.add('MULTI-SAMPLE FIELD SELECTION GUIDANCE:');
            promptParts.add('- PRIORITIZE objects with high availability (present in all samples)');
            promptParts.add('- Objects marked [CONSISTENT] have predictable data - excellent for analysis');
            promptParts.add('- Objects with [WARNING] patterns may have missing data - include defensive fields');
            promptParts.add('- Focus on fields that can reveal the patterns detected above');
        }

        // V2.1: Add parent traversal suggestions if available
        if (traversalsByObject != null && !traversalsByObject.isEmpty()) {
            promptParts.add('');
            promptParts.add('=== PARENT FIELD TRAVERSALS (V2.1) ===');
            promptParts.add('For personalization, you can select parent fields via lookup relationships.');
            promptParts.add('These fields come from PARENT objects (e.g., Contact.Name via ContactId).');
            promptParts.add('');
            promptParts.add('AVAILABLE PARENT TRAVERSALS:');

            for (String objectName : traversalsByObject.keySet()) {
                List<TraversalDefinition> traversals = traversalsByObject.get(objectName);
                for (TraversalDefinition trav : traversals) {
                    String polymorphicNote = trav.isPolymorphic ? ' [POLYMORPHIC]' : '';
                    promptParts.add('');
                    promptParts.add('From ' + trav.sourceObject + '.' + trav.sourceField + ' -> ' + trav.targetObject + polymorphicNote);
                    for (TraversalField tf : trav.fields) {
                        promptParts.add('  - ' + trav.sourceField + '.' + tf.path + ' (alias: ' + tf.alias + ')');
                    }
                }
            }

            promptParts.add('');
            promptParts.add('PARENT FIELD SELECTION GUIDANCE (V2.2 - REQUIRED):');
            promptParts.add('YOU MUST SELECT PARENT FIELDS for personalization. At minimum:');
            promptParts.add('- ALWAYS select OwnerId.Name on root object (e.g., "Opportunity": ["OwnerId.Name"])');
            promptParts.add('- ALWAYS select ContactId.Name on OpportunityContactRole (if present)');
            promptParts.add('- Consider AccountId.Name, AccountId.Industry for business context');
            promptParts.add('');
            promptParts.add('Without parent fields, output will say "the owner" instead of "Sarah Johnson".');
            promptParts.add('This is a critical personalization requirement - do NOT skip selectedParentFields!');
        }

        promptParts.add('');
        promptParts.add('AVAILABLE FIELDS BY OBJECT:');
        promptParts.add('(V2.2: Fields now include category, helpText when available, and relevance hints)');

        Integer maxFieldsPerObjectInPrompt = 30;
        for (String objectName : fieldsByObject.keySet()) {
            promptParts.add('');
            promptParts.add('Object: ' + objectName);
            List<SchemaHelper.FieldMetadata> fields = fieldsByObject.get(objectName);

            // V2.2: Group fields by category for easier selection
            Map<String, List<SchemaHelper.FieldMetadata>> fieldsByCategory = new Map<String, List<SchemaHelper.FieldMetadata>>();
            for (SchemaHelper.FieldMetadata field : fields) {
                String cat = String.isNotBlank(field.category) ? field.category : 'other';
                if (!fieldsByCategory.containsKey(cat)) {
                    fieldsByCategory.put(cat, new List<SchemaHelper.FieldMetadata>());
                }
                fieldsByCategory.get(cat).add(field);
            }

            // V2.2: Display fields grouped by category with relevance hints
            Integer fieldCount = 0;
            List<String> categoryOrder = new List<String>{'narrative', 'metric', 'classification', 'temporal', 'contact', 'flag', 'relationship', 'other'};

            for (String category : categoryOrder) {
                if (!fieldsByCategory.containsKey(category)) continue;
                List<SchemaHelper.FieldMetadata> catFields = fieldsByCategory.get(category);
                if (catFields.isEmpty()) continue;

                // V2.2: Category header with relevance hint
                String relevanceHint = getCategoryRelevanceHint(category);
                promptParts.add('  [' + category.toUpperCase() + '] ' + relevanceHint);

                for (SchemaHelper.FieldMetadata field : catFields) {
                    if (fieldCount >= maxFieldsPerObjectInPrompt) {
                        promptParts.add('    ... and more fields');
                        break;
                    }

                    // V2.2: Build enhanced field description with helpText
                    String fieldDesc = '    - ' + field.name + ' (' + field.label + ') [' + field.type + ']';

                    // V2.2: Add helpText if available (truncate if too long)
                    if (String.isNotBlank(field.helpText)) {
                        String helpTextShort = field.helpText.length() > 60
                            ? field.helpText.substring(0, 60) + '...'
                            : field.helpText;
                        fieldDesc += ' - "' + helpTextShort + '"';
                    }

                    // V2.2: Add usage density hint if available
                    if (field.usagePercent != null && field.usagePercent > 0) {
                        fieldDesc += ' [' + field.usagePercent + '% populated]';
                    }

                    promptParts.add(fieldDesc);
                    fieldCount++;
                }
            }
        }

        promptParts.add('');
        promptParts.add('=== CRITICAL REQUIREMENTS ===');
        promptParts.add('');
        promptParts.add('MINIMUM FIELD REQUIREMENTS:');
        promptParts.add('- Select ' + MIN_FIELDS_PER_OBJECT + '-' + MAX_FIELDS_PER_OBJECT + ' fields per object');
        promptParts.add('- Each object MUST have at least ' + MIN_MEANINGFUL_FIELDS + ' MEANINGFUL DATA FIELDS (not just IDs)');
        promptParts.add('- "Meaningful" fields are: text/picklist values, dates, numbers, currencies, descriptions');
        promptParts.add('- ID fields (ending in "Id") alone are NOT sufficient - they only reference other records');
        promptParts.add('');
        promptParts.add('DO NOT SELECT only ID fields like:');
        promptParts.add('- BAD: ["Id", "OpportunityId", "ContactId"] - This is useless for AI output');
        promptParts.add('- GOOD: ["Id", "Name", "Role", "IsPrimary", "ContactId"] - Has meaningful data');
        promptParts.add('');
        promptParts.add('FIELD SELECTION PRIORITIES (V2.2 - Use Category Hints Above):');
        promptParts.add('1. NARRATIVE category fields (Description, Comments, Body) - HIGH PRIORITY for insights');
        promptParts.add('2. METRIC category fields (Amount, Quantity, Percent) - HIGH PRIORITY for KPIs');
        promptParts.add('3. CLASSIFICATION category fields (Status, StageName, Type) - HIGH PRIORITY for segmentation');
        promptParts.add('4. TEMPORAL category fields (CloseDate, CreatedDate) - MEDIUM PRIORITY for trends');
        promptParts.add('5. CONTACT category fields (Email, Phone) - MEDIUM PRIORITY for personalization');
        promptParts.add('6. FLAG category fields (IsWon, IsClosed) - MEDIUM PRIORITY for filtering');
        promptParts.add('7. RELATIONSHIP category fields (AccountId, OwnerId) - LOW PRIORITY (use parent traversals instead)');
        promptParts.add('');
        promptParts.add('V2.2 TIPS:');
        promptParts.add('- Fields with helpText (in quotes) have admin-defined descriptions - they are well-maintained');
        promptParts.add('- Fields with [X% populated] have real data - prioritize highly populated fields');
        promptParts.add('- Prefer NARRATIVE fields for text summaries and METRIC fields for dashboards');
        promptParts.add('');
        promptParts.add('OBJECT-SPECIFIC GUIDANCE:');
        promptParts.add('- For Opportunity: Amount, StageName, CloseDate, Probability, Type, NextStep, Description');
        promptParts.add('- For OpportunityContactRole: Role, IsPrimary, ContactId (need the Role!)');
        promptParts.add('- For Task/Event: Subject, Status, Priority, ActivityDate, Description');
        promptParts.add('- For Case: Subject, Status, Priority, Type, Description');
        promptParts.add('- For Contact: Name, Title, Email, Phone, Department');
        promptParts.add('');
        promptParts.add('Return ONLY valid JSON in this exact format:');
        promptParts.add('{');
        promptParts.add('  "selectedFields": {');
        promptParts.add('    "' + rootObject + '": ["Id", "Name", "Field3", "Field4", ...],');
        promptParts.add('    "ChildObject": ["Id", "Name", "MeaningfulField1", "MeaningfulField2", ...]');
        promptParts.add('  },');
        // V2.2: Add parent field selection format - REQUIRED if traversals are available
        if (traversalsByObject != null && !traversalsByObject.isEmpty()) {
            promptParts.add('  "selectedParentFields": {');
            promptParts.add('    "' + rootObject + '": ["OwnerId.Name"],');
            promptParts.add('    "OpportunityContactRole": ["ContactId.Name", "ContactId.Title"]');
            promptParts.add('  },');
            promptParts.add('');
            promptParts.add('CRITICAL: "selectedParentFields" is REQUIRED - you MUST include it!');
            promptParts.add('- For ' + rootObject + ': ALWAYS include "OwnerId.Name" at minimum');
            promptParts.add('- For OpportunityContactRole: ALWAYS include "ContactId.Name" and "ContactId.Title"');
            promptParts.add('- Use the EXACT format from AVAILABLE PARENT TRAVERSALS section above');
            promptParts.add('- Parent fields enable personalization (names instead of "the owner")');
            promptParts.add('');
        }
        promptParts.add('  "reasoning": "Brief explanation of your field selection strategy"');
        promptParts.add('}');

        return String.join(promptParts, '\n');
    }

    /**
     * @description Parses Claude AI response into structured field selection data
     * ROBUST: Handles markdown, explanatory text, and extracts JSON object
     * @param aiContent Raw response from Claude
     * @return Map with selectedFields and reasoning
     */
    private Map<String, Object> parseFieldSelectionResponse(String aiContent) {
        try {
            String cleanJson = aiContent.trim();

            // Remove markdown code blocks if present
            if (cleanJson.startsWith('```json')) {
                cleanJson = cleanJson.substringAfter('```json').substringBefore('```').trim();
            } else if (cleanJson.startsWith('```')) {
                cleanJson = cleanJson.substringAfter('```').substringBefore('```').trim();
            }

            // ROBUST: If still not valid JSON, extract the JSON object
            if (!cleanJson.startsWith('{')) {
                Integer firstBrace = cleanJson.indexOf('{');
                Integer lastBrace = cleanJson.lastIndexOf('}');
                if (firstBrace >= 0 && lastBrace > firstBrace) {
                    cleanJson = cleanJson.substring(firstBrace, lastBrace + 1);
                }
            }

            // Parse JSON response
            Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);

            // Validate required fields
            if (!parsedData.containsKey('selectedFields')) {
                throw new StageException('Invalid AI response: missing selectedFields');
            }

            return parsedData;

        } catch (JSONException e) {
            throw new StageException('Failed to parse AI response as JSON: ' + e.getMessage());
        }
    }

    /**
     * @description Validates and enriches field selection to ensure minimum meaningful fields
     * CRITICAL: Ensures each object has enough non-ID fields for useful AI output
     * @param selectedFields Map of object name to selected field list
     * @param availableFieldsByObject Map of object name to all available fields
     * @param rootObject The root object name
     * @return Validated and potentially enriched field selection
     */
    private Map<String, List<String>> validateAndEnrichFieldSelection(
            Map<String, List<String>> selectedFields,
            Map<String, List<SchemaHelper.FieldMetadata>> availableFieldsByObject,
            String rootObject) {

        Map<String, List<String>> result = new Map<String, List<String>>();

        for (String objectName : selectedFields.keySet()) {
            List<String> fields = selectedFields.get(objectName);
            List<String> enrichedFields = new List<String>(fields);

            // Count meaningful (non-ID) fields
            // CRITICAL: "Id" and "*Id" fields are NOT meaningful for LLM context.
            // (They are useful for joins, but they don't provide business context.)
            Integer meaningfulCount = 0;
            for (String field : fields) {
                if (isMeaningfulField(field)) {
                    meaningfulCount++;
                }
            }

            // If not enough meaningful fields, try to add more from available fields
            if (meaningfulCount < MIN_MEANINGFUL_FIELDS && availableFieldsByObject.containsKey(objectName)) {
                List<SchemaHelper.FieldMetadata> availableFields = availableFieldsByObject.get(objectName);
                Set<String> currentFields = new Set<String>(enrichedFields);

                // Priority order for auto-adding fields
                List<String> priorityFields = getPriorityFieldsForObject(objectName);

                // First try priority fields
                for (String priorityField : priorityFields) {
                    if (meaningfulCount >= MIN_MEANINGFUL_FIELDS) break;
                    if (!currentFields.contains(priorityField)) {
                        // Check if field exists
                        for (SchemaHelper.FieldMetadata fm : availableFields) {
                            if (fm.name == priorityField) {
                                enrichedFields.add(priorityField);
                                currentFields.add(priorityField);
                                meaningfulCount++;
                                break;
                            }
                        }
                    }
                }

                // Then try any non-ID fields
                for (SchemaHelper.FieldMetadata fm : availableFields) {
                    if (meaningfulCount >= MIN_MEANINGFUL_FIELDS) break;
                    if (!currentFields.contains(fm.name) && isMeaningfulField(fm.name)) {
                        enrichedFields.add(fm.name);
                        currentFields.add(fm.name);
                        meaningfulCount++;
                    }
                }
            }

            // HARD GATE: Do not keep objects with only ID-like fields.
            // Mirrors the shell script intent: don't include objects that add no usable context.
            if (objectName != rootObject && meaningfulCount < MIN_MEANINGFUL_FIELDS) {
                // Skip this object entirely
                continue;
            }

            // Root object must have meaningful fields (otherwise the prompt is useless)
            if (objectName == rootObject && meaningfulCount < MIN_MEANINGFUL_FIELDS) {
                throw new StageException(
                    'Root object "' + rootObject + '" has insufficient meaningful fields (' +
                    meaningfulCount + '). Need at least ' + MIN_MEANINGFUL_FIELDS + '.'
                );
            }

            result.put(objectName, enrichedFields);
        }

        return result;
    }

    /**
     * @description Checks if a field name is an ID/reference field
     * @param fieldName The field name to check
     * @return true if the field is an ID field
     */
    private Boolean isIdField(String fieldName) {
        if (String.isBlank(fieldName)) return false;
        // Treat Id and all reference/id-like fields as ID fields
        if (fieldName == 'Id') return true;
        // Standard reference fields
        if (fieldName.endsWith('Id')) return true;
        // Common system reference IDs
        if (fieldName.endsWith('ById')) return true;
        return false;
    }

    /**
     * @description Returns true if a field provides meaningful business context.
     * We exclude Id-like fields because they do not help the LLM generate output.
     */
    private Boolean isMeaningfulField(String fieldName) {
        if (String.isBlank(fieldName)) return false;
        return !isIdField(fieldName);
    }

    /**
     * @description Gets priority fields for a given object type
     * @param objectName The object API name
     * @return List of priority field names
     */
    private List<String> getPriorityFieldsForObject(String objectName) {
        Map<String, List<String>> objectPriorityFields = new Map<String, List<String>>{
            'Opportunity' => new List<String>{'Name', 'Amount', 'StageName', 'CloseDate', 'Probability', 'Type', 'NextStep', 'Description', 'IsClosed', 'IsWon'},
            'OpportunityContactRole' => new List<String>{'Role', 'IsPrimary', 'ContactId'},
            'OpportunityLineItem' => new List<String>{'Name', 'Quantity', 'UnitPrice', 'TotalPrice', 'Description'},
            'Task' => new List<String>{'Subject', 'Status', 'Priority', 'ActivityDate', 'Description', 'Type'},
            'Event' => new List<String>{'Subject', 'StartDateTime', 'EndDateTime', 'Location', 'Description', 'Type'},
            'Case' => new List<String>{'Subject', 'Status', 'Priority', 'Type', 'Description', 'Origin'},
            'Contact' => new List<String>{'Name', 'Title', 'Email', 'Phone', 'Department'},
            'Account' => new List<String>{'Name', 'Industry', 'Type', 'AnnualRevenue', 'NumberOfEmployees', 'Website'},
            'Lead' => new List<String>{'Name', 'Company', 'Status', 'Industry', 'Rating', 'Email', 'Phone'},
            'EmailMessage' => new List<String>{'Subject', 'TextBody', 'FromAddress', 'ToAddress', 'MessageDate', 'Status'},
            'Note' => new List<String>{'Title', 'Body'},
            'ContentDocumentLink' => new List<String>{'LinkedEntityId', 'ContentDocumentId', 'ShareType', 'Visibility'}
        };

        return objectPriorityFields.containsKey(objectName)
            ? objectPriorityFields.get(objectName)
            : new List<String>{'Name', 'Subject', 'Status', 'Type', 'Description'};
    }

    /**
     * @description V2.2: Gets relevance hint for a field category
     * Helps the LLM understand which categories are most valuable for different use cases
     * @param category The field category (narrative, metric, classification, etc.)
     * @return Relevance hint string for the LLM
     */
    private static String getCategoryRelevanceHint(String category) {
        Map<String, String> categoryHints = new Map<String, String>{
            'narrative' => '(HIGH VALUE: Rich text for insights, summaries, context)',
            'metric' => '(HIGH VALUE: Numbers, currency, percentages for KPIs)',
            'classification' => '(HIGH VALUE: Picklists for segmentation, status, categories)',
            'temporal' => '(MEDIUM VALUE: Dates for timelines, aging, trends)',
            'contact' => '(MEDIUM VALUE: Email, phone for personalization)',
            'flag' => '(MEDIUM VALUE: Boolean flags for filtering, status)',
            'relationship' => '(LOW VALUE: IDs only - include sparingly for joins)',
            'other' => '(Misc fields - evaluate based on name/label)'
        };

        return categoryHints.containsKey(category)
            ? categoryHints.get(category)
            : '(Evaluate based on context)';
    }

    /**
     * @description V2.1: Loads traversal builder definitions for the given objects
     * Queries Builder prompts with Category__c = 'Traversal' that match the objects
     * @param objectNames List of object API names to find traversals for
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return Map of object name to list of traversal definitions
     */
    private Map<String, List<TraversalDefinition>> loadTraversalsForObjects(
            List<String> objectNames, Id runId, StageResult result) {

        Map<String, List<TraversalDefinition>> traversalsByObject = new Map<String, List<TraversalDefinition>>();

        try {
            // Get Builder RecordType ID
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
                .get('Builder').getRecordTypeId();

            // Query traversals for the objects we're analyzing
            Set<String> objectSet = new Set<String>(objectNames);
            List<ccai__AI_Prompt__c> traversals = [
                SELECT Id, Name, ccai__Prompt_Command__c, ccai__Object__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND Category__c = 'Traversal'
                  AND ccai__Status__c = 'Active'
                  AND ccai__Object__c IN :objectSet
                ORDER BY ccai__Object__c, Name
            ];

            result.queueDebug(runId, STAGE_NUMBER,
                'Loaded ' + traversals.size() + ' traversal builders for ' + objectNames.size() + ' objects');

            if (traversals.isEmpty()) {
                return traversalsByObject;
            }

            // Parse traversal JSON and group by source object
            for (ccai__AI_Prompt__c trav : traversals) {
                try {
                    String objectName = trav.ccai__Object__c;
                    TraversalDefinition def = parseTraversalJson(trav.ccai__Prompt_Command__c);

                    if (def != null) {
                        if (!traversalsByObject.containsKey(objectName)) {
                            traversalsByObject.put(objectName, new List<TraversalDefinition>());
                        }
                        traversalsByObject.get(objectName).add(def);
                    }
                } catch (Exception e) {
                    result.queueWarning(runId, STAGE_NUMBER,
                        'Failed to parse traversal ' + trav.Name + ': ' + e.getMessage());
                }
            }

            // Log summary
            Integer totalTraversals = 0;
            for (List<TraversalDefinition> defs : traversalsByObject.values()) {
                totalTraversals += defs.size();
            }
            result.queueInfo(runId, STAGE_NUMBER,
                'Parsed ' + totalTraversals + ' traversals for ' + traversalsByObject.size() + ' objects');

        } catch (Exception e) {
            result.queueError(runId, STAGE_NUMBER,
                'Failed to load traversals: ' + e.getMessage());
        }

        return traversalsByObject;
    }

    /**
     * @description V2.1: Parses traversal JSON into TraversalDefinition
     * @param jsonString The JSON string from ccai__Prompt_Command__c
     * @return Parsed TraversalDefinition or null if invalid
     */
    private TraversalDefinition parseTraversalJson(String jsonString) {
        if (String.isBlank(jsonString)) {
            return null;
        }

        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        TraversalDefinition def = new TraversalDefinition();
        def.sourceObject = (String) data.get('sourceObject');
        def.sourceField = (String) data.get('sourceField');
        def.targetObject = (String) data.get('targetObject');
        def.isPolymorphic = data.containsKey('polymorphic') && (Boolean) data.get('polymorphic');
        def.fields = new List<TraversalField>();

        List<Object> rawFields = (List<Object>) data.get('fields');
        if (rawFields != null) {
            for (Object rawField : rawFields) {
                Map<String, Object> fieldData = (Map<String, Object>) rawField;
                TraversalField tf = new TraversalField();
                tf.path = (String) fieldData.get('path');
                tf.alias = (String) fieldData.get('alias');
                def.fields.add(tf);
            }
        }

        return def;
    }

    /**
     * @description V2.2: Adds default parent fields when LLM doesn't return any
     * This ensures personalization works even if LLM doesn't follow instructions
     * @param selectedParentFields Output map to populate
     * @param traversalsByObject Available traversals by object
     * @param objectsWithData Objects that have data
     */
    private void addDefaultParentFields(
            Map<String, List<String>> selectedParentFields,
            Map<String, List<TraversalDefinition>> traversalsByObject,
            List<String> objectsWithData) {

        // Priority fields to add by source field
        Map<String, List<String>> priorityFields = new Map<String, List<String>>{
            'OwnerId' => new List<String>{'Name'},
            'AccountId' => new List<String>{'Name', 'Industry'},
            'ContactId' => new List<String>{'Name', 'Title', 'Email'}
        };

        for (String objectName : objectsWithData) {
            if (!traversalsByObject.containsKey(objectName)) {
                continue;
            }

            List<String> parentFields = new List<String>();

            for (TraversalDefinition trav : traversalsByObject.get(objectName)) {
                // Skip polymorphic fields (WhatId, WhoId) - too complex for auto-selection
                if (trav.isPolymorphic) {
                    continue;
                }

                // Check if this is a priority traversal
                if (priorityFields.containsKey(trav.sourceField)) {
                    List<String> fieldsToAdd = priorityFields.get(trav.sourceField);
                    for (String fieldPath : fieldsToAdd) {
                        // Check if traversal has this field
                        for (TraversalField tf : trav.fields) {
                            if (tf.path == fieldPath) {
                                parentFields.add(trav.sourceField + '.' + tf.path);
                                break;
                            }
                        }
                    }
                }
            }

            if (!parentFields.isEmpty()) {
                selectedParentFields.put(objectName, parentFields);
            }
        }
    }

    /**
     * @description Builds a human-readable summary of field selection
     * @param selectedFields Map of object to selected field list
     * @return Formatted summary string
     */
    private String buildSelectionSummary(Map<String, List<String>> selectedFields) {
        List<String> summaryParts = new List<String>();

        for (String objectName : selectedFields.keySet()) {
            List<String> fields = selectedFields.get(objectName);
            summaryParts.add(objectName + ' (' + fields.size() + ' fields)');
        }

        return String.join(summaryParts, ', ');
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}