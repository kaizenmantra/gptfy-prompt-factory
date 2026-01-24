/**
 * @description Builder class for creating Data Context Mapping (DCM) records
 * Handles creation of DCM, field records, and relationship details
 */
public with sharing class DCMBuilder {

    /**
     * @description Wrapper for DCM configuration
     */
    public class DCMConfig {
        @AuraEnabled public String name;
        @AuraEnabled public String rootObject;
        @AuraEnabled public List<ObjectConfig> childObjects;
        @AuraEnabled public Map<String, List<String>> fieldsByObject;

        public DCMConfig() {
            this.childObjects = new List<ObjectConfig>();
            this.fieldsByObject = new Map<String, List<String>>();
        }
    }

    /**
     * @description Wrapper for child object configuration
     */
    public class ObjectConfig {
        @AuraEnabled public String objectName;
        @AuraEnabled public String relationshipName;
        @AuraEnabled public String relationshipField;
        @AuraEnabled public String parentObject; // For grandchild support (2-level nesting)
        @AuraEnabled public Integer maxRecords;

        public ObjectConfig(String objectName, String relationshipName, String relationshipField) {
            this.objectName = objectName;
            this.relationshipName = relationshipName;
            this.relationshipField = relationshipField;
            this.maxRecords = 10; // Default
        }

        // Constructor for grandchild objects
        public ObjectConfig(String objectName, String relationshipName, String relationshipField, String parentObject) {
            this(objectName, relationshipName, relationshipField);
            this.parentObject = parentObject;
        }
    }

    /**
     * @description Result of relationship field detection
     */
    public class RelationshipDetectionResult {
        @AuraEnabled public String relationshipField;
        @AuraEnabled public String relationshipName;
        @AuraEnabled public Boolean isPolymorphic;
        @AuraEnabled public String detectionMethod;

        public RelationshipDetectionResult(String field, String name, Boolean poly, String method) {
            this.relationshipField = field;
            this.relationshipName = name;
            this.isPolymorphic = poly;
            this.detectionMethod = method;
        }
    }

    /**
     * @description Creates a complete DCM with all related records
     * @param config DCMConfig with all configuration details
     * @return ID of the created DCM record
     */
    public static Id createDCM(DCMConfig config) {
        // Redirect to the robust implementation
        return createDCMWithGrandchildren(config);
    }

    /**
     * @description Helper to create SObject instance by name
     */
    private static SObject newSObject(String objectName) {
        Schema.SObjectType t = Schema.getGlobalDescribe().get(objectName);
        if (t == null) throw new DCMBuilderException('Object type not found: ' + objectName);
        return t.newSObject();
    }

    /**
     * @description Creates an OBJECT type field record
     */
    private static SObject createObjectField(
        Id dcmId, String objectName, String label, Integer sequence) {

        SObject field = newSObject('ccai__AI_Data_Extraction_Field__c');
        field.put('ccai__AI_Data_Extraction_Mapping__c', dcmId);
        field.put('ccai__Type__c', 'OBJECT');
        field.put('ccai__Object__c', objectName);
        field.put('ccai__Field__c', objectName);
        field.put('ccai__Label__c', label);
        field.put('ccai__Send_To_AI__c', true);
        return field;
    }

    /**
     * @description Creates a FIELD type field record
     */
    private static SObject createFieldRecord(
        Id dcmId, String fieldName, String objectName, Integer sequence) {

        String fieldLabel = getFieldLabel(objectName, fieldName);

        SObject field = newSObject('ccai__AI_Data_Extraction_Field__c');
        field.put('ccai__AI_Data_Extraction_Mapping__c', dcmId);
        field.put('ccai__Type__c', 'FIELD');
        field.put('ccai__Field__c', fieldName);
        field.put('ccai__Object__c', objectName);
        field.put('ccai__Label__c', fieldLabel);
        field.put('ccai__Send_To_AI__c', true);
        field.put('ccai__Scan_for_PII__c', shouldMaskField(fieldName));
        return field;
    }

    /**
     * @description Gets the label for a field from schema
     */
    private static String getFieldLabel(String objectName, String fieldName) {
        try {
            Schema.DescribeSObjectResult objDescribe = SchemaHelper.getObjectDescribe(objectName);
            if (objDescribe != null) {
                Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    return fieldMap.get(fieldName.toLowerCase()).getDescribe().getLabel();
                }
            }
        } catch (Exception e) {
            // Fall through to return fieldName
        }
        return fieldName;
    }

    /**
     * @description Creates a detail record for child/grandchild relationship
     * Refactored to handle both child and grandchild via params
     */
    private static SObject createDetailRecordDynamic(
        Id dcmId, String childObject, String relationshipField, 
        String type, Integer maxRecords, Id parentDetailId) {

        SObject detail = newSObject('ccai__AI_Data_Extraction_Detail__c');
        detail.put('ccai__AI_Data_Extraction_Mapping__c', dcmId);
        detail.put('ccai__Object_Name__c', childObject);
        detail.put('ccai__RelationshipField__c', relationshipField);
        detail.put('ccai__RelationshipName__c', getRelationshipName(childObject));
        detail.put('ccai__Type__c', type);
        detail.put('ccai__Record_Limit__c', maxRecords);
        if (parentDetailId != null) {
            detail.put('ccai__Parent_Detail__c', parentDetailId);
        }
        return detail;
    }

    /**
     * @description Determines if a field should be masked (PII protection)
     */
    private static Boolean shouldMaskField(String fieldName) {
        String fieldLower = fieldName.toLowerCase();
        Set<String> piiKeywords = new Set<String>{
            'ssn', 'socialsecurity', 'creditcard', 'accountnumber',
            'bankaccount', 'password', 'secret', 'token'
        };
        for (String keyword : piiKeywords) {
            if (fieldLower.contains(keyword)) return true;
        }
        return false;
    }

    /**
     * @description Validates DCM configuration before creation
     */
    public static List<String> validateConfig(DCMConfig config) {
        // Redirect to schema validation
        return validateConfigWithSchema(config);
    }

    /**
     * @description Deletes a DCM using Dynamic SOQL/DML
     */
    public static void deleteDCM(Id dcmId) {
        try {
            String q = 'SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c WHERE Id = :dcmId';
            SObject dcm = Database.query(q);
            delete dcm;
        } catch (Exception e) {
            throw new DCMBuilderException('Failed to delete DCM: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Auto-detects the relationship field between parent and child objects
     */
    public static RelationshipDetectionResult detectRelationshipField(String childObject, String parentObject) {
        Schema.DescribeSObjectResult childDescribe = SchemaHelper.getObjectDescribe(childObject);
        if (childDescribe == null) {
            return null;
        }

        Map<String, Schema.SObjectField> fieldMap = childDescribe.fields.getMap();

        // Strategy 1: Look for standard relationship field pattern
        String standardFieldName = parentObject + 'Id';
        Schema.SObjectField standardField = fieldMap.containsKey(standardFieldName)
            ? fieldMap.get(standardFieldName)
            : (fieldMap.containsKey(standardFieldName.toLowerCase()) ? fieldMap.get(standardFieldName.toLowerCase()) : null);

        if (standardField != null) {
            Schema.DescribeFieldResult fieldDesc = standardField.getDescribe();
            if (fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                return new RelationshipDetectionResult(
                    fieldDesc.getName(),
                    getRelationshipName(childObject),
                    false,
                    'standard_pattern'
                );
            }
        }

        // Strategy 2: Check for polymorphic fields
        List<String> polymorphicFields = new List<String>{'WhatId', 'WhoId', 'ParentId', 'RelatedToId'};
        for (String polyField : polymorphicFields) {
            Schema.SObjectField poly = fieldMap.containsKey(polyField)
                ? fieldMap.get(polyField)
                : (fieldMap.containsKey(polyField.toLowerCase()) ? fieldMap.get(polyField.toLowerCase()) : null);

            if (poly != null) {
                Schema.DescribeFieldResult fieldDesc = poly.getDescribe();
                for (Schema.SObjectType refType : fieldDesc.getReferenceTo()) {
                    if (refType.getDescribe().getName() == parentObject) {
                        return new RelationshipDetectionResult(
                            fieldDesc.getName(),
                            getRelationshipName(childObject),
                            true,
                            'polymorphic_field'
                        );
                    }
                }
            }
        }

        // Strategy 3: Lookup scan
        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            if (fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                for (Schema.SObjectType refType : fieldDesc.getReferenceTo()) {
                    if (refType.getDescribe().getName() == parentObject) {
                        return new RelationshipDetectionResult(
                            fieldDesc.getName(),
                            getRelationshipName(childObject),
                            fieldDesc.getReferenceTo().size() > 1,
                            'lookup_scan'
                        );
                    }
                }
            }
        }

        return null;
    }

    /**
     * @description Gets the plural relationship name for a child object
     */
    public static String getRelationshipName(String objectName) {
        Map<String, String> irregularPlurals = new Map<String, String>{
            'Opportunity' => 'Opportunities',
            'Activity' => 'Activities',
            'Case' => 'Cases',
            'Address' => 'Addresses'
        };
        if (irregularPlurals.containsKey(objectName)) return irregularPlurals.get(objectName);
        if (objectName.endsWith('__c')) {
            return objectName.removeEnd('__c') + 's__r';
        }
        if (objectName.endsWith('y')) return objectName.removeEnd('y') + 'ies';
        if (objectName.endsWith('s') || objectName.endsWith('x') ||
            objectName.endsWith('ch') || objectName.endsWith('sh')) return objectName + 'es';
        return objectName + 's';
    }

    /**
     * @description Creates DCM with two-phase approach for grandchild support
     * Uses Dynamic DML to avoid dependency on managed package types
     */
    public static Id createDCMWithGrandchildren(DCMConfig config) {
        try {
            List<String> errors = validateConfigWithSchema(config);
            if (!errors.isEmpty()) {
                throw new DCMBuilderException('DCM validation failed: ' + String.join(errors, '; '));
            }

            // Create DCM root record
            SObject dcm = newSObject('ccai__AI_Data_Extraction_Mapping__c');
            dcm.put('Name', config.name);
            dcm.put('ccai__Object_Name__c', config.rootObject);
            dcm.put('ccai__Status__c', 'Active');
            dcm.put('ccai__External_Id__c', String.valueOf(System.now().getTime()));
            insert dcm;

            List<SObject> fieldsToInsert = new List<SObject>();
            List<SObject> detailsToInsert = new List<SObject>();

            // Add root object
            fieldsToInsert.add(createObjectField(dcm.Id, config.rootObject, config.rootObject, 1));

            // Add root object fields
            if (config.fieldsByObject.containsKey(config.rootObject)) {
                Integer sequence = 1;
                for (String fieldName : config.fieldsByObject.get(config.rootObject)) {
                    fieldsToInsert.add(createFieldRecord(dcm.Id, fieldName, config.rootObject, sequence++));
                }
            }

            // PHASE 1: Process direct children
            Integer objectSequence = 2;
            Map<String, Id> childDetailIds = new Map<String, Id>(); // ObjectName -> DetailId

            List<ObjectConfig> directChildren = new List<ObjectConfig>();
            List<ObjectConfig> grandchildren = new List<ObjectConfig>();

            for (ObjectConfig childObj : config.childObjects) {
                if (String.isBlank(childObj.parentObject)) directChildren.add(childObj);
                else grandchildren.add(childObj);
            }

            // Insert direct children
            for (ObjectConfig childObj : directChildren) {
                if (String.isBlank(childObj.relationshipField)) {
                    RelationshipDetectionResult detection = detectRelationshipField(
                        childObj.objectName, config.rootObject);
                    if (detection != null) {
                        childObj.relationshipField = detection.relationshipField;
                        if (String.isBlank(childObj.relationshipName)) {
                            childObj.relationshipName = detection.relationshipName;
                        }
                    }
                }

                fieldsToInsert.add(createObjectField(dcm.Id, childObj.objectName, childObj.objectName, objectSequence++));

                if (config.fieldsByObject.containsKey(childObj.objectName)) {
                    Integer fieldSequence = 1;
                    for (String fieldName : config.fieldsByObject.get(childObj.objectName)) {
                        fieldsToInsert.add(createFieldRecord(dcm.Id, fieldName, childObj.objectName, fieldSequence++));
                    }
                }
            }

            insert fieldsToInsert;

            // Create detail records for direct children
            for (ObjectConfig childObj : directChildren) {
                String relName = String.isNotBlank(childObj.relationshipName)
                    ? childObj.relationshipName
                    : getRelationshipName(childObj.objectName);

                detailsToInsert.add(createDetailRecordDynamic(
                    dcm.Id, childObj.objectName, childObj.relationshipField, 
                    'CHILD', childObj.maxRecords, null));
            }

            if (!detailsToInsert.isEmpty()) {
                insert detailsToInsert;
                // Map child object names to their detail IDs
                for (SObject detail : detailsToInsert) {
                    childDetailIds.put((String)detail.get('ccai__Object_Name__c'), detail.Id);
                }
            }

            // PHASE 1.5: Auto-discover parent lookups for child objects
            List<SObject> parentLookupFields = new List<SObject>();
            List<SObject> parentLookupDetails = new List<SObject>();

            for (ObjectConfig childObj : directChildren) {
                List<ParentLookupInfo> lookups = discoverParentLookups(childObj.objectName, config.rootObject);

                for (ParentLookupInfo lookup : lookups) {
                    // Add OBJECT record for parent (if not already added)
                    // This is handled by root object creation

                    // Add parent fields
                    List<String> standardFields = getStandardFieldsForObject(lookup.targetObject);
                    Integer fieldSeq = 1;
                    for (String parentField : standardFields) {
                        // Check if this field is accessible
                        if (SchemaHelper.isFieldAccessible(lookup.targetObject, parentField)) {
                            parentLookupFields.add(createFieldRecord(
                                dcm.Id, parentField, lookup.targetObject, fieldSeq++));
                        }
                    }

                    // Create PARENT_LOOKUP detail record
                    parentLookupDetails.add(createParentLookupDetail(
                        dcm.Id, childObj.objectName, lookup.lookupField,
                        lookup.targetObject, lookup.relationshipName));
                }
            }

            if (!parentLookupFields.isEmpty()) insert parentLookupFields;
            if (!parentLookupDetails.isEmpty()) insert parentLookupDetails;

            // PHASE 2: Process grandchildren
            if (!grandchildren.isEmpty()) {
                List<SObject> grandchildFields = new List<SObject>();
                List<SObject> grandchildDetails = new List<SObject>();

                for (ObjectConfig grandchildObj : grandchildren) {
                    if (String.isBlank(grandchildObj.relationshipField)) {
                        RelationshipDetectionResult detection = detectRelationshipField(
                            grandchildObj.objectName, grandchildObj.parentObject);
                        if (detection != null) {
                            grandchildObj.relationshipField = detection.relationshipField;
                            if (String.isBlank(grandchildObj.relationshipName)) {
                                grandchildObj.relationshipName = detection.relationshipName;
                            }
                        }
                    }

                    grandchildFields.add(createObjectField(
                        dcm.Id, grandchildObj.objectName, grandchildObj.objectName, objectSequence++));

                    if (config.fieldsByObject.containsKey(grandchildObj.objectName)) {
                        Integer fieldSequence = 1;
                        for (String fieldName : config.fieldsByObject.get(grandchildObj.objectName)) {
                            grandchildFields.add(createFieldRecord(
                                dcm.Id, fieldName, grandchildObj.objectName, fieldSequence++));
                        }
                    }

                    Id parentDetailId = childDetailIds.get(grandchildObj.parentObject);
                    grandchildDetails.add(createDetailRecordDynamic(
                        dcm.Id, grandchildObj.objectName, grandchildObj.relationshipField, 
                        'GRANDCHILD', grandchildObj.maxRecords, parentDetailId));
                }

                if (!grandchildFields.isEmpty()) insert grandchildFields;
                if (!grandchildDetails.isEmpty()) insert grandchildDetails;
            }

            return dcm.Id;

        } catch (Exception e) {
            throw new DCMBuilderException('Failed to create DCM with grandchildren: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Enhanced validation with schema checks
     */
    public static List<String> validateConfigWithSchema(DCMConfig config) {
        List<String> errors = new List<String>();

        if (String.isBlank(config.name)) errors.add('DCM name is required');
        if (String.isBlank(config.rootObject)) errors.add('Root object is required');
        else if (!SchemaHelper.isObjectAccessible(config.rootObject)) 
            errors.add('Root object "' + config.rootObject + '" does not exist or is not accessible');

        for (ObjectConfig childObj : config.childObjects) {
            if (String.isBlank(childObj.objectName)) {
                errors.add('Child object name is required');
                continue;
            }
            if (!SchemaHelper.isObjectAccessible(childObj.objectName)) {
                errors.add('Child object "' + childObj.objectName + '" does not exist or is not accessible');
                continue;
            }

            String targetParent = String.isBlank(childObj.parentObject) ? config.rootObject : childObj.parentObject;
            if (String.isBlank(childObj.relationshipField)) {
                RelationshipDetectionResult detection = detectRelationshipField(childObj.objectName, targetParent);
                if (detection == null) {
                    errors.add('Cannot auto-detect relationship field from ' + childObj.objectName +
                        ' to ' + targetParent + '.');
                }
            } else {
                if (!SchemaHelper.isFieldAccessible(childObj.objectName, childObj.relationshipField)) {
                    errors.add('Relationship field "' + childObj.relationshipField +
                        '" does not exist on ' + childObj.objectName);
                }
            }
        }

        for (String objectName : config.fieldsByObject.keySet()) {
            SchemaHelper.FieldValidationResult validation =
                SchemaHelper.validateFields(objectName, config.fieldsByObject.get(objectName));
            if (!validation.objectExists) errors.add('Object "' + objectName + '" does not exist');
            if (!validation.invalidFields.isEmpty()) 
                errors.add('Invalid fields on ' + objectName + ': ' + String.join(validation.invalidFields, ', '));
            if (!validation.inaccessibleFields.isEmpty())
                errors.add('Inaccessible fields on ' + objectName + ': ' + String.join(validation.inaccessibleFields, ', '));
        }

        return errors;
    }

    /**
     * @description Wrapper for parent lookup information
     */
    public class ParentLookupInfo {
        public String lookupField;
        public String targetObject;
        public String relationshipName;

        public ParentLookupInfo(String field, String target, String relName) {
            this.lookupField = field;
            this.targetObject = target;
            this.relationshipName = relName;
        }
    }

    /**
     * @description Discovers all parent lookup fields on a child object
     * @param childObject The object to analyze for lookup fields
     * @param rootObject The root object to exclude from parent lookups
     * @return List of parent lookup information
     */
    private static List<ParentLookupInfo> discoverParentLookups(String childObject, String rootObject) {
        List<ParentLookupInfo> lookups = new List<ParentLookupInfo>();

        Schema.DescribeSObjectResult childDescribe = SchemaHelper.getObjectDescribe(childObject);
        if (childDescribe == null) return lookups;

        Map<String, Schema.SObjectField> fieldMap = childDescribe.fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();

            // Only process reference (lookup) fields
            if (fieldDesc.getType() != Schema.DisplayType.REFERENCE) continue;

            // Get target objects
            List<Schema.sObjectType> references = fieldDesc.getReferenceTo();
            if (references.isEmpty()) continue;

            // For each target object (usually just one, unless polymorphic)
            for (Schema.sObjectType targetType : references) {
                String targetObject = targetType.getDescribe().getName();

                // Skip if target is the root object (already connected via CHILD relationship)
                if (targetObject == rootObject) continue;

                // Skip system objects we don't want to traverse
                if (isSystemObject(targetObject)) continue;

                // Get relationship name
                String relationshipName = fieldDesc.getRelationshipName();
                if (String.isBlank(relationshipName)) {
                    relationshipName = fieldName.replace('Id', '').replace('__c', '__r');
                }

                lookups.add(new ParentLookupInfo(
                    fieldDesc.getName(),
                    targetObject,
                    relationshipName
                ));
            }
        }

        return lookups;
    }

    /**
     * @description Returns standard fields to include for a parent object
     * @param objectName The object to get standard fields for
     * @return List of field names
     */
    private static List<String> getStandardFieldsForObject(String objectName) {
        List<String> standardFields = new List<String>();

        // Common fields for most objects
        List<String> commonFields = new List<String>{
            'Name', 'Title', 'Email', 'Phone', 'MobilePhone',
            'Industry', 'Type', 'Status', 'Description'
        };

        Schema.DescribeSObjectResult objDescribe = SchemaHelper.getObjectDescribe(objectName);
        if (objDescribe == null) return standardFields;

        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for (String fieldName : commonFields) {
            if (fieldMap.containsKey(fieldName.toLowerCase())) {
                // Use actual field name (correct casing)
                standardFields.add(fieldMap.get(fieldName.toLowerCase()).getDescribe().getName());
            }
        }

        // Always include Id if available
        if (fieldMap.containsKey('id')) {
            standardFields.add(0, 'Id'); // Add at beginning
        }

        return standardFields;
    }

    /**
     * @description Creates a PARENT_LOOKUP detail record
     * @param dcmId Data Context Mapping ID
     * @param childObject The child object containing the lookup
     * @param lookupField The lookup field name
     * @param parentObject The parent object being looked up
     * @param relationshipName The relationship name for traversal
     * @return Detail record
     */
    private static SObject createParentLookupDetail(
        Id dcmId, String childObject, String lookupField,
        String parentObject, String relationshipName) {

        SObject detail = newSObject('ccai__AI_Data_Extraction_Detail__c');
        detail.put('ccai__AI_Data_Extraction_Mapping__c', dcmId);
        detail.put('ccai__Object_Name__c', parentObject); // Target parent object
        detail.put('ccai__RelationshipField__c', lookupField);
        detail.put('ccai__RelationshipName__c', relationshipName);
        detail.put('ccai__Type__c', 'PARENT_LOOKUP');
        detail.put('ccai__Record_Limit__c', 1); // Parent lookups are 1:1
        // Note: No Parent_Detail__c - PARENT_LOOKUP relationships hang off child objects

        return detail;
    }

    /**
     * @description Checks if an object is a system object to exclude from traversals
     * @param objectName Object to check
     * @return true if system object
     */
    private static Boolean isSystemObject(String objectName) {
        Set<String> systemObjects = new Set<String>{
            'User', 'Group', 'Profile', 'RecordType', 'Organization',
            'PermissionSet', 'PermissionSetAssignment', 'UserRole'
        };
        return systemObjects.contains(objectName);
    }

    public class DCMBuilderException extends Exception {}
}