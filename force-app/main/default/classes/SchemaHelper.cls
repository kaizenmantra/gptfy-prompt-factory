/**
 * @description Utility class for Salesforce schema introspection
 * Provides methods to query object and field metadata with caching
 */
public with sharing class SchemaHelper {

    // Static cache for describe results to improve performance
    private static Map<String, Schema.DescribeSObjectResult> describeCache =
        new Map<String, Schema.DescribeSObjectResult>();

    /**
     * @description Wrapper class for child relationship information
     */
    public class ChildRelationship {
        @AuraEnabled public String childObject;
        @AuraEnabled public String relationshipName;
        @AuraEnabled public String field;

        public ChildRelationship(String childObject, String relationshipName, String field) {
            this.childObject = childObject;
            this.relationshipName = relationshipName;
            this.field = field;
        }
    }

    /**
     * @description Wrapper class for field metadata
     * V2.2: Enhanced with helpText, picklistValues, category, and parent relationship info
     */
    public class FieldMetadata {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isAccessible;
        @AuraEnabled public Boolean isUpdateable;
        @AuraEnabled public Boolean isCustom;
        // V2.2: New fields for enriched metadata
        @AuraEnabled public String helpText;              // Admin-defined field description
        @AuraEnabled public String category;              // narrative, metric, classification, temporal, flag, relationship, contact, other
        @AuraEnabled public List<PicklistValue> picklistValues;  // For picklist/multipicklist fields
        @AuraEnabled public List<String> referenceTo;     // Target objects for lookup fields
        @AuraEnabled public String relationshipName;      // For lookup fields (e.g., Account for AccountId)
        @AuraEnabled public Integer length;               // Field length for text fields
        @AuraEnabled public Boolean isFormula;            // Is this a formula field?
        @AuraEnabled public Integer usagePercent;         // V2.2: Field population density (0-100), null if not calculated

        public FieldMetadata(String name, String label, String type,
                           Boolean isAccessible, Boolean isUpdateable, Boolean isCustom) {
            this.name = name;
            this.label = label;
            this.type = type;
            this.isAccessible = isAccessible;
            this.isUpdateable = isUpdateable;
            this.isCustom = isCustom;
        }

        // V2.2: Extended constructor with all metadata
        public FieldMetadata(Schema.DescribeFieldResult fieldDescribe) {
            this.name = fieldDescribe.getName();
            this.label = fieldDescribe.getLabel();
            this.type = String.valueOf(fieldDescribe.getType());
            this.isAccessible = fieldDescribe.isAccessible();
            this.isUpdateable = fieldDescribe.isUpdateable();
            this.isCustom = fieldDescribe.isCustom();
            this.helpText = fieldDescribe.getInlineHelpText();
            this.length = fieldDescribe.getLength();
            this.isFormula = fieldDescribe.isCalculated();
            this.relationshipName = fieldDescribe.getRelationshipName();

            // Get reference targets for lookup fields
            List<Schema.SObjectType> refs = fieldDescribe.getReferenceTo();
            if (refs != null && !refs.isEmpty()) {
                this.referenceTo = new List<String>();
                for (Schema.SObjectType ref : refs) {
                    this.referenceTo.add(ref.getDescribe().getName());
                }
            }

            // Get picklist values
            if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST ||
                fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                this.picklistValues = new List<PicklistValue>();
                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                    this.picklistValues.add(new PicklistValue(entry));
                }
            }

            // Categorize the field
            this.category = categorizeField(fieldDescribe);
        }
    }

    /**
     * @description Wrapper class for picklist values (V2.2)
     */
    public class PicklistValue {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean isDefault;

        public PicklistValue(Schema.PicklistEntry entry) {
            this.value = entry.getValue();
            this.label = entry.getLabel();
            this.isActive = entry.isActive();
            this.isDefault = entry.isDefaultValue();
        }
    }

    /**
     * @description Wrapper class for parent (lookup) relationships (V2.2)
     * Represents a lookup field that points to a parent object
     */
    public class ParentRelationship {
        @AuraEnabled public String fieldApi;           // e.g., AccountId
        @AuraEnabled public String fieldLabel;         // e.g., Account ID
        @AuraEnabled public String relationshipName;   // e.g., Account
        @AuraEnabled public String referenceTo;        // e.g., Account (target object)
        @AuraEnabled public Boolean isRequired;        // Is this lookup required?
        @AuraEnabled public Boolean isPolymorphic;     // Does it reference multiple objects? (e.g., WhoId)

        public ParentRelationship(Schema.DescribeFieldResult fieldDescribe) {
            this.fieldApi = fieldDescribe.getName();
            this.fieldLabel = fieldDescribe.getLabel();
            this.relationshipName = fieldDescribe.getRelationshipName();
            this.isRequired = !fieldDescribe.isNillable();

            List<Schema.SObjectType> refs = fieldDescribe.getReferenceTo();
            if (refs != null && !refs.isEmpty()) {
                this.referenceTo = refs[0].getDescribe().getName();
                this.isPolymorphic = refs.size() > 1;
            }
        }
    }

    /**
     * @description Categorizes a field based on its type and name (V2.2)
     * Categories: narrative, metric, classification, temporal, flag, relationship, contact, other
     * Ported from discover-fields.sh lines 207-216
     * @param fieldDescribe The field describe result
     * @return Category string
     */
    private static String categorizeField(Schema.DescribeFieldResult fieldDescribe) {
        Schema.DisplayType fieldType = fieldDescribe.getType();
        String fieldName = fieldDescribe.getName().toLowerCase();

        // Check type first
        if (fieldType == Schema.DisplayType.ID || fieldType == Schema.DisplayType.REFERENCE) {
            return 'relationship';
        }
        if (fieldType == Schema.DisplayType.TEXTAREA ||
            fieldName.contains('description') ||
            fieldName.contains('comment') ||
            fieldName.contains('note') ||
            fieldName.contains('detail')) {
            return 'narrative';
        }
        if (fieldType == Schema.DisplayType.CURRENCY ||
            fieldType == Schema.DisplayType.DOUBLE ||
            fieldType == Schema.DisplayType.PERCENT ||
            fieldType == Schema.DisplayType.INTEGER) {
            return 'metric';
        }
        if (fieldType == Schema.DisplayType.PICKLIST ||
            fieldType == Schema.DisplayType.MULTIPICKLIST) {
            return 'classification';
        }
        if (fieldType == Schema.DisplayType.DATE ||
            fieldType == Schema.DisplayType.DATETIME) {
            return 'temporal';
        }
        if (fieldType == Schema.DisplayType.BOOLEAN) {
            return 'flag';
        }
        if (fieldType == Schema.DisplayType.EMAIL ||
            fieldType == Schema.DisplayType.PHONE ||
            fieldType == Schema.DisplayType.URL) {
            return 'contact';
        }

        return 'other';
    }

    /**
     * @description Gets parent (lookup) relationships for an object (V2.2)
     * Identifies all lookup fields and their target objects
     * Ported from discover-relationships.sh lines 161-175
     * @param objectName API name of the object
     * @return List of ParentRelationship wrapper objects
     */
    public static List<ParentRelationship> getParentRelationships(String objectName) {
        Schema.DescribeSObjectResult describe = getObjectDescribe(objectName);
        if (describe == null) {
            return new List<ParentRelationship>();
        }

        List<ParentRelationship> relationships = new List<ParentRelationship>();
        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            // Only include reference (lookup) fields
            if (fieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
                continue;
            }

            // Skip if no reference targets
            List<Schema.SObjectType> refs = fieldDescribe.getReferenceTo();
            if (refs == null || refs.isEmpty()) {
                continue;
            }

            // Skip if not accessible
            if (!fieldDescribe.isAccessible()) {
                continue;
            }

            relationships.add(new ParentRelationship(fieldDescribe));
        }

        return relationships;
    }

    /**
     * @description Gets cached describe result for an object
     * @param objectName API name of the object
     * @return DescribeSObjectResult or null if object doesn't exist
     */
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        if (!describeCache.containsKey(objectName)) {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) {
                return null;
            }
            describeCache.put(objectName, objType.getDescribe());
        }
        return describeCache.get(objectName);
    }

    /**
     * @description Gets all child relationships for an object
     * @param objectName API name of the parent object
     * @return List of ChildRelationship wrapper objects
     */
    public static List<ChildRelationship> getChildRelationships(String objectName) {
        Schema.DescribeSObjectResult describe = getObjectDescribe(objectName);
        if (describe == null) {
            return new List<ChildRelationship>();
        }

        List<Schema.ChildRelationship> allRelationships = describe.getChildRelationships();
        List<ChildRelationship> relationships = new List<ChildRelationship>();

        for (Schema.ChildRelationship rel : allRelationships) {
            String childObjectName = rel.getChildSObject().getDescribe().getName();

            // Filter out system and irrelevant objects
            if (isSystemObject(childObjectName)) {
                continue;
            }

            // Filter out Feed, History, Share objects
            if (childObjectName.endsWith('Feed') ||
                childObjectName.endsWith('History') ||
                childObjectName.endsWith('Share')) {
                continue;
            }

            relationships.add(new ChildRelationship(
                childObjectName,
                rel.getRelationshipName(),
                rel.getField().getDescribe().getName()
            ));
        }

        return relationships;
    }

    /**
     * @description Gets field metadata for an object
     * V2.2: Now uses extended constructor to populate helpText, picklistValues, category, etc.
     * @param objectName API name of the object
     * @return List of FieldMetadata wrapper objects with enriched metadata
     */
    public static List<FieldMetadata> getFields(String objectName) {
        Schema.DescribeSObjectResult objDescribe = getObjectDescribe(objectName);
        if (objDescribe == null) {
            return new List<FieldMetadata>();
        }

        List<FieldMetadata> fields = new List<FieldMetadata>();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            // Skip most system fields unless they're commonly useful
            if (isSystemField(fieldDescribe.getName()) &&
                !isUsefulSystemField(fieldDescribe.getName())) {
                continue;
            }

            // V2.2: Use extended constructor for enriched metadata
            fields.add(new FieldMetadata(fieldDescribe));
        }

        return fields;
    }

    /**
     * @description Checks if an object is accessible to current user
     * @param objectName API name of the object
     * @return true if object is accessible, queryable, and not a system object
     */
    public static Boolean isObjectAccessible(String objectName) {
        Schema.DescribeSObjectResult describe = getObjectDescribe(objectName);

        if (describe == null) {
            return false;
        }

        return describe.isAccessible() &&
               describe.isQueryable() &&
               !describe.getName().endsWith('__ChangeEvent');
    }

    /**
     * @description Checks if a field is accessible to current user
     * @param objectName API name of the object
     * @param fieldName API name of the field
     * @return true if field is accessible
     */
    public static Boolean isFieldAccessible(String objectName, String fieldName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            return false;
        }

        Schema.SObjectField field = objectType.getDescribe().fields.getMap().get(fieldName);
        if (field == null) {
            return false;
        }

        return field.getDescribe().isAccessible();
    }

    /**
     * @description Checks if an object name represents a system object
     * @param objectName API name of the object
     * @return true if it's a system object that should be filtered
     */
    private static Boolean isSystemObject(String objectName) {
        return objectName.endsWith('__Tag') ||
               objectName.endsWith('__ChangeEvent') ||
               objectName.endsWith('__ViewStat') ||
               objectName.endsWith('__mdt') ||
               objectName.endsWith('__e');
    }

    /**
     * @description Checks if a field name represents a system field
     * @param fieldName API name of the field
     * @return true if it's a system field
     */
    private static Boolean isSystemField(String fieldName) {
        Set<String> systemFields = new Set<String>{
            'CreatedById', 'CreatedDate', 'LastModifiedById', 'LastModifiedDate',
            'SystemModstamp', 'IsDeleted', 'LastActivityDate', 'LastViewedDate',
            'LastReferencedDate'
        };
        return systemFields.contains(fieldName);
    }

    /**
     * @description Checks if a system field is commonly useful in prompts
     * @param fieldName API name of the field
     * @return true if it's a useful system field
     */
    private static Boolean isUsefulSystemField(String fieldName) {
        Set<String> usefulFields = new Set<String>{
            'Id', 'Name', 'CreatedDate', 'LastModifiedDate', 'OwnerId'
        };
        return usefulFields.contains(fieldName);
    }

    /**
     * @description Gets safe/queryable fields for an object
     * Some objects like ContentDocumentLink have restrictions on which fields can be queried
     * @param objectName API name of the object
     * @return Set of field names that are safe to query
     */
    public static Set<String> getSafeQueryableFields(String objectName) {
        // ContentDocumentLink has special restrictions - only certain fields are queryable
        // See: https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_contentdocumentlink.htm
        if (objectName == 'ContentDocumentLink') {
            return new Set<String>{
                'Id', 'ContentDocumentId', 'LinkedEntityId', 'ShareType', 'Visibility'
            };
        }

        // AttachedContentDocument also has restrictions
        if (objectName == 'AttachedContentDocument') {
            return new Set<String>{
                'Id', 'ContentDocumentId', 'LinkedEntityId', 'Title', 'FileType', 'ContentSize'
            };
        }

        // CombinedAttachment is a special read-only object
        if (objectName == 'CombinedAttachment') {
            return new Set<String>{
                'Id', 'Title', 'Body', 'ContentType', 'ParentId', 'CreatedById', 'CreatedDate', 'LastModifiedById', 'LastModifiedDate'
            };
        }

        // For other objects, return empty set to indicate no restrictions
        return new Set<String>();
    }

    /**
     * @description Checks if a field is queryable on an object
     * Handles special cases like ContentDocumentLink where some fields exist but aren't queryable
     * @param objectName API name of the object
     * @param fieldName API name of the field
     * @return true if the field can be queried in SOQL
     */
    public static Boolean isFieldQueryable(String objectName, String fieldName) {
        // Check if object has restricted fields
        Set<String> safeFields = getSafeQueryableFields(objectName);
        if (!safeFields.isEmpty()) {
            // Object has restrictions - only allow safe fields
            return safeFields.contains(fieldName);
        }

        // No restrictions - check normal accessibility
        return isFieldAccessible(objectName, fieldName);
    }

    /**
     * @description Filters a list of field names to only include queryable fields
     * @param objectName API name of the object
     * @param fieldNames List of field API names to filter
     * @return List of queryable field names
     */
    public static List<String> filterQueryableFields(String objectName, List<String> fieldNames) {
        List<String> queryableFields = new List<String>();
        Set<String> safeFields = getSafeQueryableFields(objectName);

        for (String fieldName : fieldNames) {
            if (!safeFields.isEmpty()) {
                // Object has restrictions - only include safe fields
                if (safeFields.contains(fieldName)) {
                    queryableFields.add(fieldName);
                }
            } else {
                // No restrictions - include if accessible
                if (isFieldAccessible(objectName, fieldName)) {
                    queryableFields.add(fieldName);
                }
            }
        }

        return queryableFields;
    }

    /**
     * @description Validates a list of field names against an object's schema
     * Also checks for special queryability restrictions (e.g., ContentDocumentLink)
     * @param objectName API name of the object
     * @param fieldNames List of field API names to validate
     * @return ValidationResult containing valid and invalid fields
     */
    public static FieldValidationResult validateFields(String objectName, List<String> fieldNames) {
        FieldValidationResult result = new FieldValidationResult();

        Schema.DescribeSObjectResult objDescribe = getObjectDescribe(objectName);
        if (objDescribe == null) {
            // Object doesn't exist - all fields are invalid
            result.invalidFields.addAll(fieldNames);
            result.objectExists = false;
            return result;
        }

        result.objectExists = true;
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        // Check if object has special queryability restrictions
        Set<String> safeFields = getSafeQueryableFields(objectName);
        Boolean hasRestrictions = !safeFields.isEmpty();

        for (String fieldName : fieldNames) {
            // First check if object has special restrictions
            if (hasRestrictions) {
                if (safeFields.contains(fieldName)) {
                    result.validFields.add(fieldName);
                } else {
                    // Field exists in schema but not queryable on this object
                    result.invalidFields.add(fieldName);
                }
            } else if (fieldMap.containsKey(fieldName.toLowerCase())) {
                // Standard validation - check if field exists and is accessible
                Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName.toLowerCase()).getDescribe();
                if (fieldDesc.isAccessible()) {
                    result.validFields.add(fieldName);
                } else {
                    result.inaccessibleFields.add(fieldName);
                }
            } else {
                result.invalidFields.add(fieldName);
            }
        }

        return result;
    }

    /**
     * @description Wrapper class for field validation results
     */
    public class FieldValidationResult {
        @AuraEnabled public Boolean objectExists = true;
        @AuraEnabled public List<String> validFields = new List<String>();
        @AuraEnabled public List<String> invalidFields = new List<String>();
        @AuraEnabled public List<String> inaccessibleFields = new List<String>();

        public Boolean isValid() {
            return objectExists && invalidFields.isEmpty();
        }

        public Boolean hasIssues() {
            return !objectExists || !invalidFields.isEmpty() || !inaccessibleFields.isEmpty();
        }
    }

    /**
     * @description Clears the describe cache (for testing purposes)
     */
    @TestVisible
    private static void clearCache() {
        describeCache.clear();
    }

    /**
     * @description Gets child relationships for multiple objects at once (for grandchild discovery)
     * @param objectNames List of object API names to get children for
     * @return Map of parent object name to list of ChildRelationship
     */
    public static Map<String, List<ChildRelationship>> getChildRelationshipsForObjects(List<String> objectNames) {
        Map<String, List<ChildRelationship>> result = new Map<String, List<ChildRelationship>>();

        for (String objectName : objectNames) {
            result.put(objectName, getChildRelationships(objectName));
        }

        return result;
    }

    /**
     * @description Discovers grandchild relationships (2 levels deep)
     * Mirrors the shell script's Stage 3.3/3.4 functionality
     * @param rootObject The root object (e.g., Account)
     * @param selectedChildObjects List of selected child objects to explore for grandchildren
     * @return Map of child object to its child relationships (grandchildren of root)
     */
    public static Map<String, List<ChildRelationship>> discoverGrandchildRelationships(
            String rootObject, List<String> selectedChildObjects) {

        Map<String, List<ChildRelationship>> grandchildMap = new Map<String, List<ChildRelationship>>();

        for (String childObject : selectedChildObjects) {
            // Skip the root object itself
            if (childObject == rootObject) {
                continue;
            }

            // Get children of this child (grandchildren of root)
            List<ChildRelationship> grandchildren = getChildRelationships(childObject);

            // Filter to only meaningful grandchild relationships
            List<ChildRelationship> filteredGrandchildren = new List<ChildRelationship>();
            for (ChildRelationship gc : grandchildren) {
                // Additional filtering for grandchildren - be more selective
                if (isValidGrandchildObject(gc.childObject)) {
                    filteredGrandchildren.add(gc);
                }
            }

            if (!filteredGrandchildren.isEmpty()) {
                grandchildMap.put(childObject, filteredGrandchildren);
            }
        }

        return grandchildMap;
    }

    /**
     * @description Checks if an object is a valid grandchild candidate
     * More restrictive than direct child filtering
     * @param objectName API name of the object
     * @return true if valid grandchild candidate
     */
    private static Boolean isValidGrandchildObject(String objectName) {
        // Skip system objects (same as child filtering)
        if (isSystemObject(objectName)) {
            return false;
        }

        // Skip Feed, History, Share objects
        if (objectName.endsWith('Feed') ||
            objectName.endsWith('History') ||
            objectName.endsWith('Share')) {
            return false;
        }

        // Skip ProcessInstance objects
        if (objectName.contains('ProcessInstance')) {
            return false;
        }

        // Skip ChangeEvent objects
        if (objectName.endsWith('ChangeEvent')) {
            return false;
        }

        // Check if object is accessible
        return isObjectAccessible(objectName);
    }

    /**
     * @description Calculates field population density by querying sample records
     * V2.2: Task 2.6 - Enables LLM to prioritize fields that actually contain data
     * @param objectName The object to analyze
     * @param sampleSize Number of records to query (default 100, max 500)
     * @return Map of fieldName -> usagePercent (0-100)
     */
    public static Map<String, Integer> calculateFieldDensity(String objectName, Integer sampleSize) {
        // Cap sample size to avoid governor limits
        Integer maxSample = Math.min(sampleSize != null ? sampleSize : 100, 500);

        // Get queryable fields
        List<FieldMetadata> fields = getFields(objectName);

        // Build field list (limit to 50 to avoid query length issues)
        List<String> fieldNames = new List<String>();
        for (FieldMetadata f : fields) {
            if (fieldNames.size() >= 50) break;
            if (f.isAccessible && isQueryableType(f.type)) {
                fieldNames.add(f.name);
            }
        }

        // Handle case where no queryable fields found
        if (fieldNames.isEmpty()) {
            return new Map<String, Integer>();
        }

        // Query records
        String soql = 'SELECT ' + String.join(fieldNames, ', ') +
                      ' FROM ' + objectName + ' LIMIT ' + maxSample;
        List<SObject> records = Database.query(soql);

        // Count non-null values
        Map<String, Integer> counts = new Map<String, Integer>();
        for (String fn : fieldNames) counts.put(fn, 0);

        for (SObject rec : records) {
            for (String fn : fieldNames) {
                Object val = rec.get(fn);
                if (val != null && String.valueOf(val) != '') {
                    counts.put(fn, counts.get(fn) + 1);
                }
            }
        }

        // Convert to percentages
        Map<String, Integer> density = new Map<String, Integer>();
        Integer total = records.size();
        if (total > 0) {
            for (String fn : counts.keySet()) {
                density.put(fn, (counts.get(fn) * 100) / total);
            }
        }

        return density;
    }

    /**
     * @description Checks if a field type is queryable in SOQL
     * V2.2: Helper for calculateFieldDensity()
     * @param fieldType The field type (e.g., STRING, CURRENCY, BASE64)
     * @return true if the field type can be queried
     */
    private static Boolean isQueryableType(String fieldType) {
        // Exclude blob, address, location compound types
        Set<String> nonQueryable = new Set<String>{'BASE64', 'ADDRESS', 'LOCATION'};
        return !nonQueryable.contains(fieldType.toUpperCase());
    }

    /**
     * @description Gets environment information for field selection thresholds
     * @return EnvironmentInfo with sandbox type and density threshold
     */
    public static EnvironmentInfo getEnvironmentInfo() {
        EnvironmentInfo info = new EnvironmentInfo();

        try {
            Organization org = [SELECT Id, IsSandbox, InstanceName, OrganizationType FROM Organization LIMIT 1];
            info.isSandbox = org.IsSandbox;
            info.instanceName = org.InstanceName;
            info.orgType = org.OrganizationType;

            // Determine sandbox type based on instance name patterns
            if (!org.IsSandbox) {
                info.sandboxType = 'Production';
                info.fieldDensityThreshold = 20; // 20% minimum population in production
            } else {
                // Infer sandbox type from instance name
                String instance = org.InstanceName != null ? org.InstanceName.toLowerCase() : '';

                if (instance.contains('cs') || instance.contains('sandbox')) {
                    // Full or Partial sandbox
                    info.sandboxType = 'Full/Partial';
                    info.fieldDensityThreshold = 10; // 10% minimum
                } else if (instance.contains('dev')) {
                    // Developer sandbox
                    info.sandboxType = 'Developer';
                    info.fieldDensityThreshold = 0; // Disable density filtering in dev
                } else {
                    // Default to partial sandbox thresholds
                    info.sandboxType = 'Unknown';
                    info.fieldDensityThreshold = 5;
                }
            }
        } catch (Exception e) {
            // Fallback to safe defaults
            info.isSandbox = true;
            info.sandboxType = 'Unknown';
            info.fieldDensityThreshold = 5;
        }

        return info;
    }

    /**
     * @description Wrapper class for environment information
     */
    public class EnvironmentInfo {
        @AuraEnabled public Boolean isSandbox = false;
        @AuraEnabled public String sandboxType = 'Unknown';
        @AuraEnabled public String instanceName;
        @AuraEnabled public String orgType;
        @AuraEnabled public Integer fieldDensityThreshold = 10;
    }
}