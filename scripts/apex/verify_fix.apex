// Verify Fix for Run a0gQH000005GHTRYA4
Id runId = 'a0gQH000005GHTRYA4';

PF_Run__c run = [SELECT Id, Status__c, Current_Stage__c, Created_Prompt_Id__c, Error_Message__c FROM PF_Run__c WHERE Id = :runId];

System.debug('Run Status: ' + run.Status__c + ' | Stage: ' + run.Current_Stage__c);

if (run.Error_Message__c != null) {
    System.debug('❌ Run Failed: ' + run.Error_Message__c);
}

if (run.Created_Prompt_Id__c != null) {
    Id promptId = run.Created_Prompt_Id__c;
    System.debug('✅ Created Prompt ID: ' + promptId);
    
    // Check Prompt Content Length
    ccai__AI_Prompt__c prompt = [SELECT ccai__Prompt_Command__c FROM ccai__AI_Prompt__c WHERE Id = :promptId];
    
    if (prompt.ccai__Prompt_Command__c != null) {
        Integer len = prompt.ccai__Prompt_Command__c.length();
        System.debug('📊 New Prompt Length: ' + len + ' chars');
        
        if (len > 20000) {
            System.debug('✅ SUCCESS: Prompt length matches expected ~24k chars. Fix Verified!');
            
            // Print a snippet from the "Missing Middle" to be sure
            String snippet = prompt.ccai__Prompt_Command__c.mid(10000, 200);
            System.debug('Search for middle content: ' + snippet); 
        } else {
             System.debug('⚠️ WARNING: Prompt length is ' + len + ', might still be truncated?');
        }
    } else {
        System.debug('❌ Prompt Command is NULL');
    }

} else {
    System.debug('⏳ Prompt not created yet. Run still in progress...');
}
