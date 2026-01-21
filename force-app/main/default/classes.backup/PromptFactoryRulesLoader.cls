/**
 * @description Loads validation rules from Static Resources for Prompt Factory
 * Provides cached access to merge field rules, output validation rules, and UI patterns.
 */
public with sharing class PromptFactoryRulesLoader {

    // Cached rules
    private static Map<String, Object> mergeFieldRules;
    private static Map<String, Object> outputValidationRules;
    private static Map<String, Object> uiPatterns;

    /**
     * @description Gets merge field rules from PF_MergeFieldRules static resource
     * @return Map of merge field rules
     */
    public static Map<String, Object> getMergeFieldRules() {
        if (mergeFieldRules == null) {
            mergeFieldRules = loadStaticResource('PF_MergeFieldRules');
        }
        return mergeFieldRules;
    }

    /**
     * @description Gets output validation rules from PF_OutputValidationRules static resource
     * @return Map of output validation rules
     */
    public static Map<String, Object> getOutputValidationRules() {
        if (outputValidationRules == null) {
            outputValidationRules = loadStaticResource('PF_OutputValidationRules');
        }
        return outputValidationRules;
    }

    /**
     * @description Gets UI patterns from PF_UIPatterns static resource
     * @return Map of UI patterns
     */
    public static Map<String, Object> getUIPatterns() {
        if (uiPatterns == null) {
            uiPatterns = loadStaticResource('PF_UIPatterns');
        }
        return uiPatterns;
    }

    /**
     * @description Loads and parses a JSON static resource
     * @param resourceName Name of the static resource
     * @return Parsed JSON as a Map
     */
    private static Map<String, Object> loadStaticResource(String resourceName) {
        try {
            List<StaticResource> resources = [
                SELECT Body FROM StaticResource
                WHERE Name = :resourceName
                LIMIT 1
            ];

            if (resources.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'Static resource not found: ' + resourceName);
                return new Map<String, Object>();
            }

            String jsonContent = resources[0].Body.toString();
            return (Map<String, Object>) JSON.deserializeUntyped(jsonContent);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to load static resource ' + resourceName + ': ' + e.getMessage());
            return new Map<String, Object>();
        }
    }

    /**
     * @description Gets a specific rule section from merge field rules
     * @param sectionName Name of the section (e.g., 'syntaxRules', 'validMergeFieldPatterns')
     * @return Map of rules in that section
     */
    public static Map<String, Object> getMergeFieldRuleSection(String sectionName) {
        Map<String, Object> rules = getMergeFieldRules();
        if (rules.containsKey(sectionName)) {
            return (Map<String, Object>) rules.get(sectionName);
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets critical validation rules for output checking
     * @return Map of critical rules
     */
    public static Map<String, Object> getCriticalOutputRules() {
        Map<String, Object> rules = getOutputValidationRules();
        if (rules.containsKey('criticalRules')) {
            return (Map<String, Object>) rules.get('criticalRules');
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets security validation rules
     * @return Map of security rules
     */
    public static Map<String, Object> getSecurityRules() {
        Map<String, Object> rules = getOutputValidationRules();
        if (rules.containsKey('securityRules')) {
            return (Map<String, Object>) rules.get('securityRules');
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets placeholder patterns to check for
     * @return List of placeholder patterns
     */
    public static List<Map<String, Object>> getPlaceholderPatterns() {
        Map<String, Object> rules = getOutputValidationRules();
        if (rules.containsKey('placeholderRules')) {
            Map<String, Object> placeholderRules = (Map<String, Object>) rules.get('placeholderRules');
            if (placeholderRules.containsKey('rule8_noPlaceholders')) {
                Map<String, Object> rule8 = (Map<String, Object>) placeholderRules.get('rule8_noPlaceholders');
                if (rule8.containsKey('patterns')) {
                    List<Object> patterns = (List<Object>) rule8.get('patterns');
                    List<Map<String, Object>> result = new List<Map<String, Object>>();
                    for (Object p : patterns) {
                        result.add((Map<String, Object>) p);
                    }
                    return result;
                }
            }
        }
        return new List<Map<String, Object>>();
    }

    /**
     * @description Gets color scheme for a specific theme
     * @param themeName Name of the color scheme (e.g., 'salesforce', 'scoreColors')
     * @return Map of colors
     */
    public static Map<String, Object> getColorScheme(String themeName) {
        Map<String, Object> patterns = getUIPatterns();
        if (patterns.containsKey('colorSchemes')) {
            Map<String, Object> schemes = (Map<String, Object>) patterns.get('colorSchemes');
            if (schemes.containsKey(themeName)) {
                return (Map<String, Object>) schemes.get(themeName);
            }
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets common styles for HTML generation
     * @return Map of style name to style string
     */
    public static Map<String, Object> getCommonStyles() {
        Map<String, Object> patterns = getUIPatterns();
        if (patterns.containsKey('commonStyles')) {
            return (Map<String, Object>) patterns.get('commonStyles');
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets ready-to-use inline styles from PF_UIPatterns
     * These are complete style strings that can be copy-pasted into style="" attributes
     * @return Map of style name to inline style string
     */
    public static Map<String, Object> getInlineStyles() {
        Map<String, Object> patterns = getUIPatterns();
        if (patterns.containsKey('inlineStyles')) {
            return (Map<String, Object>) patterns.get('inlineStyles');
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets color palette from PF_UIPatterns
     * Contains primary, semantic, neutral, and score colors
     * @return Map of color categories
     */
    public static Map<String, Object> getColorPalette() {
        Map<String, Object> patterns = getUIPatterns();
        if (patterns.containsKey('colorPalette')) {
            return (Map<String, Object>) patterns.get('colorPalette');
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets HTML template requirements (critical rules)
     * @return Map of requirements
     */
    public static Map<String, Object> getHTMLTemplateRequirements() {
        Map<String, Object> patterns = getUIPatterns();
        if (patterns.containsKey('htmlTemplateRequirements')) {
            return (Map<String, Object>) patterns.get('htmlTemplateRequirements');
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets UI pattern definition for a specific pattern
     * @param patternName Name of the pattern (e.g., 'accountSummary', 'caseSummary')
     * @return Map of pattern definition
     */
    public static Map<String, Object> getUIPattern(String patternName) {
        Map<String, Object> patterns = getUIPatterns();
        if (patterns.containsKey('patterns')) {
            Map<String, Object> allPatterns = (Map<String, Object>) patterns.get('patterns');
            if (allPatterns.containsKey(patternName)) {
                return (Map<String, Object>) allPatterns.get(patternName);
            }
        }
        return new Map<String, Object>();
    }

    /**
     * @description Gets forbidden merge field patterns
     * @return List of forbidden pattern definitions
     */
    public static List<Map<String, Object>> getForbiddenMergePatterns() {
        Map<String, Object> rules = getMergeFieldRules();
        if (rules.containsKey('forbiddenPatterns')) {
            List<Object> patterns = (List<Object>) rules.get('forbiddenPatterns');
            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for (Object p : patterns) {
                result.add((Map<String, Object>) p);
            }
            return result;
        }
        return new List<Map<String, Object>>();
    }

    /**
     * @description Gets DCM rules for validation
     * @return Map of DCM rules
     */
    public static Map<String, Object> getDCMRules() {
        Map<String, Object> rules = getMergeFieldRules();
        if (rules.containsKey('dcmRules')) {
            return (Map<String, Object>) rules.get('dcmRules');
        }
        return new Map<String, Object>();
    }

    /**
     * @description Clears cached rules (useful for testing or after static resource updates)
     */
    public static void clearCache() {
        mergeFieldRules = null;
        outputValidationRules = null;
        uiPatterns = null;
    }
}