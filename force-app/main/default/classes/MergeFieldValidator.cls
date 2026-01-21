/**
 * @description Utility class to validate merge fields in prompt templates
 * Ensures all {{{FieldName}}} and {{{ObjectName.FieldName}}} references are valid
 */
public with sharing class MergeFieldValidator {

    /**
     * @description Wrapper for merge field information
     */
    public class MergeField {
        @AuraEnabled public String originalText;
        @AuraEnabled public String objectName;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String errorMessage;

        public MergeField(String originalText, String objectName, String fieldName) {
            this.originalText = originalText;
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.isValid = true;
        }
    }

    /**
     * @description Extracts all merge fields from a template
     * @param template HTML or text template containing merge fields
     * @return List of merge field wrapper objects
     */
    public static List<MergeField> extractMergeFields(String template) {
        List<MergeField> mergeFields = new List<MergeField>();

        if (String.isBlank(template)) {
            return mergeFields;
        }

        // Regex pattern to match {{{...}}}
        Pattern mergeFieldPattern = Pattern.compile('\\{\\{\\{([^}]+)\\}\\}\\}');
        Matcher matcher = mergeFieldPattern.matcher(template);

        while (matcher.find()) {
            String fieldReference = matcher.group(1);
            MergeField field = parseMergeField(fieldReference);
            mergeFields.add(field);
        }

        return mergeFields;
    }

    /**
     * @description Parses a merge field reference into object and field names
     * @param fieldReference The content between {{{ and }}}
     * @return MergeField wrapper object
     */
    private static MergeField parseMergeField(String fieldReference) {
        String objectName = null;
        String fieldName = fieldReference.trim();

        // Check if it's a related object field (ObjectName.FieldName)
        if (fieldReference.contains('.')) {
            List<String> parts = fieldReference.split('\\.');
            if (parts.size() == 2) {
                objectName = parts[0].trim();
                fieldName = parts[1].trim();
            }
        }

        return new MergeField('{{{' + fieldReference + '}}}', objectName, fieldName);
    }

    /**
     * @description Validates merge fields against a DCM configuration
     * Handles iteration blocks where fields inside {{#Collection}}...{{/Collection}}
     * don't need object prefix (they refer to fields on the iterated object)
     *
     * STRICT VALIDATION (Jan 2026 fix):
     * - Fields with object prefix (e.g., Contact.Name) MUST have both:
     *   1. The object in the DCM (root or child)
     *   2. The field on that specific object
     * - Fields without prefix are valid if on root OR any child (iteration block support)
     *
     * @param template Template string containing merge fields
     * @param dcmConfig Map representing DCM structure (rootObject, childObjects, fields)
     * @return List of MergeField objects with validation results
     */
    public static List<MergeField> validateAgainstDCM(String template, Map<String, Object> dcmConfig) {
        List<MergeField> mergeFields = extractMergeFields(template);

        String rootObject = (String) dcmConfig.get('rootObject');
        List<String> childObjects = (List<String>) dcmConfig.get('childObjects');
        Map<String, List<String>> fieldsByObject = (Map<String, List<String>>) dcmConfig.get('fieldsByObject');

        // Build set of all valid objects (root + children)
        Set<String> validObjects = new Set<String>();
        validObjects.add(rootObject);
        if (childObjects != null) {
            validObjects.addAll(childObjects);
        }

        // Build a set of ALL field names from ALL objects (for iteration block handling)
        // Fields inside iteration blocks like {{#Contacts}}{{{FirstName}}}{{/Contacts}}
        // are valid without object prefix
        Set<String> allFieldNames = new Set<String>();
        for (String objectName : fieldsByObject.keySet()) {
            for (String fieldName : fieldsByObject.get(objectName)) {
                allFieldNames.add(fieldName);
            }
        }

        for (MergeField field : mergeFields) {
            if (field.objectName == null) {
                // Root object field OR field inside an iteration block (no prefix)
                // Valid if:
                // 1. Field exists on root object
                // 2. OR field exists on ANY object in DCM (could be inside iteration block)
                Boolean foundOnRoot = validateFieldInObject(rootObject, field.fieldName, fieldsByObject);
                Boolean foundAnywhere = allFieldNames.contains(field.fieldName);

                if (!foundOnRoot && !foundAnywhere) {
                    field.isValid = false;
                    field.errorMessage = 'Field "' + field.fieldName + '" not found in DCM';
                }
            } else {
                // STRICT: Field with explicit object prefix (e.g., Contact.Name)
                // BOTH the object AND the field must exist in the DCM
                // This prevents templates from referencing objects not configured in DCM

                // First check: Is the object in the DCM?
                if (!validObjects.contains(field.objectName)) {
                    field.isValid = false;
                    field.errorMessage = 'Object "' + field.objectName + '" not found in DCM. ' +
                        'Available objects: ' + rootObject +
                        (childObjects != null && !childObjects.isEmpty() ? ', ' + String.join(childObjects, ', ') : '');
                }
                // Second check: Is the field on that specific object?
                else if (!validateFieldInObject(field.objectName, field.fieldName, fieldsByObject)) {
                    // Get available fields for helpful error message
                    List<String> availableFields = fieldsByObject.get(field.objectName);
                    String availableFieldsStr = availableFields != null && !availableFields.isEmpty()
                        ? String.join(availableFields, ', ')
                        : '(none)';
                    field.isValid = false;
                    field.errorMessage = 'Field "' + field.fieldName + '" not found on object "' +
                        field.objectName + '" in DCM. Available fields: ' + availableFieldsStr;
                }
            }
        }

        return mergeFields;
    }

    /**
     * @description Checks if a field exists in the DCM configuration for an object
     * @param objectName API name of the object
     * @param fieldName API name of the field
     * @param fieldsByObject Map of object names to their field lists
     * @return true if field exists in DCM
     */
    private static Boolean validateFieldInObject(String objectName, String fieldName,
                                                 Map<String, List<String>> fieldsByObject) {
        if (!fieldsByObject.containsKey(objectName)) {
            return false;
        }

        List<String> fields = fieldsByObject.get(objectName);
        return fields.contains(fieldName);
    }

    /**
     * @description Finds unsubstituted merge fields in output HTML
     * @param outputHtml The generated HTML output
     * @return List of unsubstituted merge field strings
     */
    public static List<String> findUnsubstitutedFields(String outputHtml) {
        List<String> unsubstituted = new List<String>();

        if (String.isBlank(outputHtml)) {
            return unsubstituted;
        }

        Pattern mergeFieldPattern = Pattern.compile('\\{\\{\\{([^}]+)\\}\\}\\}');
        Matcher matcher = mergeFieldPattern.matcher(outputHtml);

        while (matcher.find()) {
            unsubstituted.add(matcher.group(0));
        }

        return unsubstituted;
    }

    /**
     * @description Validates that all merge fields have been substituted
     * @param outputHtml The generated HTML output
     * @return true if no unsubstituted fields found
     */
    public static Boolean allFieldsSubstituted(String outputHtml) {
        return findUnsubstitutedFields(outputHtml).isEmpty();
    }

    /**
     * @description Builds a DCM configuration map from actual records
     * @param dcmId ID of the ccai__AI_Data_Extraction_Mapping__c record
     * @return Map with rootObject, childObjects, and fieldsByObject
     */
    public static Map<String, Object> buildDCMConfigFromRecords(Id dcmId) {
        // Query DCM fields to determine root object and structure
        // Instead of querying ccai__Root_Object__c (which may not exist),
        // we derive the root object from the DCM field records
        // Note: Using ccai__Field__c and ccai__Object__c instead of ccai__API_Name__c
        // which may not exist on this object
        List<ccai__AI_Data_Extraction_Field__c> dcmFields = [
            SELECT Id, ccai__Type__c, ccai__Field__c, ccai__Object__c
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            AND ccai__Type__c IN ('OBJECT', 'FIELD')
            ORDER BY ccai__Type__c DESC
        ];

        if (dcmFields.isEmpty()) {
            return null;
        }

        // Determine root object from the first OBJECT type field or from FIELD records
        String rootObject = null;
        Set<String> childObjects = new Set<String>();
        Map<String, List<String>> fieldsByObject = new Map<String, List<String>>();

        // First pass: identify all objects
        for (ccai__AI_Data_Extraction_Field__c field : dcmFields) {
            if (field.ccai__Type__c == 'OBJECT') {
                // For OBJECT type, ccai__Object__c contains the object API name
                String objName = field.ccai__Object__c;
                if (rootObject == null) {
                    // First OBJECT entry is typically the root
                    rootObject = objName;
                    fieldsByObject.put(rootObject, new List<String>());
                } else {
                    childObjects.add(objName);
                    fieldsByObject.put(objName, new List<String>());
                }
            }
        }

        // If no OBJECT type found, try to derive from FIELD records
        if (rootObject == null) {
            for (ccai__AI_Data_Extraction_Field__c field : dcmFields) {
                if (field.ccai__Type__c == 'FIELD' && field.ccai__Object__c != null) {
                    rootObject = field.ccai__Object__c;
                    fieldsByObject.put(rootObject, new List<String>());
                    break;
                }
            }
        }

        // If still no root object, return null
        if (rootObject == null) {
            return null;
        }

        // Second pass: add fields to their objects
        for (ccai__AI_Data_Extraction_Field__c field : dcmFields) {
            if (field.ccai__Type__c == 'FIELD') {
                String objectName = field.ccai__Object__c != null ?
                                   field.ccai__Object__c : rootObject;
                if (!fieldsByObject.containsKey(objectName)) {
                    fieldsByObject.put(objectName, new List<String>());
                }
                // Use ccai__Field__c for the field API name
                if (field.ccai__Field__c != null) {
                    fieldsByObject.get(objectName).add(field.ccai__Field__c);
                }
            }
        }

        return new Map<String, Object>{
            'rootObject' => rootObject,
            'childObjects' => new List<String>(childObjects),
            'fieldsByObject' => fieldsByObject
        };
    }

    /**
     * @description Gets a summary of validation results
     * @param mergeFields List of validated merge fields
     * @return Map with counts of valid, invalid, and total fields
     */
    public static Map<String, Integer> getValidationSummary(List<MergeField> mergeFields) {
        Integer total = mergeFields.size();
        Integer valid = 0;
        Integer invalid = 0;

        for (MergeField field : mergeFields) {
            if (field.isValid) {
                valid++;
            } else {
                invalid++;
            }
        }

        return new Map<String, Integer>{
            'total' => total,
            'valid' => valid,
            'invalid' => invalid
        };
    }
}