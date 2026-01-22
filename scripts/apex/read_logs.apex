for (PF_Run_Log__c log : [SELECT Log_Message__c, Stage_Number__c FROM PF_Run_Log__c WHERE Run__c = 'a0gQH000005GEVZYA4' AND Stage_Number__c = 8]) { System.debug('LOG: ' + log.Log_Message__c); }
