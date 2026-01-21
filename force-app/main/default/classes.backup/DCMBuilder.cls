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
        try {
            // Create DCM root record
            // ccai__Object_Name__c is CRITICAL - without it, DCM won't show in GPTfy UI
            ccai__AI_Data_Extraction_Mapping__c dcm = new ccai__AI_Data_Extraction_Mapping__c(
                Name = config.name,
                ccai__Object_Name__c = config.rootObject,
                ccai__Status__c = 'Active',
                ccai__External_Id__c = String.valueOf(System.now().getTime())
            );
            insert dcm;

            // Create object and field records
            List<ccai__AI_Data_Extraction_Field__c> fieldsToInsert = new List<ccai__AI_Data_Extraction_Field__c>();

            // Add root object
            ccai__AI_Data_Extraction_Field__c rootObjectField = createObjectField(
                dcm.Id, config.rootObject, config.rootObject, 1
            );
            fieldsToInsert.add(rootObjectField);

            // Add root object fields
            if (config.fieldsByObject.containsKey(config.rootObject)) {
                Integer sequence = 1;
                for (String fieldName : config.fieldsByObject.get(config.rootObject)) {
                    fieldsToInsert.add(createFieldRecord(
                        dcm.Id, fieldName, config.rootObject, sequence++
                    ));
                }
            }

            // Add child objects
            Integer objectSequence = 2;
            for (ObjectConfig childObj : config.childObjects) {
                ccai__AI_Data_Extraction_Field__c childObjectField = createObjectField(
                    dcm.Id, childObj.objectName, childObj.objectName, objectSequence++
                );
                fieldsToInsert.add(childObjectField);

                // Add child object fields
                if (config.fieldsByObject.containsKey(childObj.objectName)) {
                    Integer fieldSequence = 1;
                    for (String fieldName : config.fieldsByObject.get(childObj.objectName)) {
                        fieldsToInsert.add(createFieldRecord(
                            dcm.Id, fieldName, childObj.objectName, fieldSequence++
                        ));
                    }
                }
            }

            insert fieldsToInsert;

            // Create detail records for child relationships
            List<ccai__AI_Data_Extraction_Detail__c> detailsToInsert = new List<ccai__AI_Data_Extraction_Detail__c>();

            for (ObjectConfig childObj : config.childObjects) {
                // Use the relationshipName from config (which comes from schema lookup in Stage 8)
                // Fall back to auto-generated name only if not provided
                String relName = String.isNotBlank(childObj.relationshipName)
                    ? childObj.relationshipName
                    : getRelationshipName(childObj.objectName);

                detailsToInsert.add(new ccai__AI_Data_Extraction_Detail__c(
                    ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
                    ccai__Object_Name__c = childObj.objectName,
                    ccai__RelationshipField__c = childObj.relationshipField,
                    ccai__RelationshipName__c = relName,
                    ccai__Type__c = 'CHILD',
                    ccai__Record_Limit__c = childObj.maxRecords
                ));
            }

            if (!detailsToInsert.isEmpty()) {
                insert detailsToInsert;
            }

            return dcm.Id;

        } catch (Exception e) {
            throw new DCMBuilderException('Failed to create DCM: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Creates an OBJECT type field record
     * @param dcmId ID of parent DCM
     * @param objectName API name of the object
     * @param label Display label
     * @param sequence Order in the list
     * @return ccai__AI_Data_Extraction_Field__c record
     */
    private static ccai__AI_Data_Extraction_Field__c createObjectField(
        Id dcmId, String objectName, String label, Integer sequence) {

        // ccai__Send_To_AI__c = true is CRITICAL - without it, data won't be sent to LLM
        return new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcmId,
            ccai__Type__c = 'OBJECT',
            ccai__Object__c = objectName,
            ccai__Field__c = objectName,
            ccai__Label__c = label,
            ccai__Send_To_AI__c = true
        );
    }

    /**
     * @description Creates a FIELD type field record
     * @param dcmId ID of parent DCM
     * @param fieldName API name of the field
     * @param objectName Parent object name
     * @param sequence Order in the list
     * @return ccai__AI_Data_Extraction_Field__c record
     */
    private static ccai__AI_Data_Extraction_Field__c createFieldRecord(
        Id dcmId, String fieldName, String objectName, Integer sequence) {

        // Get field label from schema
        String fieldLabel = getFieldLabel(objectName, fieldName);

        // ccai__Send_To_AI__c = true is CRITICAL - without it, data won't be sent to LLM
        // ccai__Label__c provides human-readable label for the field
        return new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcmId,
            ccai__Type__c = 'FIELD',
            ccai__Field__c = fieldName,
            ccai__Object__c = objectName,
            ccai__Label__c = fieldLabel,
            ccai__Send_To_AI__c = true,
            ccai__Scan_for_PII__c = shouldMaskField(fieldName)
        );
    }

    /**
     * @description Gets the label for a field from schema
     * @param objectName API name of the object
     * @param fieldName API name of the field
     * @return Field label or field name if label not found
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
     * @description Creates a detail record for child relationship
     * @param dcmId ID of parent DCM
     * @param childObject API name of child object
     * @param relationshipField Field on child pointing to parent
     * @param maxRecords Maximum records to fetch
     * @return ccai__AI_Data_Extraction_Detail__c record
     */
    private static ccai__AI_Data_Extraction_Detail__c createDetailRecord(
        Id dcmId, String childObject, String relationshipField, Integer maxRecords) {

        // ccai__RelationshipName__c and ccai__Type__c are required for proper DCM behavior
        return new ccai__AI_Data_Extraction_Detail__c(
            ccai__AI_Data_Extraction_Mapping__c = dcmId,
            ccai__Object_Name__c = childObject,
            ccai__RelationshipField__c = relationshipField,
            ccai__RelationshipName__c = getRelationshipName(childObject),
            ccai__Type__c = 'CHILD',
            ccai__Record_Limit__c = maxRecords
        );
    }

    /**
     * @description Creates a detail record for grandchild relationship (with parent link)
     * @param dcmId ID of parent DCM
     * @param childObject API name of child object
     * @param relationshipField Field on child pointing to parent
     * @param maxRecords Maximum records to fetch
     * @param parentDetailId ID of parent detail record
     * @return ccai__AI_Data_Extraction_Detail__c record
     */
    private static ccai__AI_Data_Extraction_Detail__c createGrandchildDetailRecord(
        Id dcmId, String childObject, String relationshipField, Integer maxRecords, Id parentDetailId) {

        return new ccai__AI_Data_Extraction_Detail__c(
            ccai__AI_Data_Extraction_Mapping__c = dcmId,
            ccai__Object_Name__c = childObject,
            ccai__RelationshipField__c = relationshipField,
            ccai__RelationshipName__c = getRelationshipName(childObject),
            ccai__Type__c = 'GRANDCHILD',
            ccai__Record_Limit__c = maxRecords,
            ccai__Parent_Detail__c = parentDetailId
        );
    }

    /**
     * @description Determines if a field should be masked (PII protection)
     * @param fieldName API name of the field
     * @return true if field should be masked
     */
    private static Boolean shouldMaskField(String fieldName) {
        String fieldLower = fieldName.toLowerCase();

        // Common PII field patterns
        Set<String> piiKeywords = new Set<String>{
            'ssn', 'socialsecurity', 'creditcard', 'accountnumber',
            'bankaccount', 'password', 'secret', 'token'
        };

        for (String keyword : piiKeywords) {
            if (fieldLower.contains(keyword)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Validates DCM configuration before creation
     * @param config DCMConfig to validate
     * @return List of validation error messages (empty if valid)
     */
    public static List<String> validateConfig(DCMConfig config) {
        List<String> errors = new List<String>();

        if (String.isBlank(config.name)) {
            errors.add('DCM name is required');
        }

        if (String.isBlank(config.rootObject)) {
            errors.add('Root object is required');
        }

        if (!SchemaHelper.isObjectAccessible(config.rootObject)) {
            errors.add('Root object "' + config.rootObject + '" is not accessible');
        }

        // Validate child objects
        for (ObjectConfig childObj : config.childObjects) {
            if (String.isBlank(childObj.objectName)) {
                errors.add('Child object name is required');
            } else if (!SchemaHelper.isObjectAccessible(childObj.objectName)) {
                errors.add('Child object "' + childObj.objectName + '" is not accessible');
            }

            if (String.isBlank(childObj.relationshipField)) {
                errors.add('Relationship field is required for ' + childObj.objectName);
            }
        }

        // Validate fields exist
        for (String objectName : config.fieldsByObject.keySet()) {
            for (String fieldName : config.fieldsByObject.get(objectName)) {
                if (!SchemaHelper.isFieldAccessible(objectName, fieldName)) {
                    errors.add('Field "' + fieldName + '" is not accessible on ' + objectName);
                }
            }
        }

        return errors;
    }

    /**
     * @description Deletes a DCM and all related records
     * @param dcmId ID of the DCM to delete
     */
    public static void deleteDCM(Id dcmId) {
        try {
            ccai__AI_Data_Extraction_Mapping__c dcm = [
                SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c WHERE Id = :dcmId
            ];
            delete dcm;
        } catch (Exception e) {
            throw new DCMBuilderException('Failed to delete DCM: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Auto-detects the relationship field between parent and child objects
     * Mirrors the shell script's detect_relationship_field() function
     * @param childObject API name of the child object
     * @param parentObject API name of the parent object
     * @return RelationshipDetectionResult with field name and metadata
     */
    public static RelationshipDetectionResult detectRelationshipField(String childObject, String parentObject) {
        Schema.DescribeSObjectResult childDescribe = SchemaHelper.getObjectDescribe(childObject);
        if (childDescribe == null) {
            return null;
        }

        Map<String, Schema.SObjectField> fieldMap = childDescribe.fields.getMap();

        // Strategy 1: Look for standard relationship field pattern (e.g., AccountId for Account)
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

        // Strategy 2: Check for polymorphic fields (WhatId, WhoId, ParentId)
        List<String> polymorphicFields = new List<String>{'WhatId', 'WhoId', 'ParentId', 'RelatedToId'};
        for (String polyField : polymorphicFields) {
            Schema.SObjectField poly = fieldMap.containsKey(polyField)
                ? fieldMap.get(polyField)
                : (fieldMap.containsKey(polyField.toLowerCase()) ? fieldMap.get(polyField.toLowerCase()) : null);

            if (poly != null) {
                Schema.DescribeFieldResult fieldDesc = poly.getDescribe();
                // Check if the polymorphic field references the parent object
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

        // Strategy 3: Search all lookup fields for reference to parent
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
     * Mirrors shell script's get_relationship_name()
     * @param objectName API name of the object
     * @return Plural relationship name (e.g., Contact -> Contacts)
     */
    public static String getRelationshipName(String objectName) {
        // Handle common irregular plurals
        Map<String, String> irregularPlurals = new Map<String, String>{
            'Opportunity' => 'Opportunities',
            'Activity' => 'Activities',
            'Case' => 'Cases',
            'Address' => 'Addresses'
        };

        if (irregularPlurals.containsKey(objectName)) {
            return irregularPlurals.get(objectName);
        }

        // Handle custom objects (__c suffix)
        if (objectName.endsWith('__c')) {
            String baseName = objectName.removeEnd('__c');
            return baseName + 's__r';
        }

        // Standard pluralization rules
        if (objectName.endsWith('y')) {
            return objectName.removeEnd('y') + 'ies';
        } else if (objectName.endsWith('s') || objectName.endsWith('x') ||
                   objectName.endsWith('ch') || objectName.endsWith('sh')) {
            return objectName + 'es';
        } else {
            return objectName + 's';
        }
    }

    /**
     * @description Creates DCM with two-phase approach for grandchild support
     * Phase 1: Process direct children (no parentObject)
     * Phase 2: Process grandchildren (with parentObject)
     * @param config DCMConfig with all configuration details
     * @return ID of the created DCM record
     */
    public static Id createDCMWithGrandchildren(DCMConfig config) {
        try {
            // Validate config first
            List<String> errors = validateConfigWithSchema(config);
            if (!errors.isEmpty()) {
                throw new DCMBuilderException('DCM validation failed: ' + String.join(errors, '; '));
            }

            // Create DCM root record
            // ccai__Object_Name__c is CRITICAL - without it, DCM won't show in GPTfy UI
            ccai__AI_Data_Extraction_Mapping__c dcm = new ccai__AI_Data_Extraction_Mapping__c(
                Name = config.name,
                ccai__Object_Name__c = config.rootObject,
                ccai__Status__c = 'Active',
                ccai__External_Id__c = String.valueOf(System.now().getTime())
            );
            insert dcm;

            List<ccai__AI_Data_Extraction_Field__c> fieldsToInsert = new List<ccai__AI_Data_Extraction_Field__c>();
            List<ccai__AI_Data_Extraction_Detail__c> detailsToInsert = new List<ccai__AI_Data_Extraction_Detail__c>();

            // Add root object
            fieldsToInsert.add(createObjectField(dcm.Id, config.rootObject, config.rootObject, 1));

            // Add root object fields
            if (config.fieldsByObject.containsKey(config.rootObject)) {
                Integer sequence = 1;
                for (String fieldName : config.fieldsByObject.get(config.rootObject)) {
                    fieldsToInsert.add(createFieldRecord(dcm.Id, fieldName, config.rootObject, sequence++));
                }
            }

            // PHASE 1: Process direct children (no parentObject)
            Integer objectSequence = 2;
            Map<String, Id> childDetailIds = new Map<String, Id>();

            List<ObjectConfig> directChildren = new List<ObjectConfig>();
            List<ObjectConfig> grandchildren = new List<ObjectConfig>();

            for (ObjectConfig childObj : config.childObjects) {
                if (String.isBlank(childObj.parentObject)) {
                    directChildren.add(childObj);
                } else {
                    grandchildren.add(childObj);
                }
            }

            // Insert direct children
            for (ObjectConfig childObj : directChildren) {
                // Auto-detect relationship field if not provided
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

            // Insert fields first
            insert fieldsToInsert;

            // Create detail records for direct children
            for (ObjectConfig childObj : directChildren) {
                // Use the relationshipName from config (which comes from schema lookup in Stage 8)
                String relName = String.isNotBlank(childObj.relationshipName)
                    ? childObj.relationshipName
                    : getRelationshipName(childObj.objectName);

                ccai__AI_Data_Extraction_Detail__c detail = new ccai__AI_Data_Extraction_Detail__c(
                    ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
                    ccai__Object_Name__c = childObj.objectName,
                    ccai__RelationshipField__c = childObj.relationshipField,
                    ccai__RelationshipName__c = relName,
                    ccai__Type__c = 'CHILD',
                    ccai__Record_Limit__c = childObj.maxRecords
                );
                detailsToInsert.add(detail);
            }

            if (!detailsToInsert.isEmpty()) {
                insert detailsToInsert;

                // Map child object names to their detail IDs for grandchild linking
                for (ccai__AI_Data_Extraction_Detail__c detail : detailsToInsert) {
                    childDetailIds.put(detail.ccai__Object_Name__c, detail.Id);
                }
            }

            // PHASE 2: Process grandchildren (with parentObject reference)
            if (!grandchildren.isEmpty()) {
                List<ccai__AI_Data_Extraction_Field__c> grandchildFields = new List<ccai__AI_Data_Extraction_Field__c>();
                List<ccai__AI_Data_Extraction_Detail__c> grandchildDetails = new List<ccai__AI_Data_Extraction_Detail__c>();

                for (ObjectConfig grandchildObj : grandchildren) {
                    // Auto-detect relationship field to parent (not root)
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

                    // Create detail record linked to parent detail (GRANDCHILD type)
                    Id parentDetailId = childDetailIds.get(grandchildObj.parentObject);
                    String gcRelName = String.isNotBlank(grandchildObj.relationshipName)
                        ? grandchildObj.relationshipName
                        : getRelationshipName(grandchildObj.objectName);

                    ccai__AI_Data_Extraction_Detail__c grandchildDetail = new ccai__AI_Data_Extraction_Detail__c(
                        ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
                        ccai__Object_Name__c = grandchildObj.objectName,
                        ccai__RelationshipField__c = grandchildObj.relationshipField,
                        ccai__RelationshipName__c = gcRelName,
                        ccai__Type__c = 'GRANDCHILD',
                        ccai__Record_Limit__c = grandchildObj.maxRecords,
                        ccai__Parent_Detail__c = parentDetailId
                    );
                    grandchildDetails.add(grandchildDetail);
                }

                if (!grandchildFields.isEmpty()) {
                    insert grandchildFields;
                }

                if (!grandchildDetails.isEmpty()) {
                    insert grandchildDetails;
                }
            }

            return dcm.Id;

        } catch (Exception e) {
            throw new DCMBuilderException('Failed to create DCM with grandchildren: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Enhanced validation with schema checks
     * @param config DCMConfig to validate
     * @return List of validation error messages (empty if valid)
     */
    public static List<String> validateConfigWithSchema(DCMConfig config) {
        List<String> errors = new List<String>();

        if (String.isBlank(config.name)) {
            errors.add('DCM name is required');
        }

        if (String.isBlank(config.rootObject)) {
            errors.add('Root object is required');
        } else if (!SchemaHelper.isObjectAccessible(config.rootObject)) {
            errors.add('Root object "' + config.rootObject + '" does not exist or is not accessible');
        }

        // Validate child objects with relationship detection
        for (ObjectConfig childObj : config.childObjects) {
            if (String.isBlank(childObj.objectName)) {
                errors.add('Child object name is required');
                continue;
            }

            if (!SchemaHelper.isObjectAccessible(childObj.objectName)) {
                errors.add('Child object "' + childObj.objectName + '" does not exist or is not accessible');
                continue;
            }

            // Validate relationship field exists or can be auto-detected
            String targetParent = String.isBlank(childObj.parentObject) ? config.rootObject : childObj.parentObject;
            if (String.isBlank(childObj.relationshipField)) {
                RelationshipDetectionResult detection = detectRelationshipField(childObj.objectName, targetParent);
                if (detection == null) {
                    errors.add('Cannot auto-detect relationship field from ' + childObj.objectName +
                        ' to ' + targetParent + '. Please specify relationshipField explicitly.');
                }
            } else {
                // Validate the specified relationship field exists
                if (!SchemaHelper.isFieldAccessible(childObj.objectName, childObj.relationshipField)) {
                    errors.add('Relationship field "' + childObj.relationshipField +
                        '" does not exist on ' + childObj.objectName);
                }
            }

            // Validate relationship name has no spaces (GPTfy requirement)
            if (String.isNotBlank(childObj.relationshipName) && childObj.relationshipName.contains(' ')) {
                errors.add('Relationship name "' + childObj.relationshipName +
                    '" cannot contain spaces (GPTfy requirement)');
            }
        }

        // Validate fields against schema
        for (String objectName : config.fieldsByObject.keySet()) {
            SchemaHelper.FieldValidationResult validation =
                SchemaHelper.validateFields(objectName, config.fieldsByObject.get(objectName));

            if (!validation.objectExists) {
                errors.add('Object "' + objectName + '" does not exist in schema');
            }

            if (!validation.invalidFields.isEmpty()) {
                errors.add('Invalid fields on ' + objectName + ': ' + String.join(validation.invalidFields, ', '));
            }

            if (!validation.inaccessibleFields.isEmpty()) {
                errors.add('Inaccessible fields on ' + objectName + ': ' +
                    String.join(validation.inaccessibleFields, ', '));
            }
        }

        return errors;
    }

    /**
     * @description Custom exception for DCM builder errors
     */
    public class DCMBuilderException extends Exception {}
}