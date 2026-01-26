/**
 * @description Purpose-built Handlebars-style template engine for Apex.
 * Supports triple-brace substitution {{{Field}}}, iteration blocks {{#Collection}},
 * and nested loops for grandchild records.
 */
public with sharing class HandlebarsTemplateEngine {
    
    private static final String TRIPLE_BRACE_OPEN = '{{{';
    private static final String TRIPLE_BRACE_CLOSE = '}}}';
    private static final String BLOCK_OPEN_PREFIX = '{{#';
    private static final String BLOCK_CLOSE_PREFIX = '{{/';
    private static final String DOUBLE_BRACE_CLOSE = '}}';

    /**
     * @description Merges data into a template string
     * @param template The Handlebars template
     * @param data Map of data (supports nested maps/lists for loops)
     * @return Merged string
     */
    public static String render(String template, Map<String, Object> data) {
        if (String.isBlank(template)) {
            return '';
        }
        
        return processBlocks(template, data);
    }

    /**
     * @description Processes #Collection blocks and substitutions
     */
    private static String processBlocks(String content, Map<String, Object> context) {
        String result = content;
        
        // 1. Process Iteration Blocks: {{#Collection}}...{{/Collection}}
        while (result.contains(BLOCK_OPEN_PREFIX)) {
            Integer startIdx = result.indexOf(BLOCK_OPEN_PREFIX);
            Integer tagEndIdx = result.indexOf(DOUBLE_BRACE_CLOSE, startIdx);
            if (tagEndIdx == -1) break;
            
            String collectionName = result.substring(startIdx + 3, tagEndIdx).trim();
            String endTag = BLOCK_CLOSE_PREFIX + collectionName + DOUBLE_BRACE_CLOSE;
            Integer endIdx = result.indexOf(endTag, tagEndIdx);
            
            if (endIdx == -1) {
                // Orphaned open tag, remove it to avoid infinite loop
                result = result.substring(0, startIdx) + result.substring(tagEndIdx + 2);
                continue;
            }
            
            String innerTemplate = result.substring(tagEndIdx + 2, endIdx);
            String replacement = '';
            
            Object collectionObj = getValue(collectionName, context);
            if (collectionObj instanceof List<Object>) {
                List<Object> items = (List<Object>) collectionObj;
                for (Object item : items) {
                    if (item instanceof Map<String, Object>) {
                        // Process the inner template with the item context
                        replacement += render(innerTemplate, (Map<String, Object>) item);
                    }
                }
            }
            
            result = result.substring(0, startIdx) + replacement + result.substring(endIdx + endTag.length());
        }
        
        // 2. Process Triple Brace Substitutions: {{{Field}}}
        return substituteFields(result, context);
    }

    /**
     * @description Substitutes {{{Field}}} and {{{Relationship.Field}}} patterns
     */
    private static String substituteFields(String content, Map<String, Object> context) {
        String result = content;
        
        while (result.contains(TRIPLE_BRACE_OPEN)) {
            Integer startIdx = result.indexOf(TRIPLE_BRACE_OPEN);
            Integer endIdx = result.indexOf(TRIPLE_BRACE_CLOSE, startIdx);
            if (endIdx == -1) break;
            
            String tag = result.substring(startIdx, endIdx + 3);
            String fieldPath = result.substring(startIdx + 3, endIdx).trim();
            
            Object val = getValue(fieldPath, context);
            String stringVal = (val == null) ? '' : String.valueOf(val);
            
            result = result.replace(tag, stringVal);
        }
        
        return result;
    }

    /**
     * @description Navigates a dot-notated path (e.g., Account.Name or Opportunities.Amount)
     */
    private static Object getValue(String path, Map<String, Object> context) {
        if (context == null || String.isBlank(path)) return null;
        
        if (!path.contains('.')) {
            return context.get(path);
        }
        
        String head = path.substringBefore('.');
        String tail = path.substringAfter('.');
        
        Object nextContext = context.get(head);
        if (nextContext instanceof Map<String, Object>) {
            return getValue(tail, (Map<String, Object>) nextContext);
        }
        
        return null;
    }
}
