# Account 360 Data Analysis - 001QH000024lQv3YAE

## File Details
- **Source**: docs/samples/account360-response.json
- **Size**: 937 lines, ~81K tokens
- **Format**: Data Context Mapping JSON (DCM response format)

## Data Structure Overview

### Account (Root Object)
- **Account ID**: 001QH000024lQv3YAE
- **Name**: Anchor Wealth Management (inferred from descriptions)
- **Fields**: Name, Phone, Description, Id, Object Name

### Child Objects

#### 1. Cases (2 records)
**Case 1**: Data Sync Error in Portfolio Reporting Dashboard
- CaseNumber: 00001004
- Status: Open (IsClosed: false)
- Origin: Email
- OpenDays: 1
- **Grandchild**: 3 CaseComments

**Case 2**: Reporting Error in Portfolio Performance Dashboard
- CaseNumber: 00001005
- Status: Open (IsClosed: false)
- Origin: Email
- OpenDays: 1
- **Grandchild**: 3 CaseComments

#### 2. Opportunities (2 records)
**Opportunity 1**: Integrated Wealth Management Platform
- Amount: $250,000
- Stage: Proposal/Price Quote
- CloseDate: 2024-02-15
- Status: Open (IsClosed: false)
- **Grandchild**: 1 OpportunityContactRole
  - Contact.Name: Amy Chow (Parent Lookup!)
  - Role: Evaluator
  - IsPrimary: true

**Opportunity 2**: Retirement Planning Services Expansion
- Amount: $175,000
- Stage: Qualification
- CloseDate: 2024-03-01
- Status: Open (IsClosed: false)
- **Grandchild**: 2 OpportunityContactRoles
  - Contact.Name: Sophia Martinez (Parent Lookup!)
    - Role: Economic Buyer, IsPrimary: true
  - Contact.Name: Jacob O'Connor (Parent Lookup!)
    - Role: Influencer, IsPrimary: false

#### 3. Task (Array - appears to contain sample data from OTHER accounts)
- Note: Task records reference different AccountIds (001QH000024ljUbYAI, 001QH000024ljUcYAI)
- This may be test/sample data, not actual related tasks

## Relationship Complexity

### 2-Level Traversals (Account → Child)
- Account → Cases
- Account → Opportunities
- Account → Tasks (if valid)

### 3-Level Traversals (Account → Child → Grandchild)
- Account → Cases → CaseComments ✓
- Account → Opportunities → OpportunityContactRoles ✓

### Parent Lookup Traversals (Child → Parent via Lookup)
- OpportunityContactRole → Contact (ContactId.Name) ✓
- Opportunity → Owner (Owner.Name) ✓

## Test Case Quality Assessment

### ✅ Strengths
1. **Real 3-level data**: Cases with CaseComments, Opportunities with OCRs
2. **Parent lookups present**: Contact.Name, Owner.Name in OCRs
3. **Multiple records per child**: 2 Cases, 2 Opportunities (tests iteration)
4. **Grandchild variation**: Some OCRs have 1 contact role, others have 2
5. **Rich text fields**: Case descriptions, Opportunity descriptions have meaningful content
6. **Diverse data types**: Dates, numbers (Amount), booleans (IsClosed, IsPrimary), text

### ⚠️ Weaknesses
1. **Task data questionable**: References different AccountIds - may be sample data pollution
2. **No Contacts child collection**: Only referenced via parent lookups in OCR
3. **No Events**: Missing common Activity child object
4. **Limited scope**: Only 2 child object types (Cases, Opportunities)

### 🎯 Recommended Additions for Comprehensive Testing
To make this a true "Account 360" golden test case, we'd want:
- Contacts (direct child collection)
- Events (Activities)
- Tasks (valid ones related to this Account)
- Possibly: Contracts, Orders, Quotes

## Data Quality for Testing Merge Fields

### Merge Field Patterns to Test

#### Root Object Fields
- `{{{Name}}}` → "Anchor Wealth Management"
- `{{{Phone}}}` → (value present)
- `{{{Description}}}` → (value present)

#### Child Iteration Blocks
```handlebars
{{#Cases}}
  {{{Subject}}} → "Data Sync Error in Portfolio Reporting Dashboard"
  {{{CaseNumber}}} → "00001004"
  {{{OpenDays__c}}} → "1"
{{/Cases}}
```

#### Grandchild Iteration Blocks
```handlebars
{{#Cases}}
  {{#CaseComments}}
    {{{CommentBody}}} → "Thank you for your patience..."
    {{{CreatedDate}}} → "2026-01-24 01:35:25"
  {{/CaseComments}}
{{/Cases}}
```

#### Parent Lookup Traversals
```handlebars
{{#Opportunities}}
  {{#OpportunityContactRoles}}
    {{{Contact.Name}}} → "Amy Chow" or "Sophia Martinez"
    {{{Role}}} → "Evaluator" or "Economic Buyer"
  {{/OpportunityContactRoles}}
{{/Opportunities}}
```

## Recommendation

**Use this data for Phase 5A.5 testing with caveats:**

1. **For testing 3-level DCM creation**: ✅ Excellent
   - Cases → CaseComments works
   - Opportunities → OpportunityContactRoles works

2. **For testing parent lookups**: ✅ Excellent
   - Contact.Name via ContactId lookup
   - Owner.Name via OwnerId lookup

3. **For testing iteration blocks**: ✅ Good
   - Multiple records per child object
   - Multiple grandchild records

4. **For testing comprehensive Account 360**: ⚠️ Limited
   - Only 2 child types (Cases, Opportunities)
   - Missing Contacts, Events as direct children
   - Task data appears invalid

## Next Steps for Test Harness

1. **Use Account 001QH000024lQv3YAE as primary test case**
2. **Focus testing on**:
   - 3-level DCM generation (Cases → CaseComments, Opportunities → OCRs)
   - Parent lookup merge fields (Contact.Name, Owner.Name)
   - Iteration block syntax ({{#Cases}}...{{/Cases}})
   - No hardcoded values in generated prompts

3. **Create supplemental test cases for**:
   - Contacts as direct child
   - Events as direct child
   - More diverse child object mix (6-8 types)

