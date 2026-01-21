/**
 * @description Stage 5: Field Selection
 * Gets fields for each object from Stage 4 and uses Claude AI to select 10-15 most relevant fields per object
 *
 * CRITICAL: This stage now uses LLM-based field selection (mirroring the shell script approach)
 * instead of hardcoded candidate fields. The LLM selects fields based on:
 * - Business context and target persona
 * - Object relevance and data availability
 * - Field information value for AI-generated output
 */
public with sharing class Stage05_FieldSelection implements IStage {

    private static final Integer STAGE_NUMBER = 5;
    private static final Integer MIN_FIELDS_PER_OBJECT = 5;  // Reduced to be more realistic
    private static final Integer MAX_FIELDS_PER_OBJECT = 20;
    private static final Integer MIN_MEANINGFUL_FIELDS = 3;   // Minimum non-ID fields required

    // Feature flag: Use LLM-based field selection (matches shell script behavior)
    private static final Boolean USE_LLM_SELECTION = true;

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
            List<String> validationWarnings = new List<String>();

            if (USE_LLM_SELECTION) {
                // LLM-BASED FIELD SELECTION (mirrors shell script Stage 5)
                // This is context-aware and profile-driven
                result.queueInfo(runId, STAGE_NUMBER,
                    'Using LLM-based field selection (shell script parity)');

                // Step 1: Get all available fields for each object from schema
                Map<String, List<SchemaHelper.FieldMetadata>> fieldsByObject =
                    getFieldsForObjectsDeferred(objectsWithData, runId, result);

                // Step 2: Use Claude to select relevant fields based on context
                selectedFields = selectFieldsWithAIDeferred(
                    fieldsByObject, rootObject, businessContext, targetPersona, runId, result);

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
            // Don't pass dataAvailability - it can be large and causes stack overflow
            // Downstream stages can re-query if needed

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
     * @param rootObject The root Salesforce object
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return Map of object name to selected field list
     */
    private Map<String, List<String>> selectFieldsWithAIDeferred(
            Map<String, List<SchemaHelper.FieldMetadata>> fieldsByObject,
            String rootObject,
            String businessContext,
            String targetPersona,
            Id runId,
            StageResult result) {

        // Build prompt for field selection
        String prompt = buildFieldSelectionPrompt(fieldsByObject, rootObject,
                                                  businessContext, targetPersona);

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

        return selectedFields;
    }

    /**
     * @description Builds the prompt for Claude AI to select relevant fields
     * Uses List<String> and String.join() to avoid stack overflow from string concatenation
     * CRITICAL: Emphasizes selecting meaningful data fields, not just ID fields
     * @param fieldsByObject Map of object to available fields
     * @param rootObject The root Salesforce object
     * @param businessContext User-provided business requirements
     * @param targetPersona Target user persona
     * @return Formatted prompt string
     */
    private String buildFieldSelectionPrompt(
            Map<String, List<SchemaHelper.FieldMetadata>> fieldsByObject,
            String rootObject,
            String businessContext,
            String targetPersona) {

        // Use List<String> to avoid stack overflow from repeated string concatenation
        List<String> promptParts = new List<String>();

        promptParts.add('You are an expert Salesforce data architect specializing in field selection for AI prompts.');
        promptParts.add('');
        promptParts.add('BUSINESS CONTEXT:');
        promptParts.add(businessContext);
        promptParts.add('');
        promptParts.add('TARGET PERSONA: ' + targetPersona);
        promptParts.add('ROOT OBJECT: ' + rootObject);
        promptParts.add('');
        promptParts.add('AVAILABLE FIELDS BY OBJECT:');

        Integer maxFieldsPerObjectInPrompt = 30;
        for (String objectName : fieldsByObject.keySet()) {
            promptParts.add('');
            promptParts.add('Object: ' + objectName);
            List<SchemaHelper.FieldMetadata> fields = fieldsByObject.get(objectName);

            Integer fieldCount = 0;
            for (SchemaHelper.FieldMetadata field : fields) {
                if (fieldCount >= maxFieldsPerObjectInPrompt) {
                    promptParts.add('- ... and ' + (fields.size() - maxFieldsPerObjectInPrompt) + ' more fields');
                    break;
                }
                promptParts.add('- ' + field.name + ' (' + field.label + ') [' + field.type + ']');
                fieldCount++;
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
        promptParts.add('FIELD SELECTION PRIORITIES:');
        promptParts.add('1. Name fields (Name, FirstName, LastName, Subject, Title) - HIGH PRIORITY');
        promptParts.add('2. Status/Stage fields (Status, StageName, Priority) - HIGH PRIORITY');
        promptParts.add('3. Amount/Currency fields (Amount, TotalPrice, AnnualRevenue) - HIGH PRIORITY');
        promptParts.add('4. Date fields (CloseDate, CreatedDate, ActivityDate) - MEDIUM PRIORITY');
        promptParts.add('5. Description/Text fields (Description, Comments, Body) - MEDIUM PRIORITY');
        promptParts.add('6. Boolean flags (IsPrimary, IsClosed, IsWon) - MEDIUM PRIORITY');
        promptParts.add('7. Lookup ID fields (AccountId, OwnerId) - LOW PRIORITY (include 1-2 key ones)');
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