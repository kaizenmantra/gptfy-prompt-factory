// Execute a single variant
// Args: variantNumber (0-4)

// Read variant number from argument (passed via script)
Integer variantNumber = Integer.valueOf('{VARIANT_NUM}');
String variantName = '{VARIANT_NAME}';

System.debug('=== EXECUTING VARIANT ' + variantNumber + ': ' + variantName + ' ===');

// Read variant file content (will be injected by script)
String promptText = '{PROMPT_TEXT}';

System.debug('Prompt length: ' + promptText.length() + ' characters');

// Update prompt
ccai__AI_Prompt__c prompt = [SELECT Id, ccai__Prompt_Command__c FROM ccai__AI_Prompt__c WHERE Id = 'a0DQH00000KYLsv2AH'];
prompt.ccai__Prompt_Command__c = promptText;
update prompt;

System.debug('✅ Prompt updated successfully');
System.debug('Variant ' + variantNumber + ' ready for execution');
