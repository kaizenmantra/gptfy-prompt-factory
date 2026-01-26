# DCM vs JSON Data Mismatch Analysis

## The Problem Explained

**DCM Configuration** (Data Context Mapping a05gD000000b5GuQAI)
- Name: "Account 360 view - GPTfy"
- Root Object: Account
- Prompt: "Account 360 View - GPTfy - Reimagined" (a0DgD000001ldoZUAQ)

### DCM Detail Records (What SHOULD be queried):

| Object | Relationship Name | Type | Level |
|--------|------------------|------|-------|
| Event | Event | CHILD | Account → Event |
| Task | Task | CHILD | Account → Task |
| Opportunity | Opportunities | CHILD | Account → Opportunity |
| Case | Cases | CHILD | Account → Case |
| CaseComment | CaseComments | GRANDCHILD | Case → CaseComment |
| Task | Tasks | GRANDCHILD | (unclear parent) |
| OpportunityContactRole | OpportunityContactRoles | GRANDCHILD | Opportunity → OCR |

### Actual JSON Data (What WAS returned):

```
Account: 001QH000024lQv3YAE
├─ Cases: 2 records ✅
│  └─ CaseComments: 6 records ✅
├─ Opportunities: 2 records ✅
│  └─ OpportunityContactRoles: 3 records ✅
├─ Task: 112 records ❌ (from OTHER accounts)
└─ Event: MISSING ❌
```

## Root Cause

The DCM defines **Task and Event as CHILD objects** of Account, meaning they should be queried like:

```sql
SELECT Id, Subject, ... FROM Task WHERE AccountId = '001QH000024lQv3YAE'
SELECT Id, Subject, ... FROM Event WHERE AccountId = '001QH000024lQv3YAE'
```

However, **Tasks/Events don't have an AccountId field in Salesforce**. They use:
- **WhatId** - polymorphic lookup to Account, Opportunity, Case, etc.
- **WhoId** - polymorphic lookup to Contact, Lead

## Why the JSON Has 112 Tasks from Other Accounts

The prompt/DCM execution likely:
1. Tried to query Tasks related to Account
2. Used incorrect relationship query (not filtering by WhatId)
3. Retrieved Tasks from other test data/accounts
4. Included them in the JSON response

## The Correct DCM Configuration Should Be

Tasks and Events should **NOT** be direct CHILD records. They should be configured to filter by WhatId:

**Option 1**: Use WHERE clause in DCM Detail
```
Object: Task
Relationship: Tasks
Type: CHILD
WHERE: WhatId = :recordId
```

**Option 2**: Query via multiple relationships
```
Tasks related to Account (WhatId = Account.Id)
Tasks related to Opportunities (WhatId IN Opportunity.Ids)
Tasks related to Cases (WhatId IN Case.Ids)
Tasks related to Contacts via WhoId (WhoId IN Contact.Ids)
```

## Why Cases/Opportunities Worked

Cases and Opportunities have proper **AccountId lookup fields**:
- `Case.AccountId` → filters correctly
- `Opportunity.AccountId` → filters correctly
- Standard Salesforce parent-child relationship works as expected

## Impact on Testing

For Account 001QH000024lQv3YAE:

**What we CAN reliably test:**
- ✅ Cases (proper AccountId relationship)
- ✅ CaseComments (grandchild via Case)
- ✅ Opportunities (proper AccountId relationship)  
- ✅ OpportunityContactRoles (grandchild via Opportunity)
- ✅ Parent lookups (Contact.Name via ContactId)

**What we CANNOT test with current data:**
- ❌ Tasks (112 records are from OTHER accounts - data pollution)
- ❌ Events (not present in JSON at all)

## Recommended Fix

### Short-term (for testing):
1. Accept this Account for Cases/Opportunities testing only
2. Skip Task/Event validation in initial integration tests
3. Document that Task/Event querying needs DCM WHERE clause support

### Long-term (for production):
1. Update DCM Detail records for Task/Event to include WHERE clause filtering
2. Or modify query builder to handle WhatId/WhoId polymorphic lookups correctly
3. Re-run pipeline to generate correct JSON with only related Tasks/Events

### Alternative for immediate testing:
Create a SOQL query to verify if ANY Tasks/Events exist for this Account:

```sql
SELECT COUNT(Id) FROM Task WHERE WhatId = '001QH000024lQv3YAE'
SELECT COUNT(Id) FROM Event WHERE WhatId = '001QH000024lQv3YAE'
```

If zero, then manually create 2-3 Tasks/Events for this Account before using as test case.
