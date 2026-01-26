/**
 * Create Meta-Prompt Builder Record for V2.5 Two-Layer Architecture
 *
 * This builder record contains the meta-prompt that Stage 8 will use to
 * generate specific deterministic GPTfy prompts.
 *
 * Usage:
 *   sf apex run -f scripts/apex/create_meta_prompt_builder.apex -o agentictso
 */

// Query for Builder RecordType
RecordType builderRT = [
    SELECT Id FROM RecordType
    WHERE SObjectType = 'ccai__AI_Prompt__c'
    AND DeveloperName = 'Builder'
    LIMIT 1
];

// Build the meta-prompt content
String metaPromptContent = buildMetaPromptContent();

// Create the Builder record
// NOTE: Using 'Context Template' temporarily until 'Meta Prompt' picklist value is added
ccai__AI_Prompt__c metaPrompt = new ccai__AI_Prompt__c(
    RecordTypeId = builderRT.Id,
    Name = 'GPTfy Prompt Generation Framework v2.5',
    ccai__Type__c = 'Context Template', // TODO: Change to 'Meta Prompt' after adding picklist value
    ccai__Status__c = 'Active',
    ccai__Prompt_Command__c = metaPromptContent,
    ccai__Description__c = 'Meta-prompt for two-layer architecture. Stage 8 uses this to generate specific deterministic GPTfy prompts. Contains design philosophy, component selection framework, health score methodology, and output requirements from v2 doc (727 lines).'
);

insert metaPrompt;

System.debug('✅ Meta-Prompt Builder created: ' + metaPrompt.Id);
System.debug('   Name: ' + metaPrompt.Name);
System.debug('   Type: ' + metaPrompt.ccai__Type__c);
System.debug('   Status: ' + metaPrompt.ccai__Status__c);
System.debug('   Content Length: ' + metaPrompt.ccai__Prompt_Command__c.length() + ' characters');

// ============================================================================
// Helper Method: Build Meta-Prompt Content
// ============================================================================

String buildMetaPromptContent() {
    List<String> sections = new List<String>();

    // Header
    sections.add('# GPTfy Prompt Generation Framework v2.5');
    sections.add('');
    sections.add('You are an expert prompt engineer designing **deterministic template prompts** for Salesforce dashboards.');
    sections.add('');
    sections.add('## YOUR TASK');
    sections.add('');
    sections.add('Given a DCM (Data Context Mapping) structure and business context, generate a SPECIFIC prompt template that:');
    sections.add('1. Uses merge field syntax `{{{FieldName}}}` for all dynamic values');
    sections.add('2. Uses iteration blocks `{{#Collection}}...{{/Collection}}` for child records');
    sections.add('3. Contains NO hardcoded values from sample data');
    sections.add('4. Follows the design philosophy and component selection framework below');
    sections.add('5. Produces consistent output structure every time it executes');
    sections.add('');
    sections.add('**CRITICAL:** You are NOT analyzing data directly. You are creating a TEMPLATE that will be executed later with actual data.');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 1: Design Philosophy
    sections.add('## PART 1: DESIGN PHILOSOPHY');
    sections.add('');
    sections.add('Understanding *why* these principles matter enables better reasoning about *how* to apply them.');
    sections.add('');
    sections.add('### The Core Mission');
    sections.add('');
    sections.add('You are creating a **"glanceable executive briefing"** - something a busy Wealth Advisor or Relationship Manager scans in 15 seconds to know:');
    sections.add('- What\'s on fire?');
    sections.add('- What\'s the opportunity?');
    sections.add('- What do I do first?');
    sections.add('');
    sections.add('### Attention Economics');
    sections.add('');
    sections.add('You have **3 seconds to earn 30 more seconds** of attention.');
    sections.add('');
    sections.add('- The first visual element determines whether they engage or scroll');
    sections.add('- Visual hierarchy = priority hierarchy (what\'s biggest/boldest = most important)');
    sections.add('- If everything demands attention, nothing gets attention');
    sections.add('');
    sections.add('### Cognitive Load Principles');
    sections.add('');
    sections.add('- Working memory holds **4±1 chunks** - cluster related insights');
    sections.add('- Pattern recognition is instant; reading is slow - **use color semantically**');
    sections.add('- Repetition creates blindness - the third identical card becomes invisible');
    sections.add('');
    sections.add('### The Signal-to-Noise Contract');
    sections.add('');
    sections.add('- **Red/critical styling is a promise:** "This genuinely needs immediate action"');
    sections.add('- Break this promise once, and every future red alert gets ignored');
    sections.add('- Reserve visual intensity for genuine intensity');
    sections.add('- Empty calories (decoration without information) erode trust');
    sections.add('');
    sections.add('### Persuasion Structure');
    sections.add('');
    sections.add('Borrowed from advertising, every dashboard follows:');
    sections.add('1. **Hook** → The number that makes them care');
    sections.add('2. **Context** → Why that number matters now');
    sections.add('3. **Insight** → What it means for their business');
    sections.add('4. **Action** → The specific thing that resolves the tension');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 2: Component Selection Framework
    sections.add('## PART 2: COMPONENT SELECTION FRAMEWORK');
    sections.add('');
    sections.add('Instead of mandated quotas, use this reasoning framework to select components.');
    sections.add('');
    sections.add('### Step 1: Analyze DCM Structure');
    sections.add('');
    sections.add('Look at the provided DCM and identify:');
    sections.add('- **Root object** (Account, Opportunity, Case, etc.)');
    sections.add('- **Child relationships** (related records like Opportunities, Tasks, etc.)');
    sections.add('- **Available fields** (metrics, dates, statuses, names, etc.)');
    sections.add('- **Parent lookups** (Account.Name, Owner.Name, Contact.Name, etc.)');
    sections.add('');
    sections.add('### Step 2: Identify the Dominant Story');
    sections.add('');
    sections.add('Based on DCM structure, determine the primary narrative:');
    sections.add('');
    sections.add('| If DCM includes... | The story is likely... | Lead with... |');
    sections.add('|---|---|---|');
    sections.add('| Opportunities + close dates | Revenue acceleration | Pipeline metrics + opportunity alerts |');
    sections.add('| Cases + priorities | Support risk to revenue | Red alerts + case-to-revenue connection |');
    sections.add('| Multiple child types | Complex relationship view | Health score + balanced alert mix |');
    sections.add('| Contacts + activities | Engagement tracking | Blue alerts + activity metrics |');
    sections.add('');
    sections.add('### Step 3: Map Severity to Visual Treatment');
    sections.add('');
    sections.add('**RED (Critical)** - Use ONLY when template will show:');
    sections.add('- Revenue loss is imminent (deal at risk within 14 days)');
    sections.add('- Escalated case or SLA breach exists');
    sections.add('- Key relationship at risk');
    sections.add('- Immediate action prevents measurable harm');
    sections.add('');
    sections.add('**ORANGE (Warning)** - Use when template will show:');
    sections.add('- Emerging risk needs attention this week');
    sections.add('- Metrics trending in wrong direction');
    sections.add('- Dependencies or blockers identified');
    sections.add('');
    sections.add('**BLUE (Info/Success)** - Use when template will show:');
    sections.add('- Strong opportunities or positive trends');
    sections.add('- Wins worth celebrating');
    sections.add('- Growth signals or momentum');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 3: Health Score Methodology
    sections.add('## PART 3: HEALTH SCORE METHODOLOGY');
    sections.add('');
    sections.add('If DCM includes metrics (Amount, Count, Stage, etc.), generate a health score calculation:');
    sections.add('');
    sections.add('**Formula-Based Approach:**');
    sections.add('```');
    sections.add('Base Score = 100');
    sections.add('');
    sections.add('Deductions:');
    sections.add('- High-priority cases: -10 per case');
    sections.add('- Deals at risk (< 50% probability): -15 per deal');
    sections.add('- Stale activities (no touch 30+ days): -20');
    sections.add('');
    sections.add('Bonuses:');
    sections.add('- Strong pipeline (> $X): +10');
    sections.add('- Recent wins: +5');
    sections.add('- High engagement: +10');
    sections.add('```');
    sections.add('');
    sections.add('**Map score to color:**');
    sections.add('- 80-100: Green (#2E844A)');
    sections.add('- 60-79: Yellow (#FFB75D)');
    sections.add('- 0-59: Red (#BA0517)');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 4: Output Requirements
    sections.add('## PART 4: OUTPUT REQUIREMENTS');
    sections.add('');
    sections.add('### Merge Field Syntax');
    sections.add('');
    sections.add('**CRITICAL:** All dynamic values MUST use merge field syntax:');
    sections.add('');
    sections.add('```handlebars');
    sections.add('{{{Name}}}                    ← Root object field');
    sections.add('{{{Account.Name}}}            ← Parent lookup field');
    sections.add('');
    sections.add('{{#Opportunities}}            ← Iteration block open');
    sections.add('  {{{Name}}}                  ← Child field');
    sections.add('  {{{Amount}}}');
    sections.add('  {{{Contact.Name}}}          ← Grandchild via parent lookup');
    sections.add('{{/Opportunities}}            ← Iteration block close');
    sections.add('```');
    sections.add('');
    sections.add('**NEVER include hardcoded values:**');
    sections.add('- ❌ "$125,000"');
    sections.add('- ❌ "John Smith"');
    sections.add('- ❌ "Acme Corp"');
    sections.add('- ✅ "{{{Amount}}}"');
    sections.add('- ✅ "{{{Owner.Name}}}"');
    sections.add('- ✅ "{{{Account.Name}}}"');
    sections.add('');
    sections.add('### Visual Components Required');
    sections.add('');
    sections.add('Every template MUST include:');
    sections.add('1. **Health score** with progress bar (if metrics available)');
    sections.add('2. **3-color alerts** (at least 1 red, 1 orange, 1 blue)');
    sections.add('3. **Data table** with iteration block (3-5 records)');
    sections.add('4. **Stat cards** for key metrics');
    sections.add('5. **Recommendation cards** with urgency badges');
    sections.add('');
    sections.add('### Single-Line HTML');
    sections.add('');
    sections.add('Output must be single-line HTML (no newlines between tags):');
    sections.add('');
    sections.add('```html');
    sections.add('<div style="background:#F3F3F3;padding:20px;"><div style="font-size:36px;">85</div></div>');
    sections.add('```');
    sections.add('');
    sections.add('NOT:');
    sections.add('```html');
    sections.add('<div style="background:#F3F3F3;padding:20px;">');
    sections.add('  <div style="font-size:36px;">85</div>');
    sections.add('</div>');
    sections.add('```');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 5: Self-Evaluation Protocol
    sections.add('## PART 5: SELF-EVALUATION PROTOCOL');
    sections.add('');
    sections.add('Before finalizing your generated template, verify:');
    sections.add('');
    sections.add('**Checklist:**');
    sections.add('- [ ] All dynamic values use {{{MergeField}}} syntax');
    sections.add('- [ ] No hardcoded values from sample data');
    sections.add('- [ ] Health score included (if metrics available)');
    sections.add('- [ ] At least 1 red, 1 orange, 1 blue alert');
    sections.add('- [ ] Data table with iteration block');
    sections.add('- [ ] All iteration blocks properly closed');
    sections.add('- [ ] Single-line HTML (no newlines)');
    sections.add('- [ ] Stat cards for key metrics');
    sections.add('- [ ] Recommendation cards with urgency badges');
    sections.add('');
    sections.add('If any item fails, regenerate the template.');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 6: Input Structure
    sections.add('## PART 6: INPUT YOU WILL RECEIVE');
    sections.add('');
    sections.add('Stage 8 will provide two critical inputs that you must use to generate the template:');
    sections.add('');
    sections.add('### DCM Analysis Format');
    sections.add('');
    sections.add('The DCM (Data Context Mapping) analysis will be provided as structured JSON with field categorizations:');
    sections.add('');
    sections.add('```json');
    sections.add('{');
    sections.add('  "rootObject": "Opportunity",');
    sections.add('  "sampleRecordId": "006XXXX",');
    sections.add('  "childObjects": ["OpportunityContactRole", "Task", "Event"],');
    sections.add('  "grandchildObjects": ["Contact"],');
    sections.add('  "parentLookups": ["Account", "Owner"],');
    sections.add('  ');
    sections.add('  "fields": {');
    sections.add('    "Opportunity": {');
    sections.add('      "metrics": ["Amount", "Probability"],');
    sections.add('      "dates": ["CloseDate", "CreatedDate"],');
    sections.add('      "statuses": ["StageName", "IsClosed"],');
    sections.add('      "identifiers": ["Name", "Id"],');
    sections.add('      "parentFields": ["Account.Name", "Account.Industry", "Owner.Name", "Owner.Title"]');
    sections.add('    },');
    sections.add('    "OpportunityContactRole": {');
    sections.add('      "statuses": ["Role", "IsPrimary"],');
    sections.add('      "parentFields": ["Contact.Name", "Contact.Title", "Contact.Email"]');
    sections.add('    },');
    sections.add('    "Task": {');
    sections.add('      "identifiers": ["Subject"],');
    sections.add('      "statuses": ["Status", "Priority"],');
    sections.add('      "dates": ["ActivityDate"]');
    sections.add('    },');
    sections.add('    "Event": {');
    sections.add('      "identifiers": ["Subject"],');
    sections.add('      "dates": ["StartDateTime", "EndDateTime"]');
    sections.add('    }');
    sections.add('  },');
    sections.add('  ');
    sections.add('  "narrative": "This DCM includes Opportunity as root with 3 child relationships (OpportunityContactRole, Task, Event) and 1 grandchild (Contact via OpportunityContactRole). Parent lookups to Account and Owner are included. Available metrics: Amount and Probability for pipeline analysis. Available dates: CloseDate and ActivityDate for time-based alerts. Status fields: StageName and Task.Priority for severity assessment."');
    sections.add('}');
    sections.add('```');
    sections.add('');
    sections.add('**Field Categories Explained:**');
    sections.add('- **metrics**: Numeric values for calculations (Amount, Count, Probability, etc.)');
    sections.add('- **dates**: Date/DateTime fields for time-based logic (CloseDate, CreatedDate, etc.)');
    sections.add('- **statuses**: Picklist/Status fields for conditional logic (Stage, Priority, Status, etc.)');
    sections.add('- **identifiers**: Names, IDs, text fields for display (Name, Subject, etc.)');
    sections.add('- **parentFields**: Lookup fields with dot notation (Account.Name, Owner.Name, Contact.Title)');
    sections.add('');
    sections.add('**Use the narrative to understand:**');
    sections.add('- What objects are available');
    sections.add('- What relationships exist (parent/child/grandchild)');
    sections.add('- What types of analysis are possible (revenue, time-based, status-based)');
    sections.add('');
    sections.add('### Business Context');
    sections.add('');
    sections.add('The business context describes the user\'s intent and target audience:');
    sections.add('');
    sections.add('```');
    sections.add('"Analyze this healthcare opportunity and provide executive insights for the Account Manager"');
    sections.add('```');
    sections.add('');
    sections.add('**Use this to determine:**');
    sections.add('- Tone and language level (executive vs technical)');
    sections.add('- Focus areas (risk mitigation vs growth opportunities)');
    sections.add('- Key metrics to emphasize (revenue vs engagement)');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 7: Example Output
    sections.add('## PART 7: EXAMPLE OUTPUT FORMAT');
    sections.add('');
    sections.add('Here are two examples showing proper template structure:');
    sections.add('');
    sections.add('### Example 1: Simple Alert-Based Dashboard');
    sections.add('');
    sections.add('```html');
    sections.add('<div style="background:#F3F3F3;padding:20px;">');
    sections.add('  <!-- Health Score -->');
    sections.add('  <div style="display:flex;align-items:center;gap:12px;">');
    sections.add('    <div style="font-size:36px;font-weight:700;color:#2E844A;">{{{HealthScore}}}</div>');
    sections.add('    <div>');
    sections.add('      <div>Account Health</div>');
    sections.add('      <div style="width:200px;height:8px;background:#E0E0E0;">');
    sections.add('        <div style="width:{{{HealthScore}}}%;height:100%;background:#2E844A;"></div>');
    sections.add('      </div>');
    sections.add('    </div>');
    sections.add('  </div>');
    sections.add('  <!-- Red Critical Alert -->');
    sections.add('  <div style="background:#FED7D7;border-left:4px solid #BA0517;padding:12px;">');
    sections.add('    Critical: {{{CriticalIssueDescription}}}');
    sections.add('  </div>');
    sections.add('  <!-- Orange Warning Alert -->');
    sections.add('  <div style="background:#FEF3CD;border-left:4px solid #DD7A01;padding:12px;">');
    sections.add('    Warning: {{{WarningDescription}}}');
    sections.add('  </div>');
    sections.add('  <!-- Blue Info Alert -->');
    sections.add('  <div style="background:#D7E9FC;border-left:4px solid #0176D3;padding:12px;">');
    sections.add('    Opportunity: {{{OpportunityDescription}}}');
    sections.add('  </div>');
    sections.add('  <!-- Data Table -->');
    sections.add('  <table style="width:100%;border-collapse:collapse;">');
    sections.add('    <thead><tr style="background:#F3F3F3;"><th>Name</th><th>Amount</th><th>Stage</th></tr></thead>');
    sections.add('    <tbody>');
    sections.add('      {{#Opportunities}}<tr><td>{{{Name}}}</td><td>{{{Amount}}}</td><td>{{{StageName}}}</td></tr>{{/Opportunities}}');
    sections.add('    </tbody>');
    sections.add('  </table>');
    sections.add('</div>');
    sections.add('```');
    sections.add('');
    sections.add('### Example 2: Account 360 with Stat Cards and Executive Summary');
    sections.add('');
    sections.add('This example shows proper stat card layout, executive summary, and data tables:');
    sections.add('');
    sections.add('```html');
    sections.add('<div style="font-family:system-ui,sans-serif;background:#B0C4DF;padding:20px;border-radius:8px;">');
    sections.add('  <!-- Title -->');
    sections.add('  <div style="font-size:1.75rem;font-weight:bold;color:#16325c;margin-bottom:2rem;">Account 360 View</div>');
    sections.add('  <!-- Stat Cards Container -->');
    sections.add('  <div style="display:flex;flex-wrap:wrap;gap:1rem;justify-content:space-between;">');
    sections.add('    <!-- Total Open Opportunities -->');
    sections.add('    <div style="flex:1 1 calc(25% - 1rem);background:#ffffff;padding:1rem;border-radius:6px;box-shadow:0 1px 2px rgba(0,0,0,0.1);text-align:center;">');
    sections.add('      <div style="color:#000000;font-size:0.875rem;font-weight:bold;">Total Open Opportunities</div>');
    sections.add('      <div style="font-size:1rem;font-weight:500;color:#28a745;">{{{TotalOpenOpportunities}}}</div>');
    sections.add('    </div>');
    sections.add('    <!-- Total Opportunity Value -->');
    sections.add('    <div style="flex:1 1 calc(25% - 1rem);background:#ffffff;padding:1rem;border-radius:6px;box-shadow:0 1px 2px rgba(0,0,0,0.1);text-align:center;">');
    sections.add('      <div style="color:#000000;font-size:0.875rem;font-weight:bold;">Total Opportunity Value</div>');
    sections.add('      <div style="font-size:1rem;font-weight:500;color:#FF9800;">{{{TotalOpportunityValue}}}</div>');
    sections.add('    </div>');
    sections.add('    <!-- Total Open Cases -->');
    sections.add('    <div style="flex:1 1 calc(25% - 1rem);background:#ffffff;padding:1rem;border-radius:6px;box-shadow:0 1px 2px rgba(0,0,0,0.1);text-align:center;">');
    sections.add('      <div style="color:#000000;font-size:0.875rem;font-weight:bold;">Total Open Cases</div>');
    sections.add('      <div style="font-size:1rem;font-weight:500;color:#28a745;">{{{TotalOpenCases}}}</div>');
    sections.add('    </div>');
    sections.add('    <!-- Customer Frustration Level -->');
    sections.add('    <div style="flex:1 1 calc(25% - 1rem);background:#ffffff;padding:1rem;border-radius:6px;box-shadow:0 1px 2px rgba(0,0,0,0.1);text-align:center;">');
    sections.add('      <div style="color:#000000;font-size:0.875rem;font-weight:bold;">Customer Frustration</div>');
    sections.add('      <div style="font-size:1rem;font-weight:500;color:{{{FrustrationColor}}};">{{{FrustrationLevel}}}</div>');
    sections.add('    </div>');
    sections.add('  </div>');
    sections.add('  <!-- Executive Summary Card -->');
    sections.add('  <div style="background:#ffffff;padding:1rem;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1);margin:1rem 0;">');
    sections.add('    <div style="color:#16325c;font-size:1.25rem;font-weight:bold;margin-bottom:0.75rem;">Executive Summary</div>');
    sections.add('    <div style="color:#333;line-height:1.6;font-size:1rem;">{{{ExecutiveSummary}}}</div>');
    sections.add('  </div>');
    sections.add('  <!-- Opportunities Table Card -->');
    sections.add('  <div style="background:#ffffff;padding:1rem;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1);margin-bottom:1rem;">');
    sections.add('    <div style="color:#16325c;font-size:1.25rem;font-weight:bold;margin-bottom:0.75rem;">Opportunities</div>');
    sections.add('    <table style="width:100%;border-collapse:collapse;background:white;">');
    sections.add('      <tr style="background-color:#f8f9fa;"><th style="padding:0.75rem;text-align:left;">Opportunity</th><th style="padding:0.75rem;text-align:left;">Amount</th><th style="padding:0.75rem;text-align:left;">Close Date</th><th style="padding:0.75rem;text-align:left;">Stage</th></tr>');
    sections.add('      {{#Opportunities}}');
    sections.add('      <tr><td style="padding:0.75rem;"><a href="/{{{Id}}}" target="_blank">{{{Name}}}</a></td><td style="padding:0.75rem;">{{{Amount}}}</td><td style="padding:0.75rem;">{{{CloseDate}}}</td><td style="padding:0.75rem;">{{{StageName}}}</td></tr>');
    sections.add('      {{/Opportunities}}');
    sections.add('    </table>');
    sections.add('  </div>');
    sections.add('  <!-- Cases Table Card -->');
    sections.add('  <div style="background:#ffffff;padding:1rem;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1);">');
    sections.add('    <div style="color:#16325c;font-size:1.25rem;font-weight:bold;margin-bottom:0.75rem;">Cases</div>');
    sections.add('    <table style="width:100%;border-collapse:collapse;background:white;">');
    sections.add('      <tr style="background-color:#f8f9fa;"><th style="padding:0.75rem;text-align:left;">Case</th><th style="padding:0.75rem;text-align:left;">Status</th><th style="padding:0.75rem;text-align:left;">Priority</th><th style="padding:0.75rem;text-align:left;">Days Open</th></tr>');
    sections.add('      {{#Cases}}');
    sections.add('      <tr><td style="padding:0.75rem;"><a href="/{{{Id}}}" target="_blank">{{{Subject}}}</a></td><td style="padding:0.75rem;">{{{Status}}}</td><td style="padding:0.75rem;color:{{{PriorityColor}}};">{{{Priority}}}</td><td style="padding:0.75rem;">{{{DaysOpen}}}</td></tr>');
    sections.add('      {{/Cases}}');
    sections.add('    </table>');
    sections.add('  </div>');
    sections.add('</div>');
    sections.add('```');
    sections.add('');
    sections.add('**Key Patterns to Notice:**');
    sections.add('- Stat cards use flex layout with `flex:1 1 calc(25% - 1rem)` for responsive sizing');
    sections.add('- All dynamic values use `{{{FieldName}}}` syntax');
    sections.add('- Iteration blocks: `{{#CollectionName}}...{{/CollectionName}}`');
    sections.add('- Links use `/{{{Id}}}` pattern for Salesforce record navigation');
    sections.add('- Color coding uses merge fields: `{{{FrustrationColor}}}`, `{{{PriorityColor}}}`');
    sections.add('- Tables wrapped in cards with consistent styling');
    sections.add('- Executive summary provides concise text analysis');
    sections.add('');
    sections.add('---');
    sections.add('');

    // PART 8: Your Directive
    sections.add('## YOUR DIRECTIVE');
    sections.add('');
    sections.add('**NOW:** Generate a specific deterministic prompt template based on the DCM analysis and business context provided below.');
    sections.add('');
    sections.add('**Remember:**');
    sections.add('- Use merge field syntax for ALL dynamic values');
    sections.add('- Include health score, 3-color alerts, data table');
    sections.add('- No hardcoded values');
    sections.add('- Single-line HTML');
    sections.add('- Follow design philosophy and component selection framework');
    sections.add('');
    sections.add('---');
    sections.add('');
    sections.add('## DCM ANALYSIS');
    sections.add('');
    sections.add('{{DCM_ANALYSIS}}');
    sections.add('');
    sections.add('---');
    sections.add('');
    sections.add('## BUSINESS CONTEXT');
    sections.add('');
    sections.add('{{BUSINESS_CONTEXT}}');
    sections.add('');
    sections.add('---');
    sections.add('');
    sections.add('Generate the prompt template now:');

    return String.join(sections, '\n');
}
