/**
 * Insert Output Rules builder prompt (V2.4)
 * Contains GPTfy merge field syntax rules for prompt generation
 */

// Get Builder record type ID
Id builderRecordTypeId = Schema.SObjectType.ccai__AI_Prompt__c
    .getRecordTypeInfosByDeveloperName()
    .get('Builder')
    .getRecordTypeId();

// Output Rules content - GPTfy merge field syntax
String outputRulesContent = '=== GPTfy MERGE FIELD SYNTAX RULES ===\n\n' +
    'CRITICAL: Follow these rules exactly when generating prompts with merge fields.\n\n' +

    '--- RULE 1: Triple Braces for Values ---\n' +
    '{{{FieldName}}} - Outputs raw value (CORRECT)\n' +
    '{{FieldName}} - HTML-escapes special chars (WRONG)\n\n' +

    '--- RULE 2: Primary Object Fields - No Prefix ---\n' +
    '{{{Name}}} - Correct for root object fields\n' +
    '{{{Account.Name}}} - WRONG, do not prefix root object\n\n' +

    '--- RULE 3: Parent Lookup Fields - Dot Notation ---\n' +
    '{{{Owner.Name}}} - Lookup to User\n' +
    '{{{Account.Industry}}} - Lookup to Account\n' +
    '{{{CreatedBy.Email}}} - System relationship\n\n' +

    '--- RULE 4: Child Collections - Use DCM Relationship Name ---\n' +
    'Use the EXACT relationshipName from the DCM configuration.\n' +
    'Can be plural OR singular depending on DCM setup.\n' +
    '{{#Contacts}}...{{/Contacts}} - If DCM relationshipName is "Contacts"\n' +
    '{{#Task}}...{{/Task}} - If DCM relationshipName is "Task" (singular is valid)\n\n' +

    '--- RULE 5: Child Fields - MUST Include Collection Prefix ---\n' +
    'Inside {{#Collection}}...{{/Collection}}, fields MUST include the collection name:\n' +
    '{{#Contacts}}{{{Contacts.Name}}}{{/Contacts}} - CORRECT\n' +
    '{{#Contacts}}{{{Name}}}{{/Contacts}} - WRONG\n' +
    '{{#Events}}{{{Events.Subject}}}{{/Events}} - CORRECT\n' +
    '{{#OpportunityContactRoles}}{{{OpportunityContactRoles.Contact.Name}}}{{/OpportunityContactRoles}} - Parent lookup in child\n\n' +

    '--- RULE 6: Grandchild Fields - Chained Dot Notation ---\n' +
    'For grandchildren (child of child), chain the relationship names:\n' +
    '{{{Cases.CaseComments.CommentBody}}} - Account > Case > CaseComment\n' +
    '{{{Opportunities.OpportunityLineItems.Product2.Name}}} - Opp > LineItem > Product\n\n' +

    '--- RULE 7: Empty State Handling ---\n' +
    'PREFERRED ({{else}} syntax):\n' +
    '{{#Contacts}}<div>{{{Contacts.Name}}}</div>{{else}}<div>No contacts</div>{{/Contacts}}\n\n' +
    'LEGACY ({{^}} inverted section):\n' +
    '{{#Contacts}}<div>{{{Contacts.Name}}}</div>{{/Contacts}}\n' +
    '{{^Contacts}}<div>No contacts</div>{{/Contacts}}\n\n' +

    '--- RULE 8: Conditional Rendering ---\n' +
    '{{#unless Collection.BooleanField}}...{{/unless}} - Negation\n' +
    '{{#Opportunities}}{{#unless Opportunities.IsClosed}}<tr>...</tr>{{/unless}}{{/Opportunities}}\n\n' +

    '--- RULE 9: Table Structure ---\n' +
    'Table headers MUST be OUTSIDE the loop:\n' +
    '<table><tr><th>Name</th><th>Amount</th></tr>\n' +
    '{{#Opportunities}}<tr><td>{{{Opportunities.Name}}}</td><td>{{{Opportunities.Amount}}}</td></tr>{{/Opportunities}}\n' +
    '</table>\n\n' +

    '--- OUTPUT FORMAT RULES ---\n' +
    '1. Output must be a SINGLE LINE of HTML - no newlines\n' +
    '2. Use ONLY inline styles - no CSS classes or style blocks\n' +
    '3. No script tags or event handlers\n' +
    '4. Start with <div style="..."> and end with </div>\n';

// Check if Output Rules builder already exists
List<ccai__AI_Prompt__c> existing = [
    SELECT Id FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRecordTypeId
    AND ccai__Type__c = 'Output Rules'
    LIMIT 1
];

if (!existing.isEmpty()) {
    System.debug('Output Rules builder already exists: ' + existing[0].Id);
    System.debug('Updating content...');
    existing[0].ccai__Prompt_Command__c = outputRulesContent;
    existing[0].ccai__Status__c = 'Active';
    update existing[0];
    System.debug('Updated successfully');
} else {
    // Create new builder prompt
    ccai__AI_Prompt__c outputRulesBuilder = new ccai__AI_Prompt__c(
        RecordTypeId = builderRecordTypeId,
        Name = 'GPTfy Merge Field Syntax Rules',
        ccai__Type__c = 'Output Rules',
        ccai__Prompt_Command__c = outputRulesContent,
        ccai__Status__c = 'Active',
        ccai__Object__c = '*',  // Applies to all objects
        ccai__Description__c = 'Defines the correct syntax for GPTfy merge fields including triple braces, collection prefixes, grandchild notation, and empty state handling. Used by Prompt Factory Stage 8 to guide LLM prompt generation.'
    );

    insert outputRulesBuilder;
    System.debug('Created Output Rules builder: ' + outputRulesBuilder.Id);
}

// Verify
List<ccai__AI_Prompt__c> verify = [
    SELECT Id, Name, ccai__Type__c, ccai__Status__c,
           CreatedDate, LastModifiedDate
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = :builderRecordTypeId
    AND ccai__Type__c = 'Output Rules'
    LIMIT 1
];

if (!verify.isEmpty()) {
    System.debug('=== Output Rules Builder ===');
    System.debug('ID: ' + verify[0].Id);
    System.debug('Name: ' + verify[0].Name);
    System.debug('Type: ' + verify[0].ccai__Type__c);
    System.debug('Status: ' + verify[0].ccai__Status__c);
}
