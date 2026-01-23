/**
 * Insert ChildChain traversal records
 * These define which child objects to ALWAYS include when a root object is selected
 * The format extends the existing traversal schema with traversalType = "childChain"
 */

// Get Builder RecordType ID
Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName()
    .get('Builder').getRecordTypeId();

List<ccai__AI_Prompt__c> chains = new List<ccai__AI_Prompt__c>();

// =============================================================================
// OPPORTUNITY CHILD CHAINS
// =============================================================================

// Opportunity → OpportunityContactRole → Contact
chains.add(new ccai__AI_Prompt__c(
    Name = 'Opportunity Stakeholders Chain',
    RecordTypeId = builderRtId,
    ccai__Object__c = 'Opportunity',
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = JSON.serialize(new Map<String, Object>{
        'traversalType' => 'childChain',
        'rootObject' => 'Opportunity',
        'description' => 'Include stakeholders via OpportunityContactRole junction',
        'chain' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'object' => 'OpportunityContactRole',
                'relationshipName' => 'OpportunityContactRoles',
                'relationshipField' => 'OpportunityId',
                'keyFields' => new List<String>{'Role', 'IsPrimary', 'ContactId'}
            },
            new Map<String, Object>{
                'object' => 'Contact',
                'via' => 'ContactId',
                'keyFields' => new List<String>{'Name', 'Title', 'Email', 'Phone'}
            }
        }
    })
));

// Opportunity → OpportunityLineItem → Product2
chains.add(new ccai__AI_Prompt__c(
    Name = 'Opportunity Products Chain',
    RecordTypeId = builderRtId,
    ccai__Object__c = 'Opportunity',
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = JSON.serialize(new Map<String, Object>{
        'traversalType' => 'childChain',
        'rootObject' => 'Opportunity',
        'description' => 'Include products via OpportunityLineItem',
        'chain' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'object' => 'OpportunityLineItem',
                'relationshipName' => 'OpportunityLineItems',
                'relationshipField' => 'OpportunityId',
                'keyFields' => new List<String>{'Quantity', 'UnitPrice', 'TotalPrice', 'Product2Id'}
            },
            new Map<String, Object>{
                'object' => 'Product2',
                'via' => 'Product2Id',
                'keyFields' => new List<String>{'Name', 'Family', 'ProductCode'}
            }
        }
    })
));

// =============================================================================
// ACCOUNT CHILD CHAINS
// =============================================================================

// Account → Contact (direct child)
chains.add(new ccai__AI_Prompt__c(
    Name = 'Account Contacts Chain',
    RecordTypeId = builderRtId,
    ccai__Object__c = 'Account',
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = JSON.serialize(new Map<String, Object>{
        'traversalType' => 'childChain',
        'rootObject' => 'Account',
        'description' => 'Include primary contacts',
        'chain' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'object' => 'Contact',
                'relationshipName' => 'Contacts',
                'relationshipField' => 'AccountId',
                'keyFields' => new List<String>{'Name', 'Title', 'Email', 'Phone', 'Department'}
            }
        }
    })
));

// Account → Opportunity → OpportunityContactRole → Contact
chains.add(new ccai__AI_Prompt__c(
    Name = 'Account Opportunities Chain',
    RecordTypeId = builderRtId,
    ccai__Object__c = 'Account',
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = JSON.serialize(new Map<String, Object>{
        'traversalType' => 'childChain',
        'rootObject' => 'Account',
        'description' => 'Include opportunities and stakeholders',
        'chain' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'object' => 'Opportunity',
                'relationshipName' => 'Opportunities',
                'relationshipField' => 'AccountId',
                'keyFields' => new List<String>{'Name', 'StageName', 'Amount', 'CloseDate', 'Probability'}
            },
            new Map<String, Object>{
                'object' => 'OpportunityContactRole',
                'relationshipName' => 'OpportunityContactRoles',
                'relationshipField' => 'OpportunityId',
                'keyFields' => new List<String>{'Role', 'IsPrimary', 'ContactId'}
            }
        }
    })
));

// Account → Case → CaseComment
chains.add(new ccai__AI_Prompt__c(
    Name = 'Account Cases Chain',
    RecordTypeId = builderRtId,
    ccai__Object__c = 'Account',
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = JSON.serialize(new Map<String, Object>{
        'traversalType' => 'childChain',
        'rootObject' => 'Account',
        'description' => 'Include cases and comments',
        'chain' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'object' => 'Case',
                'relationshipName' => 'Cases',
                'relationshipField' => 'AccountId',
                'keyFields' => new List<String>{'Subject', 'Status', 'Priority', 'Type', 'CaseNumber'}
            },
            new Map<String, Object>{
                'object' => 'CaseComment',
                'relationshipName' => 'CaseComments',
                'relationshipField' => 'ParentId',
                'keyFields' => new List<String>{'CommentBody', 'IsPublished', 'CreatedDate'}
            }
        }
    })
));

// =============================================================================
// CASE CHILD CHAINS
// =============================================================================

// Case → CaseComment
chains.add(new ccai__AI_Prompt__c(
    Name = 'Case Comments Chain',
    RecordTypeId = builderRtId,
    ccai__Object__c = 'Case',
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = JSON.serialize(new Map<String, Object>{
        'traversalType' => 'childChain',
        'rootObject' => 'Case',
        'description' => 'Include case comments for conversation history',
        'chain' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'object' => 'CaseComment',
                'relationshipName' => 'CaseComments',
                'relationshipField' => 'ParentId',
                'keyFields' => new List<String>{'CommentBody', 'IsPublished', 'CreatedDate'}
            }
        }
    })
));

// Case → EmailMessage
chains.add(new ccai__AI_Prompt__c(
    Name = 'Case Emails Chain',
    RecordTypeId = builderRtId,
    ccai__Object__c = 'Case',
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = JSON.serialize(new Map<String, Object>{
        'traversalType' => 'childChain',
        'rootObject' => 'Case',
        'description' => 'Include email thread for case',
        'chain' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'object' => 'EmailMessage',
                'relationshipName' => 'EmailMessages',
                'relationshipField' => 'ParentId',
                'keyFields' => new List<String>{'Subject', 'TextBody', 'FromAddress', 'ToAddress', 'MessageDate'}
            }
        }
    })
));

// Insert all chains
insert chains;

System.debug('Inserted ' + chains.size() + ' child chain traversal records');
for (ccai__AI_Prompt__c c : chains) {
    System.debug('  - ' + c.Name + ' (' + c.Id + ')');
}
