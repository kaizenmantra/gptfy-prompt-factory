for (PF_Run__c run : [SELECT Id FROM PF_Run__c WHERE Status__c IN ('Queued', 'In Progress', 'Running', 'Pending')]) {
    PromptFactoryController.abortPipeline(run.Id);
}
