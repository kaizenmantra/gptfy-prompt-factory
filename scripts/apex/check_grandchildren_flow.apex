System.debug('=== CHECKING STAGE 3 GRANDCHILDREN OUTPUT ===');

List<PF_Run_Stage__c> stage3Records = [
    SELECT Id, Run__c, Stage_Number__c, Status__c, Output_Data__c, CreatedDate,
           Run__r.Name, Run__r.Root_Object__c
    FROM PF_Run_Stage__c
    WHERE Stage_Number__c = 3
      AND Status__c = 'Completed'
      AND Run__r.Root_Object__c = 'Account'
    ORDER BY CreatedDate DESC
    LIMIT 3
];

System.debug('Found ' + stage3Records.size() + ' Stage 3 records');

for (PF_Run_Stage__c stage : stage3Records) {
    System.debug('');
    System.debug('Run: ' + stage.Run__r.Name + ' (' + stage.CreatedDate + ')');

    if (String.isBlank(stage.Output_Data__c)) {
        System.debug('  OUTPUT: Empty');
        continue;
    }

    System.debug('  Output size: ' + stage.Output_Data__c.length() + ' chars');

    try {
        Map<String, Object> outputs = (Map<String, Object>) JSON.deserializeUntyped(stage.Output_Data__c);

        // Check for selectedGrandchildren
        Object gcRaw = outputs.get('selectedGrandchildren');
        if (gcRaw != null) {
            List<Object> gcList = (List<Object>) gcRaw;
            System.debug('  selectedGrandchildren: ' + gcList.size() + ' objects');
            for (Object gc : gcList) {
                Map<String, Object> gcMap = (Map<String, Object>) gc;
                System.debug('    - ' + gcMap.get('objectName') + ' (parent: ' + gcMap.get('parentObject') + ')');
            }
        } else {
            System.debug('  selectedGrandchildren: NULL or not present');
        }

        // Check for selectedObjects count
        Object selObj = outputs.get('selectedObjects');
        if (selObj != null) {
            List<Object> selList = (List<Object>) selObj;
            System.debug('  selectedObjects count: ' + selList.size());
        }

        // Check for childChains
        Object chainsRaw = outputs.get('childChains');
        if (chainsRaw != null) {
            System.debug('  childChains: Present');
        }

    } catch (Exception e) {
        System.debug('  ERROR parsing: ' + e.getMessage());
    }
}

// Now check Stage 8 dcmConfig
System.debug('');
System.debug('=== CHECKING STAGE 8 DCM CONFIG ===');

List<PF_Run_Stage__c> stage8Records = [
    SELECT Id, Run__c, Stage_Number__c, Status__c, Output_Data__c, CreatedDate,
           Run__r.Name, Run__r.Root_Object__c
    FROM PF_Run_Stage__c
    WHERE Stage_Number__c = 8
      AND Status__c = 'Completed'
      AND Run__r.Root_Object__c = 'Account'
    ORDER BY CreatedDate DESC
    LIMIT 3
];

System.debug('Found ' + stage8Records.size() + ' Stage 8 records');

for (PF_Run_Stage__c stage : stage8Records) {
    System.debug('');
    System.debug('Run: ' + stage.Run__r.Name);

    if (String.isBlank(stage.Output_Data__c)) {
        System.debug('  OUTPUT: Empty');
        continue;
    }

    try {
        Map<String, Object> outputs = (Map<String, Object>) JSON.deserializeUntyped(stage.Output_Data__c);

        Object dcmConfigRaw = outputs.get('dcmConfig');
        if (dcmConfigRaw != null) {
            Map<String, Object> dcmConfig = (Map<String, Object>) dcmConfigRaw;
            Object childObjsRaw = dcmConfig.get('childObjects');
            if (childObjsRaw != null) {
                List<Object> childObjs = (List<Object>) childObjsRaw;
                System.debug('  dcmConfig.childObjects: ' + childObjs.size() + ' objects');

                Integer grandchildCount = 0;
                for (Object co : childObjs) {
                    Map<String, Object> childMap = (Map<String, Object>) co;
                    String parentObj = (String) childMap.get('parentObject');
                    if (String.isNotBlank(parentObj)) {
                        grandchildCount++;
                        System.debug('    GRANDCHILD: ' + childMap.get('objectName') + ' (parent: ' + parentObj + ')');
                    }
                }
                System.debug('  Total grandchild objects in dcmConfig: ' + grandchildCount);
            }
        } else {
            System.debug('  dcmConfig: NULL');
        }

    } catch (Exception e) {
        System.debug('  ERROR: ' + e.getMessage());
    }
}
