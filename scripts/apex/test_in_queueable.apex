// Test builder queries in QUEUEABLE context (like the actual pipeline)
public class TestBuilderLoadingQueueable implements Queueable {
    public void execute(QueueableContext ctx) {
        System.debug('=== QUEUEABLE TEST START ===');
        
        try {
            // Test exact loadQualityRules() logic
            Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c
                .getRecordTypeInfosByDeveloperName()
                .get('Builder')
                .getRecordTypeId();
            
            System.debug('RecordType ID: ' + builderRtId);
            
            List<ccai__AI_Prompt__c> rules = [
                SELECT Id, Name, ccai__Prompt_Command__c
                FROM ccai__AI_Prompt__c
                WHERE RecordTypeId = :builderRtId
                  AND Category__c = 'Quality Rule'
                  AND ccai__Status__c = 'Active'
                ORDER BY Name
            ];
            
            System.debug('Found ' + rules.size() + ' quality rules');
            
            String result = '';
            for (ccai__AI_Prompt__c rule : rules) {
                if (String.isNotBlank(rule.ccai__Prompt_Command__c)) {
                    result += rule.ccai__Prompt_Command__c + '\n\n';
                    System.debug('Added: ' + rule.Name + ' (' + rule.ccai__Prompt_Command__c.length() + ' chars)');
                } else {
                    System.debug('BLANK: ' + rule.Name);
                }
            }
            
            System.debug('Total result length: ' + result.length());
            System.debug('Result is blank: ' + String.isBlank(result));
            
            // Save to a PF_Run record so we can query it
            PF_Run__c testRun = new PF_Run__c(
                Root_Object__c = 'Test',
                Status__c = 'Completed',
                Prompt_Name__c = 'Queueable Test: Found ' + rules.size() + ' builders, total ' + result.length() + ' chars'
            );
            insert testRun;
            
            System.debug('Created test run: ' + testRun.Id);
            
        } catch (Exception e) {
            System.debug('EXCEPTION: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            
            // Save error to PF_Run
            PF_Run__c errorRun = new PF_Run__c(
                Root_Object__c = 'Test',
                Status__c = 'Failed',
                Prompt_Name__c = 'Queueable Test FAILED: ' + e.getMessage()
            );
            insert errorRun;
        }
        
        System.debug('=== QUEUEABLE TEST END ===');
    }
}

// Enqueue the job
System.enqueueJob(new TestBuilderLoadingQueueable());
System.debug('Queueable job enqueued. Check PF_Run__c records in 10 seconds for results.');
