// V2.6: Insert new UI Component builders for visual richness
// These components expand the toolkit beyond basic stats/alerts/cards

System.debug('=== V2.6 UI Component Builders ===');

Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();

List<ccai__AI_Prompt__c> components = new List<ccai__AI_Prompt__c>();

// 1. Progress Ring (CSS-only donut chart)
components.add(new ccai__AI_Prompt__c(
    Name = 'Progress Ring',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for percentage completion, win probability, or health scores. Shows a circular progress indicator.',
    ccai__Prompt_Command__c = '<div style="position:relative;width:80px;height:80px;"><div style="width:80px;height:80px;border-radius:50%;background:conic-gradient(#2E844A 0% 75%, #E0E0E0 75% 100%);display:flex;align-items:center;justify-content:center;"><div style="width:60px;height:60px;background:white;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:18px;font-weight:700;color:#2E844A;">75%</div></div></div>'
));

// 2. Trend Indicator
components.add(new ccai__AI_Prompt__c(
    Name = 'Trend Indicator',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for showing value changes with directional arrows. Green up arrow for positive, red down for negative.',
    ccai__Prompt_Command__c = '<div style="display:inline-flex;align-items:center;gap:8px;padding:8px 12px;background:#D4EDDA;border-radius:6px;"><span style="font-size:20px;font-weight:700;color:#2E844A;">$125K</span><span style="color:#2E844A;font-size:14px;">▲ 15%</span></div><!-- Red variant: background:#FED7D7;color:#BA0517; with ▼ -->'
));

// 3. Comparison Card (A vs B)
components.add(new ccai__AI_Prompt__c(
    Name = 'Comparison Card',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for before/after, this quarter vs last, or A/B comparisons. Shows two values side by side.',
    ccai__Prompt_Command__c = '<div style="display:flex;gap:16px;background:white;border-radius:8px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="flex:1;text-align:center;padding-right:16px;border-right:1px solid #DDDBDA;"><div style="font-size:12px;color:#706E6B;margin-bottom:4px;">Last Quarter</div><div style="font-size:24px;font-weight:700;color:#706E6B;">$320K</div></div><div style="flex:1;text-align:center;"><div style="font-size:12px;color:#706E6B;margin-bottom:4px;">This Quarter</div><div style="font-size:24px;font-weight:700;color:#2E844A;">$420K</div></div></div>'
));

// 4. Pipeline Funnel
components.add(new ccai__AI_Prompt__c(
    Name = 'Pipeline Funnel',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for showing opportunity pipeline stages. Visual progression from wide (early stage) to narrow (closed).',
    ccai__Prompt_Command__c = '<div style="background:white;border-radius:8px;padding:16px;"><div style="font-weight:600;color:#181818;margin-bottom:12px;">Pipeline by Stage</div><div style="margin-bottom:8px;"><div style="background:#D7E9FC;padding:8px 12px;border-radius:4px;width:100%;"><span style="font-weight:600;">Discovery</span><span style="float:right;">$200K (2)</span></div></div><div style="margin-bottom:8px;"><div style="background:#B4D7F0;padding:8px 12px;border-radius:4px;width:80%;"><span style="font-weight:600;">Proposal</span><span style="float:right;">$150K (1)</span></div></div><div><div style="background:#0176D3;color:white;padding:8px 12px;border-radius:4px;width:50%;"><span style="font-weight:600;">Negotiation</span><span style="float:right;">$75K (1)</span></div></div></div>'
));

// 5. Featured Hero Card
components.add(new ccai__AI_Prompt__c(
    Name = 'Featured Hero Card',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for the single most important insight. Large, prominent card that demands attention. Use sparingly - only one per dashboard.',
    ccai__Prompt_Command__c = '<div style="background:linear-gradient(135deg,#0176D3 0%,#032D60 100%);color:white;border-radius:12px;padding:24px;margin-bottom:20px;"><div style="font-size:14px;opacity:0.9;margin-bottom:8px;">KEY INSIGHT</div><div style="font-size:24px;font-weight:700;margin-bottom:12px;">$420K Pipeline at Risk</div><div style="font-size:14px;opacity:0.9;line-height:1.5;">Three unresolved high-priority cases signal potential churn. Immediate executive engagement recommended.</div></div>'
));

// 6. Gauge Meter
components.add(new ccai__AI_Prompt__c(
    Name = 'Gauge Meter',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for scores or ratings on a scale. Semi-circle gauge with color zones (red/yellow/green).',
    ccai__Prompt_Command__c = '<div style="text-align:center;padding:16px;"><div style="position:relative;width:120px;height:60px;margin:0 auto;overflow:hidden;"><div style="position:absolute;width:120px;height:120px;border-radius:50%;background:conic-gradient(#BA0517 0% 33%, #DD7A01 33% 66%, #2E844A 66% 100%);clip-path:polygon(0 0, 100% 0, 100% 50%, 0 50%);"></div><div style="position:absolute;bottom:0;left:50%;transform:translateX(-50%);width:80px;height:40px;background:white;border-radius:40px 40px 0 0;"></div></div><div style="font-size:28px;font-weight:700;color:#2E844A;margin-top:-10px;">78</div><div style="font-size:12px;color:#706E6B;">Account Health</div></div>'
));

// 7. Risk Priority Matrix
components.add(new ccai__AI_Prompt__c(
    Name = 'Risk Priority Matrix',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for categorizing items by urgency and impact. 2x2 grid showing priority quadrants.',
    ccai__Prompt_Command__c = '<div style="background:white;border-radius:8px;padding:16px;"><div style="font-weight:600;margin-bottom:12px;">Priority Matrix</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;"><div style="background:#FED7D7;padding:12px;border-radius:4px;text-align:center;"><div style="font-size:11px;color:#BA0517;font-weight:600;">CRITICAL</div><div style="font-size:18px;font-weight:700;color:#BA0517;">2</div></div><div style="background:#FEF3CD;padding:12px;border-radius:4px;text-align:center;"><div style="font-size:11px;color:#DD7A01;font-weight:600;">HIGH</div><div style="font-size:18px;font-weight:700;color:#DD7A01;">3</div></div><div style="background:#D7E9FC;padding:12px;border-radius:4px;text-align:center;"><div style="font-size:11px;color:#0176D3;font-weight:600;">MEDIUM</div><div style="font-size:18px;font-weight:700;color:#0176D3;">5</div></div><div style="background:#D4EDDA;padding:12px;border-radius:4px;text-align:center;"><div style="font-size:11px;color:#2E844A;font-weight:600;">LOW</div><div style="font-size:18px;font-weight:700;color:#2E844A;">8</div></div></div></div>'
));

// 8. Timeline
components.add(new ccai__AI_Prompt__c(
    Name = 'Timeline',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for showing sequence of events or milestones. Horizontal or vertical timeline with dates.',
    ccai__Prompt_Command__c = '<div style="background:white;border-radius:8px;padding:16px;"><div style="font-weight:600;margin-bottom:12px;">Key Milestones</div><div style="position:relative;padding-left:24px;border-left:2px solid #DDDBDA;"><div style="margin-bottom:16px;"><div style="position:absolute;left:-7px;width:12px;height:12px;background:#2E844A;border-radius:50%;"></div><div style="font-size:12px;color:#706E6B;">Jan 15</div><div style="font-weight:600;">Initial Meeting</div></div><div style="margin-bottom:16px;"><div style="position:absolute;left:-7px;width:12px;height:12px;background:#0176D3;border-radius:50%;"></div><div style="font-size:12px;color:#706E6B;">Feb 1</div><div style="font-weight:600;">Proposal Sent</div></div><div><div style="position:absolute;left:-7px;width:12px;height:12px;background:#DD7A01;border-radius:50%;border:2px solid #DD7A01;"></div><div style="font-size:12px;color:#706E6B;">Feb 28</div><div style="font-weight:600;">Close Date (Pending)</div></div></div></div>'
));

// 9. Two-Column Layout
components.add(new ccai__AI_Prompt__c(
    Name = 'Two-Column Layout',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for placing related content side by side. Responsive grid that stacks on narrow screens.',
    ccai__Prompt_Command__c = '<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;"><!-- Left column content --><div style="background:white;border-radius:8px;padding:16px;">Left content here</div><!-- Right column content --><div style="background:white;border-radius:8px;padding:16px;">Right content here</div></div>'
));

// 10. KPI Card with Trend
components.add(new ccai__AI_Prompt__c(
    Name = 'KPI Card with Trend',
    RecordTypeId = builderRtId,
    ccai__Type__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for key metrics with historical context. Shows current value plus trend indicator.',
    ccai__Prompt_Command__c = '<div style="background:white;border-radius:8px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="display:flex;justify-content:space-between;align-items:flex-start;"><div><div style="font-size:12px;color:#706E6B;margin-bottom:4px;">Total Pipeline</div><div style="font-size:28px;font-weight:700;color:#181818;">$420K</div></div><div style="background:#D4EDDA;color:#2E844A;padding:4px 8px;border-radius:4px;font-size:12px;font-weight:600;">▲ 23%</div></div><div style="margin-top:12px;height:4px;background:#E0E0E0;border-radius:2px;"><div style="height:100%;width:70%;background:linear-gradient(90deg,#D7E9FC,#0176D3);border-radius:2px;"></div></div></div>'
));

insert components;
System.debug('Created ' + components.size() + ' new UI Component builders');

// List all UI Components
List<ccai__AI_Prompt__c> allUI = [
    SELECT Name, ccai__Status__c
    FROM ccai__AI_Prompt__c
    WHERE RecordType.DeveloperName = 'Builder'
    AND ccai__Type__c = 'UI Component'
    AND ccai__Status__c = 'Active'
    ORDER BY Name
];
System.debug('Total active UI Components: ' + allUI.size());
for (ccai__AI_Prompt__c ui : allUI) {
    System.debug('  - ' + ui.Name);
}
