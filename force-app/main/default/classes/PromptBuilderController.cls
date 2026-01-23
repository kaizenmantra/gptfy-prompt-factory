/**
 * @description Controller for the Interactive Prompt Builder
 * Enables content-first, interactive prompt building with real-time iteration
 *
 * Architecture:
 * - Phase 1: Discovery & Data Fetch (initializeSession)
 * - Phase 2: Chat Interface (chat method - to be implemented)
 * - Phase 3: Deploy (deployPrompt method - to be implemented)
 */
public with sharing class PromptBuilderController {

    /**
     * @description Initializes a new prompt building session
     * Queries sample records, gathers schema metadata, creates session record
     *
     * @param rootObject API name of the root object (e.g., "Account", "Opportunity")
     * @param sampleRecordIds List of 3-5 record IDs to analyze
     * @param businessContext User's description of what they want to build
     * @return Map containing sessionId, objectInfo, fieldMetadata, and sampleData
     */
    @AuraEnabled
    public static Map<String, Object> initializeSession(
        String rootObject,
        List<Id> sampleRecordIds,
        String businessContext
    ) {
        try {
            // Validate inputs
            if (String.isBlank(rootObject)) {
                throw new AuraHandledException('Root object is required');
            }

            if (sampleRecordIds == null || sampleRecordIds.isEmpty()) {
                throw new AuraHandledException('At least one sample record is required');
            }

            if (sampleRecordIds.size() > 5) {
                throw new AuraHandledException('Maximum 5 sample records allowed');
            }

            // Validate object exists and is accessible
            if (!SchemaHelper.isObjectAccessible(rootObject)) {
                throw new AuraHandledException('Object ' + rootObject + ' is not accessible or does not exist');
            }

            // Get schema metadata
            Schema.DescribeSObjectResult objDescribe = SchemaHelper.getObjectDescribe(rootObject);
            List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields(rootObject);
            List<SchemaHelper.ChildRelationship> allChildRelationships = SchemaHelper.getChildRelationships(rootObject);

            // Select top 3-5 most important child relationships
            List<SchemaHelper.ChildRelationship> childRelationships = selectImportantRelationships(
                allChildRelationships,
                rootObject
            );

            // Query sample records with all accessible fields
            List<String> fieldNames = getQueryableFieldNames(fields);
            String soql = 'SELECT ' + String.join(fieldNames, ', ') +
                         ' FROM ' + rootObject +
                         ' WHERE Id IN :sampleRecordIds' +
                         ' ORDER BY LastModifiedDate DESC';

            List<SObject> sampleRecords = Database.query(soql);

            if (sampleRecords.isEmpty()) {
                throw new AuraHandledException('No records found with the provided IDs');
            }

            // Create session record (using PF_Run__c with Session_Mode = Interactive)
            PF_Run__c session = new PF_Run__c(
                Root_Object__c = rootObject,
                Business_Context__c = businessContext,
                Sample_Record_Id__c = String.join(sampleRecordIds, ','),
                Status__c = 'In Progress',
                Current_Stage__c = 1,
                Started_At__c = System.now(),
                AI_Model__c = getDefaultAIModel()
            );

            insert session;

            // Build response
            Map<String, Object> response = new Map<String, Object>{
                'success' => true,
                'sessionId' => session.Id,
                'objectInfo' => buildObjectInfo(objDescribe, fields.size(), childRelationships.size()),
                'fieldMetadata' => buildFieldMetadataResponse(fields),
                'childRelationships' => buildChildRelationshipsResponse(childRelationships),
                'sampleData' => buildSampleDataResponse(sampleRecords, fieldNames),
                'sampleRecordCount' => sampleRecords.size()
            };

            return response;

        } catch (Exception e) {
            throw new AuraHandledException('Error initializing session: ' + e.getMessage());
        }
    }

    /**
     * @description Extracts queryable field names from FieldMetadata list
     * @param fields List of field metadata
     * @return List of field API names that are accessible
     */
    private static List<String> getQueryableFieldNames(List<SchemaHelper.FieldMetadata> fields) {
        List<String> fieldNames = new List<String>();

        for (SchemaHelper.FieldMetadata field : fields) {
            if (field.isAccessible) {
                fieldNames.add(field.name);
            }
        }

        // Always include Id if not already present
        if (!fieldNames.contains('Id')) {
            fieldNames.add(0, 'Id');
        }

        return fieldNames;
    }

    /**
     * @description Builds object information summary
     * @param objDescribe Object describe result
     * @param fieldCount Number of accessible fields
     * @param childCount Number of child relationships
     * @return Map with object metadata
     */
    private static Map<String, Object> buildObjectInfo(
        Schema.DescribeSObjectResult objDescribe,
        Integer fieldCount,
        Integer childCount
    ) {
        return new Map<String, Object>{
            'name' => objDescribe.getName(),
            'label' => objDescribe.getLabel(),
            'labelPlural' => objDescribe.getLabelPlural(),
            'isCustom' => objDescribe.isCustom(),
            'fieldCount' => fieldCount,
            'childRelationshipCount' => childCount
        };
    }

    /**
     * @description Builds field metadata response
     * @param fields List of FieldMetadata
     * @return List of maps with field information
     */
    private static List<Map<String, Object>> buildFieldMetadataResponse(List<SchemaHelper.FieldMetadata> fields) {
        List<Map<String, Object>> fieldList = new List<Map<String, Object>>();

        for (SchemaHelper.FieldMetadata field : fields) {
            if (field.isAccessible) {
                fieldList.add(new Map<String, Object>{
                    'name' => field.name,
                    'label' => field.label,
                    'type' => field.type,
                    'isCustom' => field.isCustom
                });
            }
        }

        return fieldList;
    }

    /**
     * @description Builds child relationships response
     * @param relationships List of ChildRelationship
     * @return List of maps with relationship information
     */
    private static List<Map<String, Object>> buildChildRelationshipsResponse(
        List<SchemaHelper.ChildRelationship> relationships
    ) {
        List<Map<String, Object>> relList = new List<Map<String, Object>>();

        for (SchemaHelper.ChildRelationship rel : relationships) {
            relList.add(new Map<String, Object>{
                'childObject' => rel.childObject,
                'relationshipName' => rel.relationshipName,
                'field' => rel.field
            });
        }

        return relList;
    }

    /**
     * @description Builds sample data response
     * Converts SObject records to maps for easy consumption by LWC
     * @param records List of sample records
     * @param fieldNames List of field names that were queried
     * @return List of maps representing each record
     */
    private static List<Map<String, Object>> buildSampleDataResponse(
        List<SObject> records,
        List<String> fieldNames
    ) {
        List<Map<String, Object>> dataList = new List<Map<String, Object>>();

        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();

            for (String fieldName : fieldNames) {
                try {
                    Object fieldValue = record.get(fieldName);
                    recordMap.put(fieldName, fieldValue);
                } catch (Exception e) {
                    // Field might not be present in this record
                    recordMap.put(fieldName, null);
                }
            }

            dataList.add(recordMap);
        }

        return dataList;
    }

    /**
     * @description Gets the default AI model name from custom settings
     * @return String representing the AI model (e.g., "Claude", "Azure OpenAI")
     */
    private static String getDefaultAIModel() {
        // Check which provider is configured as default
        Claude_API_Credentials__c claudeCreds = Claude_API_Credentials__c.getInstance();
        Azure_OpenAI_Credentials__c azureCreds = Azure_OpenAI_Credentials__c.getInstance();
        DeepSeek_Credentials__c deepseekCreds = DeepSeek_Credentials__c.getInstance();

        if (deepseekCreds != null && deepseekCreds.Default__c == true) {
            return 'DeepSeek';
        }

        if (azureCreds != null && azureCreds.Default__c == true) {
            return 'Azure OpenAI';
        }

        if (claudeCreds != null && claudeCreds.Default__c == true) {
            return 'Claude';
        }

        // Fallback
        return 'Claude';
    }

    /**
     * @description Chat with LLM to iteratively build prompt content
     * Phase 2: Interactive conversation with self-evaluating AI
     *
     * @param sessionId ID of the PF_Run__c session record
     * @param userMessage User's message or feedback
     * @return Map containing success status, AI response, and conversation history
     */
    @AuraEnabled
    public static Map<String, Object> chat(Id sessionId, String userMessage) {
        try {
            // Load session with conversation history
            PF_Run__c session = [
                SELECT Id, Root_Object__c, Business_Context__c, Sample_Record_Id__c,
                       Status__c, AI_Model__c, Current_Draft__c
                FROM PF_Run__c
                WHERE Id = :sessionId
                LIMIT 1
            ];

            // Load static resource with exemplars and system prompt
            Map<String, String> exemplars = loadExemplars();
            String systemPrompt = exemplars.get('SYSTEM_PROMPT');

            // Get sample record IDs
            List<String> recordIds = session.Sample_Record_Id__c.split(',');
            List<Id> sampleRecordIds = new List<Id>();
            for (String recordId : recordIds) {
                sampleRecordIds.add((Id)recordId.trim());
            }

            // Query sample records
            List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields(session.Root_Object__c);
            List<String> fieldNames = getQueryableFieldNames(fields);

            // Get child relationships for querying
            List<SchemaHelper.ChildRelationship> allChildRels = SchemaHelper.getChildRelationships(session.Root_Object__c);
            List<SchemaHelper.ChildRelationship> childRelationships = selectImportantRelationships(
                allChildRels,
                session.Root_Object__c
            );

            // Build SOQL with child relationships
            String soql = buildSOQLWithChildren(
                session.Root_Object__c,
                fieldNames,
                childRelationships
            );
            soql += ' WHERE Id IN :sampleRecordIds';

            List<SObject> sampleRecords = Database.query(soql);

            // Query child data for each relationship
            Map<String, List<SObject>> childDataByRelationship = queryChildData(
                sampleRecordIds,
                childRelationships
            );

            // Determine if this is first message or follow-up
            Boolean isFirstMessage = String.isBlank(userMessage) || userMessage.equals('START');
            String previousDraft = session.Current_Draft__c;

            // Build user prompt with child data
            String userPrompt = buildUserPrompt(
                session.Root_Object__c,
                session.Business_Context__c,
                sampleRecords,
                fieldNames,
                exemplars,
                userMessage,
                previousDraft,
                isFirstMessage,
                childRelationships,
                childDataByRelationship
            );

            // Call AI
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(
                systemPrompt,
                userPrompt,
                4096,
                1.0
            );

            // Check for errors
            if (!aiResponse.success) {
                throw new AuraHandledException('AI service error: ' + aiResponse.errorMessage);
            }

            // Store the AI response as current draft for future follow-ups
            session.Current_Draft__c = aiResponse.content;
            update session;

            // Build response
            Map<String, Object> response = new Map<String, Object>{
                'success' => true,
                'message' => aiResponse.content,
                'sessionId' => sessionId
            };

            return response;

        } catch (Exception e) {
            throw new AuraHandledException('Error in chat: ' + e.getMessage());
        }
    }

    /**
     * @description Loads exemplars from static resource
     * @return Map of exemplar keys to content
     */
    private static Map<String, String> loadExemplars() {
        StaticResource sr = [
            SELECT Id, Body
            FROM StaticResource
            WHERE Name = 'PromptExemplars'
            LIMIT 1
        ];

        String jsonContent = sr.Body.toString();
        Map<String, Object> exemplarsMap = (Map<String, Object>)JSON.deserializeUntyped(jsonContent);

        Map<String, String> result = new Map<String, String>();
        for (String key : exemplarsMap.keySet()) {
            result.put(key, (String)exemplarsMap.get(key));
        }

        return result;
    }

    /**
     * @description Selects appropriate exemplar based on root object
     * @param rootObject API name of the root object
     * @param exemplars Map of all exemplars
     * @return String containing the selected exemplar
     */
    private static String selectExemplar(String rootObject, Map<String, String> exemplars) {
        if (rootObject == 'Opportunity') {
            return exemplars.get('DEAL_COACH');
        } else if (rootObject == 'Account') {
            return exemplars.get('ACCOUNT_360');
        }

        // Default to Account 360 for other objects
        return exemplars.get('ACCOUNT_360');
    }

    /**
     * @description Builds the user prompt for the AI
     * @param rootObject Root object type
     * @param businessContext User's business context
     * @param sampleRecords Sample records to analyze
     * @param fieldNames Field names queried
     * @param exemplars Map of exemplars
     * @param userMessage Optional user message for follow-up
     * @param previousDraft Previous AI response (for follow-ups)
     * @param isFirstMessage Whether this is the first message or a follow-up
     * @return String containing the formatted user prompt
     */
    private static String buildUserPrompt(
        String rootObject,
        String businessContext,
        List<SObject> sampleRecords,
        List<String> fieldNames,
        Map<String, String> exemplars,
        String userMessage,
        String previousDraft,
        Boolean isFirstMessage,
        List<SchemaHelper.ChildRelationship> childRelationships,
        Map<String, List<SObject>> childDataByRelationship
    ) {
        // Select relevant exemplar
        String relevantExemplar = selectExemplar(rootObject, exemplars);

        // Format sample data (root + children)
        String formattedData = formatSampleData(sampleRecords, fieldNames, rootObject);

        // Add child relationship data (Task 19)
        String formattedChildData = formatChildRelationshipData(
            sampleRecords,
            childRelationships,
            childDataByRelationship
        );

        if (String.isNotBlank(formattedChildData)) {
            formattedData += '\n\n' + formattedChildData;
        }

        // Build prompt based on whether this is first message or follow-up
        if (isFirstMessage) {
            // First message template
            return '## WHAT I\'M BUILDING\n\n' +
                   businessContext + '\n\n' +
                   '## EXEMPLAR: What Excellent Output Looks Like\n\n' +
                   relevantExemplar + '\n\n' +
                   'Note: This exemplar uses different data. Your analysis should follow the same STRUCTURE and QUALITY, but use the actual data provided below.\n\n' +
                   '## ACTUAL DATA TO ANALYZE\n\n' +
                   '### Sample Records (' + sampleRecords.size() + ' ' + rootObject + ' records)\n\n' +
                   formattedData + '\n\n' +
                   '---\n\n' +
                   'Generate an analysis following the exemplar\'s structure and quality level. Remember to self-evaluate against the rubric before presenting.';
        } else {
            // Follow-up message template - CRITICAL: Include data and previous draft
            String prompt = '## USER FEEDBACK\n\n' +
                   userMessage + '\n\n';

            // Include the previous analysis so AI knows what to revise
            if (String.isNotBlank(previousDraft)) {
                prompt += '## YOUR PREVIOUS ANALYSIS (to revise)\n\n' +
                         previousDraft + '\n\n';
            }

            // Re-include the data so AI can reference it during revision
            prompt += '## DATA REFERENCE (for your revision)\n\n' +
                     formattedData + '\n\n' +
                     '---\n\n' +
                     'Revise your analysis based on the feedback above. Keep what was good, improve what was requested. Self-evaluate the revision against the rubric before presenting.';

            return prompt;
        }
    }

    /**
     * @description Formats sample records for the prompt
     * @param records Sample records
     * @param fieldNames Field names
     * @param rootObject Root object name
     * @return Formatted string
     */
    private static String formatSampleData(
        List<SObject> records,
        List<String> fieldNames,
        String rootObject
    ) {
        List<String> recordStrings = new List<String>();
        Integer recordNum = 1;

        for (SObject record : records) {
            List<String> fieldStrings = new List<String>();

            // Get record name/identifier
            String recordName = 'Record ' + recordNum;
            try {
                if (record.get('Name') != null) {
                    recordName = String.valueOf(record.get('Name'));
                }
            } catch (Exception e) {
                // Name field might not exist
            }

            fieldStrings.add('### Record ' + recordNum + ': ' + recordName + '\n');

            // Add key fields
            for (String fieldName : fieldNames) {
                try {
                    Object fieldValue = record.get(fieldName);
                    if (fieldValue != null && fieldName != 'Id') {
                        fieldStrings.add('- **' + fieldName + ':** ' + String.valueOf(fieldValue));
                    }
                } catch (Exception e) {
                    // Skip fields that can't be accessed
                }
            }

            recordStrings.add(String.join(fieldStrings, '\n'));
            recordNum++;
        }

        return String.join(recordStrings, '\n\n');
    }

    /**
     * @description Formats child relationship data as tables for LLM context
     * Task 19: Format relationship data for LLM context
     *
     * @param sampleRecords Parent records
     * @param childRelationships Child relationships to format
     * @param childDataByRelationship Additional child data queried separately
     * @return Formatted string with child data tables
     */
    private static String formatChildRelationshipData(
        List<SObject> sampleRecords,
        List<SchemaHelper.ChildRelationship> childRelationships,
        Map<String, List<SObject>> childDataByRelationship
    ) {
        if (childRelationships == null || childRelationships.isEmpty()) {
            return '';
        }

        List<String> childSections = new List<String>();

        // Format subquery results (from parent query)
        for (SchemaHelper.ChildRelationship rel : childRelationships) {
            if (String.isBlank(rel.relationshipName)) {
                continue;
            }

            List<SObject> allChildRecords = new List<SObject>();

            // Collect child records from all parent records
            for (SObject parent : sampleRecords) {
                try {
                    List<SObject> childRecords = parent.getSObjects(rel.relationshipName);
                    if (childRecords != null && !childRecords.isEmpty()) {
                        allChildRecords.addAll(childRecords);
                    }
                } catch (Exception e) {
                    // Relationship might not be in query or not accessible
                }
            }

            // Also check separately queried data
            if (childDataByRelationship.containsKey(rel.relationshipName)) {
                allChildRecords.addAll(childDataByRelationship.get(rel.relationshipName));
            }

            // Format as table if we have records
            if (!allChildRecords.isEmpty()) {
                String tableSection = formatChildRecordsAsTable(
                    rel.childObject,
                    rel.relationshipName,
                    allChildRecords
                );
                if (String.isNotBlank(tableSection)) {
                    childSections.add(tableSection);
                }
            }
        }

        if (childSections.isEmpty()) {
            return '';
        }

        return '### Related Records\n\n' + String.join(childSections, '\n\n');
    }

    /**
     * @description Formats child records as a markdown table
     * @param childObjectName Name of child object
     * @param relationshipName Relationship name
     * @param childRecords Child records to format
     * @return Formatted markdown table
     */
    private static String formatChildRecordsAsTable(
        String childObjectName,
        String relationshipName,
        List<SObject> childRecords
    ) {
        if (childRecords == null || childRecords.isEmpty()) {
            return '';
        }

        String header = '#### ' + childObjectName + ' (' + childRecords.size() + ' records)\n\n';

        // Simple list format (more readable than tables for AI)
        List<String> recordLines = new List<String>();
        for (SObject child : childRecords) {
            try {
                String name = child.get('Name') != null ? String.valueOf(child.get('Name')) : 'Unnamed';
                String id = child.get('Id') != null ? String.valueOf(child.get('Id')) : '';
                recordLines.add('- ' + name + (String.isNotBlank(id) ? ' (' + id.substring(0, 8) + ')' : ''));
            } catch (Exception e) {
                // Skip if can't access fields
            }
        }

        if (recordLines.isEmpty()) {
            return '';
        }

        return header + String.join(recordLines, '\n');
    }

    /**
     * @description Deploy approved prompt to DCM and Prompt records
     * Phase 3: Creates production-ready prompt configuration
     *
     * @param sessionId ID of the PF_Run__c session record
     * @param promptName Name for the prompt
     * @return Map containing success status, DCM ID, and Prompt ID
     */
    @AuraEnabled
    public static Map<String, Object> deployPrompt(Id sessionId, String promptName) {
        try {
            // Load session
            PF_Run__c session = [
                SELECT Id, Root_Object__c, Business_Context__c, Sample_Record_Id__c,
                       Current_Draft__c, Status__c
                FROM PF_Run__c
                WHERE Id = :sessionId
                LIMIT 1
            ];

            // Validate that there's an approved draft
            if (String.isBlank(session.Current_Draft__c)) {
                throw new AuraHandledException('No draft available to deploy. Please generate analysis first.');
            }

            // Get sample record IDs to determine which fields were used
            List<String> recordIds = session.Sample_Record_Id__c.split(',');
            List<Id> sampleRecordIds = new List<Id>();
            for (String recordId : recordIds) {
                sampleRecordIds.add((Id)recordId.trim());
            }

            // Query fields again to build DCM
            List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields(session.Root_Object__c);
            List<String> fieldNames = getQueryableFieldNames(fields);

            // Build DCM Config
            DCMBuilder.DCMConfig dcmConfig = new DCMBuilder.DCMConfig();
            dcmConfig.name = promptName + ' - Data Mapping';
            dcmConfig.rootObject = session.Root_Object__c;

            // Add root object fields (limit to key fields to keep it manageable)
            List<String> keyFields = getKeyFields(session.Root_Object__c, fieldNames);
            dcmConfig.fieldsByObject.put(session.Root_Object__c, keyFields);

            // Create DCM
            Id dcmId = DCMBuilder.createDCM(dcmConfig);

            // Build Prompt Config
            PromptBuilder.PromptConfig promptConfig = new PromptBuilder.PromptConfig();
            promptConfig.name = promptName;
            promptConfig.label = promptName;

            // Generate description and how-it-works using LLM
            Map<String, String> promptMetadata = generatePromptMetadata(
                promptName,
                session.Business_Context__c,
                session.Root_Object__c,
                session.Current_Draft__c
            );
            promptConfig.description = promptMetadata.get('description');
            promptConfig.howItWorks = promptMetadata.get('howItWorks');
            promptConfig.dcmId = dcmId;
            promptConfig.targetObject = session.Root_Object__c;
            promptConfig.promptType = 'Text';
            promptConfig.maxTokens = 4096;
            promptConfig.temperature = 1.0;
            promptConfig.autoActivate = false;

            // Build prompt command - use system prompt + analysis instructions
            // Note: Current_Draft__c was used for interactive iteration but should NOT be
            // included in the deployed prompt (it contains sample-specific analysis)
            Map<String, String> exemplars = loadExemplars();
            String systemPrompt = exemplars.get('SYSTEM_PROMPT');

            // Build clean prompt command with just instructions
            promptConfig.promptCommand = systemPrompt + '\n\n---\n\n' +
                '## CONTEXT\n\n' +
                'Business Objective: ' + session.Business_Context__c + '\n\n' +
                '## INSTRUCTIONS\n\n' +
                'Analyze the ' + session.Root_Object__c + ' record data provided below. ' +
                'Apply the quality rubric above, perform your self-evaluation, and generate ' +
                'an executive-ready analysis with actionable insights.\n\n' +
                'Focus on:\n' +
                '- Deal/account health assessment with specific scores\n' +
                '- Key risks with severity ratings and mitigation actions\n' +
                '- Stakeholder analysis and engagement gaps\n' +
                '- Prioritized next steps with specific dates and owners\n\n' +
                'Remember: Every insight must be grounded in the actual data provided.';

            // For text/markdown analysis prompts, we don't need an HTML template
            // GPTfy will display the AI's markdown response directly
            // HTML templates with {{{MergeField}}} syntax are used for visual dashboards, not text analysis
            promptConfig.htmlTemplate = null;

            // Create Prompt
            Id promptId = PromptBuilder.createPrompt(promptConfig);

            // Update session status
            session.Status__c = 'Completed';
            session.Created_DCM_Id__c = dcmId;
            session.Created_Prompt_Id__c = promptId;
            update session;

            // Build response
            Map<String, Object> response = new Map<String, Object>{
                'success' => true,
                'dcmId' => dcmId,
                'promptId' => promptId,
                'message' => 'Prompt deployed successfully! You can now test it in GPTfy.'
            };

            return response;

        } catch (Exception e) {
            throw new AuraHandledException('Error deploying prompt: ' + e.getMessage());
        }
    }

    /**
     * @description Generates prompt metadata (description and how-it-works) using LLM
     * @param promptName Name of the prompt
     * @param businessContext Original business context from user
     * @param rootObject Root object being analyzed
     * @param currentDraft The approved AI analysis draft
     * @return Map with 'description' (<255 chars) and 'howItWorks' (detailed)
     */
    private static Map<String, String> generatePromptMetadata(
        String promptName,
        String businessContext,
        String rootObject,
        String currentDraft
    ) {
        Map<String, String> result = new Map<String, String>();

        // Build prompt for LLM to generate metadata
        String systemPrompt = 'You are a technical writer creating documentation for an AI prompt. ' +
            'You must respond ONLY with valid JSON, no other text.';

        String userPrompt = 'Create metadata for an AI prompt with these details:\n\n' +
            'Prompt Name: ' + promptName + '\n' +
            'Target Object: ' + rootObject + '\n' +
            'Business Context: ' + businessContext + '\n\n' +
            'Based on this context, generate:\n' +
            '1. A concise description (MUST be under 250 characters) that summarizes what this prompt does\n' +
            '2. A detailed "How it Works" explanation (can be longer, use HTML formatting)\n\n' +
            'Respond with ONLY this JSON format, no markdown code blocks:\n' +
            '{"description": "your concise description here", "howItWorks": "<p>Your detailed HTML explanation here</p>"}';

        try {
            // Call AI to generate metadata
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(
                systemPrompt,
                userPrompt,
                1024,
                0.7
            );

            if (aiResponse.success && String.isNotBlank(aiResponse.content)) {
                // Parse JSON response
                String jsonContent = aiResponse.content.trim();
                // Remove markdown code blocks if present
                if (jsonContent.startsWith('```')) {
                    jsonContent = jsonContent.replaceAll('```json\\s*', '').replaceAll('```\\s*$', '');
                }

                Map<String, Object> parsed = (Map<String, Object>)JSON.deserializeUntyped(jsonContent);

                String description = (String)parsed.get('description');
                String howItWorks = (String)parsed.get('howItWorks');

                // Ensure description is under 255 chars
                if (description != null && description.length() > 255) {
                    description = description.substring(0, 252) + '...';
                }

                result.put('description', description);
                result.put('howItWorks', howItWorks);
                return result;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to generate prompt metadata via LLM: ' + e.getMessage());
        }

        // Fallback: truncate business context for description, use it as-is for howItWorks
        String fallbackDesc = businessContext;
        if (fallbackDesc != null && fallbackDesc.length() > 255) {
            fallbackDesc = fallbackDesc.substring(0, 252) + '...';
        }
        result.put('description', fallbackDesc);
        result.put('howItWorks', '<p>' + businessContext + '</p>');
        return result;
    }

    /**
     * @description Gets key fields for an object (Name, common fields, custom fields)
     * @param objectName API name of the object
     * @param allFields List of all field names
     * @return List of key field names
     */
    private static List<String> getKeyFields(String objectName, List<String> allFields) {
        Set<String> keyFieldSet = new Set<String>();

        // Always include these if they exist
        Set<String> commonFields = new Set<String>{
            'Id', 'Name', 'OwnerId', 'CreatedDate', 'LastModifiedDate',
            'Amount', 'StageName', 'CloseDate', 'Probability', // Opportunity
            'Industry', 'AnnualRevenue', 'NumberOfEmployees', // Account
            'Status', 'Priority', 'Subject', 'Origin', // Case
            'Email', 'Phone', 'Title', 'Department' // Contact/Lead
        };

        for (String field : allFields) {
            // Include common fields
            if (commonFields.contains(field)) {
                keyFieldSet.add(field);
            }
            // Include all custom fields
            else if (field.endsWith('__c')) {
                keyFieldSet.add(field);
            }
        }

        return new List<String>(keyFieldSet);
    }

    /**
     * @description Builds SOQL query with child relationship subqueries
     * @param rootObject Root object name
     * @param fieldNames Root object field names
     * @param childRelationships Child relationships to include
     * @return SOQL query string (without WHERE clause)
     */
    private static String buildSOQLWithChildren(
        String rootObject,
        List<String> fieldNames,
        List<SchemaHelper.ChildRelationship> childRelationships
    ) {
        String baseQuery = 'SELECT ' + String.join(fieldNames, ', ');

        // Add child relationship subqueries (limit to 3 to avoid query complexity)
        Integer subqueryCount = 0;
        for (SchemaHelper.ChildRelationship rel : childRelationships) {
            if (subqueryCount >= 3) {
                break; // SOQL limit: max 3 levels of subqueries
            }

            // Only add if relationship name exists
            if (String.isNotBlank(rel.relationshipName)) {
                // Query Id and Name (or other key fields) from child objects
                baseQuery += ', (SELECT Id, Name FROM ' + rel.relationshipName + ' LIMIT 10)';
                subqueryCount++;
            }
        }

        baseQuery += ' FROM ' + rootObject;
        return baseQuery;
    }

    /**
     * @description Queries child object data for all sample records
     * Used for relationships that couldn't fit in the parent query
     *
     * @param sampleRecordIds Parent record IDs
     * @param childRelationships Child relationships to query
     * @return Map of relationship name to child records
     */
    private static Map<String, List<SObject>> queryChildData(
        List<Id> sampleRecordIds,
        List<SchemaHelper.ChildRelationship> childRelationships
    ) {
        Map<String, List<SObject>> childDataMap = new Map<String, List<SObject>>();

        // Query each child object separately (for relationships not in parent query)
        Integer queryCount = 0;
        for (SchemaHelper.ChildRelationship rel : childRelationships) {
            // Skip first 3 (already in parent query)
            if (queryCount < 3) {
                queryCount++;
                continue;
            }

            try {
                String childSOQL = 'SELECT Id, Name, ' + rel.field +
                                  ' FROM ' + rel.childObject +
                                  ' WHERE ' + rel.field + ' IN :sampleRecordIds' +
                                  ' LIMIT 50';

                List<SObject> childRecords = Database.query(childSOQL);
                if (!childRecords.isEmpty()) {
                    childDataMap.put(rel.relationshipName, childRecords);
                }
            } catch (Exception e) {
                // Skip if query fails (field might not be accessible)
                System.debug('Error querying child object ' + rel.childObject + ': ' + e.getMessage());
            }

            queryCount++;
            if (queryCount >= 5) {
                break; // Limit total child queries to avoid governor limits
            }
        }

        return childDataMap;
    }

    /**
     * @description Selects the most important child relationships for a given object
     * Prioritizes relationships that provide business context
     *
     * @param allRelationships All child relationships for the object
     * @param rootObject Root object name
     * @return List of top 3-5 most important relationships
     */
    private static List<SchemaHelper.ChildRelationship> selectImportantRelationships(
        List<SchemaHelper.ChildRelationship> allRelationships,
        String rootObject
    ) {
        if (allRelationships == null || allRelationships.isEmpty()) {
            return new List<SchemaHelper.ChildRelationship>();
        }

        // Define priority child objects per root object
        Map<String, Set<String>> priorityMap = new Map<String, Set<String>>{
            'Account' => new Set<String>{
                'Opportunity', 'Contact', 'Case', 'Task', 'Event'
            },
            'Opportunity' => new Set<String>{
                'OpportunityLineItem', 'OpportunityContactRole', 'Task', 'Event', 'Note'
            },
            'Case' => new Set<String>{
                'CaseComment', 'Task', 'Attachment', 'EmailMessage'
            },
            'Lead' => new Set<String>{
                'Task', 'Event', 'LeadHistory'
            },
            'Contact' => new Set<String>{
                'Task', 'Event', 'Opportunity', 'Case'
            }
        };

        Set<String> priorityObjects = priorityMap.get(rootObject);
        if (priorityObjects == null) {
            priorityObjects = new Set<String>();
        }

        List<SchemaHelper.ChildRelationship> prioritized = new List<SchemaHelper.ChildRelationship>();
        List<SchemaHelper.ChildRelationship> others = new List<SchemaHelper.ChildRelationship>();

        // Separate priority relationships from others
        for (SchemaHelper.ChildRelationship rel : allRelationships) {
            // Skip system objects and history/share objects
            if (rel.childObject.endsWith('History') ||
                rel.childObject.endsWith('Share') ||
                rel.childObject.endsWith('Feed') ||
                rel.childObject == 'Attachment' ||
                rel.childObject == 'Note') {
                continue;
            }

            if (priorityObjects.contains(rel.childObject)) {
                prioritized.add(rel);
            } else {
                others.add(rel);
            }
        }

        // Return top 5: prioritized first, then others (custom objects)
        List<SchemaHelper.ChildRelationship> result = new List<SchemaHelper.ChildRelationship>();
        result.addAll(prioritized);

        // Add custom child objects if we have room
        for (SchemaHelper.ChildRelationship rel : others) {
            if (result.size() >= 5) {
                break;
            }
            if (rel.childObject.endsWith('__c')) {
                result.add(rel);
            }
        }

        return result;
    }

    /**
     * Convert approved markdown to GPTfy-compliant HTML
     * Phase 3b: HTML Conversion (Task 21)
     *
     * @param approvedMarkdown The final approved markdown from chat phase
     * @param rootObject The root Salesforce object
     * @param fieldWhitelist Set of allowed merge fields (e.g., "Amount", "Account.Name")
     * @return GPTfy-compliant HTML template with merge fields
     */
    public static String convertToHTML(
        String approvedMarkdown,
        String rootObject,
        Set<String> fieldWhitelist
    ) {
        // Build conversion prompt
        String conversionPrompt = buildHTMLConversionPrompt(
            approvedMarkdown,
            rootObject,
            fieldWhitelist
        );

        // Call AI for HTML conversion
        AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(
            null, // No system prompt needed - instructions in user prompt
            conversionPrompt,
            8192, // Max tokens for HTML output
            0.3   // Lower temperature for more consistent formatting
        );

        if (aiResponse == null || String.isBlank(aiResponse.content)) {
            throw new GPTfyException('Failed to convert markdown to HTML');
        }

        String htmlTemplate = aiResponse.content.trim();

        // Remove markdown code fences if present
        if (htmlTemplate.startsWith('```html')) {
            htmlTemplate = htmlTemplate.substring(7);
        } else if (htmlTemplate.startsWith('```')) {
            htmlTemplate = htmlTemplate.substring(3);
        }
        if (htmlTemplate.endsWith('```')) {
            htmlTemplate = htmlTemplate.substring(0, htmlTemplate.length() - 3);
        }
        htmlTemplate = htmlTemplate.trim();

        // Validate HTML safety
        List<String> safetyIssues = validateHTMLSafety(htmlTemplate);
        if (!safetyIssues.isEmpty()) {
            System.debug('HTML safety issues detected: ' + safetyIssues);
            htmlTemplate = sanitizeHTML(htmlTemplate);
        }

        return htmlTemplate;
    }

    /**
     * Build the HTML conversion prompt with GPTfy requirements
     */
    private static String buildHTMLConversionPrompt(
        String approvedMarkdown,
        String rootObject,
        Set<String> fieldWhitelist
    ) {
        String prompt = '';

        prompt += 'You are converting approved analysis content into a GPTfy-compatible HTML template.\n\n';

        prompt += '=== APPROVED CONTENT (Markdown) ===\n';
        prompt += approvedMarkdown + '\n\n';

        prompt += '=== FIELD WHITELIST (Only these fields are available) ===\n';
        if (fieldWhitelist != null && !fieldWhitelist.isEmpty()) {
            List<String> sortedFields = new List<String>(fieldWhitelist);
            sortedFields.sort();
            for (String field : sortedFields) {
                prompt += '- ' + field + '\n';
            }
        }
        prompt += '\n';

        prompt += '=== GPTfy HTML REQUIREMENTS ===\n';
        prompt += '1. Output as ONE continuous line - NO line breaks\n';
        prompt += '2. Use ONLY inline styles (style="...") - NO class="..." attributes\n';
        prompt += '3. NO <style> blocks or CSS classes\n';
        prompt += '4. NO <script> tags or event handlers\n';
        prompt += '5. Start with <div style=" and end with </div>\n\n';

        prompt += '=== MERGE FIELD SYNTAX ===\n';
        prompt += '- Root object fields: {{{FieldName}}}\n';
        prompt += '- Lookup fields: {{{Relationship.FieldName}}}\n';
        prompt += '- Child collections: {{#ChildCollection}}...{{/ChildCollection}}\n';
        prompt += '- Empty check: {{^ChildCollection}}No items{{/ChildCollection}}\n\n';

        prompt += '=== INLINE STYLE PATTERNS (Salesforce Brand) ===\n';
        prompt += Stage07_TemplateDesign.getStylePatternsPrompt() + '\n';

        prompt += '=== COLOR SCHEME ===\n';
        prompt += Stage07_TemplateDesign.getColorSchemePrompt() + '\n';

        prompt += 'TASK:\n';
        prompt += 'Convert the approved markdown content into a single-line HTML template.\n';
        prompt += 'Replace specific data values with appropriate merge fields from the whitelist.\n';
        prompt += 'Use the style patterns and colors provided.\n\n';

        prompt += 'Output ONLY raw HTML starting with <div - no explanation:';

        return prompt;
    }

    /**
     * Validate HTML safety (no scripts, single line, etc.)
     */
    private static List<String> validateHTMLSafety(String html) {
        List<String> issues = new List<String>();

        if (String.isBlank(html)) {
            issues.add('HTML is empty');
            return issues;
        }

        String htmlLower = html.toLowerCase();

        // Check for disallowed tags
        if (htmlLower.contains('<script')) {
            issues.add('Contains <script> tag');
        }
        if (htmlLower.contains('<style')) {
            issues.add('Contains <style> tag');
        }
        if (htmlLower.contains('javascript:')) {
            issues.add('Contains javascript: protocol');
        }
        if (htmlLower.contains('onerror=') || htmlLower.contains('onclick=') || htmlLower.contains('onload=')) {
            issues.add('Contains event handler attributes');
        }

        // Check for CSS classes (should use inline styles only)
        if (html.contains('class="')) {
            issues.add('Contains class attributes (use inline styles)');
        }

        // Check for newlines (GPTfy requires single line)
        if (html.contains('\n') || html.contains('\r')) {
            issues.add('Contains line breaks (must be single line)');
        }

        return issues;
    }

    /**
     * Sanitize HTML by removing disallowed elements
     */
    private static String sanitizeHTML(String html) {
        if (String.isBlank(html)) {
            return html;
        }

        String sanitized = html;

        // Remove script tags
        sanitized = sanitized.replaceAll('(?i)<script[^>]*>.*?</script>', '');

        // Remove style tags
        sanitized = sanitized.replaceAll('(?i)<style[^>]*>.*?</style>', '');

        // Remove event handlers
        sanitized = sanitized.replaceAll('(?i)\\s+on\\w+\\s*=\\s*["\'][^"\']*["\']', '');

        // Remove class attributes
        sanitized = sanitized.replaceAll('(?i)\\s+class\\s*=\\s*["\'][^"\']*["\']', '');

        // Remove newlines (convert to single line)
        sanitized = sanitized.replaceAll('\\r\\n|\\r|\\n', ' ');

        // Remove multiple spaces
        sanitized = sanitized.replaceAll('\\s+', ' ');

        // Trim
        sanitized = sanitized.trim();

        return sanitized;
    }
}
