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
     * @description V2.2: Inner class to hold parsed child chain traversal data
     */
    public class ChildChainDefinition {
        public String rootObject;
        public String description;
        public List<ChainStep> chain;
    }

    public class ChainStep {
        public String objectName;           // e.g., OpportunityContactRole
        public String relationshipName;     // e.g., OpportunityContactRoles
        public String relationshipField;    // e.g., OpportunityId
        public String via;                  // For lookup traversal (e.g., ContactId)
        public List<String> keyFields;      // Fields to include
    }
    
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

            result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for schema selection');

            // Call AI (HTTP callout - no DML before this!)
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, prompt, 2048, 0.5);

            if (!aiResponse.success) {
                throw new StageException('AI call failed: ' + aiResponse.errorMessage);
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

            // ===== V2.2: Load and apply child chain traversals =====
            // These define mandatory object chains (e.g., Opportunity → OCR → Contact)
            List<ChildChainDefinition> childChains = loadChildChains(rootObject, runId, result);

            if (!childChains.isEmpty()) {
                // Add child relationship objects from chains to selectedChildObjects
                // Only add TRUE children (relationshipField set), NOT lookup targets (via set)
                Set<String> selectedSet = new Set<String>(selectedChildObjects);
                for (ChildChainDefinition chain : childChains) {
                    for (ChainStep step : chain.chain) {
                        // Skip lookup traversals (via != null) - these are parent lookups, not children
                        // They should be handled by parent field traversal in Stage 5
                        if (String.isBlank(step.via) &&
                            !selectedSet.contains(step.objectName) &&
                            SchemaHelper.isObjectAccessible(step.objectName)) {
                            selectedChildObjects.add(step.objectName);
                            selectedSet.add(step.objectName);
                            result.queueInfo(runId, STAGE_NUMBER,
                                'Added ' + step.objectName + ' from child chain: ' + chain.description);
                        }
                    }
                }
            }

            // ===== STAGE 3.3/3.4: Grandchild Discovery (2-level deep) =====
            // Mirrors shell script behavior: discover children of selected children
            result.queueInfo(runId, STAGE_NUMBER, 'Starting grandchild discovery (2-level deep)');

            Map<String, List<SchemaHelper.ChildRelationship>> grandchildRelationships =
                SchemaHelper.discoverGrandchildRelationships(rootObject, selectedChildObjects);

            // V2.2 Phase 2G: Filter out system/infrastructure objects that never provide business value
            // These objects are Salesforce platform internals that clutter AI selection
            Set<String> excludedSystemObjects = new Set<String>{
                'FlowRecordRelation', 'FlowOrchestrationWorkItem', 'EntitySubscription',
                'ContentDocumentLink', 'ContentVersion', 'ContentDistribution',
                'FeedItem', 'FeedComment', 'TopicAssignment', 'UserDefinedLabelAssignment',
                'ProcessInstance', 'ProcessInstanceHistory', 'RecordAction',
                'Attachment', 'CombinedAttachment', 'NoteAndAttachment',
                'CollaborationGroupRecord', 'UserPrioritizedRecord'
            };

            // Build list of available grandchildren for AI selection (excluding system objects)
            List<Map<String, String>> availableGrandchildren = new List<Map<String, String>>();
            Integer skippedCount = 0;
            for (String parentChild : grandchildRelationships.keySet()) {
                for (SchemaHelper.ChildRelationship gc : grandchildRelationships.get(parentChild)) {
                    // Skip system objects that don't provide business context
                    if (excludedSystemObjects.contains(gc.childObject)) {
                        skippedCount++;
                        continue;
                    }
                    availableGrandchildren.add(new Map<String, String>{
                        'objectName' => gc.childObject,
                        'parentObject' => parentChild,
                        'relationshipName' => gc.relationshipName,
                        'relationshipField' => gc.field
                    });
                }
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Found ' + availableGrandchildren.size() + ' potential grandchild objects (filtered ' + skippedCount + ' system objects)');

            // Select grandchildren using AI if we have any candidates
            List<Map<String, String>> selectedGrandchildren = new List<Map<String, String>>();
            if (!availableGrandchildren.isEmpty()) {
                String grandchildPrompt = buildGrandchildSelectionPrompt(
                    rootObject, selectedChildObjects, availableGrandchildren,
                    businessContext, targetPersona
                );

                result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for grandchild selection');
                AIServiceClient.AIResponse gcResponse = AIServiceClient.callAI(null, grandchildPrompt, 2048, 0.5);

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

            // V2.2: Pass child chains for DCMBuilder to add traversal fields
            if (!childChains.isEmpty()) {
                result.outputs.put('childChains', JSON.serialize(childChains));
                result.queueInfo(runId, STAGE_NUMBER,
                    'Passing ' + childChains.size() + ' child chains to downstream stages');
            }

            // Pass through inputs (avoid large data to prevent serialization issues)
            result.outputs.put('rootObject', rootObject);
            result.outputs.put('businessContext', businessContext);
            result.outputs.put('targetPersona', targetPersona);
            result.outputs.put('businessObjectives', inputs.get('businessObjectives'));
            result.outputs.put('promptName', inputs.get('promptName'));
            result.outputs.put('sampleRecordId', inputs.get('sampleRecordId'));
            result.outputs.put('outputFormat', inputs.get('outputFormat'));
            // Pass through enriched context from Stage 2 for downstream stages
            result.outputs.put('companyIntelligence', inputs.get('companyIntelligence'));
            result.outputs.put('industryContext', inputs.get('industryContext'));
            result.outputs.put('companyProfile', inputs.get('companyProfile'));
            result.outputs.put('strategicInsights', inputs.get('strategicInsights'));
            result.outputs.put('companyWebsite', inputs.get('companyWebsite'));
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
               getKeyObjectGuidance(rootObject) +
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
               'SELECTION CRITERIA:\n' +
               '1. Select 0-' + TARGET_GRANDCHILD_COUNT + ' grandchild objects that provide BUSINESS context\n' +
               '2. PRIORITIZE objects that contain:\n' +
               '   - People/stakeholder data (roles, contacts, participants)\n' +
               '   - Product/line item data (what is being sold/serviced)\n' +
               '   - Activity details (meeting attendees, task assignees)\n' +
               '   - Transaction details (order items, invoice lines)\n' +
               '3. AVOID selecting:\n' +
               '   - Objects ending in "Relation" unless they contain business roles (e.g., EventRelation for attendees is OK)\n' +
               '   - Objects that only track system behavior\n\n' +
               'EXAMPLES of valuable grandchildren:\n' +
               '- Opportunity -> OpportunityContactRole (stakeholders in deals)\n' +
               '- Opportunity -> OpportunityLineItem (products in deals)\n' +
               '- Case -> CaseComment (customer interactions)\n' +
               '- Event -> EventRelation (meeting attendees)\n' +
               '- Order -> OrderItem (order line items)\n\n' +
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
     * @description V2.2: Loads child chain traversals for the root object
     * These define which child objects and their lookups to include
     * @param rootObject The root object API name
     * @param runId Run ID for logging
     * @param result StageResult for deferred logging
     * @return List of ChildChainDefinition objects
     */
    private List<ChildChainDefinition> loadChildChains(String rootObject, Id runId, StageResult result) {
        List<ChildChainDefinition> chains = new List<ChildChainDefinition>();

        try {
            // Get Builder RecordType ID
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
                .get('Builder').getRecordTypeId();

            // Query child chain traversals for this root object
            List<ccai__AI_Prompt__c> traversals = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND Category__c = 'Traversal'
                  AND ccai__Status__c = 'Active'
                  AND ccai__Object__c = :rootObject
                ORDER BY Name
            ];

            result.queueDebug(runId, STAGE_NUMBER,
                'Found ' + traversals.size() + ' traversals for ' + rootObject);

            for (ccai__AI_Prompt__c trav : traversals) {
                try {
                    ChildChainDefinition chain = parseChildChainJson(trav.ccai__Prompt_Command__c);
                    if (chain != null && chain.chain != null && !chain.chain.isEmpty()) {
                        chains.add(chain);
                        result.queueDebug(runId, STAGE_NUMBER,
                            'Loaded child chain: ' + trav.Name + ' with ' + chain.chain.size() + ' steps');
                    }
                } catch (Exception e) {
                    result.queueWarning(runId, STAGE_NUMBER,
                        'Failed to parse traversal ' + trav.Name + ': ' + e.getMessage());
                }
            }

        } catch (Exception e) {
            result.queueWarning(runId, STAGE_NUMBER,
                'Failed to load child chains: ' + e.getMessage());
        }

        return chains;
    }

    /**
     * @description V2.2: Parses child chain JSON into ChildChainDefinition
     * @param jsonString The JSON string from ccai__Prompt_Command__c
     * @return Parsed ChildChainDefinition or null if not a childChain type
     */
    private ChildChainDefinition parseChildChainJson(String jsonString) {
        if (String.isBlank(jsonString)) {
            return null;
        }

        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        // Only process childChain type traversals
        String traversalType = (String) data.get('traversalType');
        if (traversalType != 'childChain') {
            return null;
        }

        ChildChainDefinition def = new ChildChainDefinition();
        def.rootObject = (String) data.get('rootObject');
        def.description = (String) data.get('description');
        def.chain = new List<ChainStep>();

        List<Object> chainList = (List<Object>) data.get('chain');
        if (chainList != null) {
            for (Object stepObj : chainList) {
                Map<String, Object> stepData = (Map<String, Object>) stepObj;
                ChainStep step = new ChainStep();
                step.objectName = (String) stepData.get('object');
                step.relationshipName = (String) stepData.get('relationshipName');
                step.relationshipField = (String) stepData.get('relationshipField');
                step.via = (String) stepData.get('via');

                // Parse keyFields
                List<Object> keyFieldsRaw = (List<Object>) stepData.get('keyFields');
                if (keyFieldsRaw != null) {
                    step.keyFields = new List<String>();
                    for (Object kf : keyFieldsRaw) {
                        step.keyFields.add(String.valueOf(kf));
                    }
                }

                def.chain.add(step);
            }
        }

        return def;
    }

    /**
     * @description Provides object-specific guidance for key child objects
     * Ensures critical junction and activity objects are prioritized in selection
     * @param rootObject The root object API name
     * @return Guidance string to include in the prompt
     */
    private String getKeyObjectGuidance(String rootObject) {
        Map<String, String> guidanceByRoot = new Map<String, String>{
            'Opportunity' =>
                'CRITICAL OBJECTS FOR OPPORTUNITY:\n' +
                '- OpportunityContactRole: MUST INCLUDE - shows stakeholders, decision makers, roles in deal\n' +
                '- OpportunityLineItem: Include if products/pricing matter\n' +
                '- Task: Include for activity history and follow-ups\n' +
                '- Event: Include for meeting history\n' +
                '- Note: Include for deal notes and context\n\n',
            'Account' =>
                'CRITICAL OBJECTS FOR ACCOUNT:\n' +
                '- Contact: MUST INCLUDE - primary contacts and stakeholders\n' +
                '- Opportunity: Include for pipeline and revenue context\n' +
                '- Case: Include for support and satisfaction insights\n' +
                '- Task: Include for activity history\n' +
                '- Contract: Include for contract/subscription context\n\n',
            'Contact' =>
                'CRITICAL OBJECTS FOR CONTACT:\n' +
                '- OpportunityContactRole: Include to show opportunities contact is involved in\n' +
                '- Task: Include for activity history\n' +
                '- Case: Include if contact submits cases\n\n',
            'Case' =>
                'CRITICAL OBJECTS FOR CASE:\n' +
                '- CaseComment: MUST INCLUDE - shows conversation history\n' +
                '- EmailMessage: Include for email thread context\n' +
                '- Task: Include for follow-up activities\n\n',
            'Lead' =>
                'CRITICAL OBJECTS FOR LEAD:\n' +
                '- Task: Include for activity and follow-up history\n' +
                '- CampaignMember: Include for marketing campaign context\n\n'
        };

        return guidanceByRoot.containsKey(rootObject)
            ? guidanceByRoot.get(rootObject)
            : '';
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}