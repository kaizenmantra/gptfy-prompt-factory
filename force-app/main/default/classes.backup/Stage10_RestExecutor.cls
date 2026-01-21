/**
 * @description REST-based executor for GPTfy prompt execution
 *
 * This class uses HTTP callout to GPTfy's REST API endpoint instead of the
 * direct Invocable Apex call. This provides:
 * 1. Fresh execution context on GPTfy's backend (bypasses potential caching issues)
 * 2. Clean separation from the DML transaction chain
 * 3. Ability to capture detailed error responses
 *
 * CRITICAL: Must be called from a context that allows callouts (Queueable with
 * Database.AllowsCallouts or @future(callout=true)). The Stage10_TestExecutionJob
 * has been updated to implement Database.AllowsCallouts.
 */
public with sharing class Stage10_RestExecutor {

    // GPTfy REST API endpoint path
    private static final String GPTFY_EXECUTE_ENDPOINT = '/services/apexrest/ccai/v1/executePrompt';

    // Timeout for the REST callout (2 minutes to allow for AI processing)
    private static final Integer CALLOUT_TIMEOUT_MS = 120000;

    /**
     * @description Result wrapper for REST execution
     */
    public class ExecutionResult {
        public Boolean success;
        public String responseBody;
        public Id aiResponseId;
        public String errorMessage;
        public Integer httpStatusCode;
        public String rawResponse;

        public ExecutionResult() {
            this.success = false;
        }
    }

    /**
     * @description Executes a GPTfy prompt via REST API callout
     *
     * This method calls /services/apexrest/ccai/v1/executePrompt with the
     * Prompt Request ID and Record ID. The REST approach creates a fresh
     * execution context on GPTfy's backend, which can resolve issues that
     * occur with the direct Invocable call in certain transaction chains.
     *
     * @param promptRequestId The Prompt Request ID (ccai__Prompt_Request_Id__c) from activated prompt
     * @param recordId The ID of the record to process
     * @return ExecutionResult with success status, response body, and any error details
     */
    public static ExecutionResult executePromptViaRest(String promptRequestId, Id recordId) {
        ExecutionResult result = new ExecutionResult();

        try {
            // Build the base URL for the current org
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String endpoint = baseUrl + GPTFY_EXECUTE_ENDPOINT;

            System.debug('Stage10_RestExecutor: Calling GPTfy REST endpoint: ' + endpoint);
            System.debug('Stage10_RestExecutor: Prompt Request ID: ' + promptRequestId);
            System.debug('Stage10_RestExecutor: Record ID: ' + recordId);

            // Build request body matching GPTfy's expected format
            Map<String, Object> requestBody = new Map<String, Object>{
                'promptRequestId' => promptRequestId,
                'recordId' => String.valueOf(recordId),
                'customPromptCommand' => '' // Empty for standard execution
            };

            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + getSessionId());
            req.setTimeout(CALLOUT_TIMEOUT_MS);
            req.setBody(JSON.serialize(requestBody));

            // Execute callout
            Http http = new Http();
            HttpResponse res = http.send(req);

            result.httpStatusCode = res.getStatusCode();
            result.rawResponse = res.getBody();

            System.debug('Stage10_RestExecutor: Response status code: ' + res.getStatusCode());
            System.debug('Stage10_RestExecutor: Response body length: ' +
                (res.getBody() != null ? res.getBody().length() : 0));

            // Parse response
            if (res.getStatusCode() == 200) {
                result = parseSuccessResponse(res.getBody(), result);
            } else {
                result = parseErrorResponse(res, result);
            }

        } catch (System.CalloutException ce) {
            result.success = false;
            result.errorMessage = 'REST callout failed: ' + ce.getMessage();
            System.debug('Stage10_RestExecutor: CalloutException: ' + ce.getMessage());
            System.debug('Stage10_RestExecutor: Stack trace: ' + ce.getStackTraceString());
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Unexpected error during REST execution: ' + e.getMessage();
            System.debug('Stage10_RestExecutor: Exception: ' + e.getMessage());
            System.debug('Stage10_RestExecutor: Stack trace: ' + e.getStackTraceString());
        }

        return result;
    }

    /**
     * @description Parses a successful (HTTP 200) response from GPTfy
     * @param responseBody The JSON response body
     * @param result The ExecutionResult to populate
     * @return Updated ExecutionResult
     */
    private static ExecutionResult parseSuccessResponse(String responseBody, ExecutionResult result) {
        try {
            // GPTfy REST response format (based on Invocable response structure)
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Extract status
            String status = (String) data.get('status');
            System.debug('Stage10_RestExecutor: Parsed status: ' + status);

            // Check for error status
            if (status == 'Errored' || status == 'Error' || status == 'Failed') {
                result.success = false;
                result.errorMessage = 'GPTfy returned error status: ' + status;
                String message = (String) data.get('message');
                if (String.isNotBlank(message)) {
                    result.errorMessage += '. Message: ' + message;
                }
                return result;
            }

            // Extract response body (HTML output)
            result.responseBody = (String) data.get('responseBody');

            // Extract AI Response ID if present
            String responseId = (String) data.get('responseId');
            if (String.isNotBlank(responseId)) {
                try {
                    result.aiResponseId = Id.valueOf(responseId);
                } catch (Exception e) {
                    System.debug('Stage10_RestExecutor: Could not parse responseId as Id: ' + responseId);
                }
            }

            // Validate we got actual content
            if (String.isBlank(result.responseBody)) {
                // Check if status indicates processing - may need to poll
                if (status == 'Processing' || status == 'Pending') {
                    result.success = false;
                    result.errorMessage = 'GPTfy is still processing. Status: ' + status;
                } else if (status == 'Processed' || status == 'Success') {
                    // Success but empty response is unusual
                    result.success = true;
                    result.responseBody = '';
                    System.debug('Stage10_RestExecutor: WARNING - Success status but empty response body');
                } else {
                    result.success = false;
                    result.errorMessage = 'GPTfy returned unexpected status with no content: ' + status;
                }
            } else {
                result.success = true;
            }

            System.debug('Stage10_RestExecutor: Parse success. Response length: ' +
                (result.responseBody != null ? result.responseBody.length() : 0));

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to parse GPTfy response: ' + e.getMessage();
            System.debug('Stage10_RestExecutor: Parse exception: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Parses an error response from GPTfy REST API
     * @param res The HTTP response
     * @param result The ExecutionResult to populate
     * @return Updated ExecutionResult with error details
     */
    private static ExecutionResult parseErrorResponse(HttpResponse res, ExecutionResult result) {
        result.success = false;

        String errorMessage = 'GPTfy REST API error: HTTP ' + res.getStatusCode();

        try {
            // Try to parse error details from response body
            if (String.isNotBlank(res.getBody())) {
                Map<String, Object> errorData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                // Check for various error message fields
                if (errorData.containsKey('message')) {
                    errorMessage += '. Message: ' + errorData.get('message');
                } else if (errorData.containsKey('error')) {
                    Object errorObj = errorData.get('error');
                    if (errorObj instanceof String) {
                        errorMessage += '. Error: ' + errorObj;
                    } else if (errorObj instanceof Map<String, Object>) {
                        Map<String, Object> errorMap = (Map<String, Object>) errorObj;
                        if (errorMap.containsKey('message')) {
                            errorMessage += '. Error: ' + errorMap.get('message');
                        }
                    }
                } else if (errorData.containsKey('errorMessage')) {
                    errorMessage += '. ' + errorData.get('errorMessage');
                }
            }
        } catch (Exception e) {
            // If we can't parse the error, include raw response
            errorMessage += '. Raw response: ' + truncateForLogging(res.getBody(), 500);
        }

        result.errorMessage = errorMessage;

        System.debug('Stage10_RestExecutor: Error response - ' + errorMessage);

        return result;
    }

    /**
     * @description Gets the current user's session ID for REST API authentication
     *
     * IMPORTANT: This uses UserInfo.getSessionId() which works in Queueable contexts.
     * The Queueable job runs with the user's session, so this should return a valid
     * session ID. If not available, we throw an exception with guidance.
     *
     * @return Session ID string
     * @throws Stage10_RestExecutorException if session ID cannot be obtained
     */
    private static String getSessionId() {
        String sessionId = UserInfo.getSessionId();

        if (String.isBlank(sessionId)) {
            throw new Stage10_RestExecutorException(
                'Cannot obtain session ID for REST callout. ' +
                'UserInfo.getSessionId() returned null. ' +
                'This may happen in certain async contexts (scheduled jobs, batch). ' +
                'Stage 10 REST mode requires Queueable execution context.'
            );
        }

        return sessionId;
    }

    /**
     * @description Truncates a string for logging purposes
     * @param input The string to truncate
     * @param maxLength Maximum length
     * @return Truncated string with indicator if truncated
     */
    private static String truncateForLogging(String input, Integer maxLength) {
        if (String.isBlank(input)) {
            return '[empty]';
        }
        if (input.length() <= maxLength) {
            return input;
        }
        return input.substring(0, maxLength) + '... [truncated]';
    }

    /**
     * @description Custom exception for REST executor errors
     */
    public class Stage10_RestExecutorException extends Exception {}
}