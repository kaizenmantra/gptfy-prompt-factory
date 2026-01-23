/**
 * @description Service to inject relevant prompt topics based on the root object
 * Implements the IApexService interface for the Prompt Factory pipeline
 */
public class PromptTopicService implements IApexService {

    /**
     * @description Executes the service logic
     * @param inputs Map containing stage inputs (rootObject, businessContext, etc.)
     * @return Formatted string with relevant topics
     */
    public String execute(Map<String, Object> inputs) {
        String rootObject = (String) inputs.get('rootObject');
        if (String.isBlank(rootObject)) {
            return '';
        }

        String output = '=== RELEVANT PROMPT TOPICS (Contextual) ===\n';
        output += 'Consider these themes when generating content:\n';

        // simple heuristic based on object type
        if (rootObject == 'Opportunity') {
            output += '- Revenue Growth\n';
            output += '- Deal Velocity\n';
            output += '- Risk Mitigation\n';
        } else if (rootObject == 'Case') {
            output += '- Customer Satisfaction (CSAT)\n';
            output += '- Resolution Efficiency\n';
            output += '- Issue De-escalation\n';
        } else if (rootObject == 'Lead') {
            output += '- Conversion Rate Optimization\n';
            output += '- Response Timeliness\n';
            output += '- Lead Qualification\n';
        } else if (rootObject == 'Account') {
             output += '- Account Health\n';
             output += '- Strategic Alignment\n';
             output += '- Expansion Opportunities\n';
        } else {
            output += '- Data Integrity\n';
            output += '- Process Compliance\n';
        }
        
        return output;
    }
}
