String parentObj = 'Account';
String childObj = 'Contact';
List<SchemaHelper.ChildRelationship> rels = SchemaHelper.getChildRelationships(parentObj);
System.debug('--- Relationships for ' + parentObj + ' ---');
for (SchemaHelper.ChildRelationship rel : rels) {
    if (rel.childObject == childObj) {
        System.debug('Found Relationship: ' + rel.relationshipName + ' to ' + rel.childObject + ' via field ' + rel.field);
    }
}

// Check Stage 8 outputs for Vanguard Run PFR-00000194
List<PF_Stage__c> stages = [SELECT Outputs__c FROM PF_Stage__c WHERE Run__r.Name = 'PFR-00000194' AND Stage_Number__c = 8];
if (!stages.isEmpty()) {
    System.debug('--- Stage 8 Outputs for PFR-00000194 ---');
    System.debug(stages[0].Outputs__c);
} else {
    System.debug('No Stage 8 record found for PFR-00000194');
}
