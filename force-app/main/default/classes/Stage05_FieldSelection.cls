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
            // PHASE 2F FIX: Removed manual pass-throughs.
            // Result only contains data generated by this stage.
            // Downstream stages use Accumulation Logic to retrieve context.
            
            result.outputs.put('selectedFields', selectedFields);
            result.outputs.put('totalFieldsSelected', totalFieldsSelected);
            result.outputs.put('selectionSummary', selectionSummary);
            result.outputs.put('objectsWithData', objectsWithData);

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
            promptParts.add('PARENT FIELD SELECTION GUIDANCE:');
            promptParts.add('- Use Owner.Name to personalize "assigned to Sarah Johnson" instead of "the owner"');
            promptParts.add('- Use Contact.Name for stakeholder names in OpportunityContactRole');
            promptParts.add('- Use Account.Industry for business context');
            promptParts.add('- Include 1-3 key parent fields per object for personalization');
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
        // V2.1: Add parent field selection format if traversals are available
        if (traversalsByObject != null && !traversalsByObject.isEmpty()) {
            promptParts.add('  "selectedParentFields": {');
            promptParts.add('    "' + rootObject + '": ["OwnerId.Name", "OwnerId.Email"],');
            promptParts.add('    "OpportunityContactRole": ["ContactId.Name", "ContactId.Title"]');
            promptParts.add('  },');
        }
        promptParts.add('  "reasoning": "Brief explanation of your field selection strategy"');
        promptParts.add('}');

        return String.join(promptParts, '\n');
    }

    // Helper to get helper text for categories
    private String getCategoryRelevanceHint(String category) {
        if (category == 'narrative') return 'Rich context for AI analysis (High Priority)';
        if (category == 'metric') return 'Quantitative data for KPIs (High Priority)';
        if (category == 'classification') return 'Status/Type for segmentation';
        if (category == 'temporal') return 'Dates for trend analysis';
        if (category == 'contact') return 'Personal details for outreach';
        if (category == 'flag') return 'Boolean indicators';
        if (category == 'relationship') return 'Link to other objects';
        return 'General fields';
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
            Integer meaningfulFieldCount = 0;
            Set<String> fieldSet = new Set<String>(fields);

            for (String field : fields) {
                if (!field.endsWith('Id') && field != 'Id') {
                    meaningfulFieldCount++;
                }
            }

            // Enrichment Logic: If we don't have enough meaningful fields, add some!
            if (meaningfulFieldCount < MIN_MEANINGFUL_FIELDS) {
                // Find candidates to add
                List<SchemaHelper.FieldMetadata> available = availableFieldsByObject.get(objectName);
                if (available != null) {
                    Integer addedCount = 0;
                    Integer needed = MIN_MEANINGFUL_FIELDS - meaningfulFieldCount;

                    for (SchemaHelper.FieldMetadata candidate : available) {
                        if (addedCount >= needed) break;

                        // Add meaningful fields that aren't already selected
                        if (!fieldSet.contains(candidate.name) &&
                            !candidate.name.endsWith('Id') &&
                            candidate.name != 'Id' &&
                            // Prefer strings, picklists, dates
                            (candidate.type == 'STRING' || candidate.type == 'PICKLIST' ||
                             candidate.type == 'TEXTAREA' || candidate.type == 'DATE' ||
                             candidate.type == 'DATETIME' || candidate.type == 'DOUBLE' ||
                             candidate.type == 'CURRENCY')) {

                            enrichedFields.add(candidate.name);
                            fieldSet.add(candidate.name);
                            addedCount++;
                        }
                    }
                }
            }

            result.put(objectName, enrichedFields);
        }

        return result;
    }

    /**
     * @description Builds a human-readable summary of selected fields
     * @param selectedFields Map of selected fields
     * @return Formatted summary string
     */
    private String buildSelectionSummary(Map<String, List<String>> selectedFields) {
        Map<String, Integer> counts = new Map<String, Integer>();
        for (String obj : selectedFields.keySet()) {
            counts.put(obj, selectedFields.get(obj).size());
        }
        return JSON.serialize(counts);
    }

    /**
     * @description Loads available parent traversals for objects (V2.1)
     * Queries PromptBuilder_Traversal__mdt or similar config (mocked here for now)
     * @param objectNames List of objects to find traversals for
     * @param runId Run ID
     * @param result Stage result
     * @return Map of object name to traversal definitions
     */
    private Map<String, List<TraversalDefinition>> loadTraversalsForObjects(
            List<String> objectNames, Id runId, StageResult result) {
        
        // V2.1: This would normally query metadata or use SchemaHelper
        // For now, we return a simple mocked structure based on standard relationships
        // This is sufficient for the MVP of V2.1
        
        Map<String, List<TraversalDefinition>> traversals = new Map<String, List<TraversalDefinition>>();
        
        for (String obj : objectNames) {
            List<TraversalDefinition> objTraversals = new List<TraversalDefinition>();
            
            // Standard traversals for common objects
            if (obj == 'Account' || obj == 'Opportunity' || obj == 'Contact' || obj == 'Case') {
                // Owner Traversal
                TraversalDefinition ownerTrav = new TraversalDefinition();
                ownerTrav.sourceObject = obj;
                ownerTrav.sourceField = 'OwnerId';
                ownerTrav.targetObject = 'User';
                ownerTrav.isPolymorphic = true;
                ownerTrav.fields = new List<TraversalField>();
                
                TraversalField nameField = new TraversalField();
                nameField.path = 'Name';
                nameField.alias = 'OwnerName';
                ownerTrav.fields.add(nameField);
                
                TraversalField emailField = new TraversalField();
                emailField.path = 'Email';
                emailField.alias = 'OwnerEmail';
                ownerTrav.fields.add(emailField);
                
                objTraversals.add(ownerTrav);
            }
            
            if (obj == 'Contact' || obj == 'Opportunity' || obj == 'Case') {
                // Account Traversal
                TraversalDefinition accTrav = new TraversalDefinition();
                accTrav.sourceObject = obj;
                accTrav.sourceField = 'AccountId';
                accTrav.targetObject = 'Account';
                accTrav.isPolymorphic = false;
                accTrav.fields = new List<TraversalField>();
                
                TraversalField nameField = new TraversalField();
                nameField.path = 'Name';
                nameField.alias = 'AccountName';
                accTrav.fields.add(nameField);
                
                TraversalField indField = new TraversalField();
                indField.path = 'Industry';
                indField.alias = 'AccountIndustry';
                accTrav.fields.add(indField);
                
                objTraversals.add(accTrav);
            }
            
            if (obj == 'OpportunityContactRole') {
                // Contact Traversal
                TraversalDefinition conTrav = new TraversalDefinition();
                conTrav.sourceObject = obj;
                conTrav.sourceField = 'ContactId';
                conTrav.targetObject = 'Contact';
                conTrav.isPolymorphic = false;
                conTrav.fields = new List<TraversalField>();
                
                TraversalField nameField = new TraversalField();
                nameField.path = 'Name';
                nameField.alias = 'ContactName';
                conTrav.fields.add(nameField);
                
                TraversalField titleField = new TraversalField();
                titleField.path = 'Title';
                titleField.alias = 'ContactTitle';
                conTrav.fields.add(titleField);
                
                objTraversals.add(conTrav);
            }
            
            if (!objTraversals.isEmpty()) {
                traversals.put(obj, objTraversals);
            }
        }
        
        return traversals;
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}