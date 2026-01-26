/**
 * @description Utility class to load and manage GPTfy security filters
 *
 * Provides dynamic access to ccai__AI_Security_Filters__c records for
 * applying field-level masking during prompt generation.
 *
 * Usage:
 *   // Load all active filters
 *   List<GPTfySecurityFilterLoader.SecurityFilter> filters = GPTfySecurityFilterLoader.getActiveFilters();
 *
 *   // Get filters by type
 *   List<GPTfySecurityFilterLoader.SecurityFilter> emailFilters = GPTfySecurityFilterLoader.getFiltersByType('Email');
 *
 *   // Get recommended filter for a field
 *   GPTfySecurityFilterLoader.SecurityFilter filter = GPTfySecurityFilterLoader.getRecommendedFilter('Account', 'Name');
 *
 * @author Claude (Prompt Factory V2.6)
 * @date 2026-01-26
 */
public with sharing class GPTfySecurityFilterLoader {

    // Cache for loaded filters (cleared on each transaction)
    private static List<SecurityFilter> cachedFilters;
    private static Map<String, List<SecurityFilter>> filtersByType;

    // Standard field-to-filter mappings for auto-detection
    private static final Map<String, String> FIELD_TO_FILTER_TYPE = new Map<String, String>{
        // Email fields
        'Email' => 'Email',
        'PersonEmail' => 'Email',
        'npe01__HomeEmail__c' => 'Email',
        'npe01__WorkEmail__c' => 'Email',

        // Phone fields
        'Phone' => 'Phone',
        'Fax' => 'Phone',
        'MobilePhone' => 'Phone',
        'HomePhone' => 'Phone',
        'OtherPhone' => 'Phone',
        'AssistantPhone' => 'Phone',

        // Name fields (company names that might trigger content filters)
        'Name' => 'Company',
        'CompanyName' => 'Company',
        'Account.Name' => 'Company',

        // URL fields
        'Website' => 'URL',
        'PhotoUrl' => 'URL',

        // ID/Tax fields
        'SSN__c' => 'National/Tax ID',
        'TaxId__c' => 'National/Tax ID',
        'NationalId__c' => 'National/Tax ID'
    };

    // Custom mask patterns for fields without standard filters
    private static final Map<String, String> CUSTOM_MASKS = new Map<String, String>{
        'Company' => 'Company{n}',
        'Person' => 'Person{n}',
        'Contact' => 'Contact{n}'
    };

    /**
     * @description Wrapper class for security filter data
     */
    public class SecurityFilter {
        public Id filterId;
        public String name;
        public String filterType;
        public String replacementValue;
        public String searchPattern;
        public String comment;
        public Boolean isActive;

        public SecurityFilter(ccai__AI_Security_Filters__c record) {
            this.filterId = record.Id;
            this.name = record.Name;
            this.filterType = record.ccai__Type__c;
            this.replacementValue = record.ccai__Replacement_Value__c;
            this.searchPattern = record.ccai__Search_Pattern__c;
            this.comment = record.ccai__Comment__c;
            this.isActive = record.ccai__Status__c == 'Active';
        }
    }

    /**
     * @description Field security configuration for DCM creation
     */
    public class FieldSecurityConfig {
        public String objectName;
        public String fieldName;
        public String fieldLabel;
        public String anonymizeWith;      // The mask pattern (e.g., "Company{n}")
        public String maskingScope;       // "Entire Value" or "Partial"
        public Boolean scanForPII;

        public FieldSecurityConfig(String objectName, String fieldName, String fieldLabel) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.anonymizeWith = null;
            this.maskingScope = null;
            this.scanForPII = false;
        }
    }

    /**
     * @description Get all active security filters
     * @return List of SecurityFilter wrappers
     */
    public static List<SecurityFilter> getActiveFilters() {
        if (cachedFilters != null) {
            return cachedFilters;
        }

        cachedFilters = new List<SecurityFilter>();
        filtersByType = new Map<String, List<SecurityFilter>>();

        List<ccai__AI_Security_Filters__c> records = [
            SELECT Id, Name, ccai__Type__c, ccai__Replacement_Value__c,
                   ccai__Search_Pattern__c, ccai__Comment__c, ccai__Status__c
            FROM ccai__AI_Security_Filters__c
            WHERE ccai__Status__c = 'Active'
            ORDER BY ccai__Type__c, Name
        ];

        for (ccai__AI_Security_Filters__c record : records) {
            SecurityFilter filter = new SecurityFilter(record);
            cachedFilters.add(filter);

            // Index by type
            String filterType = filter.filterType != null ? filter.filterType : 'Others';
            if (!filtersByType.containsKey(filterType)) {
                filtersByType.put(filterType, new List<SecurityFilter>());
            }
            filtersByType.get(filterType).add(filter);
        }

        System.debug('GPTfySecurityFilterLoader: Loaded ' + cachedFilters.size() + ' active filters');
        return cachedFilters;
    }

    /**
     * @description Get filters by type (Email, Phone, National/Tax ID, etc.)
     * @param filterType The type to filter by
     * @return List of matching SecurityFilter wrappers
     */
    public static List<SecurityFilter> getFiltersByType(String filterType) {
        if (filtersByType == null) {
            getActiveFilters();
        }

        return filtersByType.containsKey(filterType)
            ? filtersByType.get(filterType)
            : new List<SecurityFilter>();
    }

    /**
     * @description Get all available filter types
     * @return Set of filter type names
     */
    public static Set<String> getAvailableFilterTypes() {
        if (filtersByType == null) {
            getActiveFilters();
        }
        return filtersByType.keySet();
    }

    /**
     * @description Get recommended filter for a specific field
     * Auto-detects based on field name and object context
     * @param objectName The SObject API name
     * @param fieldName The field API name
     * @return SecurityFilter or null if no match
     */
    public static SecurityFilter getRecommendedFilter(String objectName, String fieldName) {
        // Check for exact field match first
        String fullFieldPath = objectName + '.' + fieldName;
        String filterType = FIELD_TO_FILTER_TYPE.get(fullFieldPath);

        // Fall back to field name only
        if (filterType == null) {
            filterType = FIELD_TO_FILTER_TYPE.get(fieldName);
        }

        if (filterType == null) {
            return null;
        }

        // Get first filter of matching type
        List<SecurityFilter> filters = getFiltersByType(filterType);
        return filters.isEmpty() ? null : filters[0];
    }

    /**
     * @description Get field security configuration with auto-detection
     * Analyzes field and recommends appropriate masking
     * @param objectName The SObject API name
     * @param fieldName The field API name
     * @param fieldLabel The field label for display
     * @return FieldSecurityConfig with recommended settings
     */
    public static FieldSecurityConfig getFieldSecurityConfig(String objectName, String fieldName, String fieldLabel) {
        FieldSecurityConfig config = new FieldSecurityConfig(objectName, fieldName, fieldLabel);

        // Check for standard filter mapping
        String fullFieldPath = objectName + '.' + fieldName;
        String filterType = FIELD_TO_FILTER_TYPE.get(fullFieldPath);
        if (filterType == null) {
            filterType = FIELD_TO_FILTER_TYPE.get(fieldName);
        }

        if (filterType != null) {
            // Check if we have a custom mask for this type
            if (CUSTOM_MASKS.containsKey(filterType)) {
                config.anonymizeWith = CUSTOM_MASKS.get(filterType);
                config.maskingScope = 'Entire Value';
                config.scanForPII = false;
            } else {
                // Use GPTfy's built-in filter
                List<SecurityFilter> filters = getFiltersByType(filterType);
                if (!filters.isEmpty()) {
                    config.anonymizeWith = filters[0].replacementValue;
                    config.maskingScope = 'Entire Value';
                    config.scanForPII = true;
                }
            }
        }

        return config;
    }

    /**
     * @description Get security configurations for multiple fields
     * Batch method for efficiency during DCM creation
     * @param fieldInfos List of maps with 'objectName', 'fieldName', 'fieldLabel' keys
     * @return List of FieldSecurityConfig objects
     */
    public static List<FieldSecurityConfig> getFieldSecurityConfigs(List<Map<String, String>> fieldInfos) {
        // Pre-load filters
        getActiveFilters();

        List<FieldSecurityConfig> configs = new List<FieldSecurityConfig>();

        for (Map<String, String> fieldInfo : fieldInfos) {
            String objectName = fieldInfo.get('objectName');
            String fieldName = fieldInfo.get('fieldName');
            String fieldLabel = fieldInfo.get('fieldLabel');

            configs.add(getFieldSecurityConfig(objectName, fieldName, fieldLabel));
        }

        return configs;
    }

    /**
     * @description Get summary of available filters for logging/display
     * @return Map of filter type to count
     */
    public static Map<String, Integer> getFilterSummary() {
        if (filtersByType == null) {
            getActiveFilters();
        }

        Map<String, Integer> summary = new Map<String, Integer>();
        for (String filterType : filtersByType.keySet()) {
            summary.put(filterType, filtersByType.get(filterType).size());
        }
        return summary;
    }

    /**
     * @description Clear the cache (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        cachedFilters = null;
        filtersByType = null;
    }

    /**
     * @description Check if a field should have PII scanning enabled
     * Based on field name patterns
     * @param fieldName The field API name
     * @return true if PII scanning recommended
     */
    public static Boolean shouldScanForPII(String fieldName) {
        if (String.isBlank(fieldName)) {
            return false;
        }

        String lowerField = fieldName.toLowerCase();

        // Fields that commonly contain PII
        return lowerField.contains('email') ||
               lowerField.contains('phone') ||
               lowerField.contains('mobile') ||
               lowerField.contains('fax') ||
               lowerField.contains('ssn') ||
               lowerField.contains('social') ||
               lowerField.contains('tax') ||
               lowerField.contains('national') ||
               lowerField.contains('passport') ||
               lowerField.contains('license') ||
               lowerField.contains('credit') ||
               lowerField.contains('card') ||
               lowerField.contains('account') ||
               lowerField.contains('routing');
    }
}
