/**
 * @description Stage 11: Safety Validation
 * Validates output for errors, script injection, unsubstituted fields, and content quality.
 * Uses validation rules from PF_OutputValidationRules static resource for GPTfy compatibility.
 */
public with sharing class Stage11_SafetyValidation implements IStage {

    private static final Integer STAGE_NUMBER = 11;

    // Cached validation rules from static resource
    private Map<String, Object> criticalRules;
    private Map<String, Object> securityRules;
    private List<Map<String, Object>> placeholderPatterns;

    /**
     * @description Executes Stage 11: Safety Validation
     * @param runId ID of the PF_Run__c record
     * @param inputs Map containing outputHtml from Stage 10
     * @return StageResult with safety validation checklist
     */
    public StageResult execute(Id runId, Map<String, Object> inputs) {
        StageResult result = new StageResult('Stage 11: Safety Validation');
        // Don't store inputs - causes stack overflow during serialization
        // result.inputs = inputs;

        try {
            PromptFactoryLogger.info(runId, STAGE_NUMBER, 'Starting safety validation');

            // Load validation rules from static resource
            loadValidationRules();
            PromptFactoryLogger.info(runId, STAGE_NUMBER, 'Loaded validation rules from static resource');

            // Extract inputs from previous stages
            String outputHtml = (String) inputs.get('outputHtml');

            if (String.isBlank(outputHtml)) {
                throw new StageException('Output HTML is required for safety validation');
            }

            PromptFactoryLogger.info(runId, STAGE_NUMBER,
                'Validating output HTML (' + outputHtml.length() + ' characters)');

            // Initialize validation checklist
            Map<String, Object> safetyChecklist = new Map<String, Object>();
            List<String> issues = new List<String>();
            List<String> warnings = new List<String>();

            // Check 1: No error messages in output
            ValidationResult errorCheck = checkForErrorMessages(outputHtml);
            safetyChecklist.put('noErrorMessages', errorCheck.passed);
            if (!errorCheck.passed) {
                issues.add('Error messages found: ' + errorCheck.details);
            }

            // Check 2: No script injection attempts
            ValidationResult scriptCheck = checkForScriptInjection(outputHtml);
            safetyChecklist.put('noScriptInjection', scriptCheck.passed);
            if (!scriptCheck.passed) {
                issues.add('Script injection detected: ' + scriptCheck.details);
            }

            // Check 3: All merge fields are substituted
            ValidationResult mergeFieldCheck = checkMergeFieldSubstitution(outputHtml);
            safetyChecklist.put('allFieldsSubstituted', mergeFieldCheck.passed);
            if (!mergeFieldCheck.passed) {
                warnings.add('Unsubstituted fields found: ' + mergeFieldCheck.details);
            }

            // Check 4: Content is present and meaningful
            ValidationResult contentCheck = checkContentQuality(outputHtml);
            safetyChecklist.put('hasMeaningfulContent', contentCheck.passed);
            if (!contentCheck.passed) {
                issues.add('Content quality issue: ' + contentCheck.details);
            }

            // Check 5: No suspicious patterns
            ValidationResult patternCheck = checkSuspiciousPatterns(outputHtml);
            safetyChecklist.put('noSuspiciousPatterns', patternCheck.passed);
            if (!patternCheck.passed) {
                warnings.add('Suspicious patterns found: ' + patternCheck.details);
            }

            // Check 6: GPTfy format compliance (single line, inline styles only)
            ValidationResult gptfyCheck = checkGPTfyCompliance(outputHtml);
            safetyChecklist.put('gptfyCompliant', gptfyCheck.passed);
            if (!gptfyCheck.passed) {
                warnings.add('GPTfy compliance issue: ' + gptfyCheck.details);
            }

            // Check 7: No placeholder text patterns
            ValidationResult placeholderCheck = checkForPlaceholders(outputHtml);
            safetyChecklist.put('noPlaceholders', placeholderCheck.passed);
            if (!placeholderCheck.passed) {
                warnings.add('Placeholder patterns found: ' + placeholderCheck.details);
            }

            // Calculate overall safety score
            Integer passedChecks = 0;
            Integer totalChecks = 7;
            for (String key : safetyChecklist.keySet()) {
                if ((Boolean) safetyChecklist.get(key)) {
                    passedChecks++;
                }
            }
            Decimal safetyScore = (Decimal) passedChecks / totalChecks * 100;

            // Build outputs
            result.outputs.put('safetyChecklist', safetyChecklist);
            result.outputs.put('safetyScore', safetyScore);
            result.outputs.put('passedChecks', passedChecks);
            result.outputs.put('totalChecks', totalChecks);
            result.outputs.put('issues', issues);
            result.outputs.put('warnings', warnings);
            result.outputs.put('isSafe', issues.isEmpty());

            // PHASE 2F FIX: Removed manual pass-throughs.
            // Accumulator handles data continuity for outputHtml, promptId, etc.
            // Outputs only: safetyChecklist, safetyScore, issues, warnings.

            // Determine final status
            if (issues.isEmpty()) {
                result.markCompleted();
                PromptFactoryLogger.info(runId, STAGE_NUMBER,
                    'Safety validation passed. Score: ' + safetyScore + '%');
            } else {
                String errorMsg = 'Safety validation failed: ' + String.join(issues, '; ');
                result.markFailed(errorMsg);
                PromptFactoryLogger.error(runId, STAGE_NUMBER, errorMsg);
            }

            // Log warnings if any
            if (!warnings.isEmpty()) {
                PromptFactoryLogger.warning(runId, STAGE_NUMBER,
                    'Validation warnings: ' + String.join(warnings, '; '));
            }

        } catch (Exception e) {
            String errorMsg = 'Failed to complete safety validation: ' + e.getMessage();
            result.markFailed(errorMsg);
            PromptFactoryLogger.logException(runId, STAGE_NUMBER, 'Stage execution failed', e);
        }

        return result;
    }

    /**
     * @description Checks for error messages in output
     * @param outputHtml Generated HTML output
     * @return ValidationResult with check outcome
     */
    private ValidationResult checkForErrorMessages(String outputHtml) {
        List<String> errorPatterns = new List<String>{
            'error:', 'exception:', 'failed to',
            'could not', 'unable to', 'invalid request',
            'something went wrong', 'unexpected error'
        };

        String lowerOutput = outputHtml.toLowerCase();
        List<String> foundErrors = new List<String>();

        for (String pattern : errorPatterns) {
            if (lowerOutput.contains(pattern)) {
                foundErrors.add(pattern);
            }
        }

        if (foundErrors.isEmpty()) {
            return new ValidationResult(true, 'No error messages detected');
        } else {
            return new ValidationResult(false, String.join(foundErrors, ', '));
        }
    }

    /**
     * @description Checks for script injection attempts
     * @param outputHtml Generated HTML output
     * @return ValidationResult with check outcome
     */
    private ValidationResult checkForScriptInjection(String outputHtml) {
        List<String> dangerousPatterns = new List<String>{
            '<script', 'javascript:', 'onerror=',
            'onclick=', 'onload=', 'eval(',
            'document.cookie', 'window.location'
        };

        String lowerOutput = outputHtml.toLowerCase();
        List<String> foundPatterns = new List<String>();

        for (String pattern : dangerousPatterns) {
            if (lowerOutput.contains(pattern)) {
                foundPatterns.add(pattern);
            }
        }

        if (foundPatterns.isEmpty()) {
            return new ValidationResult(true, 'No script injection detected');
        } else {
            return new ValidationResult(false, String.join(foundPatterns, ', '));
        }
    }

    /**
     * @description Checks that all merge fields have been substituted
     * @param outputHtml Generated HTML output
     * @return ValidationResult with check outcome
     */
    private ValidationResult checkMergeFieldSubstitution(String outputHtml) {
        List<String> unsubstituted = MergeFieldValidator.findUnsubstitutedFields(outputHtml);

        if (unsubstituted.isEmpty()) {
            return new ValidationResult(true, 'All merge fields substituted');
        } else {
            String details = 'Found ' + unsubstituted.size() + ' unsubstituted field(s): ' +
                           String.join(unsubstituted, ', ');
            return new ValidationResult(false, details);
        }
    }

    /**
     * @description Checks that output has meaningful content
     * @param outputHtml Generated HTML output
     * @return ValidationResult with check outcome
     */
    private ValidationResult checkContentQuality(String outputHtml) {
        // Remove HTML tags to check text content
        String textContent = outputHtml.replaceAll('<[^>]+>', ' ').trim();

        // Check minimum length
        if (textContent.length() < 50) {
            return new ValidationResult(false, 'Output too short (' + textContent.length() + ' chars)');
        }

        // Check for placeholder text
        String lowerText = textContent.toLowerCase();
        List<String> placeholders = new List<String>{
            'lorem ipsum', 'placeholder', '[insert',
            'todo:', 'tbd', 'coming soon'
        };

        for (String placeholder : placeholders) {
            if (lowerText.contains(placeholder)) {
                return new ValidationResult(false, 'Contains placeholder text: ' + placeholder);
            }
        }

        // Check word count
        List<String> words = textContent.split('\\s+');
        if (words.size() < 10) {
            return new ValidationResult(false, 'Too few words (' + words.size() + ')');
        }

        return new ValidationResult(true, 'Content quality acceptable');
    }

    /**
     * @description Checks for suspicious patterns in output
     * @param outputHtml Generated HTML output
     * @return ValidationResult with check outcome
     */
    private ValidationResult checkSuspiciousPatterns(String outputHtml) {
        List<String> suspiciousPatterns = new List<String>{
            'base64', 'data:image/svg+xml',
            'iframe', 'embed', 'object'
        };

        String lowerOutput = outputHtml.toLowerCase();
        List<String> foundPatterns = new List<String>();

        for (String pattern : suspiciousPatterns) {
            if (lowerOutput.contains(pattern)) {
                foundPatterns.add(pattern);
            }
        }

        if (foundPatterns.isEmpty()) {
            return new ValidationResult(true, 'No suspicious patterns detected');
        } else {
            return new ValidationResult(false, String.join(foundPatterns, ', '));
        }
    }

    /**
     * @description Wrapper class for validation check results
     */
    private class ValidationResult {
        public Boolean passed;
        public String details;

        public ValidationResult(Boolean passed, String details) {
            this.passed = passed;
            this.details = details;
        }
    }

    /**
     * @description Loads validation rules from static resource
     */
    private void loadValidationRules() {
        criticalRules = PromptFactoryRulesLoader.getCriticalOutputRules();
        securityRules = PromptFactoryRulesLoader.getSecurityRules();
        placeholderPatterns = PromptFactoryRulesLoader.getPlaceholderPatterns();
    }

    /**
     * @description Checks GPTfy format compliance (single line, inline styles, no classes)
     * @param outputHtml Generated HTML output
     * @return ValidationResult with check outcome
     */
    private ValidationResult checkGPTfyCompliance(String outputHtml) {
        List<String> complianceIssues = new List<String>();

        // Check for line breaks (GPTfy requires single line)
        if (outputHtml.contains('\n') || outputHtml.contains('\r')) {
            complianceIssues.add('contains line breaks (must be single line)');
        }

        // Check for CSS classes (GPTfy requires inline styles only)
        Pattern classPattern = Pattern.compile('(?i)class\\s*=\\s*["\']');
        if (classPattern.matcher(outputHtml).find()) {
            complianceIssues.add('contains CSS classes (must use inline styles only)');
        }

        // Check for style blocks
        if (outputHtml.toLowerCase().contains('<style')) {
            complianceIssues.add('contains <style> block (must use inline styles only)');
        }

        // Check max length
        if (outputHtml.length() > 131072) {
            complianceIssues.add('exceeds max length of 131072 characters');
        }

        // Check starts with <div style="
        if (!outputHtml.trim().startsWith('<div style="')) {
            complianceIssues.add('does not start with <div style="');
        }

        if (complianceIssues.isEmpty()) {
            return new ValidationResult(true, 'GPTfy format compliant');
        } else {
            return new ValidationResult(false, String.join(complianceIssues, ', '));
        }
    }

    /**
     * @description Checks for placeholder text patterns from static resource rules
     * @param outputHtml Generated HTML output
     * @return ValidationResult with check outcome
     */
    private ValidationResult checkForPlaceholders(String outputHtml) {
        List<String> foundPlaceholders = new List<String>();
        String lowerOutput = outputHtml.toLowerCase();

        // Default placeholder patterns if static resource not loaded
        List<String> defaultPatterns = new List<String>{
            '[insert', '[your', '[add', 'todo:', 'tbd', 'xxx',
            'placeholder', 'example_', 'sample_', '{{field}}',
            '[field_name]', '<field_name>', 'coming soon'
        };

        // Use patterns from static resource if available
        if (placeholderPatterns != null && !placeholderPatterns.isEmpty()) {
            for (Map<String, Object> patternDef : placeholderPatterns) {
                if (patternDef.containsKey('pattern')) {
                    String pattern = ((String) patternDef.get('pattern')).toLowerCase();
                    if (lowerOutput.contains(pattern)) {
                        String name = patternDef.containsKey('name') ?
                            (String) patternDef.get('name') : pattern;
                        foundPlaceholders.add(name);
                    }
                }
            }
        } else {
            // Fallback to default patterns
            for (String pattern : defaultPatterns) {
                if (lowerOutput.contains(pattern)) {
                    foundPlaceholders.add(pattern);
                }
            }
        }

        if (foundPlaceholders.isEmpty()) {
            return new ValidationResult(true, 'No placeholder patterns detected');
        } else {
            return new ValidationResult(false, String.join(foundPlaceholders, ', '));
        }
    }

    /**
     * @description Custom exception for stage errors
     */
    public class StageException extends Exception {}
}