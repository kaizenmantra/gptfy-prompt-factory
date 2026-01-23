// Test Step 1 only - Initialize Session
System.debug('=== Step 1: Initialize Session ===');

List<Id> oppIds = new List<Id>{
    '006QH00000HjgvlYAB',
    '006QH00000Hjl5qYAB',
    '006gD000001lqquQAA'
};

String businessContext = 'This prompt reviews the opportunity and comes back with deal coaching guidance.';

// Verify opps exist first
List<Opportunity> opps = [SELECT Id, Name, Amount FROM Opportunity WHERE Id IN :oppIds];
System.debug('Found ' + opps.size() + ' opportunities:');
for (Opportunity o : opps) {
    System.debug('  - ' + o.Name + ' ($' + o.Amount + ')');
}

// Check if Opportunity is accessible
System.debug('Opportunity accessible: ' + SchemaHelper.isObjectAccessible('Opportunity'));

// Get fields
List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields('Opportunity');
System.debug('Found ' + fields.size() + ' fields');

// Create session manually (avoiding AuraHandledException)
PF_Run__c session = new PF_Run__c(
    Root_Object__c = 'Opportunity',
    Business_Context__c = businessContext,
    Sample_Record_Id__c = String.join(oppIds, ','),
    Status__c = 'In Progress',
    Current_Stage__c = 1,
    Started_At__c = System.now(),
    AI_Model__c = 'Claude'
);
insert session;
System.debug('Created session: ' + session.Id);
