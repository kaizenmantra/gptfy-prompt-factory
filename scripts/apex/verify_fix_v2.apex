// Verify Fix v2 - Find latest prompt
System.debug('🔍 Searching for recently created prompts...');

List<ccai__AI_Prompt__c> recentPrompts = [
    SELECT Id, Name, CreatedDate, ccai__Prompt_Command__c 
    FROM ccai__AI_Prompt__c 
    WHERE CreatedDate > :DateTime.now().addMinutes(-10)
    ORDER BY CreatedDate DESC 
    LIMIT 1
];

if (!recentPrompts.isEmpty()) {
    ccai__AI_Prompt__c prompt = recentPrompts[0];
    System.debug('✅ Found New Prompt: ' + prompt.Name + ' (' + prompt.Id + ')');
    System.debug('Created At: ' + prompt.CreatedDate);
    
    if (prompt.ccai__Prompt_Command__c != null) {
        Integer len = prompt.ccai__Prompt_Command__c.length();
        System.debug('📊 New Prompt Length: ' + len + ' chars');
        
        if (len > 20000) {
            System.debug('✅ SUCCESS: Prompt length matches expected ~24k chars. Fix Verified!');
            String snippet = prompt.ccai__Prompt_Command__c.mid(10000, 200);
            System.debug('Search for middle content: ' + snippet); 
        } else {
             System.debug('⚠️ WARNING: Prompt length is ' + len + ', still looks truncated?');
        }
    } else {
        System.debug('❌ Prompt Command is NULL');
    }
} else {
    System.debug('⏳ No new prompts found yet. Stage 9 might still be running.');
}
