// Phase 2: Create UI Component Builders
// Stat Card + Alert Box

System.debug('=== PHASE 2: UI COMPONENT BUILDERS ===');

// Get Builder record type
Id builderRtId = [SELECT Id FROM RecordType 
                   WHERE SobjectType = 'ccai__AI_Prompt__c' 
                   AND DeveloperName = 'Builder' 
                   LIMIT 1].Id;

// Get topic IDs
Map<String, Id> topicMap = new Map<String, Id>();
for (Topic t : [SELECT Id, Name FROM Topic 
                WHERE Name IN ('Stat Card', 'Alert Box', 'Above-the-Fold', 'P0', 'P1')]) {
    topicMap.put(t.Name, t.Id);
}

System.debug('✅ Builder RecordType: ' + builderRtId);
System.debug('✅ Topics found: ' + topicMap.size());

// Create Stat Card Builder
String statCardContent = 
'=== UI COMPONENT: STAT CARD ===\n\n' +
'PURPOSE: Display key metrics in a clean, scannable card format.\n\n' +
'WHEN TO USE:\n' +
'- Dashboard-style layouts with multiple metrics\n' +
'- Above-the-fold content (Zone 2: 100-200px)\n' +
'- Executive summaries requiring quick data scan\n' +
'- 4-8 cards optimal (not too few, not overwhelming)\n\n' +
'HTML TEMPLATE:\n' +
'<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">\n' +
'  <div style="color: #706E6B; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; margin-bottom: 0.5rem;">{{METRIC_LABEL}}</div>\n' +
'  <div style="font-size: 2rem; font-weight: 700; color: {{VALUE_COLOR}}; line-height: 1.2;">{{METRIC_VALUE}}</div>\n' +
'  <div style="font-size: 0.625rem; color: #706E6B; margin-top: 0.25rem;">{{EVIDENCE_SOURCE}}</div>\n' +
'</div>\n\n' +
'CONTAINER WRAPPER:\n' +
'<div style="display: flex; flex-wrap: wrap; gap: 1rem; justify-content: space-between; margin-bottom: 1.5rem;">\n' +
'  <!-- Place 4-8 stat cards here -->\n' +
'</div>\n\n' +
'COLOR CODING:\n' +
'- Success/Positive: #28a745 (green)\n' +
'- Warning/Medium: #FF9800 (orange)\n' +
'- Critical/Negative: #dc3545 (red)\n' +
'- Neutral/Info: #0176D3 (blue)\n' +
'- Default: #181818 (dark gray)\n\n' +
'BEST PRACTICES:\n' +
'- Label: SHORT (1-3 words), uppercase, small font\n' +
'- Value: LARGE (28-32px), bold, color-coded by sentiment\n' +
'- Evidence: Tiny (10px), subtle color, at bottom\n' +
'- Use semantic colors to convey urgency without words\n' +
'- Aim for 4-6 cards above-the-fold (responsive wraps to 2 columns on mobile)\n\n' +
'EXAMPLES:\n' +
'Total Value: $1.5M (green if on track, orange if at risk)\n' +
'Days to Close: 67 (red if <30, orange if <60, green if >60)\n' +
'Open Tasks: 12 (red if >10, orange if 5-10, green if <5)\n' +
'Stage: Proposal (blue neutral color)\n\n' +
'AVOID:\n' +
'- Too many cards (>8 becomes overwhelming)\n' +
'- Too few cards (<4 wastes white space)\n' +
'- Long labels (should be scannable at a glance)\n' +
'- Mixing stat cards with unrelated UI (keep cards together)';

ccai__AI_Prompt__c statCard = new ccai__AI_Prompt__c(
    Name = 'Stat Card Component',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = 'a01gD000003okzEQAQ',
    ccai__AI_Data_Extraction_Mapping__c = 'a05QH000008Olh8YAC',
    ccai__Prompt_Command__c = statCardContent
);

insert statCard;
System.debug('✅ Created Stat Card Builder: ' + statCard.Id);

// Create Alert Box Builder
String alertBoxContent = 
'=== UI COMPONENT: ALERT BOX ===\n\n' +
'PURPOSE: Highlight critical information, warnings, or important callouts with color-coded visual emphasis.\n\n' +
'WHEN TO USE:\n' +
'- CRITICAL risks (Zone 1: 0-100px, above everything)\n' +
'- WARNING messages (Zone 2-3: still above-the-fold)\n' +
'- SUCCESS confirmations or positive signals\n' +
'- INFO summaries or contextual notes\n' +
'- Limit to 2-3 alert boxes above-the-fold (prioritize!)\n\n' +
'HTML TEMPLATE:\n' +
'<div style="background-color: {{ALERT_BG_COLOR}}; padding: 1rem; border-radius: 6px; border-left: 4px solid {{ALERT_BORDER_COLOR}}; margin-bottom: 1rem;">\n' +
'  <p style="margin: 0 0 0.5rem 0; font-weight: bold; font-size: 0.875rem; color: {{ALERT_TEXT_COLOR}};">{{SEVERITY_ICON}} {{ALERT_TITLE}}</p>\n' +
'  <p style="margin: 0; font-size: 0.875rem; color: {{ALERT_TEXT_COLOR}};">{{ALERT_MESSAGE}}</p>\n' +
'  <p style="margin: 0.5rem 0 0 0; font-size: 0.75rem; color: {{ALERT_TEXT_COLOR}}; opacity: 0.8;"><strong>Action:</strong> {{RECOMMENDED_ACTION}}</p>\n' +
'</div>\n\n' +
'ALERT TYPES & COLOR SCHEMES:\n\n' +
'CRITICAL (Red) - Deal-killers, immediate action required:\n' +
'- Background: #f8d7da\n' +
'- Border: #dc3545\n' +
'- Text: #721c24\n' +
'- Icon: 🔴 or ⛔\n' +
'- Examples: "Missing Economic Buyer", "Overdue ROI Analysis blocking approval"\n\n' +
'WARNING (Orange) - Significant gaps, attention needed:\n' +
'- Background: #fff3cd\n' +
'- Border: #FF9800\n' +
'- Text: #856404\n' +
'- Icon: ⚠️ or 🟠\n' +
'- Examples: "Low activity velocity", "Single-threaded relationship"\n\n' +
'SUCCESS (Green) - Positive signals, opportunities:\n' +
'- Background: #d4edda\n' +
'- Border: #28a745\n' +
'- Text: #155724\n' +
'- Icon: ✅ or 🟢\n' +
'- Examples: "Strong champion identified", "Recent executive engagement"\n\n' +
'INFO (Blue) - Contextual information, summaries:\n' +
'- Background: #f0f7ff\n' +
'- Border: #0176d3\n' +
'- Text: #014486\n' +
'- Icon: ℹ️ or 🔵\n' +
'- Examples: "Stage analysis", "Historical context"\n\n' +
'BEST PRACTICES:\n' +
'- Title: Short, action-oriented (3-5 words)\n' +
'- Message: 1-2 sentences max, specific evidence\n' +
'- Action: Clear next step with owner/timeframe\n' +
'- Priority order: CRITICAL → WARNING → SUCCESS → INFO\n' +
'- Zone 1 (above-the-fold): Only CRITICAL alerts\n' +
'- Zone 2-3: WARNING and SUCCESS\n' +
'- Zone 4+: INFO and detailed context\n\n' +
'STRUCTURE FOR RISK ALERTS:\n' +
'Title: [Risk description - specific, not generic]\n' +
'Message: [Evidence from Salesforce fields + Business impact]\n' +
'Action: [Specific mitigation with timeframe]\n\n' +
'EXAMPLES:\n\n' +
'CRITICAL:\n' +
'🔴 No Economic Buyer Identified\n' +
'This $1.5M deal is in late stage (Proposal) but has no contact with budget authority. (Source: OpportunityContactRole)\n' +
'Action: Identify and engage CFO or VP Finance before Feb 1.\n\n' +
'WARNING:\n' +
'⚠️ Activity Velocity Below Benchmark\n' +
'Only 2 activities in past 14 days (benchmark: 5-7 for proposal stage). Deal momentum may be stalling.\n' +
'Action: Schedule discovery call and send ROI analysis this week.\n\n' +
'SUCCESS:\n' +
'✅ Strong Multi-Threading Established\n' +
'6 stakeholders engaged across 3 departments, including VP-level champion.\n' +
'Recommendation: Leverage champion for executive sponsor introduction.\n\n' +
'AVOID:\n' +
'- Generic messages without evidence ("Deal needs attention")\n' +
'- Too many alerts above-the-fold (>3 = alert fatigue)\n' +
'- Mixing alert types randomly (order by severity)\n' +
'- Alerts without actionable next steps';

ccai__AI_Prompt__c alertBox = new ccai__AI_Prompt__c(
    Name = 'Alert Box Component',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Type__c = 'Text',
    ccai__Object__c = 'Opportunity',
    ccai__AI_Connection__c = 'a01gD000003okzEQAQ',
    ccai__AI_Data_Extraction_Mapping__c = 'a05QH000008Olh8YAC',
    ccai__Prompt_Command__c = alertBoxContent
);

insert alertBox;
System.debug('✅ Created Alert Box Builder: ' + alertBox.Id);

// Create topic assignments
List<TopicAssignment> assignments = new List<TopicAssignment>();

// Stat Card topics
if (topicMap.containsKey('Stat Card')) {
    assignments.add(new TopicAssignment(EntityId = statCard.Id, TopicId = topicMap.get('Stat Card')));
}
if (topicMap.containsKey('Above-the-Fold')) {
    assignments.add(new TopicAssignment(EntityId = statCard.Id, TopicId = topicMap.get('Above-the-Fold')));
}
if (topicMap.containsKey('P0')) {
    assignments.add(new TopicAssignment(EntityId = statCard.Id, TopicId = topicMap.get('P0')));
}

// Alert Box topics
if (topicMap.containsKey('Alert Box')) {
    assignments.add(new TopicAssignment(EntityId = alertBox.Id, TopicId = topicMap.get('Alert Box')));
}
if (topicMap.containsKey('Above-the-Fold')) {
    assignments.add(new TopicAssignment(EntityId = alertBox.Id, TopicId = topicMap.get('Above-the-Fold')));
}
if (topicMap.containsKey('P0')) {
    assignments.add(new TopicAssignment(EntityId = alertBox.Id, TopicId = topicMap.get('P0')));
}

if (!assignments.isEmpty()) {
    insert assignments;
    System.debug('✅ Created ' + assignments.size() + ' topic assignments');
}

// Verification
List<ccai__AI_Prompt__c> builders = [
    SELECT Id, Name, Category__c, ccai__Status__c
    FROM ccai__AI_Prompt__c
    WHERE Id IN (:statCard.Id, :alertBox.Id)
];

System.debug('\n=== VERIFICATION ===');
for (ccai__AI_Prompt__c b : builders) {
    System.debug('📦 ' + b.Name + ' (' + b.Category__c + ') - ' + b.ccai__Status__c);
}

System.debug('\n✅ PHASE 2 COMPLETE');
System.debug('Stat Card ID: ' + statCard.Id);
System.debug('Alert Box ID: ' + alertBox.Id);
