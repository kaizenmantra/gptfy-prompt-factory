# SALESFORCE AI PROMPTS - PATTERN EXTRACTION ANALYSIS

**Purpose**: Extract reusable analytical patterns and UI components from production Salesforce AI prompts  
**Date**: January 22, 2026  
**Total Sources**: 10 prompts (9 pre-packaged + 1 sample MEDDIC)  

---

## INSTRUCTIONS FOR AI ANALYSIS

You are analyzing production Salesforce AI prompts to extract:

1. **ANALYTICAL PATTERNS** - Reusable instruction blocks for specific analysis types
2. **UI/HTML COMPONENTS** - Reusable HTML/CSS components for output formatting

For each **ANALYTICAL PATTERN**:
- Pattern ID (snake_case)
- Pattern Name (human-readable)
- Category (Risk, Stakeholder, Timeline, Sentiment, Financial, etc.)
- Instruction Block (exact text)
- Trigger Conditions (when to use)
- Evidence Requirements (what data fields needed)
- Output Format (table, bullets, narrative)
- Used In (which prompts)
- Frequency (how many prompts)

For each **UI/HTML COMPONENT**:
- Component ID (snake_case)
- Component Name (human-readable)
- Category (Card, Table, Alert, Chart, etc.)
- HTML/CSS Code (exact markup)
- Merge Fields (what data gets injected)
- Visual Style (colors, layout)
- Used In (which prompts)
- Frequency (how many prompts)

**Prioritize patterns that**:
- Appear in multiple prompts
- Have clear, specific purpose
- Show evidence of effectiveness

---

## SOURCE PROMPTS

[Note: Full prompts consolidated below - analyze ALL content]

---

# PRE-PACKAGED SALESFORCE PROMPTS - CONSOLIDATED

**Total Prompts**: 9
**Source**: Salesforce Org (agentictso)
**Purpose**: Pattern extraction for Phase 0B testing

---

## PROMPT 1: Account 360 View - GPTfy

**ID**: a0DgD000001ldoYUAQ

**Prompt Body**:
```
Objective: Generate clean HTML tables from Salesforce JSON data. Output should be in plain HTML format without Markdown or code block syntax.

Instructions:

Use data from the provided JSON, linked by 18-digit IDs.
Task summary must always include names and titles of people involved.
Ensure all records are shown in the tables.
Include border="1" in all HTML table tags.
Write summaries in third person and condense key points.
Dates should be formatted as "01-Jan-23".
Add captions to each HTML table.
Prioritize quality over speed in responses.
Convert all internal CSS to inline CSS for the response.
Use the following inline CSS for table header 'th' style="background-color: #e1ebf7; color: #16325c; padding: 0.5rem; text-align: left;"
Use the following inline CSS for caption = "font-size: 1.0rem; font-weight: bold; padding: 0.5rem; color: #5C5C5C;text-align: left;"

To-Do:

Table 1: 'Opportunities'
Columns: ''Opportunity' (Display a hyperlink that opens in a new tab. Show {{{Opportunities.Name}}} and link '/'+{{{Opportunities.Id}}}),'.''Summary' (Summarize this opportunity in 30 words or less)',''Objection' (Objection raised by customer that is preventing us from closing this opportunity. Keep it under 5 words.)',''Next Best Action' (The next best action we should take on this opportunity that will help us close-won it.Keep it under 30 words only.)','Close date ({{{Opportunities.CloseDate}}})','Amount ({{{Opportunities.Amount}}})'.

Table 2: 'Cases'
Columns: ' 'Case' (Display a hyperlink that opens in a new tab. Show {{{Cases.Subject}}} and link '/'+{{{Cases.Id}}})', ''Summary' (Summarize this case in 30 words or less)','Customer Intent','Sentiment' (Constrain the value of the sentiment to positive, Neutral, Negative), 'Days Open' ((Calculated as the difference between Today() and {{{Cases.CreatedDate}}}).

Expected Output:
HTML tables filled with data from the JSON payload, formatted as specified above, without any Markdown or code block (````) or (```) characters.
```

---

## PROMPT 2: Account 360 View - GPTfy - Reimagined

**ID**: a0DgD000001ldoZUAQ

**Prompt Body**:
```
Objective:
I am a Sales Representative reviewing this account for the first time. Help me understand what's happening with this account by analyzing Opportunities and Cases. Return all insights in structured, clean HTML only.

IMPORTANT:
Return only clean HTML without any backticks, "html" tags, markdown formatting, escaped characters, or newlines. The HTML should be ready to use directly as a single continuous string. DO NOT add \n, line breaks, or any form of newlines in the output. Ensure ALL records are shown in the tables.

Instructions:
- Output only HTML(No markdown, `<html>` tags, or unnecessary spaces).
- Use inline CSS exclusively.
- Ensure precise calculations for all metrics.
- Apply consistent color-coding for sentiment, priority, and status indicators.
- Maintain responsiveness for various screen sizes.
- Use only inline CSS. Do not use class names or external styles.
- CRITICAL: Include EVERY single record from the provided data in tables. Do not filter out any records for any reason.

Key Insights Panel (Displayed before the tables)
- Total Open Opportunities (CRITICAL: Count ONLY opportunities where {{{Opportunities.IsClosed}}} is EXPLICITLY "false")
- Total Opportunity Value (CRITICAL: Sum of {{{Opportunities.Amount}}} from ALL opportunities regardless of stage or status. If Amount is missing, count as $0)
- Customer Frustration Level (CRITICAL: Strictly add only one value always. Low, Medium, High) – Analyze and specify the customer frustration level for this account based on interaction's tone and escalation frequency. If a case description mentions "urgently" or similar urgent terms, set frustration level to "High". 
- Top Next Best Action (Most recurring or urgent action, max 30 words)
- Total Open Cases (Count of all cases where {{{cases.IsClosed}}} equals "false")
- Most Urgent Case (CRITICAL: ALWAYS display a case in this section. Check first for any case with "urgent" in the Description, regardless of status. If none found, show the oldest case by CreatedDate. If all cases are closed, show the most recently closed case as "Recently Resolved: [Case Subject]")
- Case Sentiment Distribution (CRITICAL: Count of Positive, Neutral, Negative based on case table. Each case MUST be classified as either Positive, Neutral, or Negative. The count here MUST match exactly what's shown in the Cases table)
- Top Complaint Theme (Repeated issue across case descriptions/comments)
- Most Common Objection (Short phrase from task descriptions which describes if there is any objections, max 6 words)

Metrics Displayed:
- Total Open Opportunities
- Total Opportunity Value
- Customer Frustration Level
- Top Next Best Action
- Total Open Cases
- Most Urgent Case
- Case Sentiment Distribution – (Positive, Neutral, Negative)(Provide the count)
- Top Complaint Theme
- Most Common Objection (Provide 3 most common objectives as per the data)

Provide the executive summary and table in new stat card and card should not occupy extra spaces.

Executive Summary
Write 2–3 concise sentences
Summarize high-value opportunities, objections, customer risks, and next steps
Use plain English. No jargon. No paragraphs.
There should be a space before the executive summary card.

To-Do: 

Table 1: 'Opportunities' Show ALL opportunities in the data without exception.
Columns: 'Opportunity' (Display a hyperlink that opens in a new tab. Show {{{Opportunities.Name}}} and link '/'+{{{Opportunities.Id}}}),'Summary' (Summarize this opportunity in 30 words or less),'Objection' (Objection raised by customer that is preventing us from closing this opportunity. Keep it under 5 words.),'Next Best Action' (The next best action we should take on this opportunity that will help us close-won it. Keep it under 30 words only.),'Close date ({{{Opportunities.CloseDate}}})','Amount ({{{Opportunities.Amount}}})'.

Table 2: 'Cases' Show ALL cases in the data without exception.
Columns: 'Case' (Display a hyperlink that opens in a new tab. Show {{{Cases.Subject}}} and link '/'+{{{Cases.Id}}})', 'Summary' (Summarize this case in 30 words or less)','Customer Intent','Sentiment' (Constrain the value of the sentiment to positive, Neutral, Negative), 'Days Open' ((Calculated as the difference between Today() and {{{Cases.CreatedDate}}}).

Important Requirements:
-Include ALL records from the provided data in each table
-Use EXACT numbers from the data (counts, sums, etc.)
-Use ONLY information that is provided in the data, do not add imagined details
-Ensure Customer Insights are displayed in a 2-column grid layout
-Return CLEAN HTML only - no backticks or markdown formatting
-All tables must have consistent width, padding, and border styling
-Use hover effects for table rows to improve readability
-Ensure mobile responsiveness through appropriate flex-wrap settings

Instructions:
- Use data from the provided JSON, linked by 18-digit IDs.
- Address all parts of a multi-part question.
- Task summary must always include names and titles of people involved.
- Ensure ALL records are shown in the tables - EVERY SINGLE opportunity and case MUST appear in the tables.
- Include border="1" in all HTML table tags.
- Write summaries in third person and condense key points.
- Dates should be formatted as "01-Jan-23".
- Don't add captions to each HTML table.
- Prioritize quality over speed in responses.
- Convert all internal CSS to inline CSS for the response.
- Use the following inline CSS for table header 'th' style="background-color: #e1ebf7; color: #16325c; 
padding: 0.5rem; text-align: left;"
- Use the following inline CSS for caption = "font-size: 1.0rem; font-weight: bold; padding: 0.5rem; color: #5C5C5C;text-align: left;"
- Don't add any '\n' characters in your HTML. Replace each '\n' with the HTML line break tag <br>. Ensure the rest of the text is properly wrapped in HTML tags, like <p> for paragraphs, to maintain the formatting.

CRITICAL VERIFICATION CHECKS:
1. Verify that ALL opportunities from the data appear in the opportunities table - count them to make sure.
2. Verify that ALL cases from the data appear in the cases table - count them to make sure.
3. Calculate the TOTAL OPPORTUNITY VALUE as the sum of Amount from ALL opportunities regardless of status.
4. Verify that the Customer Frustration Level is set to "High" if any case description contains the word "urgent".
5. Verify that the Most Urgent Case is properly identified.
6. Verify the sentiment distribution counts match what's in your Cases table.

Sample Output:

<!-- Title -->
<div style="font-size: 1.75rem; font-weight: bold; color: #16325c; margin-bottom: 2rem;">
Account 360 - Reimagined
</div>

Container:
<div style="font-family:system-ui,sans-serif;width:100%;max-width:1200px;margin:0 auto;padding:20px;border-radius:8px;background:#B0C4DF;">

Stat Card Styling:
<!-- Stat Cards Container -->
<div style="display: flex; flex-wrap: wrap; gap: 1rem; justify-content: space-between;">

<!-- Total Open Opportunities -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Total Open Opportunities</div>
<div style="font-size: 1rem; font-weight: 500; color: #28a745;">[Total Open Opportunities]</div>
</div>

<!-- Total Opportunity Value -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Total Opportunity Value</div>
<div style="font-size: 1rem; font-weight: 500; color: #FF9800;">$[Total Opportunity Value]</div>
</div>

<!-- Customer Frustration Level -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Customer Frustration Level</div>
<div style="font-size: 1rem; font-weight: 500;">
<span style="color: #28a745;">Low</span> |
<span style="color: #ff9800;">Med</span> |
<span style="color: #dc3545;">High</span>
</div>
</div>


<!-- Top Next Best Action -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Top Next Best Action</div>
<div style="font-size: 1rem; font-weight: 500; color: #28a745;">[Top Next Best Action]</div>
</div>

<!-- Total Open Cases -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Total Open Cases</div>
<div style="font-size: 1rem; font-weight: 500; color: #28a745;">[Total Open Cases]</div>
</div>

<!-- Most Urgent Case -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Most Urgent Case</div>
<div style="font-size: 1rem; font-weight: 500;">
<a href="[Case URL]" style="color: #dc3545; text-decoration: underline;">[Most Urgent Case Subject]</a>
</div>
</div>

<!-- Sentiment Distribution -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Sentiment Distribution</div>
<div style="font-size: 1rem; font-weight: 500;">
<span style="color: #28a745;">Pos: [Positive Count]</span> |
<span style="color: #FF9800;">Neu: [Neutral Count]</span> |
<span style="color: #dc3545;">Neg: [Negative Count]</span>
</div>
</div>

<!-- Top Complaint Theme -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Top Complaint Theme</div>
<div style="font-size: 1rem; font-weight: 500; color: #dc3545;">"[Top Complaint Theme]"</div>
</div>

<!-- Most Common Objection -->
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
<div style="color: #000000; font-size: 0.875rem;font-weight: bold">Most Common Objection</div>
<div style="font-size: 1rem; font-weight: 500; color: #dc3545;">"[Most Common Objection]"</div>
</div>

<!-- Executive Summary Card -->
<div style="background: #ffffff; padding: 1rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 1rem;">
<div style="color: #16325c; font-size: 1.25rem; font-weight: bold; margin-bottom: 0.75rem;">Executive Summary</div>
<div style="color: #333; line-height: 1.6; text-align: center; font-size: 1rem; font-weight: 500;">[This section will summarize high-value opportunities, objections, customer risks, and next steps.]</div>
</div>

<!-- Opportunities Table Card -->
<div style="background: #ffffff; padding: 1rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 1rem;">
<div style="color: #16325c; font-size: 1.25rem; font-weight: bold; margin-bottom: 0.75rem;">Opportunities</div>
<table style="width: 100%; border-collapse: collapse; background: white;">
<tr style="background-color: #f8f9fa;">
<th style="padding: 0.75rem; text-align: left;">Opportunity</th>
<th style="padding: 0.75rem; text-align: left;">Summary</th>
<th style="padding: 0.75rem; text-align: left;">Objection</th>
<th style="padding: 0.75rem; text-align: left;">Next Best Action</th>
<th style="padding: 0.75rem; text-align: left;">Close Date</th>
<th style="padding: 0.75rem; text-align: left;">Amount</th>
</tr>
<tr>
<td><a href="/{{{Opportunities.Id}}}" target="_blank">{{{Opportunities.Name}}}</a></td>
<td>Summarize about the opportunity (20–30 words)</td>
<td>Objection (under 10 words)</td>
<td>Recommended action (20–30 words)</td>
<td>$1,500,000.00</td>
<td>MM/DD/YYYY</td>
</tr>
<!-- Additional rows dynamically inserted -->
</table>
</div>

<!-- Cases Table Card -->
<div style="background: #ffffff; padding: 1rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 1rem;">
<div style="color: #16325c; font-size: 1.25rem; font-weight: bold; margin-bottom: 0.75rem;">Cases</div>
<table style="width: 100%; border-collapse: collapse; background: white;">
<tr style="background-color: #f8f9fa;">
<th style="padding: 0.75rem; text-align: left;">Case</th>
<th style="padding: 0.75rem; text-align: left;">Summary</th>
<th style="padding: 0.75rem; text-align: left;">Sentiment</th>
<th style="padding: 0.75rem; text-align: left;">Intent</th>
<th style="padding: 0.75rem; text-align: left;">Days Open</th>
</tr>
<tr>
<td><a href="/{{{Cases.Id}}}" target="_blank">{{{Cases.Subject}}}</a></td>
<td>20–25 word case description</td>
<td style="color: #d32f2f; font-weight: bold;">Negative</td>
<td>One sentence describing customer objective</td>
<td>{{{Cases.OpenDays__c}}}</td>
</tr>
<!-- Additional rows dynamically inserted -->
</table>
</div></div>
```

---

## PROMPT 3: Case Follow-up / Feedback Email - GPTfy

**ID**: a0DgD000001ldoaUAA

**Prompt Body**:
```
Draft a 150-word email to {{{Contact.FirstName}}} from {{{CreatedBy.Name}}} as any one of the following based on the condition,
Follow-up email when case status {{{IsClosed}}} = 'False' or
Feedback email when case status {{{IsClosed}}} = 'True'.

Instruction:
Consider {{{CreatedBy.Name}}} as sender of the mail, who is the owner of this case.
Consider {{{Contact.FirstName}}} as receiver of the mail.
```

---

## PROMPT 4: Case Intent Analysis - GPTfy

**ID**: a0DgD000001ldobUAA

**Prompt Body**:
```
Return response in following parsable JSON format
{
  "Intent" : "Generate a Intent Analysis for this Case . Limit it to Under 90 Words only. Analyze all the activities, emails, tasks. Do not use imagination",
  "Next Best Action" : "Generate a Next Best Action for this Case . If isClosed=true, then return back \"The case is closed.\""
}
```

---

## PROMPT 5: Case Root Cause Analysis - GPTfy

**ID**: a0DgD000001ldocUAA

**Prompt Body**:
```
Generate the following both 
1.Root Cause Analysis for this Case . Limit it to Under 90 Words only.
2.Corrective Action for this Case . Limit it to Under 90 Words only. Do NOT imagine anything. Corrective Action must to be based on the information provided
```

---

## PROMPT 6: Escalated Case - GPTfy

**ID**: a0DgD000001ldodUAA

**Prompt Body**:
```
Generate a Root Cause Analysis for this Case based on the condition, when case status {{{isEscalated}}} = 'true'.  Else if {{{isEscalated}}}= 'false', then return back with a message - 'This is not a Escalated Case.'
```

---

## PROMPT 7: Inbound Lead Follow-up Email - GPTfy

**ID**: a0DgD000001ldoeUAA

**Prompt Body**:
```
If the lead is inbound, generate a Follow-up email providing a response to the raised enquiry, for this Lead {{{Name}}} from {{{CreatedBy.Name}}}, in 90 words or less. Keep the tone Professional .
```

---

## PROMPT 8: Outbound Lead Follow-up Email - GPTfy

**ID**: a0DgD000001ldofUAA

**Prompt Body**:
```
If the lead is outbound, generate a follow-up email, for this Lead {{{Name}}} from {{{CreatedBy.Name}}}, in 90 words or less. Keep the tone Professional .
```

---

## PROMPT 9: Sentiment Analysis - GPTfy

**ID**: a0DgD000001ldogUAA

**Prompt Body**:
```
Return response in following parsable JSON format
{
  "Sentiment" : "Generate a Sentiment for this Account . with values constrained to Positive, Negative, Neutral only Don't use any imagination. Please reason it."
}
```

---


## PROMPT 10: MEDDIC Compliance Analyzer (Sample from docs/pattern-meddic)

**Source**: docs/pattern-meddic/ENHANCED_PROMPT.md  
**Type**: Opportunity Analysis - MEDDIC Framework  
**Purpose**: Comprehensive MEDDIC compliance analysis and deal health assessment

**Prompt Body**:
```
I am a MEDDIC compliance analyst and sales strategist specializing in comprehensive retail technology sales opportunity analysis.

MEDDIC COMPLIANCE ANALYSIS:

### M - METRICS (Weight: 15%)
Evaluate business case and quantified value with scoring criteria (0-100).
Data Sources: Business case documentation, ROI calculations, DealQuestion scorecards.

###E - ECONOMIC BUYER (Weight: 20%)
Assess Economic Buyer identification and engagement.
Data Sources: DealStakeholder roles, HasPower, SupportStatus, OpportunityContactRole.

### D - DECISION CRITERIA (Weight: 15%)
Evaluate technical and business criteria documentation.
Data Sources: DealQuestion categories, Technical Buyer contacts, validation notes.

### D - DECISION PROCESS (Weight: 15%)
Assess understanding of buying decision process.
Data Sources: Mutual action plan milestones, Event status, IsMutual commitments.

### I - IDENTIFY PAIN (Weight: 15%)
Evaluate documented business pains and validation.
Data Sources: Description field, DealQuestion pain categories, Stakeholder goals.

### C - CHAMPION (Weight: 20%)
Assess Champion identification, validation, and engagement.
Champion Validation Checklist:
1. Has Power
2. Support Status (Promoter/Supporter)
3. Relationship (Regular Cadence/In Depth)
4. Personal Win documented

OVERALL MEDDIC SCORE CALCULATION:
Weighted average of all 6 elements with stage-appropriate thresholds.

STAGE-MEDDIC ALIGNMENT:
| Stage | Min MEDDIC Score | Key Requirements |
|-------|------------------|------------------|
| New/Interest | 35 | Pain confirmed, Champion identified |
| Analysis in progress | 50 | Pain documented, Champion validated, EB identified |
| Proposal sent | 65 | EB engaged, Criteria confirmed, Process mapped |
| Budget approved | 75 | Metrics validated, All criteria addressed |

RISK IDENTIFICATION:
- Critical Risks (RED): No Champion + advanced stage, No EB engagement, single-threaded
- Warning Risks (YELLOW): Champion with low influence, EB neutral, no mutual milestones
- Positive Indicators (GREEN): Validated champion, EB engaged, mutual commitments

PRIORITY ACTIONS:
Format for each action:
- Action: [Specific task]
- MEDDIC Element: [Which element addressed]
- Priority: CRITICAL/HIGH/MEDIUM
- Owner: AE/SE/Manager
- Target: [7/14/30 days]
- Success Criteria: [Validation method]

OUTPUT FORMAT:
MEDDIC Summary Table with scores, status, evidence, and gaps for each element.
Executive Summary with stage alignment and health assessment.
Strategic Opportunity Assessment (13-point framework).
```

---

