# GPTfy Prompt Generation Rules - Deterministic Process

**Purpose:** This document defines the EXACT rules for generating GPTfy prompts. Follow these rules deterministically - no exceptions.

---

## CRITICAL: PROMPT QUALITY REQUIREMENTS

**A good GPTfy prompt is NOT just a pretty infographic.** It must provide:

### 1. Actionable Insights (REQUIRED)
- Tell the user what to DO, not just what IS
- Include recommendations, next steps, priorities
- Highlight risks, opportunities, and alerts
- Example: "Focus on opportunities closing this quarter" not just "Open Opportunities: 5"

### 2. Industry/Customer Context (REQUIRED)
- Tailor language to the specific industry
- Reference customer's business model and challenges
- Use domain-specific terminology
- Example: For retail - "store expansion", "inventory velocity", "seasonal trends"

### 3. Business Value (REQUIRED)
- Answer the "so what?" question
- Connect data to business outcomes
- Support decision-making, not just information display
- Example: "Pipeline coverage is 2.1x - below 3x target suggests prospecting needed"

### 4. Data Utilization (REQUIRED)
- Use ALL relevant available data from DCM
- Include child relationships (Contacts, Opportunities, Cases, etc.)
- Apply conditional logic for smart filtering
- Example: Show only open opportunities, prioritize high-value contacts

### 5. Analytical Depth (REQUIRED)
- Go beyond surface-level data display
- Include scoring, health indicators, status badges
- Provide synthesis and summaries
- Example: "Account Health: At Risk" based on case volume + opportunity momentum

**Run `validate-prompt-quality.sh` to check these dimensions.**

---

## CRITICAL UNDERSTANDING: How GPTfy Text Prompts Work

GPTfy Text prompts work in **TWO PHASES**:

### Phase 1: GPTfy Merge Field Substitution
GPTfy receives the prompt text and **substitutes all merge fields** with actual data from Salesforce BEFORE sending to the LLM.

```
BEFORE (what you write):
"Generate an account plan for {{{Name}}} in the {{{Industry}}} industry."

AFTER (what LLM receives):
"Generate an account plan for Carrefour Market France in the Retail industry."
```

### Phase 2: LLM Processing
The LLM receives the prompt with **actual data values already injected** and generates output.

**KEY INSIGHT:** The LLM never sees `{{{...}}}` syntax - it sees the actual values.

---

## SECTION FILE RULES

### 1-guardrails.txt
**Purpose:** Anti-hallucination rules and output format constraints
**Allowed:** Plain text instructions only
**NOT Allowed:** Any merge field syntax

```
✅ CORRECT:
Output must be a SINGLE LINE of HTML with NO line breaks.
Use ONLY inline styles - NO style blocks, NO CSS classes.

❌ WRONG:
Use {{{Name}}} for the account name.
Example: {{{Industry}}}
```

### 2-goal.txt
**Purpose:** What the prompt should generate
**Allowed:** Plain text describing the goal, references to field names in prose
**NOT Allowed:** Merge field syntax in examples

```
✅ CORRECT:
Generate an account plan dashboard showing:
- Account name and industry in the header
- Key stakeholders from the Contacts collection
- Open opportunities from the Opportunities collection

❌ WRONG:
Display {{{Name}}} at the top
Show {{{Industry}}} next to the name
```

### 3-data.txt
**Purpose:** Document what data is available (for LLM context)
**Allowed:** Field names as prose, descriptions of what data exists
**NOT Allowed:** ANY merge field syntax - not even as examples

```
✅ CORRECT:
AVAILABLE DATA:

Primary Object: Account
- Name: The account's display name
- Industry: Business sector classification
- AnnualRevenue: Yearly revenue in currency
- Owner.Name: Account owner's full name

Child Objects:
- Contacts: Related contacts with Name, Title, Email, Phone
- Opportunities: Deals with Name, StageName, Amount, CloseDate

❌ WRONG:
Use {{{Name}}} to get the account name
Access contacts via {{{Contacts.Name}}}
```

### 4-styling.txt (THE CRITICAL SECTION)
**Purpose:** This is WHERE the actual merge fields go
**REQUIRED:** Actual merge field syntax that GPTfy will substitute
**Structure:** Complete HTML output template with merge fields

```
✅ CORRECT:
Generate a single-line HTML output with this exact structure:

<div style="font-family:sans-serif;padding:20px;">
<div style="background:linear-gradient(135deg,#1a365d,#2c5282);color:white;padding:20px;border-radius:8px;">
<div style="font-size:24px;font-weight:bold;">{{{Name}}}</div>
<div style="font-size:14px;margin-top:8px;">Industry: {{{Industry}}} | Type: {{{Type}}} | Owner: {{{Owner.Name}}}</div>
</div>
<div style="margin-top:16px;background:white;padding:16px;border-radius:8px;">
<div style="font-weight:bold;margin-bottom:8px;">Key Stakeholders</div>
{{#Contacts}}<div style="padding:8px;border-bottom:1px solid #eee;"><strong>{{{Name}}}</strong> - {{{Title}}}</div>{{/Contacts}}
{{^Contacts}}<div style="color:#999;">No contacts available</div>{{/Contacts}}
</div>
</div>

❌ WRONG:
HEADER SECTION:
Use this pattern: <div>{{{Name}}}</div>
For contacts, iterate like this: {{#Contacts}}...{{/Contacts}}
```

---

## MERGE FIELD SYNTAX RULES

### Rule 1: Triple Braces for Values
```
{{{Name}}}        ✅ Outputs raw value
{{Name}}          ❌ HTML-escapes (breaks special chars)
```

### Rule 2: Primary Object - No Prefix
```
{{{Name}}}        ✅ Correct for Account.Name when Account is primary
{{{Account.Name}}} ❌ Wrong - don't prefix with primary object
```

### Rule 3: Lookup Fields - Dot Notation
```
{{{Owner.Name}}}       ✅ Owner lookup field
{{{CreatedBy.Email}}}  ✅ System relationship
```

### Rule 4: Child Collections - Use DCM Relationship Name
```
The relationship name MUST match exactly what is defined in the DCM (Data Context Mapping).
This can be plural OR singular depending on the DCM configuration.

{{#Contacts}}...{{/Contacts}}         ✅ If DCM relationshipName is "Contacts"
{{#Task}}...{{/Task}}                 ✅ If DCM relationshipName is "Task" (singular is valid!)
{{#Cases}}...{{/Cases}}               ✅ If DCM relationshipName is "Cases"

Check your DCM's relationshipName field - use that exact value.
```

### Rule 5: Conditional Rendering & Empty States
```
✅ PREFERRED ({{else}} syntax):
{{#Contacts}}
  <div>{{{Name}}}</div>
{{else}}
  <div>No contacts available</div>
{{/Contacts}}

✅ LEGACY ({{^}} inverted section):
{{#Contacts}}<div>{{{Name}}}</div>{{/Contacts}}
{{^Contacts}}<div>No contacts available</div>{{/Contacts}}

✅ NEGATION ({{#unless}}):
{{#Opportunities}}
  {{#unless IsClosed}}<tr><td>{{{Name}}}</td></tr>{{/unless}}
{{/Opportunities}}

❌ WRONG ({{^Field}} shorthand for negation - unreliable):
{{#Opportunities}}{{^IsClosed}}<tr>...</tr>{{/IsClosed}}{{/Opportunities}}
```

### Rule 6: Fields Inside Loops - MUST Include Collection Prefix
```
{{#Contacts}}
  {{{Contacts.Name}}}      ✅ Contact's name (GPTfy requires collection prefix)
  {{{Contacts.Title}}}     ✅ Contact's title
  {{{Name}}}               ❌ Wrong - GPTfy requires the collection prefix
{{/Contacts}}

{{#OpportunityContactRoles}}
  {{{OpportunityContactRoles.Role}}}           ✅ Direct field
  {{{OpportunityContactRoles.Contact.Name}}}   ✅ Parent lookup field
  {{{OpportunityContactRoles.Contact.Title}}}  ✅ Parent lookup field
  {{{Contact.Name}}}                           ❌ Wrong - missing collection prefix
{{/OpportunityContactRoles}}
```

### Rule 7: Grandchild Relationships - Chained Dot Notation
```
Grandchildren are child objects OF child objects. Use chained dot notation:
{{{ParentRelationship.ChildRelationship.FieldName}}}

Example: Account → Case → CaseComment
DCM Structure:
  - Cases (CHILD of Account, relationshipName: "Cases")
  - CaseComments (GRANDCHILD of Account via Cases, relationshipName: "CaseComments")

Merge Field Syntax:
{{{Cases.CaseComments.CommentBody}}}     ✅ Grandchild field
{{{Cases.CaseComments.CreatedDate}}}     ✅ Grandchild field
{{{CaseComments.CommentBody}}}           ❌ Wrong - missing parent chain

Full iteration example:
{{#Cases}}
  <div>Case: {{{Cases.Subject}}}</div>
  {{#Cases.CaseComments}}
    <div>Comment: {{{Cases.CaseComments.CommentBody}}}</div>
  {{/Cases.CaseComments}}
{{/Cases}}
```

---

## OUTPUT FORMAT RULES (HTML)

### Rule 8: Single Line Output
The ENTIRE HTML output must be ONE LINE - no newlines, no line breaks.

### Rule 9: Inline Styles Only
```
<div style="color:red;">Text</div>  ✅ Inline style
<div class="red">Text</div>         ❌ CSS class
<style>.red{color:red}</style>      ❌ Style block
```

### Rule 10: No Script Tags
```
<script>...</script>  ❌ Not allowed
onclick="..."         ❌ Not allowed
```

### Rule 11: Proper Structure
```
<div style="...">...</div>  ✅ Must start and end with div
<p>...</p>                  ❌ Don't start with other tags
```

---

## TABLE RENDERING RULES

### Rule 12: Table Header OUTSIDE Loop
```
✅ CORRECT:
<table style="width:100%;">
<tr><th>Name</th><th>Stage</th><th>Amount</th></tr>
{{#Opportunities}}{{#unless Opportunities.IsClosed}}<tr><td>{{{Opportunities.Name}}}</td><td>{{{Opportunities.StageName}}}</td><td>{{{Opportunities.Amount}}}</td></tr>{{/unless}}{{/Opportunities}}
</table>

❌ WRONG:
{{#Opportunities}}<table><tr><th>Name</th></tr><tr><td>{{{Name}}}</td></tr></table>{{/Opportunities}}
```

### Rule 13: Empty State Handling
```
✅ PREFERRED (inline {{else}}):
{{#Opportunities}}<tr><td>{{{Opportunities.Name}}}</td></tr>{{else}}<div>No opportunities</div>{{/Opportunities}}

✅ LEGACY (separate {{^}} block):
{{#Opportunities}}...{{/Opportunities}}
{{^Opportunities}}<div>No opportunities found</div>{{/Opportunities}}
```

---

## DCM CONFIGURATION RULES

### Rule 14: Relationship Types
The DCM (Data Context Mapping) supports three relationship types:

| Type | Description | Example |
|------|-------------|---------|
| **CHILD** | Direct child of the primary object | Account → Cases |
| **GRANDCHILD** | Child of a child object | Account → Cases → CaseComments |
| **PARENT** | Lookup relationship (future) | Case → Account (via AccountId) |

```json
// CHILD example
{
  "objectName": "Case",
  "relationshipName": "Cases",
  "relationshipField": "AccountId",
  "type": "CHILD"
}

// GRANDCHILD example
{
  "objectName": "CaseComment",
  "relationshipName": "CaseComments",
  "relationshipField": "ParentId",
  "parentDetailId": "a02J9000005JuRMIA0",  // Links to parent CHILD
  "type": "GRANDCHILD"
}
```

### Rule 15: WHERE Clause / Ordering
DCM details support a `whereClause` for filtering and ordering child records:

```json
{
  "objectName": "Case",
  "relationshipName": "Cases",
  "type": "CHILD",
  "whereClause": "ORDER BY CreatedDate DESC"
}
```

Common patterns:
- `ORDER BY CreatedDate DESC` - Most recent first
- `ORDER BY Amount DESC` - Highest value first
- `WHERE IsClosed = false ORDER BY CloseDate ASC` - Open items, soonest first

### Rule 16: File Attachments (Future)
Prompts can include file attachments via the `includeFiles` setting:

```json
{
  "promptName": "Document Analysis",
  "includeFiles": true,
  "objectName": "Account"
}
```

When `includeFiles: true`:
- Files attached to the record are included in the prompt context
- File content is available for LLM analysis
- Syntax for referencing files: TBD (not yet implemented in Prompt Factory)

---

## VALIDATION CHECKLIST

Before generating any prompt, verify:

1. [ ] **1-guardrails.txt**: Contains NO merge field syntax
2. [ ] **2-goal.txt**: Contains NO merge field syntax
3. [ ] **3-data.txt**: Contains NO merge field syntax (describes fields in prose only)
4. [ ] **4-styling.txt**: Contains ACTUAL merge fields that GPTfy will substitute
5. [ ] All merge fields use triple braces `{{{...}}}`
6. [ ] Primary object fields have no prefix
7. [ ] Child collection names match DCM `relationshipName` exactly (can be singular or plural)
8. [ ] Child fields include collection prefix: `{{{Contacts.Name}}}` not `{{{Name}}}`
9. [ ] Grandchild fields use chained notation: `{{{Cases.CaseComments.CommentBody}}}`
10. [ ] Tables have headers outside loops
11. [ ] Empty states are handled with `{{else}}` or `{{^Collection}}`
12. [ ] No newlines in 4-styling.txt (single line HTML template)

---

## PROMPT ASSEMBLY ORDER

The generate-prompt.sh script assembles sections in this order:

```
1. 1-guardrails.txt  (Rules/constraints)
2. 2-goal.txt        (What to generate)
3. 3-data.txt        (Available data description)
4. 4-styling.txt     (HTML template with merge fields)
```

**Note:** The 4-styling.txt section is the ONLY section that should contain merge field syntax.

---

## EXAMPLE: CORRECT ACCOUNT PLAN PROMPT

### 1-guardrails.txt
```
You are a sales assistant generating account plan dashboards.

CRITICAL RULES:
1. Output must be a SINGLE LINE of HTML - no newlines
2. Use ONLY inline styles - no style blocks or CSS classes
3. Never use script tags or event handlers
4. Start with <div style="..."> and end with </div>
5. If data is missing, show "No data available" - never show null or undefined
6. Use only the data provided - do not fabricate information
```

### 2-goal.txt
```
Generate a comprehensive Account Plan dashboard for VusionGroup sales teams.

The dashboard should include:
1. Header with account name, industry, type, and owner
2. Key metrics section showing revenue and employee count
3. Stakeholder section listing all contacts with their roles
4. Pipeline section showing open opportunities with amounts
5. Contract status showing active contracts and renewal dates
6. Support health showing open cases
```

### 3-data.txt
```
AVAILABLE DATA:

Primary Object: Account
Fields: Name, Industry, Type, AnnualRevenue, NumberOfEmployees, Website, Phone, Description, Owner.Name

Child Collections:
- Contacts: Name, Title, Email, Phone, Department
- Opportunities: Name, StageName, Amount, CloseDate, IsClosed, IsWon, Probability
- Cases: CaseNumber, Subject, Status, Priority, IsClosed, CreatedDate
- Contracts: ContractNumber, Status, StartDate, EndDate, Contract_Amount__c
- Tasks: Subject, Status, ActivityDate, Priority

Use the child collection names exactly as shown (Contacts, Opportunities, Cases, etc.)
```

### 4-styling.txt
```
<div style="font-family:system-ui,sans-serif;background:#f7fafc;padding:24px;"><div style="background:linear-gradient(135deg,#1a365d,#2c5282);color:white;padding:20px;border-radius:8px;margin-bottom:16px;"><div style="font-size:24px;font-weight:bold;">{{{Name}}}</div><div style="display:flex;gap:20px;margin-top:10px;font-size:14px;"><span>Industry: {{{Industry}}}</span><span>Type: {{{Type}}}</span><span>Owner: {{{Owner.Name}}}</span></div></div><div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:16px;"><div style="background:white;padding:16px;border-radius:8px;border-left:4px solid #38a169;"><div style="font-size:12px;color:#718096;">Annual Revenue</div><div style="font-size:20px;font-weight:bold;color:#1a365d;">{{{AnnualRevenue}}}</div></div><div style="background:white;padding:16px;border-radius:8px;border-left:4px solid #4299e1;"><div style="font-size:12px;color:#718096;">Employees</div><div style="font-size:20px;font-weight:bold;color:#1a365d;">{{{NumberOfEmployees}}}</div></div><div style="background:white;padding:16px;border-radius:8px;border-left:4px solid #ed8936;"><div style="font-size:12px;color:#718096;">Website</div><div style="font-size:14px;color:#1a365d;">{{{Website}}}</div></div></div><div style="background:white;border-radius:8px;padding:20px;margin-bottom:16px;"><div style="font-size:16px;font-weight:bold;color:#1a365d;margin-bottom:12px;border-bottom:2px solid #e2e8f0;padding-bottom:8px;">Key Stakeholders</div>{{#Contacts}}<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #f0f0f0;"><div><strong style="color:#1a365d;">{{{Contacts.Name}}}</strong><span style="color:#718096;margin-left:8px;">{{{Contacts.Title}}}</span></div><div style="color:#4a5568;font-size:13px;">{{{Contacts.Email}}}</div></div>{{else}}<div style="color:#a0aec0;font-style:italic;text-align:center;padding:20px;">No contacts available</div>{{/Contacts}}</div><div style="background:white;border-radius:8px;padding:20px;margin-bottom:16px;"><div style="font-size:16px;font-weight:bold;color:#1a365d;margin-bottom:12px;border-bottom:2px solid #e2e8f0;padding-bottom:8px;">Pipeline & Opportunities</div>{{#Opportunities}}<table style="width:100%;border-collapse:collapse;font-size:13px;"><tr style="background:#f7fafc;"><th style="text-align:left;padding:10px;border-bottom:1px solid #e2e8f0;">Name</th><th style="text-align:left;padding:10px;border-bottom:1px solid #e2e8f0;">Stage</th><th style="text-align:right;padding:10px;border-bottom:1px solid #e2e8f0;">Amount</th><th style="text-align:left;padding:10px;border-bottom:1px solid #e2e8f0;">Close Date</th></tr>{{#unless Opportunities.IsClosed}}<tr><td style="padding:10px;border-bottom:1px solid #f0f0f0;">{{{Opportunities.Name}}}</td><td style="padding:10px;border-bottom:1px solid #f0f0f0;">{{{Opportunities.StageName}}}</td><td style="padding:10px;border-bottom:1px solid #f0f0f0;text-align:right;">{{{Opportunities.Amount}}}</td><td style="padding:10px;border-bottom:1px solid #f0f0f0;">{{{Opportunities.CloseDate}}}</td></tr>{{/unless}}</table>{{else}}<div style="color:#a0aec0;font-style:italic;text-align:center;padding:20px;">No open opportunities</div>{{/Opportunities}}</div><div style="background:white;border-radius:8px;padding:20px;"><div style="font-size:16px;font-weight:bold;color:#1a365d;margin-bottom:12px;border-bottom:2px solid #e2e8f0;padding-bottom:8px;">Support Cases</div>{{#Cases}}{{#unless Cases.IsClosed}}<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #f0f0f0;"><div><strong>{{{Cases.CaseNumber}}}</strong> - {{{Cases.Subject}}}</div><div><span style="background:#ed8936;color:white;padding:2px 8px;border-radius:4px;font-size:11px;">{{{Cases.Priority}}}</span></div></div>{{/unless}}{{else}}<div style="color:#a0aec0;font-style:italic;text-align:center;padding:20px;">No open cases</div>{{/Cases}}</div></div>
```

---

## COMMON MISTAKES TO AVOID

1. **Putting merge field examples in documentation**
   - Wrong: "Use {{{Name}}} to display the account name"
   - Right: "The Name field will be displayed in the header"

2. **Using double braces instead of triple**
   - Wrong: `{{Name}}`
   - Right: `{{{Name}}}`

3. **Prefixing primary object fields**
   - Wrong: `{{{Account.Name}}}`
   - Right: `{{{Name}}}`

4. **Missing collection prefix for child fields**
   - Wrong: `{{#Contacts}}{{{Name}}}{{/Contacts}}`
   - Right: `{{#Contacts}}{{{Contacts.Name}}}{{/Contacts}}`
   - Wrong: `{{#OpportunityContactRoles}}{{{Contact.Title}}}{{/OpportunityContactRoles}}`
   - Right: `{{#OpportunityContactRoles}}{{{OpportunityContactRoles.Contact.Title}}}{{/OpportunityContactRoles}}`

5. **Missing parent chain for grandchild fields**
   - Wrong: `{{{CaseComments.CommentBody}}}`
   - Right: `{{{Cases.CaseComments.CommentBody}}}`

6. **Assuming relationship names are always plural**
   - Wrong: Assuming `{{#Tasks}}` when DCM has `relationshipName: "Task"`
   - Right: Use exactly what DCM specifies - check `relationshipName` field

7. **Table headers inside loops**
   - Wrong: `{{#Opportunities}}<table><th>Name</th><td>{{{Opportunities.Name}}}</td></table>{{/Opportunities}}`
   - Right: `<table><th>Name</th>{{#Opportunities}}<tr><td>{{{Opportunities.Name}}}</td></tr>{{/Opportunities}}</table>`

8. **Newlines in HTML template**
   - Wrong: Multi-line HTML with proper formatting
   - Right: Single line, no newlines
