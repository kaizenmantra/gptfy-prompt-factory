public with sharing class ApexFieldMetadataService implements IApexService {
    
    // --- Special Picklist Registry ---
    public enum SpecialPicklistType {
        OPPORTUNITY_STAGE,
        CASE_STATUS,
        LEAD_STATUS
    }

    private static final Map<String, SpecialPicklistType> SPECIAL_REGISTRY = new Map<String, SpecialPicklistType>{
        'Opportunity.StageName' => SpecialPicklistType.OPPORTUNITY_STAGE,
        'Case.Status' => SpecialPicklistType.CASE_STATUS,
        'Lead.Status' => SpecialPicklistType.LEAD_STATUS
    };

    /**
     * Main execution method.
     * inputs expectations:
     * - 'rootObject' (String): The main object being processed.
     * - 'selectedFields' (Map<String, List<String>>): The fields selected for the prompt.
     * - 'fieldMetadata' (Map<String, String>): Optional optimization map (Field API Name -> Field Type).
     */
    public String execute(Map<String, Object> inputs) {
        String rootObject = (String) inputs.get('rootObject');
        Map<String, Object> selectedFieldsUntyped = (Map<String, Object>) inputs.get('selectedFields');
        Map<String, Object> fieldMetadataUntyped = (Map<String, Object>) inputs.get('fieldMetadata');

        // Cast safely (inputs from JSON deserialization might be generic Objects)
        Map<String, List<String>> selectedFields = new Map<String, List<String>>();
        if (selectedFieldsUntyped != null) {
            for (String obj : selectedFieldsUntyped.keySet()) {
                Object listObj = selectedFieldsUntyped.get(obj);
                if (listObj instanceof List<Object>) {
                    List<String> fields = new List<String>();
                    for (Object field : (List<Object>) listObj) {
                        fields.add((String) field);
                    }
                    selectedFields.put(obj, fields);
                }
            }
        }

        Map<String, String> fieldMetadata = new Map<String, String>();
        if (fieldMetadataUntyped != null) {
            for (String key : fieldMetadataUntyped.keySet()) {
                fieldMetadata.put(key, (String) fieldMetadataUntyped.get(key));
            }
        }

        List<String> contextLines = new List<String>();
        contextLines.add('## Picklist Context Analysis');

        // Iterate over objects in selectedFields (usually just rootObject, but could be related objects)
        for (String objName : selectedFields.keySet()) {
            List<String> fields = selectedFields.get(objName);
            if (fields == null) continue;

            for (String fieldName : fields) {
                // 1. Identify if it is a Picklist
                // Optimization: Check fieldMetadata first if available
                boolean isPicklist = false;
                if (fieldMetadata.containsKey(fieldName) && fieldMetadata.get(fieldName) == 'PICKLIST') {
                    isPicklist = true;
                } else if (!fieldMetadata.containsKey(fieldName)) {
                    // Fallback to Describe if generic metadata not passed (or for sanity check)
                    // We only do this check if we don't have the optimization map
                    // effectively "Lazy Loading" the describe
                     try {
                        Schema.DescribeFieldResult dfr = SchemaHelper.getFieldDescribe(objName, fieldName);
                        if (dfr != null && dfr.getType() == Schema.DisplayType.PICKLIST) {
                            isPicklist = true;
                        }
                    } catch (Exception e) {
                        // Field might not exist or be accessible
                        continue;
                    }
                }

                if (isPicklist) {
                    String enrichment = processPicklist(objName, fieldName);
                    if (String.isNotBlank(enrichment)) {
                        contextLines.add(enrichment);
                    }
                }
            }
        }

        if (contextLines.size() <= 1) {
            return ''; // No picklists found
        }

        return String.join(contextLines, '\n\n');
    }

    private String processPicklist(String objName, String fieldName) {
        String key = objName + '.' + fieldName;
        SpecialPicklistType specialType = SPECIAL_REGISTRY.get(key);

        if (specialType != null) {
            return handleSpecialPicklist(objName, fieldName, specialType);
        } else {
            return handleStandardPicklist(objName, fieldName);
        }
    }

    // --- Special Handlers ---

    private String handleSpecialPicklist(String objName, String fieldName, SpecialPicklistType type) {
        if (type == SpecialPicklistType.OPPORTUNITY_STAGE) {
            return getOpportunityStageContext();
        } else if (type == SpecialPicklistType.CASE_STATUS) {
            return getCaseStatusContext();
        } else if (type == SpecialPicklistType.LEAD_STATUS) {
            return getLeadStatusContext();
        }
        return null;
    }

    private String getOpportunityStageContext() {
        List<OpportunityStage> stages = [SELECT ApiName, DefaultProbability, SortOrder, IsClosed, IsWon FROM OpportunityStage WHERE IsActive = true ORDER BY SortOrder ASC];
        
        String output = '### Field: Opportunity.StageName (Business Process)\n';
        output += 'This field represents the sales cycle. Higher probability indicates closer to closing.\n';
        output += '| Stage Name | Probability | Type |\n';
        output += '| :--- | :--- | :--- |\n';
        
        for (OpportunityStage stage : stages) {
            String statusType = stage.IsWon ? 'Closed Won' : (stage.IsClosed ? 'Closed Lost' : 'Open');
            output += '| ' + stage.ApiName + ' | ' + stage.DefaultProbability + '% | ' + statusType + ' |\n';
        }
        return output;
    }

    private String getCaseStatusContext() {
        List<CaseStatus> statuses = [SELECT ApiName, SortOrder, IsClosed FROM CaseStatus ORDER BY SortOrder ASC];
        
        String output = '### Field: Case.Status (Support Process)\n';
        output += 'This field tracks the resolution lifecycle of a support case.\n';
        output += '| Status | Category |\n';
        output += '| :--- | :--- |\n';
        
        for (CaseStatus status : statuses) {
            String category = status.IsClosed ? 'Closed' : 'Open';
            output += '| ' + status.ApiName + ' | ' + category + ' |\n';
        }
        return output;
    }

    private String getLeadStatusContext() {
        List<LeadStatus> statuses = [SELECT ApiName, SortOrder, IsConverted FROM LeadStatus ORDER BY SortOrder ASC];
        
        String output = '### Field: Lead.Status (Lead Process)\n';
        output += '| Status | Converted? |\n';
        output += '| :--- | :--- |\n';
        
        for (LeadStatus status : statuses) {
            String converted = status.IsConverted ? 'Yes' : 'No';
            output += '| ' + status.ApiName + ' | ' + converted + ' |\n';
        }
        return output;
    }

    // --- Standard Handler ---

    private String handleStandardPicklist(String objName, String fieldName) {
        Schema.DescribeFieldResult dfr = SchemaHelper.getFieldDescribe(objName, fieldName);
        if (dfr == null) return null;

        List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
        if (entries.isEmpty()) return null;

        // Heuristic: If too many values, just summarize active ones
        Integer activeCount = 0;
        List<String> values = new List<String>();
        
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                activeCount++;
                if (values.size() < 20) { // Limit to first 20 to avoid token bloat
                    values.add(entry.getLabel());
                }
            }
        }

        String output = '### Field: ' + objName + '.' + fieldName + '\n';
        output += 'Defined Values (' + activeCount + ' total): ' + String.join(values, ', ');
        if (activeCount > 20) output += '... (truncated)';
        
        return output;
    }
}
