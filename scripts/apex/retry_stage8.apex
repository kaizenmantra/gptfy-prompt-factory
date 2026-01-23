// Retry Stage 8 for Run a0gQH000005GHTRYA4
Id runId = 'a0gQH000005GHTRYA4';

PF_Run__c run = [SELECT Id, Status__c, Current_Stage__c FROM PF_Run__c WHERE Id = :runId];

// Reset status to In Progress
run.Status__c = 'In Progress';
run.Current_Stage__c = 8;
run.Error_Message__c = null; // Clear previous error
update run;

System.debug('✅ Run status reset. Enqueueing Stage 8 Job...');

// Manually enqueue the job (this mimics the Orchestrator/Chain behavior)
Id jobId = System.enqueueJob(new Stage08_PromptAssemblyJob(runId));

System.debug('🚀 Stage 8 Job enqueued. Job ID: ' + jobId);
