/**
 * @description Test class to verify @future(callout=true) works after DML
 * This is a proof-of-concept for Stage 10 execution
 */
public with sharing class FutureCalloutTest {

    /**
     * @description Calls GPTfy invocable in a future context (fresh transaction)
     * @param promptRequestId The prompt request ID from GPTfy
     * @param recordId The Salesforce record ID to process
     */
    @future(callout=true)
    public static void executePromptAsync(String promptRequestId, String recordId) {
        try {
            System.debug('=== @future method started ===');
            System.debug('promptRequestId: ' + promptRequestId);
            System.debug('recordId: ' + recordId);

            // Call GPTfy invocable (now in fresh transaction, no prior DML)
            ccai.AIPromptProcessingInvokable.RequestWrapper wrap = new ccai.AIPromptProcessingInvokable.RequestWrapper();
            wrap.promptRequestId = promptRequestId;
            wrap.recordId = recordId;
            wrap.customPromptCommand = '';

            List<ccai.AIPromptProcessingInvokable.ResponseWrapper> responses =
                ccai.AIPromptProcessingInvokable.processRequest(
                    new List<ccai.AIPromptProcessingInvokable.RequestWrapper>{wrap}
                );

            if (responses != null && !responses.isEmpty()) {
                ccai.AIPromptProcessingInvokable.ResponseWrapper resp = responses[0];
                System.debug('=== GPTfy Response ===');
                System.debug('Status: ' + resp.status);
                System.debug('Response ID: ' + resp.responseId);

                // Check if we got actual content vs error
                Boolean success = resp.responseBody != null &&
                                  resp.responseBody.length() > 100 &&
                                  !resp.responseBody.contains('"error"');

                System.debug('SUCCESS: ' + success);
                System.debug('Response Length: ' + (resp.responseBody != null ? resp.responseBody.length() : 0));

                if (success) {
                    System.debug('=== PROOF OF CONCEPT PASSED ===');
                    System.debug('Response preview: ' + resp.responseBody.left(200));
                } else {
                    System.debug('=== PROOF OF CONCEPT FAILED ===');
                    System.debug('Response: ' + resp.responseBody);
                }
            }

        } catch (Exception e) {
            System.debug('=== @future method EXCEPTION ===');
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
        }
    }

    /**
     * @description Synchronous test method to simulate Stage 9 DML then Stage 10 callout
     * Call this from Anonymous Apex to test the full flow
     */
    public static void testDmlThenFutureCallout(String promptRequestId, String recordId) {
        // Simulate Stage 9: Do some DML first
        Account testAcc = new Account(Name = 'DML Test ' + DateTime.now().getTime());
        insert testAcc;
        System.debug('=== Stage 9 DML completed: ' + testAcc.Id + ' ===');

        // Now call @future for Stage 10 (will execute in separate transaction)
        System.debug('=== Enqueuing @future callout ===');
        executePromptAsync(promptRequestId, recordId);
        System.debug('=== @future enqueued (will execute async) ===');

        // Cleanup test data
        delete testAcc;
        System.debug('=== Test account cleaned up ===');
    }
}
