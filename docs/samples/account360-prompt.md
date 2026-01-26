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