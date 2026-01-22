/**
 * @description Field metadata extraction service for picklist intelligence
 * Provides stage-relative context for picklist fields
 */
public class FieldMetadataService implements IFieldService {
    
    /**
     * @description Execute metadata extraction for a picklist field
     * @param data Map with keys: objectName, fieldName, currentValue
     * @return Formatted field context string
     */
    public String execute(Map<String, Object> data) {
        try {
            String objectName = (String) data.get('objectName');
            String fieldName = (String) data.get('fieldName');
            String currentValue = (String) data.get('currentValue');
            
            if (String.isBlank(objectName) || String.isBlank(fieldName)) {
                return '';
            }
            
            return getPicklistContext(objectName, fieldName, currentValue);
            
        } catch (Exception e) {
            System.debug('FieldMetadataService error: ' + e.getMessage());
            return '';
        }
    }
    
    /**
     * @description Extract picklist values and provide stage-relative context
     * @param objectName Salesforce object API name
     * @param fieldName Field API name
     * @param currentValue Current field value
     * @return Formatted context block
     */
    private String getPicklistContext(String objectName, String fieldName, String currentValue) {
        try {
            // Get object describe
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) {
                return '';
            }
            
            // Get field describe
            Schema.DescribeFieldResult fieldDescribe = 
                objType.getDescribe().fields.getMap().get(fieldName)?.getDescribe();
            
            if (fieldDescribe == null || fieldDescribe.getType() != Schema.DisplayType.PICKLIST) {
                return '';
            }
            
            // Get picklist values
            List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
            if (entries.isEmpty()) {
                return '';
            }
            
            // Build context string
            String context = '';
            context += '=== FIELD CONTEXT: ' + objectName + '.' + fieldName + ' ===\n\n';
            context += 'Current Value: "' + (currentValue != null ? currentValue : 'Not Set') + '"\n\n';
            context += 'Available Values (' + entries.size() + ' total):\n';
            
            Integer order = 1;
            Integer currentPosition = null;
            List<String> valueList = new List<String>();
            
            for (Schema.PicklistEntry entry : entries) {
                if (entry.isActive()) {
                    String marker = '';
                    if (entry.getValue() == currentValue) {
                        marker = ' ← CURRENT';
                        currentPosition = order;
                    }
                    
                    String line = '  ' + order + '. ' + entry.getLabel() + marker;
                    
                    // Add probability for OpportunityStage
                    if (objectName == 'Opportunity' && fieldName == 'StageName') {
                        Decimal probability = getStageProbability(entry.getValue());
                        if (probability != null) {
                            line += ' (' + probability.intValue() + '% probability)';
                        }
                    }
                    
                    valueList.add(line);
                    context += line + '\n';
                    order++;
                }
            }
            
            // Add stage-relative analysis
            if (currentPosition != null) {
                Integer totalValues = order - 1;
                context += '\nStage Analysis:\n';
                
                if (currentPosition <= totalValues / 3) {
                    context += '- Position: EARLY stage (' + currentPosition + ' of ' + totalValues + ')\n';
                    context += '- Typical behavior: Long runway, lower probability, focus on qualification\n';
                    context += '- Risk threshold: Probability <20% is NORMAL for early stage\n';
                } else if (currentPosition <= 2 * totalValues / 3) {
                    context += '- Position: MID stage (' + currentPosition + ' of ' + totalValues + ')\n';
                    context += '- Typical behavior: Active engagement, increasing probability, proposal phase\n';
                    context += '- Risk threshold: Probability <40% or slow velocity is concerning\n';
                } else {
                    context += '- Position: LATE stage (' + currentPosition + ' of ' + totalValues + ')\n';
                    context += '- Typical behavior: Contract negotiation, high probability, near close\n';
                    context += '- Risk threshold: Probability <60% or missing stakeholders is HIGH RISK\n';
                }
                
                context += '\nIMPORTANT: When evaluating this field, consider the expected behavior ';
                context += 'for this stage position. A "low" probability may be NORMAL for an early ';
                context += 'stage, while the same probability in a late stage is a red flag.\n';
            }
            
            context += '\n---\n\n';
            return context;
            
        } catch (Exception e) {
            System.debug('getPicklistContext error: ' + e.getMessage());
            return '';
        }
    }
    
    /**
     * @description Get probability for OpportunityStage (if available)
     * @param stageName Stage name
     * @return Probability percentage or null
     */
    private Decimal getStageProbability(String stageName) {
        try {
            List<OpportunityStage> stages = [
                SELECT DefaultProbability
                FROM OpportunityStage
                WHERE MasterLabel = :stageName OR ApiName = :stageName
                LIMIT 1
            ];
            
            return stages.isEmpty() ? null : stages[0].DefaultProbability;
            
        } catch (Exception e) {
            return null;
        }
    }
}
