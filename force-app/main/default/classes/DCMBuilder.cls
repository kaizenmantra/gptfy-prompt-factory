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
        @AuraEnabled public Map<String, List<String>> selectedParentFields;  // V2.2: Parent field paths like {"Opportunity": ["OwnerId.Name"]}

        public DCMConfig() {
            this.childObjects = new List<ObjectConfig>();
            this.fieldsByObject = new Map<String, List<String>>();
            this.selectedParentFields = new Map<String, List<String>>();  // V2.2
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
     * @description Creates a FIELD type record for parent fields (V2.2 Task 2.10)
     * Enables parent field resolution like "Owner.Name" via lookup relationships
     * @param dcmId The DCM ID to associate with
     * @param lookupField The lookup field API name (e.g., "OwnerId", "AccountId")
     * @param parentObject The target object of the lookup (e.g., "User", "Account")
     * @param parentField The field on the parent object (e.g., "Name", "Industry")
     * @param sourceObject The source object containing the lookup field (e.g., "Opportunity")
     * @param sequence The sequence number for ordering
     * @return SObject The parent field record to insert
     */
    private static SObject createParentFieldRecord(
        Id dcmId,
        String lookupField,
        String parentObject,
        String parentField,
        String sourceObject,
        Integer sequence) {

        // Determine the relationship name (e.g., "Owner" from "OwnerId")
        String relationshipName = lookupField.endsWith('Id') ?
            lookupField.removeEnd('Id') : lookupField;

        // Build the field path using dot notation (e.g., "Owner.Name")
        String fieldPath = relationshipName + '.' + parentField;

        // Get the parent field's label for better display
        String parentFieldLabel = getFieldLabel(parentObject, parentField);
        String combinedLabel = relationshipName + ' ' + parentFieldLabel;

        SObject field = newSObject('ccai__AI_Data_Extraction_Field__c');
        field.put('ccai__AI_Data_Extraction_Mapping__c', dcmId);
        field.put('ccai__Type__c', 'FIELD');
        field.put('ccai__Field__c', fieldPath);  // Dot notation: "Owner.Name"
        field.put('ccai__Object__c', sourceObject);  // Source object: "Opportunity"
        field.put('ccai__Label__c', combinedLabel);  // "Owner Name"
        field.put('ccai__Send_To_AI__c', true);
        field.put('ccai__Scan_for_PII__c', shouldMaskField(parentField));
        return field;
    }

    /**
     * @description Gets the parent object name from a lookup field (V2.2 Task 2.10)
     * @param objectName The source object containing the lookup field
     * @param lookupField The lookup field API name (e.g., "OwnerId", "AccountId")
     * @return String The name of the parent object (e.g., "User", "Account"), or null if not found
     */
    private static String getParentObjectFromLookup(String objectName, String lookupField) {
        try {
            Schema.DescribeSObjectResult objDescribe = SchemaHelper.getObjectDescribe(objectName);
            if (objDescribe != null) {
                Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
                if (fieldMap.containsKey(lookupField.toLowerCase())) {
                    Schema.DescribeFieldResult fieldDescribe =
                        fieldMap.get(lookupField.toLowerCase()).getDescribe();

                    // Check if this is a reference field
                    if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        List<Schema.SObjectType> refs = fieldDescribe.getReferenceTo();
                        if (refs != null && !refs.isEmpty()) {
                            // Return the first reference target (for polymorphic fields, this returns the first)
                            return refs[0].getDescribe().getName();
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error getting parent object for ' + objectName + '.' + lookupField + ': ' + e.getMessage());
        }
        return null;
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

            // V2.2 Task 2.11: Add parent fields for root object
            if (config.selectedParentFields != null && config.selectedParentFields.containsKey(config.rootObject)) {
                Integer parentSeq = 1;
                for (String parentFieldPath : config.selectedParentFields.get(config.rootObject)) {
                    // Parse "OwnerId.Name" -> lookupField="OwnerId", parentField="Name"
                    List<String> parts = parentFieldPath.split('\\.');
                    if (parts.size() == 2) {
                        String lookupField = parts[0];
                        String parentField = parts[1];
                        String parentObject = getParentObjectFromLookup(config.rootObject, lookupField);

                        if (parentObject != null) {
                            fieldsToInsert.add(createParentFieldRecord(
                                dcm.Id, lookupField, parentObject, parentField, config.rootObject, parentSeq++
                            ));
                        }
                    }
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

                // V2.2 Task 2.11: Add parent fields for child object
                if (config.selectedParentFields != null && config.selectedParentFields.containsKey(childObj.objectName)) {
                    Integer parentSeq = 1;
                    for (String parentFieldPath : config.selectedParentFields.get(childObj.objectName)) {
                        List<String> parts = parentFieldPath.split('\\.');
                        if (parts.size() == 2) {
                            String lookupField = parts[0];
                            String parentField = parts[1];
                            String parentObject = getParentObjectFromLookup(childObj.objectName, lookupField);

                            if (parentObject != null) {
                                fieldsToInsert.add(createParentFieldRecord(
                                    dcm.Id, lookupField, parentObject, parentField, childObj.objectName, parentSeq++
                                ));
                            }
                        }
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

                    // V2.2 Task 2.11: Add parent fields for grandchild object
                    if (config.selectedParentFields != null && config.selectedParentFields.containsKey(grandchildObj.objectName)) {
                        Integer parentSeq = 1;
                        for (String parentFieldPath : config.selectedParentFields.get(grandchildObj.objectName)) {
                            List<String> parts = parentFieldPath.split('\\.');
                            if (parts.size() == 2) {
                                String lookupField = parts[0];
                                String parentField = parts[1];
                                String parentObject = getParentObjectFromLookup(grandchildObj.objectName, lookupField);

                                if (parentObject != null) {
                                    grandchildFields.add(createParentFieldRecord(
                                        dcm.Id, lookupField, parentObject, parentField, grandchildObj.objectName, parentSeq++
                                    ));
                                }
                            }
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

    public class DCMBuilderException extends Exception {}
}