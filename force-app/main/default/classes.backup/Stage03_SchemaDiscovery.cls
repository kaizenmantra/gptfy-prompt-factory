/**
 * @description Stage 3: Schema Discovery
 * Uses SchemaHelper to get child relationships and calls Claude AI to select relevant objects.
 * Now supports 2-level deep discovery (children + grandchildren) matching shell script behavior.
 */
public with sharing class Stage03_SchemaDiscovery implements IStage {

    private static final Integer STAGE_NUMBER = 3;
    private static final Integer TARGET_CHILD_COUNT = 10;
    private static final Integer TARGET_GRANDCHILD_COUNT = 5;
    
    /**
     * @description Executes Stage 3: Schema Discovery
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing rootObject, businessContext, and profiling results
     * @return StageResult with selected objects list in outputs
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 3: Schema Discovery');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            // Use deferred logging (no DML) - logs will be inserted AFTER callout completes
            result.queueInfo(runId, STAGE_NUMBER, 'Starting schema discovery');

            // Extract inputs
            String rootObject = (String) inputs.get('rootObject');
            String businessContext = (String) inputs.get('businessContext');
            String targetPersona = (String) inputs.get('targetPersona');

            if (String.isBlank(rootObject)) {
                throw new StageException('Root object is required for schema discovery');
            }

            // Get child relationships using SchemaHelper
            List<SchemaHelper.ChildRelationship> childRelationships =
                SchemaHelper.getChildRelationships(rootObject);

            result.queueInfo(runId, STAGE_NUMBER,
                'Found ' + childRelationships.size() + ' child relationships for ' + rootObject);

            // Build list of available child objects
            List<String> availableObjects = new List<String>{ rootObject };
            for (SchemaHelper.ChildRelationship rel : childRelationships) {
                if (SchemaHelper.isObjectAccessible(rel.childObject)) {
                    availableObjects.add(rel.childObject);
                }
            }

            result.queueDebug(runId, STAGE_NUMBER,
                'Available objects: ' + String.join(availableObjects, ', '));

            // Call Claude AI to select relevant objects
            String prompt = buildSchemaSelectionPrompt(
                rootObject,
                availableObjects,
                businessContext,
                targetPersona
            );

            result.queueDebug(runId, STAGE_NUMBER, 'Calling Claude AI for schema selection');

            // Call Claude AI (HTTP callout - no DML before this!)
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callClaude(prompt, 2048, 0.5);

            if (!aiResponse.success) {
                throw new StageException('Claude AI call failed: ' + aiResponse.errorMessage);
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Claude AI response received (Tokens: ' + aiResponse.inputTokens + '/' + aiResponse.outputTokens + ')');

            // Parse AI response
            Map<String, Object> selectionResult = parseSchemaSelectionResponse(
                aiResponse.content,
                availableObjects
            );

            List<String> selectedChildObjects = (List<String>) selectionResult.get('selectedObjects');

            result.queueInfo(runId, STAGE_NUMBER,
                'Selected ' + selectedChildObjects.size() + ' child objects');

            // ===== STAGE 3.3/3.4: Grandchild Discovery (2-level deep) =====
            // Mirrors shell script behavior: discover children of selected children
            result.queueInfo(runId, STAGE_NUMBER, 'Starting grandchild discovery (2-level deep)');

            Map<String, List<SchemaHelper.ChildRelationship>> grandchildRelationships =
                SchemaHelper.discoverGrandchildRelationships(rootObject, selectedChildObjects);

            // Build list of available grandchildren for AI selection
            List<Map<String, String>> availableGrandchildren = new List<Map<String, String>>();
            for (String parentChild : grandchildRelationships.keySet()) {
                for (SchemaHelper.ChildRelationship gc : grandchildRelationships.get(parentChild)) {
                    availableGrandchildren.add(new Map<String, String>{
                        'objectName' => gc.childObject,
                        'parentObject' => parentChild,
                        'relationshipName' => gc.relationshipName,
                        'relationshipField' => gc.field
                    });
                }
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Found ' + availableGrandchildren.size() + ' potential grandchild objects');

            // Select grandchildren using AI if we have any candidates
            List<Map<String, String>> selectedGrandchildren = new List<Map<String, String>>();
            if (!availableGrandchildren.isEmpty()) {
                String grandchildPrompt = buildGrandchildSelectionPrompt(
                    rootObject, selectedChildObjects, availableGrandchildren,
                    businessContext, targetPersona
                );

                result.queueDebug(runId, STAGE_NUMBER, 'Calling Claude AI for grandchild selection');
                AIServiceClient.AIResponse gcResponse = AIServiceClient.callClaude(grandchildPrompt, 2048, 0.5);

                if (gcResponse.success) {
                    selectedGrandchildren = parseGrandchildSelectionResponse(
                        gcResponse.content, availableGrandchildren);
                    result.queueInfo(runId, STAGE_NUMBER,
                        'Selected ' + selectedGrandchildren.size() + ' grandchild objects');
                } else {
                    result.queueWarning(runId, STAGE_NUMBER,
                        'Grandchild selection failed: ' + gcResponse.errorMessage);
                }
            }

            // Build combined list of all selected objects
            List<String> allSelectedObjects = new List<String>(selectedChildObjects);
            for (Map<String, String> gc : selectedGrandchildren) {
                allSelectedObjects.add(gc.get('objectName'));
            }

            // Build outputs
            result.outputs.put('selectedObjects', allSelectedObjects);
            result.outputs.put('selectedChildObjects', selectedChildObjects);
            result.outputs.put('selectedGrandchildren', selectedGrandchildren);
            result.outputs.put('allAvailableObjects', availableObjects);
            result.outputs.put('childRelationships', serializeRelationships(childRelationships));
            result.outputs.put('grandchildRelationships', JSON.serialize(availableGrandchildren));
            result.outputs.put('selectionJson', aiResponse.content);
            result.aiReasoning = (String) selectionResult.get('reasoning');

            // Pass through inputs (avoid large data to prevent serialization issues)
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('targetPersona', targetPersona);
            result.outputs.put('businessObjectives', inputs.get('businessObjectives'));
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            result.outputs.put('outputFormat', inputs.get('outputFormat'));
            // recordData omitted - causes stack overflow during serialization

            result.markCompleted();
            result.queueInfo(runId, STAGE_NUMBER,
                'Schema discovery completed. Selected ' + selectedChildObjects.size() +
                ' children + ' + selectedGrandchildren.size() + ' grandchildren');

        } catch (Exception e) {
            String errorMsg = 'Failed to complete schema discovery: ' + e.getMessage();
            result.markFailed(errorMsg);
            result.queueError(runId, STAGE_NUMBER, 'Stage execution failed: ' + e.getMessage());
        }

        return result;
    }
    
    /**
     * @description Builds the prompt for Claude AI to select relevant objects
     * @param rootObject Primary object
     * @param availableObjects List of all available related objects
     * @param businessContext Business requirements
     * @param targetPersona Target user persona
     * @return Formatted prompt string
     */
    private String buildSchemaSelectionPrompt(String rootObject, List<String> availableObjects, 
                                              String businessContext, String targetPersona) {
        return 'You are a Salesforce data architect selecting relevant objects for an AI prompt.\n\n' +
               'ROOT OBJECT: ' + rootObject + '\n' +
               'TARGET PERSONA: ' + targetPersona + '\n' +
               'BUSINESS CONTEXT:\n' + businessContext + '\n\n' +
               'AVAILABLE OBJECTS:\n' + String.join(availableObjects, '\n') + '\n\n' +
               'Select 8-10 most relevant objects that should be included in the AI prompt context.\n' +
               'Consider:\n' +
               '1. Direct relevance to business objectives\n' +
               '2. Data likely needed by target persona\n' +
               '3. Parent-child relationships that provide context\n' +
               '4. Objects that enable the desired insights\n\n' +
               'ALWAYS include the root object: ' + rootObject + '\n\n' +
               'Return ONLY valid JSON in this exact format:\n' +
               '{\n' +
               '  "selectedObjects": ["Object1__c", "Object2__c", ...],\n' +
               '  "reasoning": "Brief explanation of why these objects were selected"\n' +
               '}';
    }
    
    /**
     * @description Parses Claude AI response and validates selected objects
     * ROBUST: Handles markdown, explanatory text, and extracts JSON object
     * @param aiContent Raw response from Claude
     * @param availableObjects List of valid objects to validate against
     * @return Map with selectedObjects and reasoning
     */
    private Map<String, Object> parseSchemaSelectionResponse(String aiContent,
                                                              List<String> availableObjects) {
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

            if (!parsedData.containsKey('selectedObjects')) {
                throw new StageException('Invalid AI response: missing selectedObjects');
            }

            // Validate and filter selected objects
            List<Object> rawObjects = (List<Object>) parsedData.get('selectedObjects');
            List<String> validatedObjects = new List<String>();
            Set<String> availableSet = new Set<String>(availableObjects);

            for (Object obj : rawObjects) {
                String objectName = String.valueOf(obj);
                if (availableSet.contains(objectName)) {
                    validatedObjects.add(objectName);
                }
            }

            if (validatedObjects.isEmpty()) {
                throw new StageException('No valid objects selected by AI');
            }

            parsedData.put('selectedObjects', validatedObjects);
            return parsedData;

        } catch (JSONException e) {
            throw new StageException('Failed to parse AI response as JSON: ' + e.getMessage());
        }
    }
    
    /**
     * @description Serializes child relationships for output
     * @param relationships List of ChildRelationship objects
     * @return JSON string representation
     */
    private String serializeRelationships(List<SchemaHelper.ChildRelationship> relationships) {
        List<Map<String, String>> serialized = new List<Map<String, String>>();
        for (SchemaHelper.ChildRelationship rel : relationships) {
            serialized.add(new Map<String, String>{
                'childObject' => rel.childObject,
                'relationshipName' => rel.relationshipName,
                'field' => rel.field
            });
        }
        return JSON.serialize(serialized);
    }
    
    /**
     * @description Builds the prompt for Claude AI to select relevant grandchild objects
     * @param rootObject Primary object (e.g., Account)
     * @param selectedChildren Already selected child objects
     * @param availableGrandchildren List of available grandchild objects with metadata
     * @param businessContext Business requirements
     * @param targetPersona Target user persona
     * @return Formatted prompt string
     */
    private String buildGrandchildSelectionPrompt(String rootObject, List<String> selectedChildren,
            List<Map<String, String>> availableGrandchildren, String businessContext, String targetPersona) {

        List<String> grandchildList = new List<String>();
        for (Map<String, String> gc : availableGrandchildren) {
            grandchildList.add(gc.get('parentObject') + ' -> ' + gc.get('objectName') +
                ' (via ' + gc.get('relationshipField') + ')');
        }

        return 'You are a Salesforce data architect selecting grandchild objects for an AI prompt.\n\n' +
               'ROOT OBJECT: ' + rootObject + '\n' +
               'SELECTED CHILD OBJECTS: ' + String.join(selectedChildren, ', ') + '\n' +
               'TARGET PERSONA: ' + targetPersona + '\n' +
               'BUSINESS CONTEXT:\n' + businessContext + '\n\n' +
               'AVAILABLE GRANDCHILD OBJECTS (Parent -> Child):\n' + String.join(grandchildList, '\n') + '\n\n' +
               'Select 0-' + TARGET_GRANDCHILD_COUNT + ' grandchild objects that would provide valuable additional context.\n' +
               'Only select objects that are HIGHLY relevant to the business context.\n' +
               'Common valuable grandchildren:\n' +
               '- Opportunity -> OpportunityContactRole (who is involved in deals)\n' +
               '- Opportunity -> OpportunityLineItem (products in deals)\n' +
               '- Case -> CaseComment (customer interactions)\n\n' +
               'Return ONLY valid JSON in this exact format:\n' +
               '{\n' +
               '  "selectedGrandchildren": [\n' +
               '    {"objectName": "OpportunityContactRole", "parentObject": "Opportunity"},\n' +
               '    ...\n' +
               '  ],\n' +
               '  "reasoning": "Brief explanation"\n' +
               '}';
    }

    /**
     * @description Parses Claude AI response for grandchild selection
     * ROBUST: Handles markdown, explanatory text, and extracts JSON object
     * @param aiContent Raw response from Claude
     * @param availableGrandchildren List of valid grandchild options
     * @return List of selected grandchild maps with full metadata
     */
    private List<Map<String, String>> parseGrandchildSelectionResponse(String aiContent,
            List<Map<String, String>> availableGrandchildren) {

        List<Map<String, String>> result = new List<Map<String, String>>();

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

            Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);

            if (!parsedData.containsKey('selectedGrandchildren')) {
                return result;
            }

            List<Object> selectedList = (List<Object>) parsedData.get('selectedGrandchildren');

            // Build lookup map for validation
            Map<String, Map<String, String>> gcLookup = new Map<String, Map<String, String>>();
            for (Map<String, String> gc : availableGrandchildren) {
                String key = gc.get('parentObject') + '|' + gc.get('objectName');
                gcLookup.put(key, gc);
            }

            // Validate and build result
            for (Object selObj : selectedList) {
                Map<String, Object> sel = (Map<String, Object>) selObj;
                String objName = (String) sel.get('objectName');
                String parentObj = (String) sel.get('parentObject');
                String key = parentObj + '|' + objName;

                if (gcLookup.containsKey(key)) {
                    result.add(gcLookup.get(key));
                }
            }

        } catch (Exception e) {
            // Return empty list on parse error
        }

        return result;
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}