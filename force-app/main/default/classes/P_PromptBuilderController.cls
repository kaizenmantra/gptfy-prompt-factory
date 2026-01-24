/**
 * @description Controller for AI-powered Prompt Builder component
 * @author Piyush Chourasia
 * @group Plumcloud Labs
 * @last modified on 11-13-2024
 * @last modified by AI Assistant
 */
public with sharing class P_PromptBuilderController {
    
    /**
     * Generates prompt details using OpenAI based on user input
     * @param userInput User's description of the prompt they want to create
     * @param existingPromptsJson JSON string containing existing prompts for reference
     * @return JSON string with generated prompt details
     */
    @AuraEnabled
    public static String generatePromptDetails(String userInput, String existingPromptsJson) {
        try {
            if (String.isBlank(userInput)) {
                throw new AuraHandledException('User input cannot be empty');
            }
            
            ccai__AI_Connection__c connection = getGPTfyConnection();
            String systemPrompt = buildSystemPrompt();
            String userPrompt = buildUserPrompt(userInput, existingPromptsJson);
            
            Integer maxOutputToken = connection.Max_Tokens__c != null ? Integer.valueOf(connection.Max_Tokens__c) : 3000;
            Decimal temperature = 0.7;
            Decimal topP = connection.Top_P__c != null ? connection.Top_P__c : 1.0;
            
            HttpResponse response = callResponsesAPI(
                systemPrompt,
                userPrompt,
                connection,
                maxOutputToken,
                temperature,
                topP
            );
            
            if (response != null && response.getStatusCode() == 200) {
                String responseBody = response.getBody();
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                
                String content = null;
                
                try {
                    if (responseMap.containsKey('output')) {
                        Object outputObj = responseMap.get('output');
                        content = extractContentFromObject(outputObj);
                    } else if (responseMap.containsKey('response')) {
                        Object responseObj = responseMap.get('response');
                        content = extractContentFromObject(responseObj);
                    } else if (responseMap.containsKey('content')) {
                        Object contentObj = responseMap.get('content');
                        content = extractContentFromObject(contentObj);
                    } else if (responseMap.containsKey('text')) {
                        Object textObj = responseMap.get('text');
                        content = extractContentFromObject(textObj);
                    } else if (responseMap.containsKey('choices')) {
                        List<Object> choices = (List<Object>) responseMap.get('choices');
                        if (choices != null && !choices.isEmpty()) {
                            Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
                            if (firstChoice.containsKey('message')) {
                                Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
                                if (message != null && message.containsKey('content')) {
                                    content = (String) message.get('content');
                                }
                            } else if (firstChoice.containsKey('text')) {
                                content = (String) firstChoice.get('text');
                            }
                        }
                    }
                } catch (Exception parseEx) {
                    throw new AuraHandledException('Error parsing AI response: ' + parseEx.getMessage());
                }
                
                if (String.isNotBlank(content)) {
                    return content;
                }
                
                throw new AuraHandledException('Invalid response format from AI service. Response: ' + responseBody);
            } else {
                String errorMsg = 'HTTP ' + (response != null ? String.valueOf(response.getStatusCode()) + ' - ' + response.getStatus() : 'No response');
                String detailedError = 'AI Service Error: ' + errorMsg + 
                                      '. Connection: ' + connection.Name + 
                                      ', Named Credential: ' + connection.Named_Credential__c + 
                                      ', Endpoint: ' + (String.isNotBlank(connection.EndPoint_URL__c) ? connection.EndPoint_URL__c : '/v1/responses');
                
                if (response != null && String.isNotBlank(response.getBody())) {
                    detailedError += '. Response: ' + response.getBody().abbreviate(200);
                }
                
                throw new AuraHandledException(detailedError);
            }
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            gptfyException.log(e, AIConstants.APPLICATION_NAME, '', 'P_PromptBuilderController', 'generatePromptDetails','');
            throw new AuraHandledException('Error generating prompt details: ' + e.getMessage());
        }
    }
    
    /**
     * Creates an AI_Prompt__c record with data extraction mapping
     * @param promptName Name of the prompt
     * @param targetObject Target Salesforce object
     * @param description Description of the prompt
     * @param promptCommand The actual prompt command/instruction
     * @param dataContextMapping JSON string with data context mapping details
     * @return ID of the created prompt record
     */
    @AuraEnabled
    public static String createPromptWithMapping(String promptName, String targetObject, 
                                                String description, String promptCommand, 
                                                String dataContextMapping) {
        try {
            if (String.isBlank(promptName) || String.isBlank(targetObject) || String.isBlank(promptCommand)) {
                throw new AuraHandledException('Required fields cannot be empty');
            }
            
            ccai__AI_Connection__c connection = getGPTfyConnection();
            
            String extractionMappingId = null;
            if (String.isNotBlank(dataContextMapping) && dataContextMapping != 'undefined' && dataContextMapping != 'null') {
                extractionMappingId = createDataExtractionMapping(
                    promptName, 
                    targetObject, 
                    description, 
                    dataContextMapping
                );
            }
            
            String truncatedDescription = String.isNotBlank(description) ? 
                                         description.abbreviate(255) : '';
            
            AI_Prompt__c prompt = new AI_Prompt__c(
                Name = promptName,
                Description__c = truncatedDescription,
                Object__c = targetObject,
                Prompt_Command__c = promptCommand,
                Type__c = 'Text',
                Status__c = 'Draft',
                ccai__AI_Connection__c = connection.Id,
                AI_Data_Extraction_Mapping__c = extractionMappingId,
                Temperature__c = 0.7,
                Top_P__c = 1.0,
                Max_Output_Tokens__c = 2000
            );
            
            List<SObject> insertedRecords = FLSCheck.getInstance().insertDML(new List<AI_Prompt__c>{prompt});
            
            if (insertedRecords != null && !insertedRecords.isEmpty()) {
                return String.valueOf(insertedRecords.get(0).get('Id'));
            }
            
            throw new AuraHandledException('Failed to create prompt record');
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            gptfyException.log(e, AIConstants.APPLICATION_NAME, '', 'P_PromptBuilderController', 'createPromptWithMapping','');
            throw new AuraHandledException('Error creating prompt: ' + e.getMessage());
        }
    }
    
    /**
     * Gets all standard and custom objects with their fields for metadata context
     * @return List of object metadata
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getSalesforceObjectsMetadata() {
        try {
            List<Map<String, Object>> objectsList = new List<Map<String, Object>>();
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            
            for (String objName : globalDescribe.keySet()) {
                Schema.SObjectType objType = globalDescribe.get(objName);
                Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
                
                if (objDescribe.isCreateable() && objDescribe.isUpdateable() && 
                    !objDescribe.isCustomSetting()) {
                    
                    Map<String, Object> objInfo = new Map<String, Object>();
                    objInfo.put('name', objDescribe.getName());
                    objInfo.put('label', objDescribe.getLabel());
                    objInfo.put('isCustom', objDescribe.isCustom());
                    
                    List<String> childRelationships = new List<String>();
                    for (Schema.ChildRelationship childRel : objDescribe.getChildRelationships()) {
                        if (childRel.getRelationshipName() != null) {
                            childRelationships.add(childRel.getRelationshipName() + ' (' + 
                                                 childRel.getChildSObject().getDescribe().getLabel() + ')');
                        }
                    }
                    objInfo.put('childRelationships', childRelationships);
                    
                    objectsList.add(objInfo);
                }
            }
            
            return objectsList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Salesforce objects: ' + e.getMessage());
        }
    }
    
    /**
     * Gets existing prompts for AI to understand the pattern
     * @return List of existing prompt records with their details
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getExistingPrompts() {
        try {
            List<Map<String, String>> promptsList = new List<Map<String, String>>();
            
            List<AI_Prompt__c> prompts = [
                SELECT Id, Name, Description__c, Object__c, Prompt_Command__c, Type__c
                FROM AI_Prompt__c
                WHERE Status__c = 'Active' AND Type__c = 'Text'
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
            
            for (AI_Prompt__c prompt : prompts) {
                Map<String, String> promptInfo = new Map<String, String>();
                promptInfo.put('name', prompt.Name);
                promptInfo.put('object', prompt.Object__c);
                promptInfo.put('description', prompt.Description__c != null ? prompt.Description__c : '');
                promptInfo.put('command', prompt.Prompt_Command__c != null ? 
                             prompt.Prompt_Command__c.substring(0, Math.min(200, prompt.Prompt_Command__c.length())) : '');
                promptsList.add(promptInfo);
            }
            
            return promptsList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching existing prompts: ' + e.getMessage());
        }
    }
    
    // ==================== PRIVATE HELPER METHODS ====================
    
    /**
     * Builds the system prompt for AI to generate prompt details
     */
    private static String buildSystemPrompt() {
        String basePrompt = 'You are an expert Salesforce AI Prompt Engineer. Your task is to generate comprehensive, ' +
               'well-structured prompts for Salesforce data analysis based on user requirements.\n\n' +
               'CRITICAL INSTRUCTIONS:\n' +
               '1. Respond ONLY with valid JSON in this exact structure:\n' +
               '{\n' +
               '  "name": "Concise prompt name (e.g., Account Sentiment Analysis)",\n' +
               '  "targetObject": "Primary Salesforce object (e.g., Account, Case, Opportunity)",\n' +
               '  "description": "2-3 sentence description of what the prompt does",\n' +
               '  "promptCommand": "Detailed, comprehensive prompt instruction (300-500 words)",\n' +
               '  "dataContextMapping": {\n' +
               '    "childRelationships": [\n' +
               '      {\n' +
               '        "relationshipName": "Opportunities",\n' +
               '        "objectName": "Opportunity",\n' +
               '        "fields": ["Name", "StageName", "Amount", "CloseDate"]\n' +
               '      }\n' +
               '    ],\n' +
               '    "mainObjectFields": ["Name", "Industry", "AnnualRevenue", "Description"]\n' +
               '  }\n' +
               '}\n\n' +
               '2. For promptCommand, create a COMPREHENSIVE, WELL-FORMATTED instruction that produces VISUALLY APPEALING output:\n' +
               '   - Uses HTML-style formatting for better readability\n' +
               '   - Starts with a clear objective paragraph\n' +
               '   - Uses <br/><br/> for paragraph breaks\n' +
               '   - Uses numbered or bulleted lists with proper line breaks\n' +
               '   - Clearly defines the analysis or task objective\n' +
               '   - Specifies what data points to focus on (use bullet points)\n' +
               '   - CRITICAL: Include detailed formatting instructions that produce GRAPHICAL, STRUCTURED output:\n' +
               '     * Use emojis for visual appeal (✅ ❌ ⚠️ 📊 📈 📉 💡 🎯 ⭐ 🔥 etc.)\n' +
               '     * Request tables with borders using markdown or HTML format\n' +
               '     * Use headers (###), bold (**text**), and bullet points (•)\n' +
               '     * Include sections with clear visual separators (═══, ───, etc.)\n' +
               '     * Request color indicators or status badges where applicable\n' +
               '     * Use indentation and spacing for hierarchy\n' +
               '     * Include summary boxes or key highlights sections\n' +
               '   - Provides specific examples of the expected formatted output structure\n' +
               '   - Includes constraints (e.g., word limits, specific values)\n' +
               '   - Instructs to avoid hallucination and use only provided data\n' +
               '   - Example format:\n' +
               '     "You are tasked with [objective].<br/><br/>Analyze the provided data and deliver a VISUALLY FORMATTED response with:<br/><br/>### 📊 Summary Section<br/>• Key Metric 1: [value] ✅<br/>• Key Metric 2: [value] ⚠️<br/><br/>### 📈 Detailed Analysis<br/>Present findings in a formatted table:<br/>| Category | Value | Status |<br/>|----------|-------|--------|<br/>| Item 1   | X     | ✅     |<br/><br/>### 💡 Recommendations<br/>1. **Priority Action**: [description]<br/>2. **Secondary Action**: [description]"\n\n' +
               '3. For dataContextMapping, intelligently suggest:\n' +
               '   - CRITICAL: ONLY use POPULAR, STANDARD Salesforce objects:\n' +
               '     * Primary Objects: Account, Contact, Lead, Opportunity, Case, Campaign\n' +
               '     * Secondary Objects: Order, Product2, Quote, Contract, Asset\n' +
               '     * AVOID: Event, Task, ActivityHistory, OpenActivity, EmailMessage, Attachment, ContentDocument, FeedItem, Note, and other system/activity objects\n' +
               '     * EXCEPTION: Only include non-standard objects if the user EXPLICITLY mentions them by name\n' +
               '   - Relevant child relationships (e.g., Opportunities for Account, Cases for Contact, Contacts for Account)\n' +
               '   - MAXIMUM 3 child relationships - prioritize the most important/relevant ones\n' +
               '   - Focus on business-critical relationships, not activity tracking\n' +
               '   - Key fields from the main object (standard fields like Name, Status, Amount, etc.)\n' +
               '   - Appropriate fields from child objects (avoid system fields)\n' +
               '   - ONLY include "whereClause" in childRelationships if the user EXPLICITLY requests filtering, sorting, or limiting records (e.g., "latest 10 opportunities", "closed cases only", "sorted by date")\n' +
               '   - If no specific filtering is mentioned, DO NOT include the "whereClause" field at all\n\n' +
               '4. Match the tone and structure of existing prompts provided in the context.\n' +
               '5. Always set Type to "Text"\n' +
               '6. Do NOT include any explanations, markdown formatting, or additional text outside the JSON.\n' +
               '7. Ensure all field names are valid Salesforce API names.';
        
        // NEW: Inject Builder Prompts for quality guidance
        String builderContent = loadBuilderGuidance();
        if (String.isNotBlank(builderContent)) {
            basePrompt += '\n\n' + builderContent;
        }
        
        return basePrompt;
    }
    
    /**
     * @description Load builder prompts to guide AI prompt generation quality
     * @return Combined builder content for quality guidance
     */
    private static String loadBuilderGuidance() {
        try {
            List<ccai__AI_Prompt__c> builders = [
                SELECT Id, Name, ccai__Type__c, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordType.DeveloperName = 'Builder'
                  AND ccai__Status__c = 'Active'
                  AND ccai__Type__c IN ('Quality Rule', 'Pattern')
                ORDER BY ccai__Type__c, Name
            ];
            
            if (builders.isEmpty()) {
                System.debug('No builder guidance found for wizard');
                return '';
            }
            
            String guidance = '\n\n=== QUALITY GUIDANCE (Apply to Generated Prompts) ===\n\n';
            guidance += 'When generating promptCommand, follow these quality standards:\n\n';
            
            for (ccai__AI_Prompt__c builder : builders) {
                guidance += '--- ' + builder.Name + ' ---\n';
                // Add first 500 chars as guidance snippet (full content too large for wizard system prompt)
                String snippet = builder.ccai__Prompt_Command__c;
                if (snippet.length() > 1000) {
                    snippet = snippet.substring(0, 1000) + '...\n[See full guidance in builder: ' + builder.Name + ']';
                }
                guidance += snippet + '\n\n';
            }
            
            System.debug('Loaded ' + builders.size() + ' builder prompts for wizard guidance');
            return guidance;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not load builder guidance: ' + e.getMessage());
            return '';
        }
    }
    
    /**
     * Builds the user prompt with context from existing prompts
     */
    private static String buildUserPrompt(String userInput, String existingPromptsJson) {
        String userPrompt = 'User Request: ' + userInput + '\n\n';
        
        if (String.isNotBlank(existingPromptsJson)) {
            userPrompt += 'Here are examples of existing prompts for reference (study their structure and style):\n' +
                         existingPromptsJson + '\n\n';
        }
        
        userPrompt += 'Based on the user\'s request and the pattern from existing prompts, ' +
                     'generate a complete prompt configuration following the exact JSON structure specified. ' +
                     'Make the prompt command detailed, professional, and production-ready.';
        
        return userPrompt;
    }
    
    /**
     * Creates data extraction mapping from the AI-generated context
     */
    private static String createDataExtractionMapping(String mappingName, String targetObject, 
                                                     String description, String dataContextJson) {
        try {
            Map<String, Object> contextMap = (Map<String, Object>) JSON.deserializeUntyped(dataContextJson);
            
            AI_Data_Extraction_Mapping__c mapping = new AI_Data_Extraction_Mapping__c(
                Name = mappingName,
                Object_Name__c = targetObject,
                Description__c = description,
                Status__c = 'Active'
            );
            
            List<SObject> insertedMappings = FLSCheck.getInstance().insertDML(
                new List<AI_Data_Extraction_Mapping__c>{mapping}
            );
            
            if (insertedMappings == null || insertedMappings.isEmpty()) {
                return null;
            }
            
            String mappingId = String.valueOf(insertedMappings.get(0).get('Id'));
            
            List<Object> childRelationships = (List<Object>) contextMap.get('childRelationships');
            if (childRelationships != null && !childRelationships.isEmpty()) {
                createDataExtractionDetails(mappingId, childRelationships);
            }
            
            List<Object> mainObjectFieldsObj = (List<Object>) contextMap.get('mainObjectFields');
            if (mainObjectFieldsObj != null && !mainObjectFieldsObj.isEmpty()) {
                List<String> mainObjectFields = new List<String>();
                for (Object fieldObj : mainObjectFieldsObj) {
                    mainObjectFields.add((String) fieldObj);
                }
                createDataExtractionFields(mappingId, targetObject, mainObjectFields);
            }
            
            return mappingId;
            
        } catch (Exception e) {
            gptfyException.log(e, AIConstants.APPLICATION_NAME, '', 'P_PromptBuilderController', 'createDataExtractionMapping','');
            return null;
        }
    }
    
    /**
     * Creates detail records for child relationships
     * Maximum 3 child relationships are supported
     */
    private static void createDataExtractionDetails(String mappingId, List<Object> childRelationships) {
        try {
            final Integer MAX_CHILD_RELATIONSHIPS = 3;
            
            List<AI_Data_Extraction_Mapping__c> mappings = [
                SELECT Object_Name__c FROM AI_Data_Extraction_Mapping__c WHERE Id = :mappingId LIMIT 1
            ];
            String parentObjectName = mappings.isEmpty() ? null : mappings[0].Object_Name__c;
            
            List<AI_Data_Extraction_Detail__c> details = new List<AI_Data_Extraction_Detail__c>();
            List<AI_Data_Extraction_Field__c> childFields = new List<AI_Data_Extraction_Field__c>();
            List<Map<String, Object>> validChildRelationships = new List<Map<String, Object>>();
            Integer runningIndex = 0;
            Integer processedCount = 0;
            
            for (Object childRelObj : childRelationships) {
                if (processedCount >= MAX_CHILD_RELATIONSHIPS) {
                    break;
                }
                
                Map<String, Object> childRel = (Map<String, Object>) childRelObj;
                
                String objectName = (String) childRel.get('objectName');
                String relationshipName = (String) childRel.get('relationshipName');
                String whereClause = (String) childRel.get('whereClause');
                
                // Validate child object exists in Salesforce
                if (!isValidSalesforceObject(objectName)) {
                    continue;
                }
                
                String relationshipField = getRelationshipFieldName(parentObjectName, objectName);
                
                if (String.isBlank(relationshipField)) {
                    continue;
                }
                
                AI_Data_Extraction_Detail__c detail = new AI_Data_Extraction_Detail__c(
                    AI_Data_Extraction_Mapping__c = mappingId,
                    Object_Name__c = objectName,
                    RelationshipName__c = relationshipName,
                    Type__c = 'CHILD',
                    Running_Index__c = runningIndex,
                    Where_Clause__c = String.isNotBlank(whereClause) ? whereClause : null,
                    Order_By__c = null,
                    Record_Limit__c = null,
                    RelationshipField__c = relationshipField
                );
                
                details.add(detail);
                validChildRelationships.add(childRel);
                runningIndex += 100;
                processedCount++;
            }
            
            if (!details.isEmpty()) {
                List<SObject> insertedDetails = FLSCheck.getInstance().insertDML(details);
                
                if (insertedDetails != null && !insertedDetails.isEmpty()) {
                    List<AI_Data_Extraction_Field__c> objectLabelFields = new List<AI_Data_Extraction_Field__c>();
                    
                    Integer detailIndex = 0;
                    for (Map<String, Object> childRel : validChildRelationships) {
                        String objectName = (String) childRel.get('objectName');
                        String relationshipName = (String) childRel.get('relationshipName');
                        
                        AI_Data_Extraction_Field__c objectField = new AI_Data_Extraction_Field__c(
                            AI_Data_Extraction_Mapping__c = mappingId,
                            Object__c = objectName,
                            Field__c = objectName,
                            Label__c = relationshipName != null ? relationshipName : objectName,
                            Type__c = 'OBJECT',
                            Send_To_AI__c = false
                        );
                        objectLabelFields.add(objectField);
                        
                        List<Object> fieldsObj = (List<Object>) childRel.get('fields');
                        
                        if (fieldsObj != null && !fieldsObj.isEmpty() && detailIndex < insertedDetails.size()) {
                            // Convert List<Object> to List<String> for validation
                            List<String> fieldNames = new List<String>();
                            for (Object fieldObj : fieldsObj) {
                                fieldNames.add((String) fieldObj);
                            }
                            
                            // Validate fields against Salesforce schema
                            List<String> validFields = getValidFields(objectName, fieldNames);
                            
                            for (String fieldApi : validFields) {
                                AI_Data_Extraction_Field__c field = new AI_Data_Extraction_Field__c(
                                    AI_Data_Extraction_Mapping__c = mappingId,
                                    Object__c = objectName,
                                    Field__c = fieldApi,
                                    Label__c = fieldApi,
                                    Send_To_AI__c = true,
                                    Type__c = 'FIELD'
                                );
                                
                                childFields.add(field);
                            }
                        }
                        detailIndex++;
                    }
                    
                    if (!objectLabelFields.isEmpty()) {
                        FLSCheck.getInstance().insertDML(objectLabelFields);
                    }
                    
                    if (!childFields.isEmpty()) {
                        FLSCheck.getInstance().insertDML(childFields);
                    }
                }
            }
            
        } catch (Exception e) {
            gptfyException.log(e, AIConstants.APPLICATION_NAME, '', 'P_PromptBuilderController', 'createDataExtractionDetails','');
        }
    }
    
    /**
     * Creates field records for data extraction (with validation)
     */
    private static void createDataExtractionFields(String mappingId, String objectName, List<String> fields) {
        try {
            // Validate object exists
            if (!isValidSalesforceObject(objectName)) {
                return;
            }
            
            List<AI_Data_Extraction_Field__c> fieldRecords = new List<AI_Data_Extraction_Field__c>();
            
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            AI_Data_Extraction_Field__c objectField = new AI_Data_Extraction_Field__c(
                AI_Data_Extraction_Mapping__c = mappingId,
                Object__c = objectName,
                Field__c = objectName,
                Label__c = objDescribe.getLabel(),
                Type__c = 'OBJECT',
                Send_To_AI__c = false
            );
            fieldRecords.add(objectField);
            
            // Validate and filter fields
            List<String> validFields = getValidFields(objectName, fields);
            
            for (String fieldApi : validFields) {
                AI_Data_Extraction_Field__c field = new AI_Data_Extraction_Field__c(
                    AI_Data_Extraction_Mapping__c = mappingId,
                    Object__c = objectName,
                    Field__c = fieldApi,
                    Label__c = fieldApi,
                    Send_To_AI__c = true,
                    Type__c = 'FIELD'
                );
                
                fieldRecords.add(field);
            }
            
            if (!fieldRecords.isEmpty()) {
                FLSCheck.getInstance().insertDML(fieldRecords);
            }
            
        } catch (Exception e) {
            gptfyException.log(e, AIConstants.APPLICATION_NAME, '', 'P_PromptBuilderController', 'createDataExtractionFields','');
        }
    }
    
    /**
     * Makes a direct HTTP callout to the Responses API
     */
    private static HttpResponse callResponsesAPI(String systemPrompt, String userPrompt, 
                                                ccai__AI_Connection__c connection, Integer maxTokens, 
                                                Decimal temperature, Decimal topP) {
        try {
            Map<String, Object> requestBody = new Map<String, Object>();
            
            String model = connection.Model__c != null ? connection.Model__c : 'gpt-4';
            requestBody.put('model', model);
            
            String combinedInput = systemPrompt + '\n\n' + userPrompt;
            requestBody.put('input', combinedInput);
            
            requestBody.put('max_output_tokens', maxTokens);
            requestBody.put('temperature', temperature);
            requestBody.put('top_p', topP);
            
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest request = new HttpRequest();
            
            String endpoint = 'callout:' + connection.Named_Credential__c;
            
            if (String.isNotBlank(connection.EndPoint_URL__c)) {
                endpoint += connection.EndPoint_URL__c;
            } else {
                endpoint += '/v1/responses';
            }
            
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(jsonBody);
            request.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            return response;
            
        } catch (Exception e) {
            throw e;
        }
    }
    
    /**
     * Helper method to get GPTfy connection
     */
    private static ccai__AI_Connection__c getGPTfyConnection() {
        List<ccai__AI_Connection__c> connections = [
            SELECT Id, Name, Named_Credential__c, Model__c, Max_Tokens__c, 
                   Temperature__c, Top_P__c, EndPoint_URL__c, AI_Technology__c,
                   Connector_Class__c, Processing_Class__c, Version__c, 
                   Additional_Parameters__c
            FROM ccai__AI_Connection__c
            WHERE Name = 'Response API'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (connections.isEmpty()) {
            throw new AuraHandledException('No AI Connection found. Please configure an AI Connection record with Name = "Response API". ' +
                                         'Ensure the Named_Credential__c field is set to your Named Credential name (without "callout:" prefix) and EndPoint_URL__c is configured correctly.');
        }
        
        return connections[0];
    }
    
    /**
     * Helper method to find the relationship field API name between parent and child objects
     */
    private static String getRelationshipFieldName(String parentObjectName, String childObjectName) {
        try {
            if (String.isBlank(parentObjectName) || String.isBlank(childObjectName)) {
                return null;
            }
            
            Schema.DescribeSObjectResult parentDescribe = Schema.getGlobalDescribe().get(parentObjectName).getDescribe();
            
            for (Schema.ChildRelationship childRel : parentDescribe.getChildRelationships()) {
                if (String.valueOf(childRel.getChildSObject()) == childObjectName) {
                    String fieldName = String.valueOf(childRel.getField());
                    return fieldName;
                }
            }
            
            return null;
            
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Validates that an object exists in Salesforce
     */
    private static Boolean isValidSalesforceObject(String objectName) {
        try {
            if (String.isBlank(objectName)) {
                return false;
            }
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            return globalDescribe.containsKey(objectName.toLowerCase());
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Validates that a field exists on a Salesforce object
     */
    private static Boolean isValidField(String objectName, String fieldName) {
        try {
            if (String.isBlank(objectName) || String.isBlank(fieldName)) {
                return false;
            }
            
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) {
                return false;
            }
            
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            return fieldMap.containsKey(fieldName.toLowerCase());
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Validates and filters a list of fields for an object, returning only valid fields
     */
    private static List<String> getValidFields(String objectName, List<String> fields) {
        List<String> validFields = new List<String>();
        
        if (String.isBlank(objectName) || fields == null || fields.isEmpty()) {
            return validFields;
        }
        
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) {
                return validFields;
            }
            
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            
            for (String fieldName : fields) {
                if (String.isNotBlank(fieldName) && fieldMap.containsKey(fieldName.toLowerCase())) {
                    validFields.add(fieldName);
                }
            }
        } catch (Exception e) {
            gptfyException.log(e, AIConstants.APPLICATION_NAME, '', 'P_PromptBuilderController', 'getValidFields','');
        }
        
        return validFields;
    }
    
    /**
     * Helper method to safely extract content from an object that could be String, List, or other type
     */
    private static String extractContentFromObject(Object obj) {
        if (obj == null) {
            return null;
        }
        
        if (obj instanceof String) {
            return (String) obj;
        }
        
        if (obj instanceof List<Object>) {
            List<Object> listObj = (List<Object>) obj;
            if (!listObj.isEmpty()) {
                Object firstItem = listObj[0];
                if (firstItem instanceof Map<String, Object>) {
                    Map<String, Object> mapItem = (Map<String, Object>) firstItem;
                    if (mapItem.containsKey('text')) {
                        return extractContentFromObject(mapItem.get('text'));
                    } else if (mapItem.containsKey('content')) {
                        return extractContentFromObject(mapItem.get('content'));
                    }
                    return JSON.serialize(mapItem);
                }
                if (firstItem instanceof String) {
                    return (String) firstItem;
                }
                return JSON.serialize(firstItem);
            }
        }
        
        if (obj instanceof Map<String, Object>) {
            Map<String, Object> mapObj = (Map<String, Object>) obj;
            if (mapObj.containsKey('text')) {
                return extractContentFromObject(mapObj.get('text'));
            } else if (mapObj.containsKey('content')) {
                return extractContentFromObject(mapObj.get('content'));
            }
            return JSON.serialize(mapObj);
        }
        
        if (obj instanceof Integer || obj instanceof Decimal || obj instanceof Double || 
            obj instanceof Long || obj instanceof Boolean) {
            return String.valueOf(obj);
        }
        
        try {
            return JSON.serialize(obj);
        } catch (Exception e) {
            return String.valueOf(obj);
        }
    }
}