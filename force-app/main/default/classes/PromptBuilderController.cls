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
}
