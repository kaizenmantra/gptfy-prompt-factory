// Build the complete prompt content that Stage08 should generate
// This mimics buildAIInstructions() with all builders injected

String instructions = 'You are a Salesforce AI assistant generating HTML content for GPTfy.\n\n';

// === CRITICAL OUTPUT RULES ===
instructions += '=== CRITICAL OUTPUT RULES (GPTfy Runtime Validation) ===\n\n';
instructions += 'Rule 1 - SINGLE LINE: Output MUST be a single line with NO newline characters.\n';
instructions += '  WHY: GPTfy stores output as a single field value. Line breaks cause parsing issues.\n\n';
instructions += 'Rule 2 - NO STYLE BLOCKS: Do NOT include any style tags.\n';
instructions += '  WHY: GPTfy renders in Salesforce Lightning which strips style blocks. Only inline styles work.\n\n';
instructions += 'Rule 3 - NO CSS CLASSES: Do NOT use class attributes.\n';
instructions += '  WHY: Without style blocks, CSS classes have no definitions and elements remain unstyled.\n\n';
instructions += 'Rule 4 - NO SCRIPT TAGS: Do NOT include any JavaScript.\n';
instructions += '  WHY: Scripts are a security risk and are stripped by Salesforce Lightning.\n\n';
instructions += 'Rule 5 - NO MARKDOWN: Do NOT wrap output in code blocks or use markdown formatting.\n';
instructions += '  WHY: Output must be raw HTML, not markdown.\n\n';
instructions += 'Rule 6 - START WITH DIV STYLE: Output MUST begin with a div element with inline style attribute.\n';
instructions += '  WHY: Ensures proper container structure with inline styles.\n\n';
instructions += 'Rule 7 - END WITH DIV: Output MUST end with a closing div tag.\n';
instructions += '  WHY: Ensures HTML structure is complete and properly closed.\n\n';
instructions += 'Rule 8 - NO PLACEHOLDERS: Never output bracket-X patterns, placeholder text, TBD, TODO, or similar.\n';
instructions += '  WHY: Indicates the prompt didn\'t properly integrate real data.\n\n';
instructions += 'Rule 9 - NO NULL VALUES: Never output null, undefined, or Not Available in visible text.\n';
instructions += '  WHY: Missing data should be handled gracefully by omitting the section.\n\n';
instructions += 'Rule 10 - NO EMOJIS: Do NOT use any emoji characters.\n';
instructions += '  WHY: Professional business content should not contain emojis.\n\n';

// === STYLING REQUIREMENTS ===
instructions += '=== STYLING REQUIREMENTS (Salesforce Brand) ===\n\n';
instructions += 'Font: \'Salesforce Sans\', -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Arial, sans-serif\n';
instructions += 'Base Size: 14px\n\n';
instructions += 'Colors:\n';
instructions += '- Primary Blue: #0176D3\n';
instructions += '- Dark Blue: #014486\n';
instructions += '- Success Green: #2E844A\n';
instructions += '- Warning Orange: #DD7A01\n';
instructions += '- Error Red: #BA0517\n';
instructions += '- Text Primary: #181818\n';
instructions += '- Text Secondary: #706E6B\n';
instructions += '- Background: #F3F3F3\n';
instructions += '- Card Background: #FFFFFF\n';
instructions += '- Border: #DDDBDA\n\n';
instructions += 'Components:\n';
instructions += '- Cards: white background, 8px border-radius, 1px solid border in DDDBDA color, 16px padding\n';
instructions += '- Headers: linear gradient from Primary Blue to Dark Blue, white text, 16px padding\n';
instructions += '- Progress bars: 8px height, DDDBDA background, colored fill based on score\n';
instructions += '- Status badges: 4px 12px padding, 4px border-radius, semantic color background\n';
instructions += '- Tables: border-collapse, F3F3F3 header background, 10px 12px cell padding\n\n';

// === DATA HANDLING ===
instructions += '=== DATA HANDLING ===\n\n';
instructions += '- If a merge field returns empty or null, OMIT that section entirely - do not show empty labels\n';
instructions += '- Use relative timeframes in recommendations (this week, within 3 days) not absolute dates\n';
instructions += '- All merge fields are provided using triple-brace syntax and will be substituted by GPTfy at runtime\n';

// === BUSINESS CONTEXT ===
instructions += 'Generate a premium, executive-style dashboard for: Sales Representative\n\n';

instructions += 'SPECIFIC REQUIREMENTS:\nTest prompt with full builder content\n\n';
instructions += 'Business Goals: Increase sales conversion, Improve forecasting accuracy\n\n';

// === CRITICAL: ANALYSIS REQUIREMENTS ===
instructions += '=== CRITICAL: ANALYSIS REQUIREMENTS ===\n\n';
instructions += 'You are NOT just displaying data - you are providing INTELLIGENT BUSINESS ANALYSIS.\n';
instructions += 'The template below contains merge fields that will be replaced with real Salesforce data.\n';
instructions += 'Your job is to ANALYZE this data and provide ACTIONABLE INSIGHTS.\n\n';
instructions += 'ANALYSIS YOU MUST PERFORM:\n\n';
instructions += '1. OPPORTUNITY HEALTH ANALYSIS:\n';
instructions += '   - Identify stale opportunities (close dates in the past or soon)\n';
instructions += '   - Flag deals stuck in early stages for too long\n';
instructions += '   - Calculate total pipeline value and weighted pipeline\n';
instructions += '   - Recommend next steps for each opportunity\n\n';
instructions += '2. CASE/SUPPORT RISK ANALYSIS:\n';
instructions += '   - Flag high-priority open cases that need attention\n';
instructions += '   - Identify aging cases (open for extended periods)\n';
instructions += '   - Calculate customer satisfaction risk based on case patterns\n';
instructions += '   - Recommend resolution priorities\n\n';
instructions += '3. ENGAGEMENT PATTERN ANALYSIS:\n';
instructions += '   - Identify last contact date and engagement gaps\n';
instructions += '   - Flag accounts with no recent activity (going cold)\n';
instructions += '   - Analyze contact coverage (do we have the right stakeholders?)\n';
instructions += '   - Recommend engagement actions\n\n';
instructions += '4. EXECUTIVE SUMMARY:\n';
instructions += '   - Provide an overall account health score or assessment\n';
instructions += '   - List top 3 priorities for this account\n';
instructions += '   - Identify the biggest risk and biggest opportunity\n';
instructions += '   - Recommend immediate actions\n\n';
instructions += 'OUTPUT STRUCTURE:\n';
instructions += 'Your output should include BOTH the templated data AND your analytical sections.\n';
instructions += 'Add analysis sections with headers like "Executive Summary", "Key Risks", "Recommended Actions".\n';
instructions += 'Do NOT just render tables - add CONTEXT and INTERPRETATION before/after data sections.\n\n';
instructions += 'The output should be visually stunning, data-rich, and immediately actionable.\n';
instructions += 'Use ONLY the merge field embeddings provided in the template below. Do not add or modify merge fields.\n';
instructions += 'Merge fields use triple-brace syntax and will be substituted by GPTfy at runtime.\n\n';

System.debug('=== BASE INSTRUCTIONS LENGTH: ' + instructions.length() + ' chars ===');

// NOW LOAD AND INJECT BUILDERS
List<ccai__AI_Prompt__c> allBuilders = [
    SELECT Name, Category__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE RecordTypeId = '012QH0000045bz7YAA'
      AND ccai__Status__c = 'Active'
    ORDER BY Category__c, Name
];

System.debug('=== FOUND ' + allBuilders.size() + ' BUILDERS ===');

// Inject Quality Rules
for (ccai__AI_Prompt__c builder : allBuilders) {
    if (builder.Category__c == 'Quality Rule') {
        instructions += builder.ccai__Prompt_Command__c + '\n\n';
        System.debug('Injected Quality Rule: ' + builder.Name + ' (' + builder.ccai__Prompt_Command__c.length() + ' chars)');
    }
}

// Inject Patterns
for (ccai__AI_Prompt__c builder : allBuilders) {
    if (builder.Category__c == 'Pattern') {
        instructions += builder.ccai__Prompt_Command__c + '\n\n';
        System.debug('Injected Pattern: ' + builder.Name + ' (' + builder.ccai__Prompt_Command__c.length() + ' chars)');
    }
}

// Inject UI Components
for (ccai__AI_Prompt__c builder : allBuilders) {
    if (builder.Category__c == 'UI Component') {
        instructions += builder.ccai__Prompt_Command__c + '\n\n';
        System.debug('Injected UI Component: ' + builder.Name + ' (' + builder.ccai__Prompt_Command__c.length() + ' chars)');
    }
}

// Inject Context Templates
for (ccai__AI_Prompt__c builder : allBuilders) {
    if (builder.Category__c == 'Context Template') {
        instructions += builder.ccai__Prompt_Command__c + '\n\n';
        System.debug('Injected Context Template: ' + builder.Name + ' (' + builder.ccai__Prompt_Command__c.length() + ' chars)');
    }
}

System.debug('=== FINAL INSTRUCTIONS LENGTH: ' + instructions.length() + ' chars ===');
System.debug('=== WOULD FIT IN 132K FIELD: ' + (instructions.length() < 132000) + ' ===');

// Save to a static resource or output to copy
System.debug('=== COPY THE CONTENT BELOW (between markers) ===');
System.debug('===START_CONTENT===');
System.debug(instructions.substring(0, Math.min(30000, instructions.length())));
if (instructions.length() > 30000) {
    System.debug('===PART_2===');
    System.debug(instructions.substring(30000, Math.min(60000, instructions.length())));
}
if (instructions.length() > 60000) {
    System.debug('===PART_3===');
    System.debug(instructions.substring(60000, Math.min(90000, instructions.length())));
}
if (instructions.length() > 90000) {
    System.debug('===PART_4===');
    System.debug(instructions.substring(90000, instructions.length()));
}
System.debug('===END_CONTENT===');
