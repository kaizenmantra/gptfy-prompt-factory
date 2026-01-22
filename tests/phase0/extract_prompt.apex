// Extract baseline prompt
ccai__AI_Prompt__c prompt = [SELECT ccai__Prompt_Command__c FROM ccai__AI_Prompt__c WHERE Id = 'a0DQH00000KYLsv2AH'];
String promptText = prompt.ccai__Prompt_Command__c;

System.debug('=====PROMPT_START=====');
System.debug(promptText);
System.debug('=====PROMPT_END=====');
System.debug('Prompt length: ' + promptText.length() + ' characters');
