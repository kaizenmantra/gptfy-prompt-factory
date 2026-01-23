/**
 * Insert Traversal Builder Prompts Only
 * 25 traversals for parent field resolution
 */

Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
List<ccai__AI_Prompt__c> builders = new List<ccai__AI_Prompt__c>();

// Contact Traversals
builders.add(new ccai__AI_Prompt__c(
    Name = 'OpportunityContactRole Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OpportunityContactRole',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Title, Contact.Email for stakeholder personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"OpportunityContactRole","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Title","alias":"ContactTitle"},{"path":"Email","alias":"ContactEmail"},{"path":"Phone","alias":"ContactPhone"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'CaseContactRole Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'CaseContactRole',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Email for case contact personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"CaseContactRole","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Title","alias":"ContactTitle"},{"path":"Email","alias":"ContactEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'AccountContactRole Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'AccountContactRole',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Title for account team personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"AccountContactRole","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Title","alias":"ContactTitle"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'CampaignMember Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'CampaignMember',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Email for campaign targeting.',
    ccai__Prompt_Command__c = '{"sourceObject":"CampaignMember","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Email","alias":"ContactEmail"}]}'
));

// Account Traversals
builders.add(new ccai__AI_Prompt__c(
    Name = 'Opportunity Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Opportunity',
    ccai__Description__c = 'Resolves AccountId to Account.Name, Account.Industry for context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Opportunity","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"Industry","alias":"AccountIndustry"},{"path":"AnnualRevenue","alias":"AccountRevenue"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Contact Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Contact',
    ccai__Description__c = 'Resolves AccountId to Account.Name for contact context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Contact","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"Industry","alias":"AccountIndustry"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Case Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Case',
    ccai__Description__c = 'Resolves AccountId to Account.Name for case context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Case","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Contract Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Contract',
    ccai__Description__c = 'Resolves AccountId to Account.Name for contract context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Contract","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"BillingCity","alias":"AccountCity"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Order Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Order',
    ccai__Description__c = 'Resolves AccountId to Account.Name for order context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Order","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"ShippingCity","alias":"AccountCity"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Quote Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Quote',
    ccai__Description__c = 'Resolves AccountId to Account.Name for quote context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Quote","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Asset Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Asset',
    ccai__Description__c = 'Resolves AccountId to Account.Name, Account.Industry for asset context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Asset","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"Industry","alias":"AccountIndustry"}]}'
));

// Owner Traversals
builders.add(new ccai__AI_Prompt__c(
    Name = 'Opportunity Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Opportunity',
    ccai__Description__c = 'Resolves OwnerId to User.Name for owner personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Opportunity","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Case Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Case',
    ccai__Description__c = 'Resolves OwnerId to User.Name for case owner personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Case","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Account Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Account',
    ccai__Description__c = 'Resolves OwnerId to User.Name for account manager personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Account","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"},{"path":"Title","alias":"OwnerTitle"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Lead Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Lead',
    ccai__Description__c = 'Resolves OwnerId to User.Name for lead owner personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Lead","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"}]}'
));

// Polymorphic Traversals
builders.add(new ccai__AI_Prompt__c(
    Name = 'Task Who Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Task',
    ccai__Description__c = 'Resolves WhoId to Contact.Name or Lead.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Task","sourceField":"WhoId","targetObject":"Contact|Lead","polymorphic":true,"fields":[{"path":"Name","alias":"WhoName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Task What Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Task',
    ccai__Description__c = 'Resolves WhatId to Account.Name or Opportunity.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Task","sourceField":"WhatId","targetObject":"Account|Opportunity","polymorphic":true,"fields":[{"path":"Name","alias":"WhatName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Event Who Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Event',
    ccai__Description__c = 'Resolves WhoId to Contact.Name or Lead.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Event","sourceField":"WhoId","targetObject":"Contact|Lead","polymorphic":true,"fields":[{"path":"Name","alias":"WhoName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Event What Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Event',
    ccai__Description__c = 'Resolves WhatId to Account.Name or Opportunity.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Event","sourceField":"WhatId","targetObject":"Account|Opportunity","polymorphic":true,"fields":[{"path":"Name","alias":"WhatName"}]}'
));

// Product Traversals
builders.add(new ccai__AI_Prompt__c(
    Name = 'OpportunityLineItem Product Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OpportunityLineItem',
    ccai__Description__c = 'Resolves Product2Id to Product2.Name, Family for product context.',
    ccai__Prompt_Command__c = '{"sourceObject":"OpportunityLineItem","sourceField":"Product2Id","targetObject":"Product2","fields":[{"path":"Name","alias":"ProductName"},{"path":"Family","alias":"ProductFamily"},{"path":"ProductCode","alias":"ProductCode"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'QuoteLineItem Product Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'QuoteLineItem',
    ccai__Description__c = 'Resolves Product2Id to Product2.Name, Family for quote line context.',
    ccai__Prompt_Command__c = '{"sourceObject":"QuoteLineItem","sourceField":"Product2Id","targetObject":"Product2","fields":[{"path":"Name","alias":"ProductName"},{"path":"Family","alias":"ProductFamily"},{"path":"ProductCode","alias":"ProductCode"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'OrderItem Product Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OrderItem',
    ccai__Description__c = 'Resolves Product2Id to Product2.Name for order line context.',
    ccai__Prompt_Command__c = '{"sourceObject":"OrderItem","sourceField":"Product2Id","targetObject":"Product2","fields":[{"path":"Name","alias":"ProductName"},{"path":"Family","alias":"ProductFamily"}]}'
));

// Case Child Traversals
builders.add(new ccai__AI_Prompt__c(
    Name = 'Case Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Case',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Email for case personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Case","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Email","alias":"ContactEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'CaseComment Case Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'CaseComment',
    ccai__Description__c = 'Resolves ParentId to Case.Subject, CaseNumber for comment context.',
    ccai__Prompt_Command__c = '{"sourceObject":"CaseComment","sourceField":"ParentId","targetObject":"Case","fields":[{"path":"Subject","alias":"CaseSubject"},{"path":"CaseNumber","alias":"CaseNumber"},{"path":"Status","alias":"CaseStatus"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'EmailMessage Case Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'EmailMessage',
    ccai__Description__c = 'Resolves ParentId to Case.Subject, CaseNumber for email thread context.',
    ccai__Prompt_Command__c = '{"sourceObject":"EmailMessage","sourceField":"ParentId","targetObject":"Case","fields":[{"path":"Subject","alias":"CaseSubject"},{"path":"CaseNumber","alias":"CaseNumber"}]}'
));

System.debug('Inserting ' + builders.size() + ' traversal builders...');
Database.SaveResult[] results = Database.insert(builders, false);

Integer successCount = 0;
Integer failCount = 0;
for (Integer i = 0; i < results.size(); i++) {
    if (results[i].isSuccess()) {
        successCount++;
    } else {
        failCount++;
        System.debug('Failed: ' + builders[i].Name + ' - ' + results[i].getErrors()[0].getMessage());
    }
}

System.debug('=== TRAVERSAL BUILDERS COMPLETE ===');
System.debug('Success: ' + successCount);
System.debug('Failed: ' + failCount);
