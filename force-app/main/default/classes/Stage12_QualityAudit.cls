/**
 * @description Stage 12: Quality Audit
 * Calls Claude AI to score output quality on 11 dimensions and stores in JSON
 * V2.6: Added Date Analysis, Forbidden Phrases, Customer References dimensions
 */
public with sharing class Stage12_QualityAudit implements IStage {

    private static final Integer STAGE_NUMBER = 12;
    private static final Decimal DEFAULT_QUALITY_THRESHOLD = 9.0;  // Raised from 7.0 in V2.6

    /**
     * @description Executes Stage 12: Quality Audit
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing outputHtml, businessContext, targetPersona from previous stages
     * @return StageResult with quality scorecard
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 12: Quality Audit');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            // Use deferred logging (no DML) - logs will be inserted AFTER callout completes
            result.queueInfo(runId, STAGE_NUMBER, 'Starting quality audit with Claude AI');

            // Extract inputs from previous stages
            String outputHtml = (String) inputs.get('outputHtml');
            String businessContext = (String) inputs.get('businessContext');
            String targetPersona = (String) inputs.get('targetPersona');
            List<Object> businessObjectives = (List<Object>) inputs.get('businessObjectives');
            String rootObject = (String) inputs.get('rootObject');

            if (String.isBlank(outputHtml)) {
                throw new StageException('Output HTML is required for quality audit');
            }

            // Build prompt for Claude to score quality
            String auditPrompt = buildQualityAuditPrompt(
                outputHtml, businessContext, targetPersona, businessObjectives, rootObject
            );

            result.queueDebug(runId, STAGE_NUMBER, 'Calling AI for quality scoring');

            // Call AI (HTTP callout - no DML before this!)
            AIServiceClient.AIResponse aiResponse = AIServiceClient.callAI(null, auditPrompt, 2048, 0.5);

            if (!aiResponse.success) {
                throw new StageException('AI call failed: ' + aiResponse.errorMessage);
            }

            result.queueInfo(runId, STAGE_NUMBER,
                'Claude AI response received (Tokens: ' + aiResponse.inputTokens + '/' + aiResponse.outputTokens + ')');

            // Parse quality scores from AI response
            Map<String, Object> qualityScorecard = parseQualityScores(aiResponse.content);

            // Calculate overall score
            Decimal overallScore = calculateOverallScore(qualityScorecard);
            qualityScorecard.put('overallScore', overallScore);

            // Check against threshold
            Boolean meetsThreshold = overallScore >= DEFAULT_QUALITY_THRESHOLD;
            qualityScorecard.put('meetsThreshold', meetsThreshold);
            qualityScorecard.put('threshold', DEFAULT_QUALITY_THRESHOLD);

            // Create PF_Quality_Score__c record (DML - after callout is done)
            Id qualityScoreId = createQualityScoreRecordDeferred(
                runId,
                qualityScorecard,
                aiResponse.content,
                result
            );

            // Build outputs
            result.outputs.put('qualityScorecard', qualityScorecard);
            result.outputs.put('overallScore', overallScore);
            result.outputs.put('meetsThreshold', meetsThreshold);
            result.outputs.put('qualityScoreId', qualityScoreId);
            result.outputs.put('auditReasoningJson', aiResponse.content);

            // Pass through critical inputs
            result.outputs.put('outputHtml', outputHtml);
            result.outputs.put('promptId', inputs.get('promptId'));
            result.outputs.put('dcmId', inputs.get('dcmId'));

            // Set AI reasoning for UI display
            result.aiReasoning = (String) qualityScorecard.get('reasoning');

            // Determine final status
            if (meetsThreshold) {
                result.markCompleted();
                result.queueInfo(runId, STAGE_NUMBER,
                    'Quality audit passed. Overall score: ' + overallScore + '/10');
            } else {
                String warningMsg = 'Quality audit completed but score below threshold. ' +
                                   'Score: ' + overallScore + '/10, Threshold: ' + DEFAULT_QUALITY_THRESHOLD;
                result.markWarning(warningMsg);
                result.queueError(runId, STAGE_NUMBER, warningMsg);
            }

        } catch (Exception e) {
            String errorMsg = 'Failed to complete quality audit: ' + e.getMessage();
            result.markFailed(errorMsg);
            result.queueError(runId, STAGE_NUMBER, 'Stage execution failed: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Builds the prompt for Claude AI to audit quality
     * @param outputHtml Generated HTML output to audit
     * @param businessContext Original business requirements
     * @param targetPersona Target user persona
     * @param businessObjectives List of business objectives
     * @param rootObject Salesforce object name
     * @return Formatted prompt string
     */
    private String buildQualityAuditPrompt(String outputHtml, String businessContext,
                                          String targetPersona, List<Object> businessObjectives,
                                          String rootObject) {
        String objectivesStr = businessObjectives != null ?
            String.join((List<String>) businessObjectives, ', ') : 'N/A';

        return 'You are an expert AI quality auditor for Salesforce implementations.\n\n' +
               'BUSINESS CONTEXT:\n' + (businessContext != null ? businessContext : 'Not provided') + '\n\n' +
               'TARGET PERSONA: ' + (targetPersona != null ? targetPersona : 'Not specified') + '\n' +
               'BUSINESS OBJECTIVES: ' + objectivesStr + '\n' +
               'SALESFORCE OBJECT: ' + rootObject + '\n\n' +
               'GENERATED OUTPUT:\n' + truncateForPrompt(outputHtml, 4000) + '\n\n' +
               'Audit this AI-generated output and score it on 11 dimensions (scale 1-10):\n\n' +
               '1. EVIDENCE BINDING: Are field citations present, correctly formatted, and accurate?\n' +
               '2. DIAGNOSTIC DEPTH: Does it use diagnostic/prescriptive language vs descriptive reports?\n' +
               '3. VISUAL QUALITY: Is the formatting clean, using SLDS patterns and good hierarchy?\n' +
               '4. UI COMPONENT EFFECTIVENESS: Are stat cards, alerts, and tables used correctly?\n' +
               '5. DATA ACCURACY: Are totals, dates, and related record data handled correctly?\n' +
               '6. PERSONA FIT: Is the density and tone appropriate for the target archetype?\n' +
               '7. ACTIONABILITY: Are there specific, time-bound, and actionable next steps?\n' +
               '8. BUSINESS VALUE: Does it provide strategic "so what" value to the business?\n' +
               '9. DATE ANALYSIS: Does it calculate date deltas (e.g., "22 months overdue", "45 days past close")? Score 1 if no date calculations, 10 if every date has context.\n' +
               '10. FORBIDDEN PHRASES: Score 10 if NO generic phrases like "touch base", "ensure alignment", "circle back", "reach out", "consider scheduling". Deduct 2 points per phrase found.\n' +
               '11. CUSTOMER REFERENCES: Does it use specific names (people, accounts) instead of generic "stakeholder" or "the client"? Score 10 if specific, 1 if generic.\n\n' +
               'Also provide:\n' +
               '- REASONING: Brief explanation of scores (2-3 sentences)\n' +
               '- STRENGTHS: 2-3 key strengths\n' +
               '- IMPROVEMENTS: 2-3 suggested improvements\n\n' +
               'Return ONLY valid JSON in this exact format:\n' +
               '{\n' +
               '  "evidenceBinding": 8,\n' +
               '  "diagnosticDepth": 9,\n' +
               '  "visualQuality": 8,\n' +
               '  "uiEffectiveness": 7,\n' +
               '  "dataAccuracy": 9,\n' +
               '  "personaFit": 7,\n' +
               '  "actionability": 8,\n' +
               '  "businessValue": 9,\n' +
               '  "dateAnalysis": 8,\n' +
               '  "forbiddenPhrases": 10,\n' +
               '  "customerReferences": 9,\n' +
               '  "reasoning": "string",\n' +
               '  "strengths": ["s1", "s2"],\n' +
               '  "improvements": ["i1", "i2"]\n' +
               '}';
    }

    /**
     * @description Parses Claude AI response into quality scorecard
     * @param aiContent Raw response from Claude
     * @return Map with parsed quality scores
     */
    private Map<String, Object> parseQualityScores(String aiContent) {
        try {
            // Remove markdown code blocks if present
            String cleanJson = aiContent.trim();
            if (cleanJson.startsWith('```json')) {
                cleanJson = cleanJson.substringAfter('```json').substringBefore('```').trim();
            } else if (cleanJson.startsWith('```')) {
                cleanJson = cleanJson.substringAfter('```').substringBefore('```').trim();
            }

            // Parse JSON response
            Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);

            // Validate required fields (11 dimensions in V2.6)
            List<String> requiredFields = new List<String>{
                'evidenceBinding', 'diagnosticDepth', 'visualQuality',
                'uiEffectiveness', 'dataAccuracy', 'personaFit',
                'actionability', 'businessValue',
                'dateAnalysis', 'forbiddenPhrases', 'customerReferences'
            };

            for (String field : requiredFields) {
                if (!parsedData.containsKey(field)) {
                    throw new StageException('Invalid AI response: missing field ' + field);
                }
            }

            return parsedData;

        } catch (JSONException e) {
            throw new StageException('Failed to parse AI response as JSON: ' + e.getMessage());
        }
    }

    /**
     * @description Calculates overall quality score as weighted average of 11 dimensions
     * V2.6: Added dateAnalysis, forbiddenPhrases, customerReferences
     * @param scorecard Map with individual dimension scores
     * @return Overall score (weighted average, scale 1-10)
     */
    private Decimal calculateOverallScore(Map<String, Object> scorecard) {
        // V2.6 Weighted dimensions (total = 100%)
        // Core dimensions (60%):
        Decimal eb = (Integer) scorecard.get('evidenceBinding');      // 15%
        Decimal dd = (Integer) scorecard.get('diagnosticDepth');      // 10%
        Decimal vq = (Integer) scorecard.get('visualQuality');        // 10%
        Decimal ui = (Integer) scorecard.get('uiEffectiveness');      // 5%
        Decimal da = (Integer) scorecard.get('dataAccuracy');         // 10%
        Decimal pf = (Integer) scorecard.get('personaFit');           // 5%
        Decimal ac = (Integer) scorecard.get('actionability');        // 5%
        Decimal bv = (Integer) scorecard.get('businessValue');        // 5% (was 10%)

        // V2.6 New dimensions (35%):
        Decimal dateAn = (Integer) scorecard.get('dateAnalysis');         // 15% - CRITICAL
        Decimal forbid = (Integer) scorecard.get('forbiddenPhrases');     // 10% - CRITICAL
        Decimal custRef = (Integer) scorecard.get('customerReferences');  // 10%

        Decimal weightedScore =
            (eb * 0.15) + (dd * 0.10) + (vq * 0.10) + (ui * 0.05) +
            (da * 0.10) + (pf * 0.05) + (ac * 0.05) + (bv * 0.05) +
            (dateAn * 0.15) + (forbid * 0.10) + (custRef * 0.10);

        return weightedScore.setScale(2);
    }

    /**
     * @description Creates PF_Quality_Score__c record with JSON-only storage
     * V2.6: All 11 dimensions stored in AI_Feedback__c JSON (no individual fields)
     * @param runId ID of the PF_Run__c record
     * @param scorecard Map with quality scores
     * @param aiReasoningJson Raw AI response JSON
     * @param result StageResult for deferred logging
     * @return ID of created quality score record
     */
    private Id createQualityScoreRecordDeferred(Id runId, Map<String, Object> scorecard,
                                       String aiReasoningJson, StageResult result) {
        try {
            // Build AI_Feedback__c JSON containing all 11 dimensions
            Map<String, Object> feedbackData = new Map<String, Object>{
                'weightedScore' => scorecard.get('overallScore'),
                'threshold' => scorecard.get('threshold'),
                'meetsThreshold' => scorecard.get('meetsThreshold'),
                'dimensions' => new Map<String, Object>{
                    'evidenceBinding' => scorecard.get('evidenceBinding'),
                    'diagnosticDepth' => scorecard.get('diagnosticDepth'),
                    'visualQuality' => scorecard.get('visualQuality'),
                    'uiEffectiveness' => scorecard.get('uiEffectiveness'),
                    'dataAccuracy' => scorecard.get('dataAccuracy'),
                    'personaFit' => scorecard.get('personaFit'),
                    'actionability' => scorecard.get('actionability'),
                    'businessValue' => scorecard.get('businessValue'),
                    'dateAnalysis' => scorecard.get('dateAnalysis'),
                    'forbiddenPhrases' => scorecard.get('forbiddenPhrases'),
                    'customerReferences' => scorecard.get('customerReferences')
                },
                'reasoning' => scorecard.get('reasoning'),
                'strengths' => scorecard.get('strengths'),
                'improvements' => scorecard.get('improvements'),
                'schema' => 'v2.6-11-dimension-weighted',
                'rawAiResponse' => aiReasoningJson
            };
            String aiFeedbackJson = truncate(JSON.serialize(feedbackData), 131072);

            // V2.6: Only use Run__c and AI_Feedback__c (JSON storage)
            PF_Quality_Score__c qualityScore = new PF_Quality_Score__c(
                Run__c = runId,
                AI_Feedback__c = aiFeedbackJson
            );

            insert qualityScore;

            result.queueInfo(runId, STAGE_NUMBER,
                'Created 11-dimension quality score record: ' + qualityScore.Id +
                ' (Score: ' + scorecard.get('overallScore') + '/10)');

            return qualityScore.Id;

        } catch (Exception e) {
            result.queueError(runId, STAGE_NUMBER,
                'Failed to create quality score record: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Truncates string to maximum length
     * @param str String to truncate
     * @param maxLength Maximum length
     * @return Truncated string
     */
    private String truncate(String str, Integer maxLength) {
        if (str == null) {
            return null;
        }
        if (str.length() <= maxLength) {
            return str;
        }
        return str.substring(0, maxLength - 3) + '...';
    }

    /**
     * @description Truncates HTML output for prompt to avoid token limits
     * @param html HTML to truncate
     * @param maxChars Maximum characters
     * @return Truncated HTML
     */
    private String truncateForPrompt(String html, Integer maxChars) {
        if (html == null) {
            return '';
        }
        if (html.length() <= maxChars) {
            return html;
        }
        return html.substring(0, maxChars) + '\n\n[... truncated for length ...]';
    }

    /**
     * @description Serializes a list to a formatted string
     * @param items List of items
     * @return Formatted string
     */
    private String serializeList(List<Object> items) {
        if (items == null || items.isEmpty()) {
            return null;
        }

        List<String> stringItems = new List<String>();
        for (Object item : items) {
            stringItems.add(String.valueOf(item));
        }

        return '- ' + String.join(stringItems, '\n- ');
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}