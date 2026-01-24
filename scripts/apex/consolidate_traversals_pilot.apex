/**
 * Consolidate Traversals - Pilot (Account + Opportunity)
 *
 * Creates two new consolidated traversal records and deactivates the old granular ones.
 * This is a pilot - if successful, we'll consolidate the remaining objects.
 */

Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c
    .getRecordTypeInfosByDeveloperName()
    .get('Builder')
    .getRecordTypeId();

// ============================================================================
// CONSOLIDATED ACCOUNT TRAVERSALS
// ============================================================================
String accountTraversals = '=== ACCOUNT TRAVERSALS ===\n\n' +
    'When the ROOT OBJECT is Account, these traversals are available:\n\n' +

    '--- PARENT LOOKUPS (use {{{Relationship.Field}}} syntax) ---\n\n' +
    'Owner (via OwnerId):\n' +
    '  {{{Owner.Name}}} - Account owner name\n' +
    '  {{{Owner.Email}}} - Account owner email\n' +
    '  {{{Owner.Title}}} - Account owner title\n\n' +

    'CreatedBy (via CreatedById):\n' +
    '  {{{CreatedBy.Name}}} - Record creator name\n\n' +

    'Parent Account (via ParentId):\n' +
    '  {{{Parent.Name}}} - Parent account name\n' +
    '  {{{Parent.Industry}}} - Parent account industry\n\n' +

    '--- CHILD RELATIONSHIPS (use {{#Collection}}...{{/Collection}}) ---\n\n' +
    'Contacts (relationshipName: Contacts):\n' +
    '  Key fields: Name, Title, Email, Phone, Department, MailingCity\n' +
    '  Use: {{#Contacts}}{{{Contacts.Name}}} - {{{Contacts.Title}}}{{/Contacts}}\n\n' +

    'Opportunities (relationshipName: Opportunities):\n' +
    '  Key fields: Name, StageName, Amount, CloseDate, Probability, IsClosed, IsWon\n' +
    '  Use: {{#Opportunities}}{{{Opportunities.Name}}} - {{{Opportunities.Amount}}}{{/Opportunities}}\n' +
    '  Filter open: {{#Opportunities}}{{#unless Opportunities.IsClosed}}...{{/unless}}{{/Opportunities}}\n\n' +

    'Cases (relationshipName: Cases):\n' +
    '  Key fields: CaseNumber, Subject, Status, Priority, Type, IsClosed, CreatedDate\n' +
    '  Use: {{#Cases}}{{{Cases.CaseNumber}}} - {{{Cases.Subject}}}{{/Cases}}\n\n' +

    'Contracts (relationshipName: Contracts):\n' +
    '  Key fields: ContractNumber, Status, StartDate, EndDate, ContractTerm\n' +
    '  Use: {{#Contracts}}{{{Contracts.ContractNumber}}} - {{{Contracts.Status}}}{{/Contracts}}\n\n' +

    'Tasks (relationshipName: Tasks - via WhatId):\n' +
    '  Key fields: Subject, Status, ActivityDate, Priority, Description\n' +
    '  Use: {{#Tasks}}{{{Tasks.Subject}}} - {{{Tasks.Status}}}{{/Tasks}}\n\n' +

    'Events (relationshipName: Events - via WhatId):\n' +
    '  Key fields: Subject, StartDateTime, EndDateTime, Location, Description\n' +
    '  Use: {{#Events}}{{{Events.Subject}}} - {{{Events.StartDateTime}}}{{/Events}}\n\n' +

    'Assets (relationshipName: Assets):\n' +
    '  Key fields: Name, SerialNumber, Status, InstallDate, PurchaseDate\n' +
    '  Use: {{#Assets}}{{{Assets.Name}}} - {{{Assets.Status}}}{{/Assets}}\n\n' +

    'Orders (relationshipName: Orders):\n' +
    '  Key fields: OrderNumber, Status, EffectiveDate, TotalAmount\n' +
    '  Use: {{#Orders}}{{{Orders.OrderNumber}}} - {{{Orders.TotalAmount}}}{{/Orders}}\n\n' +

    '--- GRANDCHILD CHAINS (nested iterations) ---\n\n' +
    'Cases → CaseComments:\n' +
    '  {{#Cases}}\n' +
    '    Case: {{{Cases.Subject}}}\n' +
    '    {{#Cases.CaseComments}}{{{Cases.CaseComments.CommentBody}}}{{/Cases.CaseComments}}\n' +
    '  {{/Cases}}\n\n' +

    'Opportunities → OpportunityContactRoles → Contact:\n' +
    '  {{#Opportunities}}\n' +
    '    Opp: {{{Opportunities.Name}}}\n' +
    '    {{#Opportunities.OpportunityContactRoles}}\n' +
    '      {{{Opportunities.OpportunityContactRoles.Contact.Name}}} ({{{Opportunities.OpportunityContactRoles.Role}}})\n' +
    '    {{/Opportunities.OpportunityContactRoles}}\n' +
    '  {{/Opportunities}}\n\n' +

    'Opportunities → OpportunityLineItems → Product2:\n' +
    '  {{#Opportunities}}\n' +
    '    {{#Opportunities.OpportunityLineItems}}\n' +
    '      {{{Opportunities.OpportunityLineItems.Product2.Name}}} - {{{Opportunities.OpportunityLineItems.TotalPrice}}}\n' +
    '    {{/Opportunities.OpportunityLineItems}}\n' +
    '  {{/Opportunities}}\n';

// ============================================================================
// CONSOLIDATED OPPORTUNITY TRAVERSALS
// ============================================================================
String opportunityTraversals = '=== OPPORTUNITY TRAVERSALS ===\n\n' +
    'When the ROOT OBJECT is Opportunity, these traversals are available:\n\n' +

    '--- PARENT LOOKUPS (use {{{Relationship.Field}}} syntax) ---\n\n' +
    'Account (via AccountId):\n' +
    '  {{{Account.Name}}} - Related account name\n' +
    '  {{{Account.Industry}}} - Account industry\n' +
    '  {{{Account.AnnualRevenue}}} - Account annual revenue\n' +
    '  {{{Account.Type}}} - Account type\n' +
    '  {{{Account.BillingCity}}} - Account billing city\n\n' +

    'Owner (via OwnerId):\n' +
    '  {{{Owner.Name}}} - Opportunity owner name\n' +
    '  {{{Owner.Email}}} - Opportunity owner email\n' +
    '  {{{Owner.Title}}} - Opportunity owner title\n\n' +

    'Campaign (via CampaignId):\n' +
    '  {{{Campaign.Name}}} - Primary campaign name\n' +
    '  {{{Campaign.Type}}} - Campaign type\n\n' +

    'CreatedBy (via CreatedById):\n' +
    '  {{{CreatedBy.Name}}} - Record creator name\n\n' +

    '--- CHILD RELATIONSHIPS (use {{#Collection}}...{{/Collection}}) ---\n\n' +
    'OpportunityContactRoles (relationshipName: OpportunityContactRoles):\n' +
    '  Key fields: Role, IsPrimary, ContactId\n' +
    '  Parent lookup: Contact.Name, Contact.Title, Contact.Email, Contact.Phone\n' +
    '  Use: {{#OpportunityContactRoles}}\n' +
    '         {{{OpportunityContactRoles.Contact.Name}}} - {{{OpportunityContactRoles.Role}}}\n' +
    '       {{/OpportunityContactRoles}}\n\n' +

    'OpportunityLineItems (relationshipName: OpportunityLineItems):\n' +
    '  Key fields: Quantity, UnitPrice, TotalPrice, Description\n' +
    '  Parent lookup: Product2.Name, Product2.Family, Product2.ProductCode\n' +
    '  Use: {{#OpportunityLineItems}}\n' +
    '         {{{OpportunityLineItems.Product2.Name}}} - {{{OpportunityLineItems.TotalPrice}}}\n' +
    '       {{/OpportunityLineItems}}\n\n' +

    'Tasks (relationshipName: Tasks - via WhatId):\n' +
    '  Key fields: Subject, Status, ActivityDate, Priority, Description\n' +
    '  Use: {{#Tasks}}{{{Tasks.Subject}}} - {{{Tasks.Status}}}{{/Tasks}}\n\n' +

    'Events (relationshipName: Events - via WhatId):\n' +
    '  Key fields: Subject, StartDateTime, EndDateTime, Location\n' +
    '  Use: {{#Events}}{{{Events.Subject}}} - {{{Events.StartDateTime}}}{{/Events}}\n\n' +

    'OpportunityHistories (relationshipName: OpportunityHistories):\n' +
    '  Key fields: StageName, Amount, Probability, CloseDate, CreatedDate\n' +
    '  Use: {{#OpportunityHistories}}{{{OpportunityHistories.StageName}}}{{/OpportunityHistories}}\n\n' +

    'Quotes (relationshipName: Quotes):\n' +
    '  Key fields: Name, Status, TotalPrice, ExpirationDate, IsSyncing\n' +
    '  Use: {{#Quotes}}{{{Quotes.Name}}} - {{{Quotes.TotalPrice}}}{{/Quotes}}\n\n' +

    '--- STAKEHOLDER ANALYSIS PATTERN ---\n\n' +
    'For comprehensive stakeholder coverage:\n' +
    '{{#OpportunityContactRoles}}\n' +
    '  <div style="...">\n' +
    '    <strong>{{{OpportunityContactRoles.Contact.Name}}}</strong>\n' +
    '    <span>{{{OpportunityContactRoles.Contact.Title}}}</span>\n' +
    '    <span>Role: {{{OpportunityContactRoles.Role}}}</span>\n' +
    '    {{#OpportunityContactRoles.IsPrimary}}<span style="color:green;">PRIMARY</span>{{/OpportunityContactRoles.IsPrimary}}\n' +
    '  </div>\n' +
    '{{else}}\n' +
    '  <div>No stakeholders identified - consider adding contact roles</div>\n' +
    '{{/OpportunityContactRoles}}\n\n' +

    '--- PRODUCT ANALYSIS PATTERN ---\n\n' +
    '{{#OpportunityLineItems}}\n' +
    '  <tr>\n' +
    '    <td>{{{OpportunityLineItems.Product2.Name}}}</td>\n' +
    '    <td>{{{OpportunityLineItems.Product2.Family}}}</td>\n' +
    '    <td>{{{OpportunityLineItems.Quantity}}}</td>\n' +
    '    <td>{{{OpportunityLineItems.TotalPrice}}}</td>\n' +
    '  </tr>\n' +
    '{{else}}\n' +
    '  <tr><td colspan="4">No products added to opportunity</td></tr>\n' +
    '{{/OpportunityLineItems}}\n';

// ============================================================================
// CREATE/UPDATE CONSOLIDATED RECORDS
// ============================================================================

// Check for existing consolidated records
List<ccai__AI_Prompt__c> existingConsolidated = [
    SELECT Id, Name FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
    AND ccai__Type__c = 'Traversal'
    AND Name IN ('Account Traversals', 'Opportunity Traversals')
];

Map<String, Id> existingMap = new Map<String, Id>();
for (ccai__AI_Prompt__c p : existingConsolidated) {
    existingMap.put(p.Name, p.Id);
}

List<ccai__AI_Prompt__c> toUpsert = new List<ccai__AI_Prompt__c>();

// Account Traversals
ccai__AI_Prompt__c accountBuilder = new ccai__AI_Prompt__c(
    RecordTypeId = builderRtId,
    Name = 'Account Traversals',
    ccai__Type__c = 'Traversal',
    ccai__Object__c = 'Account',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = accountTraversals,
    ccai__Description__c = 'Consolidated traversals for Account: parent lookups (Owner, Parent), child relationships (Contacts, Opportunities, Cases, Contracts, Tasks, Events, Assets, Orders), and grandchild chains.'
);
if (existingMap.containsKey('Account Traversals')) {
    accountBuilder.Id = existingMap.get('Account Traversals');
}
toUpsert.add(accountBuilder);

// Opportunity Traversals
ccai__AI_Prompt__c oppBuilder = new ccai__AI_Prompt__c(
    RecordTypeId = builderRtId,
    Name = 'Opportunity Traversals',
    ccai__Type__c = 'Traversal',
    ccai__Object__c = 'Opportunity',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = opportunityTraversals,
    ccai__Description__c = 'Consolidated traversals for Opportunity: parent lookups (Account, Owner, Campaign), child relationships (ContactRoles, LineItems, Tasks, Events, Quotes), and common analysis patterns.'
);
if (existingMap.containsKey('Opportunity Traversals')) {
    oppBuilder.Id = existingMap.get('Opportunity Traversals');
}
toUpsert.add(oppBuilder);

upsert toUpsert;
System.debug('Created/Updated consolidated traversal records:');
for (ccai__AI_Prompt__c p : toUpsert) {
    System.debug('  - ' + p.Name + ' (Id: ' + p.Id + ')');
}

// ============================================================================
// DEACTIVATE OLD GRANULAR RECORDS
// ============================================================================

List<String> accountGranularNames = new List<String>{
    'Account Owner Traversal',
    'Account Contacts Chain',
    'Account Opportunities Chain',
    'Account Cases Chain',
    'AccountContactRole Contact Traversal'
};

List<String> oppGranularNames = new List<String>{
    'Opportunity Account Traversal',
    'Opportunity Owner Traversal',
    'Opportunity Products Chain',
    'Opportunity Stakeholders Chain',
    'OpportunityContactRole Contact Traversal',
    'OpportunityLineItem Product Traversal'
};

List<String> allGranularNames = new List<String>();
allGranularNames.addAll(accountGranularNames);
allGranularNames.addAll(oppGranularNames);

List<ccai__AI_Prompt__c> toDeactivate = [
    SELECT Id, Name, ccai__Status__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRtId
    AND ccai__Type__c = 'Traversal'
    AND Name IN :allGranularNames
    AND ccai__Status__c = 'Active'
];

for (ccai__AI_Prompt__c p : toDeactivate) {
    p.ccai__Status__c = 'Inactive';
}

if (!toDeactivate.isEmpty()) {
    update toDeactivate;
    System.debug('Deactivated ' + toDeactivate.size() + ' granular traversal records:');
    for (ccai__AI_Prompt__c p : toDeactivate) {
        System.debug('  - ' + p.Name);
    }
} else {
    System.debug('No granular records to deactivate (may already be inactive)');
}

// ============================================================================
// SUMMARY
// ============================================================================
System.debug('=== CONSOLIDATION COMPLETE ===');
System.debug('Active consolidated: Account Traversals, Opportunity Traversals');
System.debug('Deactivated: ' + toDeactivate.size() + ' granular records');
System.debug('');
System.debug('To rollback, run: UPDATE ccai__AI_Prompt__c SET ccai__Status__c = \'Active\' WHERE Name IN (' + String.join(allGranularNames, ', ') + ')');
