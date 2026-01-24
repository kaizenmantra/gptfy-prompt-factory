/**
 * @description REST API controller for Prompt Factory test harness
 * Exposes schema discovery and data retrieval endpoints for autonomous testing
 *
 * Endpoints:
 *   GET  /test-harness/schema/{objectName}     - Get fields, children, parent lookups
 *   GET  /test-harness/children/{objectName}   - Get child relationships
 *   GET  /test-harness/sample/{objectName}/{recordId} - Get sample record with children
 *   POST /test-harness/dcm-config              - Build DCM config from selections
 */
@RestResource(urlMapping='/test-harness/*')
global with sharing class TestHarnessController {

    /**
     * @description Handle GET requests
     * Routes based on URL path segments
     * Returns JSON string (REST methods must return primitive types)
     */
    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        Map<String, Object> result = new Map<String, Object>();

        try {
            // Parse URL path: /test-harness/{resource}/{param1}/{param2}
            String path = req.requestURI;
            List<String> segments = path.split('/');

            // segments: ['', 'services', 'apexrest', 'test-harness', 'resource', 'param1', ...]
            // Find index of 'test-harness' and work from there
            Integer baseIndex = -1;
            for (Integer i = 0; i < segments.size(); i++) {
                if (segments[i] == 'test-harness') {
                    baseIndex = i;
                    break;
                }
            }

            if (baseIndex == -1 || baseIndex + 1 >= segments.size()) {
                result.put('error', 'Invalid path. Use /test-harness/{resource}/{params}');
                res.statusCode = 400;
                return JSON.serialize(result);
            }

            String resource = segments[baseIndex + 1];
            String param1 = segments.size() > baseIndex + 2 ? segments[baseIndex + 2] : null;
            String param2 = segments.size() > baseIndex + 3 ? segments[baseIndex + 3] : null;

            // Route to appropriate handler
            if (resource == 'schema' && param1 != null) {
                result = getSchema(param1);
            } else if (resource == 'children' && param1 != null) {
                result = getChildren(param1);
            } else if (resource == 'grandchildren' && param1 != null) {
                result = getGrandchildren(param1, req.params.get('childObjects'));
            } else if (resource == 'sample' && param1 != null && param2 != null) {
                result = getSampleRecord(param1, param2);
            } else if (resource == 'example-prompts') {
                result = getExamplePrompts();
            } else {
                result.put('error', 'Unknown resource: ' + resource);
                result.put('availableResources', new List<String>{
                    'GET /test-harness/schema/{objectName}',
                    'GET /test-harness/children/{objectName}',
                    'GET /test-harness/grandchildren/{objectName}?childObjects=Obj1,Obj2',
                    'GET /test-harness/sample/{objectName}/{recordId}',
                    'GET /test-harness/example-prompts',
                    'POST /test-harness/dcm-config'
                });
                res.statusCode = 400;
            }
        } catch (Exception e) {
            result.put('error', e.getMessage());
            result.put('stackTrace', e.getStackTraceString());
            res.statusCode = 500;
        }

        return JSON.serialize(result);
    }

    /**
     * @description Handle POST requests
     * Returns JSON string (REST methods must return primitive types)
     */
    @HttpPost
    global static String doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        Map<String, Object> result = new Map<String, Object>();

        try {
            String path = req.requestURI;

            if (path.contains('dcm-config')) {
                // Parse request body
                String body = req.requestBody.toString();
                Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(body);
                result = buildDCMConfig(params);
            } else {
                result.put('error', 'Unknown POST endpoint');
                res.statusCode = 400;
            }
        } catch (Exception e) {
            result.put('error', e.getMessage());
            result.put('stackTrace', e.getStackTraceString());
            res.statusCode = 500;
        }

        return JSON.serialize(result);
    }

    /**
     * @description Get schema information for an object
     * Returns fields, child relationships, and parent lookup suggestions
     */
    private static Map<String, Object> getSchema(String objectName) {
        Map<String, Object> result = new Map<String, Object>();

        // Get fields
        List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields(objectName);
        List<Map<String, Object>> fieldList = new List<Map<String, Object>>();
        for (SchemaHelper.FieldMetadata f : fields) {
            fieldList.add(new Map<String, Object>{
                'name' => f.name,
                'label' => f.label,
                'type' => f.type,
                'isCustom' => f.isCustom
            });
        }
        result.put('fields', fieldList);

        // Get child relationships
        List<SchemaHelper.ChildRelationship> children = SchemaHelper.getChildRelationships(objectName);
        List<Map<String, Object>> childList = new List<Map<String, Object>>();
        for (SchemaHelper.ChildRelationship c : children) {
            childList.add(new Map<String, Object>{
                'childObject' => c.childObject,
                'relationshipName' => c.relationshipName,
                'field' => c.field
            });
        }
        result.put('childRelationships', childList);

        // Get parent lookups (lookup fields on this object)
        List<Map<String, Object>> parentLookups = getParentLookups(objectName);
        result.put('parentLookups', parentLookups);

        result.put('objectName', objectName);
        result.put('isAccessible', SchemaHelper.isObjectAccessible(objectName));

        return result;
    }

    /**
     * @description Get child relationships for an object
     */
    private static Map<String, Object> getChildren(String objectName) {
        Map<String, Object> result = new Map<String, Object>();

        List<SchemaHelper.ChildRelationship> children = SchemaHelper.getChildRelationships(objectName);
        List<Map<String, Object>> childList = new List<Map<String, Object>>();

        for (SchemaHelper.ChildRelationship c : children) {
            // Get field count for each child object
            List<SchemaHelper.FieldMetadata> childFields = SchemaHelper.getFields(c.childObject);

            childList.add(new Map<String, Object>{
                'childObject' => c.childObject,
                'relationshipName' => c.relationshipName,
                'field' => c.field,
                'fieldCount' => childFields.size()
            });
        }

        result.put('objectName', objectName);
        result.put('children', childList);
        result.put('childCount', childList.size());

        return result;
    }

    /**
     * @description Get grandchild relationships (children of children)
     */
    private static Map<String, Object> getGrandchildren(String objectName, String childObjectsParam) {
        Map<String, Object> result = new Map<String, Object>();

        List<String> childObjects = new List<String>();
        if (String.isNotBlank(childObjectsParam)) {
            childObjects = childObjectsParam.split(',');
        }

        Map<String, List<SchemaHelper.ChildRelationship>> grandchildMap =
            SchemaHelper.discoverGrandchildRelationships(objectName, childObjects);

        Map<String, Object> formattedMap = new Map<String, Object>();
        for (String childObj : grandchildMap.keySet()) {
            List<Map<String, Object>> gcList = new List<Map<String, Object>>();
            for (SchemaHelper.ChildRelationship gc : grandchildMap.get(childObj)) {
                gcList.add(new Map<String, Object>{
                    'childObject' => gc.childObject,
                    'relationshipName' => gc.relationshipName,
                    'field' => gc.field
                });
            }
            formattedMap.put(childObj, gcList);
        }

        result.put('rootObject', objectName);
        result.put('grandchildren', formattedMap);

        return result;
    }

    /**
     * @description Get a sample record with related child data
     */
    private static Map<String, Object> getSampleRecord(String objectName, String recordId) {
        Map<String, Object> result = new Map<String, Object>();

        // Get fields for root object
        List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields(objectName);
        List<String> fieldNames = new List<String>();
        for (SchemaHelper.FieldMetadata f : fields) {
            fieldNames.add(f.name);
        }

        // Build and execute query
        String query = 'SELECT ' + String.join(fieldNames, ', ') +
                       ' FROM ' + objectName +
                       ' WHERE Id = :recordId LIMIT 1';

        List<SObject> records = Database.query(query);
        if (records.isEmpty()) {
            result.put('error', 'Record not found: ' + recordId);
            return result;
        }

        SObject record = records[0];
        Map<String, Object> recordData = new Map<String, Object>();
        for (String fieldName : fieldNames) {
            recordData.put(fieldName, record.get(fieldName));
        }
        result.put('record', recordData);

        // Get child records (first 5 of each type)
        List<SchemaHelper.ChildRelationship> children = SchemaHelper.getChildRelationships(objectName);
        Map<String, Object> childData = new Map<String, Object>();

        for (SchemaHelper.ChildRelationship child : children) {
            try {
                // Get fields for child object
                List<SchemaHelper.FieldMetadata> childFields = SchemaHelper.getFields(child.childObject);
                Set<String> safeFields = SchemaHelper.getSafeQueryableFields(child.childObject);

                List<String> childFieldNames = new List<String>();
                for (SchemaHelper.FieldMetadata f : childFields) {
                    // Only include queryable fields
                    if (safeFields.isEmpty() || safeFields.contains(f.name)) {
                        childFieldNames.add(f.name);
                    }
                }

                if (childFieldNames.isEmpty()) {
                    continue;
                }

                // Query child records
                String childQuery = 'SELECT ' + String.join(childFieldNames, ', ') +
                                   ' FROM ' + child.childObject +
                                   ' WHERE ' + child.field + ' = :recordId' +
                                   ' ORDER BY CreatedDate DESC LIMIT 5';

                List<SObject> childRecords = Database.query(childQuery);
                List<Map<String, Object>> childList = new List<Map<String, Object>>();

                for (SObject childRec : childRecords) {
                    Map<String, Object> childRecData = new Map<String, Object>();
                    for (String fieldName : childFieldNames) {
                        childRecData.put(fieldName, childRec.get(fieldName));
                    }
                    childList.add(childRecData);
                }

                if (!childList.isEmpty()) {
                    childData.put(child.relationshipName, new Map<String, Object>{
                        'objectName' => child.childObject,
                        'records' => childList,
                        'count' => childList.size()
                    });
                }
            } catch (Exception e) {
                // Skip objects we can't query
                continue;
            }
        }

        result.put('children', childData);
        result.put('objectName', objectName);
        result.put('recordId', recordId);

        return result;
    }

    /**
     * @description Get example prompts from the org
     * Returns prompts that can be used as few-shot examples
     */
    private static Map<String, Object> getExamplePrompts() {
        Map<String, Object> result = new Map<String, Object>();

        // Query AI Prompt records that have good example content
        // Note: ccai__Prompt_Command__c is a long text area and cannot be filtered
        List<ccai__AI_Prompt__c> prompts = [
            SELECT Id, Name, ccai__Prompt_Command__c, ccai__Object__c, ccai__Type__c
            FROM ccai__AI_Prompt__c
            WHERE ccai__Status__c = 'Active'
              AND (Name LIKE '%360%' OR Name LIKE '%Dashboard%' OR Name LIKE '%Analysis%')
            ORDER BY LastModifiedDate DESC
            LIMIT 10
        ];

        List<Map<String, Object>> promptList = new List<Map<String, Object>>();
        for (ccai__AI_Prompt__c p : prompts) {
            promptList.add(new Map<String, Object>{
                'id' => p.Id,
                'name' => p.Name,
                'promptCommand' => p.ccai__Prompt_Command__c,
                'objectName' => p.ccai__Object__c,
                'type' => p.ccai__Type__c
            });
        }

        result.put('prompts', promptList);
        result.put('count', promptList.size());

        return result;
    }

    /**
     * @description Build DCM configuration from selected objects and fields
     */
    private static Map<String, Object> buildDCMConfig(Map<String, Object> params) {
        Map<String, Object> result = new Map<String, Object>();

        String rootObject = (String) params.get('rootObject');
        Map<String, Object> selectedFields = (Map<String, Object>) params.get('selectedFields');
        List<Object> selectedChildren = (List<Object>) params.get('selectedChildren');

        // Build DCM config structure
        Map<String, Object> dcmConfig = new Map<String, Object>();
        dcmConfig.put('rootObject', rootObject);
        dcmConfig.put('fields', selectedFields);

        // Process children
        List<Map<String, Object>> childConfigs = new List<Map<String, Object>>();
        if (selectedChildren != null) {
            for (Object childObj : selectedChildren) {
                Map<String, Object> child = (Map<String, Object>) childObj;
                childConfigs.add(new Map<String, Object>{
                    'objectName' => child.get('objectName'),
                    'relationshipName' => child.get('relationshipName'),
                    'fields' => child.get('fields')
                });
            }
        }
        dcmConfig.put('children', childConfigs);

        result.put('dcmConfig', dcmConfig);
        result.put('valid', true);

        return result;
    }

    /**
     * @description Get parent lookup fields for an object
     */
    private static List<Map<String, Object>> getParentLookups(String objectName) {
        List<Map<String, Object>> lookups = new List<Map<String, Object>>();

        Schema.DescribeSObjectResult objDescribe = SchemaHelper.getObjectDescribe(objectName);
        if (objDescribe == null) {
            return lookups;
        }

        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            // Check if this is a lookup or master-detail field
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
                if (!referenceTo.isEmpty()) {
                    String parentObject = referenceTo[0].getDescribe().getName();
                    String relationshipName = fieldDescribe.getRelationshipName();

                    // Skip polymorphic lookups and system relationships
                    if (relationshipName != null && !isSystemRelationship(relationshipName)) {
                        lookups.add(new Map<String, Object>{
                            'fieldName' => fieldDescribe.getName(),
                            'relationshipName' => relationshipName,
                            'parentObject' => parentObject,
                            'label' => fieldDescribe.getLabel()
                        });
                    }
                }
            }
        }

        return lookups;
    }

    /**
     * @description Check if a relationship name is a system relationship to skip
     */
    private static Boolean isSystemRelationship(String relationshipName) {
        Set<String> systemRelationships = new Set<String>{
            'CreatedBy', 'LastModifiedBy', 'RecordType'
        };
        return systemRelationships.contains(relationshipName);
    }
}
