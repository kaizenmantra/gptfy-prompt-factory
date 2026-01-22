Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.PF_Run_Stage__c.fields.getMap(); for (String fieldName : fieldMap.keySet()) { System.debug('Field: ' + fieldName); }
