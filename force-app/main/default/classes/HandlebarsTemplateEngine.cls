/**
 * @description Purpose-built Handlebars-style template engine for Apex.
 * Optimized for GPTfy compliance:
 * - Triple-brace substitution {{{Field}}}
 * - Iteration blocks {{#Collection}}...{{/Collection}}
 * - Empty state handling {{else}} or {{^Collection}}
 * - Prefix-aware field resolution (strips collection names inside loops)
 */
public with sharing class HandlebarsTemplateEngine {
    
    private static final String TRIPLE_BRACE_OPEN = '{{{';
    private static final String TRIPLE_BRACE_CLOSE = '}}}';
    private static final String BLOCK_OPEN_PREFIX = '{{#';
    private static final String BLOCK_CLOSE_PREFIX = '{{/';
    private static final String INVERTED_OPEN_PREFIX = '{{^';
    private static final String ELSE_TAG = '{{else}}';
    private static final String DOUBLE_BRACE_CLOSE = '}}';

    /**
     * @description Merges data into a template string
     */
    public static String render(String template, Map<String, Object> data) {
        if (String.isBlank(template)) return '';
        return processBlocks(template, data);
    }

    /**
     * @description Processes iteration and conditional blocks
     */
    private static String processBlocks(String content, Map<String, Object> context) {
        String result = content;
        
        // 1. Process Inverted Sections: {{^Collection}}...{{/Collection}}
        // (Handled before standard blocks to simplify logic)
        while (result.contains(INVERTED_OPEN_PREFIX)) {
            Integer startIdx = result.indexOf(INVERTED_OPEN_PREFIX);
            Integer tagEndIdx = result.indexOf(DOUBLE_BRACE_CLOSE, startIdx);
            if (tagEndIdx == -1) break;
            
            String collectionName = result.substring(startIdx + 3, tagEndIdx).trim();
            String endTag = BLOCK_CLOSE_PREFIX + collectionName + DOUBLE_BRACE_CLOSE;
            Integer endIdx = result.indexOf(endTag, tagEndIdx);
            if (endIdx == -1) break;
            
            String innerTemplate = result.substring(tagEndIdx + 2, endIdx);
            Object obj = resolveValue(collectionName, context);
            Boolean isEmpty = (obj == null) || (obj instanceof List<Object> && ((List<Object>)obj).isEmpty());
            
            String replacement = isEmpty ? processBlocks(innerTemplate, context) : '';
            result = result.substring(0, startIdx) + replacement + result.substring(endIdx + endTag.length());
        }

        // 2. Process Standard Blocks: {{#Collection}} or {{#if Field}} or {{#if not Field}}
        while (result.contains(BLOCK_OPEN_PREFIX)) {
            Integer startIdx = result.indexOf(BLOCK_OPEN_PREFIX);
            Integer tagEndIdx = result.indexOf(DOUBLE_BRACE_CLOSE, startIdx);
            if (tagEndIdx == -1) break;
            
            String fullTagName = result.substring(startIdx + 3, tagEndIdx).trim();
            String blockType = fullTagName.substringBefore(' ');
            String blockName = String.isBlank(blockType) ? fullTagName : blockType;
            String argument = fullTagName.substringAfter(' ').trim();
            
            // Handle if / if not / each
            String collectionName = blockName;
            Boolean isInvertedIf = false;
            
            if (blockName == 'if') {
                if (argument.startsWith('not ')) {
                    collectionName = argument.substringAfter('not ').trim();
                    isInvertedIf = true;
                } else {
                    // Handle simple expressions like 'HealthScore < 80' - just take the field name
                    collectionName = argument.substringBefore(' ').trim();
                }
            } else if (blockName == 'each') {
                collectionName = argument;
            }

            String endTag = BLOCK_CLOSE_PREFIX + blockName + DOUBLE_BRACE_CLOSE;
            Integer endIdx = result.indexOf(endTag, tagEndIdx);
            
            // If specific end tag not found (e.g. {{/each}}), try generic block close or original name
            if (endIdx == -1 && blockName != fullTagName) {
               endTag = BLOCK_CLOSE_PREFIX + fullTagName + DOUBLE_BRACE_CLOSE;
               endIdx = result.indexOf(endTag, tagEndIdx);
            }
            
            if (endIdx == -1) {
                // Skip this tag to avoid infinite loop
                result = result.substring(0, startIdx) + '_SKIP_' + result.substring(startIdx + 3);
                continue;
            }
            
            String innerContent = result.substring(tagEndIdx + 2, endIdx);
            String mainTemplate = innerContent;
            String elseTemplate = '';
            
            if (innerContent.contains(ELSE_TAG)) {
                mainTemplate = innerContent.substringBefore(ELSE_TAG);
                elseTemplate = innerContent.substringAfter(ELSE_TAG);
            }
            
            String replacement = '';
            Object collectionObj = resolveValue(collectionName, context);
            
            if (blockName == 'if') {
                Boolean condition = (collectionObj != null);
                if (collectionObj instanceof Boolean) condition = (Boolean)collectionObj;
                else if (collectionObj instanceof List<Object>) condition = !((List<Object>)collectionObj).isEmpty();
                
                if (isInvertedIf) condition = !condition;
                
                replacement = condition ? processBlocks(mainTemplate, context) : processBlocks(elseTemplate, context);
            } else {
                // Iteration block
                if (collectionObj instanceof List<Object> && !((List<Object>)collectionObj).isEmpty()) {
                    List<Object> items = (List<Object>) collectionObj;
                    for (Object item : items) {
                        if (item instanceof Map<String, Object>) {
                            replacement += processBlocks(mainTemplate, (Map<String, Object>) item);
                        }
                    }
                } else {
                    replacement = processBlocks(elseTemplate, context);
                }
            }
            
            result = result.substring(0, startIdx) + replacement + result.substring(endIdx + endTag.length());
        }
        
        // Clean up any _SKIP_ tokens
        result = result.replace('_SKIP_', '{{#');
        
        // 3. Process Triple Brace Substitutions: {{{Field}}}
        return substituteFields(result, context);
    }

    /**
     * @description Substitutes {{{Field}}} patterns with prefix-aware resolution
     */
    private static String substituteFields(String content, Map<String, Object> context) {
        String result = content;
        
        while (result.contains(TRIPLE_BRACE_OPEN)) {
            Integer startIdx = result.indexOf(TRIPLE_BRACE_OPEN);
            Integer endIdx = result.indexOf(TRIPLE_BRACE_CLOSE, startIdx);
            if (endIdx == -1) break;
            
            String tag = result.substring(startIdx, endIdx + 3);
            String fieldPath = result.substring(startIdx + 3, endIdx).trim();
            
            Object val = resolveValue(fieldPath, context);
            result = result.replace(tag, (val == null) ? '' : String.valueOf(val));
        }
        
        return result;
    }

    /**
     * @description Resolves value with prefix fallback
     * If path is 'Contacts.Name' but context only has 'Name', it resolves successfully.
     */
    private static Object resolveValue(String path, Map<String, Object> context) {
        Object val = getValue(path, context);
        
        // If not found, try stripping prefixes (GPTfy required prefixes in loops)
        if (val == null && path.contains('.')) {
            String tempPath = path;
            while (tempPath.contains('.')) {
                tempPath = tempPath.substringAfter('.');
                val = getValue(tempPath, context);
                if (val != null) break;
            }
        }
        
        return val;
    }

    /**
     * @description Navigates dot-notated paths
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
