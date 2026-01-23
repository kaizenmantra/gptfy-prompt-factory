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
            List<SchemaHelper.ChildRelationship> childRelationships = SchemaHelper.getChildRelationships(rootObject);

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
            String soql = 'SELECT ' + String.join(fieldNames, ', ') +
                         ' FROM ' + session.Root_Object__c +
                         ' WHERE Id IN :sampleRecordIds';
            List<SObject> sampleRecords = Database.query(soql);

            // Determine if this is first message or follow-up
            Boolean isFirstMessage = String.isBlank(userMessage) || userMessage.equals('START');
            String previousDraft = session.Current_Draft__c;

            // Build user prompt
            String userPrompt = buildUserPrompt(
                session.Root_Object__c,
                session.Business_Context__c,
                sampleRecords,
                fieldNames,
                exemplars,
                userMessage,
                previousDraft,
                isFirstMessage
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
        Boolean isFirstMessage
    ) {
        // Select relevant exemplar
        String relevantExemplar = selectExemplar(rootObject, exemplars);

        // Format sample data
        String formattedData = formatSampleData(sampleRecords, fieldNames, rootObject);

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
            promptConfig.description = session.Business_Context__c;
            promptConfig.dcmId = dcmId;
            promptConfig.targetObject = session.Root_Object__c;
            promptConfig.promptType = 'Text';
            promptConfig.maxTokens = 4096;
            promptConfig.temperature = 1.0;
            promptConfig.autoActivate = false;

            // Build prompt command from the approved draft
            // Use the system prompt + structure from the draft
            Map<String, String> exemplars = loadExemplars();
            String systemPrompt = exemplars.get('SYSTEM_PROMPT');

            promptConfig.promptCommand = systemPrompt + '\n\n---\n\n' +
                'Generate an analysis following the structure below:\n\n' +
                session.Current_Draft__c;

            // Set HTML template for rendering the AI response
            // This template displays the AI response with proper formatting
            promptConfig.htmlTemplate = '<div class="ai-analysis-output">\n' +
                '  <style>\n' +
                '    .ai-analysis-output { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; }\n' +
                '    .ai-analysis-output h1, .ai-analysis-output h2, .ai-analysis-output h3 { margin-top: 1em; margin-bottom: 0.5em; }\n' +
                '    .ai-analysis-output ul, .ai-analysis-output ol { margin: 0.5em 0; padding-left: 1.5em; }\n' +
                '    .ai-analysis-output li { margin: 0.25em 0; }\n' +
                '    .ai-analysis-output strong { font-weight: 600; }\n' +
                '  </style>\n' +
                '  {!response}\n' +
                '</div>';

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
}
