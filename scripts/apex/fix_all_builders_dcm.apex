// Fix all builder prompts to use correct Opportunity DCM
// Correct DCM: a05QH000008PLavYAG (from Deal Coach prompt)

System.debug('=== FIXING ALL BUILDER PROMPTS - CORRECT DCM ===');

String correctDCM = 'a05QH000008PLavYAG';

// Get all builders we created
List<ccai__AI_Prompt__c> builders = [
    SELECT Id, Name, Category__c, ccai__Object__c, ccai__AI_Data_Extraction_Mapping__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND Category__c IN ('Quality Rule', 'Pattern', 'UI Component', 'Context Template')
      AND Name IN ('Evidence Binding Rules v2', 'Risk Assessment Pattern', 
                   'Stat Card Component', 'Alert Box Component', 
                   'Healthcare Payer Context')
];

System.debug('Found ' + builders.size() + ' builders to fix');

// Update all to correct DCM
for (ccai__AI_Prompt__c b : builders) {
    System.debug('Before: ' + b.Name + ' → DCM: ' + b.ccai__AI_Data_Extraction_Mapping__c);
    b.ccai__AI_Data_Extraction_Mapping__c = correctDCM;
    b.ccai__Object__c = 'Opportunity'; // Ensure this is also set correctly
}

update builders;

System.debug('\n✅ Updated ' + builders.size() + ' builders');

// Verification
builders = [
    SELECT Id, Name, Category__c, ccai__Object__c, ccai__AI_Data_Extraction_Mapping__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
      AND Category__c IN ('Quality Rule', 'Pattern', 'UI Component', 'Context Template')
];

System.debug('\n=== VERIFICATION ===');
for (ccai__AI_Prompt__c b : builders) {
    System.debug('✅ ' + b.Name);
    System.debug('   Object: ' + b.ccai__Object__c);
    System.debug('   DCM: ' + b.ccai__AI_Data_Extraction_Mapping__c);
    System.debug('   Category: ' + b.Category__c);
}

System.debug('\n🎯 ALL BUILDERS NOW TESTABLE WITH OPPORTUNITY DATA');
