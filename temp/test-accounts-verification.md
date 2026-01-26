# Test Accounts Verification Report

Date: 2026-01-24
Org: agentictso

## Summary

Three test accounts were created with comprehensive Account 360 data:

---

### TESTDATA_Pinnacle Wealth Partners

- **ID**: 001QH000024mdDnYAI
- **Industry**: Financial Services
- **Type**: Customer
- **Annual Revenue**: $15000000
- **Employees**: 75

#### Child Objects

| Object | Count | Type |
|--------|-------|------|
| Contacts | 5 | CHILD |
| Opportunities | 3 | CHILD |
| Cases | 3 | CHILD |
| Tasks | 6 | CHILD |
| Events | 9 | CHILD |
| OpportunityContactRoles | 5 | GRANDCHILD |
| CaseComments | 6 | GRANDCHILD |

**Total Records**: 38 (including Account)

---

### TESTDATA_Vanguard Insurance Group

- **ID**: 001QH000024mdDoYAI
- **Industry**: Insurance
- **Type**: Customer
- **Annual Revenue**: $50000000
- **Employees**: 150

#### Child Objects

| Object | Count | Type |
|--------|-------|------|
| Contacts | 5 | CHILD |
| Opportunities | 3 | CHILD |
| Cases | 3 | CHILD |
| Tasks | 6 | CHILD |
| Events | 9 | CHILD |
| OpportunityContactRoles | 5 | GRANDCHILD |
| CaseComments | 6 | GRANDCHILD |

**Total Records**: 38 (including Account)

---

### TESTDATA_MediCare Solutions Inc.

- **ID**: 001QH000024mdDpYAI
- **Industry**: Healthcare
- **Type**: Customer
- **Annual Revenue**: $150000000
- **Employees**: 250

#### Child Objects

| Object | Count | Type |
|--------|-------|------|
| Contacts | 5 | CHILD |
| Opportunities | 3 | CHILD |
| Cases | 3 | CHILD |
| Tasks | 6 | CHILD |
| Events | 9 | CHILD |
| OpportunityContactRoles | 6 | GRANDCHILD |
| CaseComments | 6 | GRANDCHILD |

**Total Records**: 39 (including Account)

---

## Test Coverage Analysis

### What These Accounts Test

✅ **2-Level Traversals** (Account → Child):
- Account → Contacts
- Account → Opportunities
- Account → Cases
- Account → Tasks
- Account → Events

✅ **3-Level Traversals** (Account → Child → Grandchild):
- Account → Opportunities → OpportunityContactRoles
- Account → Cases → CaseComments

✅ **Parent Lookup Traversals** (Child → Parent):
- OpportunityContactRole → Contact (Contact.Name, Contact.Title, Contact.Email)
- Opportunity → Owner (Owner.Name)
- Case → Contact (Contact.Name)

✅ **Iteration Blocks**:
- Multiple records per child object (5 Contacts, 3 Opportunities, 3 Cases)
- Variable grandchild counts (different OCR and Comment counts per parent)

## Recommendation

**Primary Test Account**: 001QH000024mdDnYAI (Pinnacle Wealth Partners)
- Use as golden test case for Phase 5A.5 integration testing
- Financial Services industry provides realistic business context
- Comprehensive child/grandchild data tests all pipeline features

**Secondary Test Accounts**: 001QH000024mdDoYAI, 001QH000024mdDpYAI
- Use for multi-industry regression testing
- Validate pipeline works across different business contexts
