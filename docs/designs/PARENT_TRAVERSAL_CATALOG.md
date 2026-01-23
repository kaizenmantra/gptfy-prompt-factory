# Parent Traversal Catalog

Reference catalog of common Salesforce parent-child relationship traversals for field selection and DCM building.

---

## Overview

### What is Parent Traversal?

In Salesforce, records often reference parent records via lookup or master-detail fields. Parent traversal allows accessing fields from the parent record using dot notation:

```
ContactId → Contact.Name
AccountId → Account.Industry
OwnerId → User.Email
```

### Why It Matters

Without parent traversal, prompts can only use fields from the base object. This leads to:
- Generic outputs ("the account owner" instead of "Sarah Johnson")
- Missing context (no account industry when analyzing opportunities)
- Impersonal tone (titles instead of names)

### DCM Syntax

In Data Context Mappings, parent fields use this syntax:
```
{!ContactId.Name}      → Resolves to Contact's Name
{!Account.Industry}    → Resolves to Account's Industry (when Account is a lookup)
{!Owner.Email}         → Resolves to Owner User's Email
```

---

## Traversal Catalog

### Category: Contact Traversals

Access Contact information from child objects.

| Child Object | Lookup Field | Parent Object | Recommended Fields | Priority | Use Case |
|--------------|--------------|---------------|-------------------|----------|----------|
| OpportunityContactRole | ContactId | Contact | Name, Title, Email, Phone | High | Personalize stakeholder references |
| CaseContactRole | ContactId | Contact | Name, Title, Email | High | Address case contacts by name |
| AccountContactRole | ContactId | Contact | Name, Title | Medium | Account team personalization |
| Task | WhoId | Contact/Lead | Name | High | Activity personalization (polymorphic) |
| Event | WhoId | Contact/Lead | Name | High | Meeting personalization (polymorphic) |
| CampaignMember | ContactId | Contact | Name, Email | Medium | Campaign targeting |

### Category: Account Traversals

Access Account information from child objects.

| Child Object | Lookup Field | Parent Object | Recommended Fields | Priority | Use Case |
|--------------|--------------|---------------|-------------------|----------|----------|
| Opportunity | AccountId | Account | Name, Industry, Type, BillingCity, AnnualRevenue | High | Account context for deals |
| Contact | AccountId | Account | Name, Industry, Type | High | Company context for contacts |
| Case | AccountId | Account | Name, Type, Industry | High | Customer context for support |
| Contract | AccountId | Account | Name, BillingCity | Medium | Contract account details |
| Order | AccountId | Account | Name, ShippingCity | Medium | Order fulfillment context |
| Quote | AccountId | Account | Name | Medium | Quote account reference |
| Asset | AccountId | Account | Name, Industry | Medium | Asset ownership context |

### Category: Opportunity Traversals

Access Opportunity information from child objects.

| Child Object | Lookup Field | Parent Object | Recommended Fields | Priority | Use Case |
|--------------|--------------|---------------|-------------------|----------|----------|
| OpportunityLineItem | OpportunityId | Opportunity | Name, StageName, Amount, CloseDate | High | Line item deal context |
| Quote | OpportunityId | Opportunity | Name, Amount, CloseDate | High | Quote deal alignment |
| Order | OpportunityId | Opportunity | Name, Amount | Medium | Order-to-opportunity tracing |
| OpportunityContactRole | OpportunityId | Opportunity | Name, StageName | Medium | Role-to-deal mapping |

### Category: Product Traversals

Access Product information from line items.

| Child Object | Lookup Field | Parent Object | Recommended Fields | Priority | Use Case |
|--------------|--------------|---------------|-------------------|----------|----------|
| OpportunityLineItem | Product2Id | Product2 | Name, Family, ProductCode, Description | High | Product context in deals |
| QuoteLineItem | Product2Id | Product2 | Name, Family, ProductCode | High | Product details in quotes |
| OrderItem | Product2Id | Product2 | Name, Family | Medium | Ordered product details |
| PricebookEntry | Product2Id | Product2 | Name, Family | Low | Price book product reference |

### Category: User/Owner Traversals

Access User information from owner fields.

| Child Object | Lookup Field | Parent Object | Recommended Fields | Priority | Use Case |
|--------------|--------------|---------------|-------------------|----------|----------|
| Opportunity | OwnerId | User | Name, Email, Title | High | Sales rep personalization |
| Case | OwnerId | User | Name, Email | High | Support agent identification |
| Account | OwnerId | User | Name, Email | High | Account manager reference |
| Lead | OwnerId | User | Name, Email | High | Lead owner identification |
| Task | OwnerId | User | Name | Medium | Task assignee reference |
| Event | OwnerId | User | Name | Medium | Event organizer reference |

### Category: Case Traversals

Access Case information from child objects.

| Child Object | Lookup Field | Parent Object | Recommended Fields | Priority | Use Case |
|--------------|--------------|---------------|-------------------|----------|----------|
| CaseComment | ParentId | Case | Subject, Status, CaseNumber | High | Comment context |
| EmailMessage | ParentId | Case | Subject, CaseNumber | High | Email thread context |
| CaseHistory | CaseId | Case | Subject, CaseNumber | Low | History tracking |

### Category: Polymorphic Traversals

Special handling for WhatId/WhoId fields that can reference multiple object types.

| Child Object | Lookup Field | Possible Parents | Recommended Fields | Priority | Notes |
|--------------|--------------|------------------|-------------------|----------|-------|
| Task | WhatId | Opportunity, Account, Case, etc. | Name | High | Requires type detection |
| Event | WhatId | Opportunity, Account, Case, etc. | Name | High | Requires type detection |
| Task | WhoId | Contact, Lead | Name | High | Person reference |
| Event | WhoId | Contact, Lead | Name | High | Person reference |
| Attachment | ParentId | Any | (varies) | Low | Universal parent |
| ContentDocumentLink | LinkedEntityId | Any | (varies) | Low | Universal parent |

---

## JSON Schema for Static Resource

This schema is designed for Task 1.7 (Static Resource creation):

```json
{
  "version": "1.0",
  "lastUpdated": "2026-01-23",
  "traversals": [
    {
      "childObject": "OpportunityContactRole",
      "lookupField": "ContactId",
      "parentObject": "Contact",
      "recommendedFields": ["Name", "Title", "Email", "Phone"],
      "priority": "High",
      "category": "Contact",
      "useCase": "Personalize stakeholder references",
      "isPolymorphic": false
    }
  ]
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| childObject | String | The object containing the lookup field |
| lookupField | String | The API name of the lookup/master-detail field |
| parentObject | String | The object being referenced |
| recommendedFields | String[] | Fields commonly useful from the parent |
| priority | Enum | "High", "Medium", "Low" - selection importance |
| category | String | Grouping for organization |
| useCase | String | Brief description of when to use |
| isPolymorphic | Boolean | True if field can reference multiple object types |

---

## Implementation Notes

### Stage 3 (Schema Analysis) Requirements

1. Detect lookup fields by checking `field.getType() == Schema.DisplayType.REFERENCE`
2. Get parent object via `field.getReferenceTo()` (returns list for polymorphic)
3. Cross-reference with catalog to get recommended fields
4. Include parent fields in schema output for Stage 5

### Stage 5 (Field Selection) Requirements

1. Present parent field candidates to LLM alongside base object fields
2. Format: `ContactId.Name` (lookup field + parent field)
3. Include priority from catalog to guide selection
4. For polymorphic fields, note the complexity

### DCM Builder Requirements

1. Support dot notation: `{!ContactId.Name}`
2. Validate that lookup field exists on base object
3. Validate that target field exists on parent object
4. Handle null lookups gracefully in output

---

## Priority Guidelines

**High Priority** - Always suggest when the lookup exists:
- Owner.Name (personalization)
- Contact.Name (stakeholder names)
- Account.Name, Account.Industry (context)
- Product2.Name (product identification)

**Medium Priority** - Suggest based on use case:
- Contact.Email, Contact.Phone (communication)
- Account.AnnualRevenue (financial context)
- User.Title (role context)

**Low Priority** - Only if specifically relevant:
- Historical references
- Technical IDs
- Audit fields

---

## Catalog Statistics

- **Total Traversals:** 33
- **Categories:** 7
- **High Priority:** 18
- **Medium Priority:** 12
- **Low Priority:** 3
- **Polymorphic:** 6

---

## Related Documents

- [META_PROMPT_DESIGN.md](./META_PROMPT_DESIGN.md) - How parent fields integrate into prompts
- [MULTI_SAMPLE_DESIGN.md](./MULTI_SAMPLE_DESIGN.md) - Data profiling architecture
- [BUILDER_IMPROVEMENTS.md](../../BUILDER_IMPROVEMENTS.md) - Master tracker
