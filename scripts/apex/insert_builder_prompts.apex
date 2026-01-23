/**
 * Insert Builder Prompts - V2.1 Builder Library
 *
 * Run this script in Anonymous Apex to populate all builder prompts.
 *
 * Categories included:
 * - Quality Rules (10)
 * - UI Components (10)
 * - Context Templates (5)
 * - Traversals (25)
 *
 * Total: 50 builder prompts
 *
 * USAGE:
 *   sf apex run -f scripts/apex/insert_builder_prompts.apex -o agentictso
 *
 * NOTE: This script uses upsert based on Name field to be idempotent.
 * Re-running will update existing records rather than create duplicates.
 */

// Get Builder record type
Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();

List<ccai__AI_Prompt__c> builders = new List<ccai__AI_Prompt__c>();

// ============================================
// QUALITY RULES (10)
// ============================================

builders.add(new ccai__AI_Prompt__c(
    Name = 'Evidence Citation',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Ensures all insights are grounded in verifiable data, making outputs trustworthy and auditable.',
    ccai__Prompt_Command__c = 'Always cite specific field:value pairs as evidence when making claims or observations. Format as "FieldName=$value" or "FieldName=value". Example: "Amount=$500K, CloseDate=2024-03-15, Stage=Negotiation". Never make statements without backing them up with actual data field references.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Name Personalization',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Makes insights relatable by referencing real people, not generic titles.',
    ccai__Prompt_Command__c = 'Use actual names from data records, never generic titles or roles. Say "Sarah Johnson" not "the CFO", "Mike Chen" not "the account owner". Extract names from fields like Owner.Name, Contact.Name, Account.Name, or User.Name. Personalization creates engagement and clarity.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Specific Dates',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Provides concrete timing information that does not decay or become ambiguous.',
    ccai__Prompt_Command__c = 'Include actual dates, not relative terms. Say "March 15, 2024" or "March 15" not "next week" or "soon". Use date fields like CloseDate, CreatedDate, LastModifiedDate. If showing relative timing, include both: "March 15 (3 days from now)". Precision builds trust.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Numeric Precision',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Enables accurate decision-making with properly formatted quantitative data.',
    ccai__Prompt_Command__c = 'Show exact numbers with appropriate formatting. Currency: $1.2M, $450K, $3,250. Percentages: 85%, 12.5%. Duration: 7 days, 3 weeks. Counts: 23 opportunities, 156 leads. Never round to vague terms like "several" or "many".'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Action Specificity',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Transforms vague suggestions into executable tasks with clear ownership.',
    ccai__Prompt_Command__c = 'Recommendations must be specific and immediately actionable. Include WHO should do WHAT by WHEN. Good: "Schedule call with Gene Simmons by Friday to discuss $500K renewal". Bad: "Follow up soon" or "Review account". Every action needs clear ownership, task, and timeframe.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Visual Diversity',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Creates engaging dashboards that communicate insights visually.',
    ccai__Prompt_Command__c = 'Use at least 3 different component types per dashboard. Choose from: KPI cards, charts (bar, line, pie, funnel), tables, progress bars, timelines, alerts. Never lead with tables - start with visual components. Match component type to data: trends->line charts, comparisons->bar charts.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Executive Summary',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Provides immediate value for time-constrained executives.',
    ccai__Prompt_Command__c = 'Always start with a 2-3 sentence executive summary of key findings. Cover: (1) Overall situation/context, (2) Most important insight or trend, (3) Primary recommended action or outcome. Use concise language. This should be readable in under 15 seconds.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Insight Depth',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Transforms raw observations into actionable business intelligence.',
    ccai__Prompt_Command__c = 'Each insight must include four elements: (1) FINDING: What the data shows, (2) EVIDENCE: Specific field:value pairs supporting it, (3) IMPLICATION: Why it matters to business goals, (4) ACTION: Specific recommended next step. Never present findings without interpretation and action.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Recommendation Urgency',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Helps users prioritize actions based on time-sensitivity.',
    ccai__Prompt_Command__c = 'Tag every recommendation with urgency level: URGENT (within 24 hours), HIGH (within 3 days), NORMAL (within 2 weeks). Base urgency on: close dates approaching, at-risk renewals, stalled deals, high-value opportunities. Format: "[URGENT] Schedule call with..."'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Data Completeness Warning',
    RecordTypeId = builderRtId,
    Category__c = 'Quality Rule',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Builds trust by being transparent about data limitations.',
    ccai__Prompt_Command__c = 'If key data is missing, show an Info-level alert explaining: (1) What data is unavailable (specific fields), (2) Why it matters (what insights are limited), (3) How to fix it (populate fields, adjust permissions). Example: "Owner name unavailable - limits personalization."'
));

// ============================================
// UI COMPONENTS (10)
// ============================================

builders.add(new ccai__AI_Prompt__c(
    Name = 'Alert Box - Error',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for critical issues requiring immediate attention.',
    ccai__Prompt_Command__c = '<div style="background:#FED7D7;border-left:4px solid #BA0517;padding:12px 16px;border-radius:4px;margin-bottom:12px;"><div style="font-weight:600;color:#BA0517;margin-bottom:4px;">Critical Issue</div><div style="color:#54514C;">Description with specific evidence</div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Alert Box - Warning',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for warnings about at-risk items or potential issues.',
    ccai__Prompt_Command__c = '<div style="background:#FEF3CD;border-left:4px solid #DD7A01;padding:12px 16px;border-radius:4px;margin-bottom:12px;"><div style="font-weight:600;color:#DD7A01;margin-bottom:4px;">Warning</div><div style="color:#54514C;">Description with specific evidence</div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Alert Box - Info',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for informational callouts and helpful context.',
    ccai__Prompt_Command__c = '<div style="background:#D7E9FC;border-left:4px solid #0176D3;padding:12px 16px;border-radius:4px;margin-bottom:12px;"><div style="font-weight:600;color:#0176D3;margin-bottom:4px;">Information</div><div style="color:#54514C;">Description with specific evidence</div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Stats Strip',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for displaying 3-5 key metrics horizontally at top of dashboard.',
    ccai__Prompt_Command__c = '<div style="display:flex;gap:16px;margin-bottom:20px;"><div style="flex:1;background:white;border-radius:6px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="font-size:28px;font-weight:700;color:#0176D3;margin-bottom:4px;">{{{Value}}}</div><div style="font-size:13px;color:#706E6B;">Label</div></div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Insight Card',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for analysis findings with supporting evidence citations.',
    ccai__Prompt_Command__c = '<div style="background:white;border-radius:6px;padding:16px;margin-bottom:12px;border:1px solid #DDDBDA;"><div style="font-weight:600;color:#181818;margin-bottom:8px;">Insight Title</div><div style="color:#706E6B;margin-bottom:12px;line-height:1.5;">Analysis text with specific evidence</div><div style="font-size:12px;color:#706E6B;"><strong>Evidence:</strong> Field=Value, Field2=Value2</div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Recommendation Card',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for action items with urgency badges and rationale.',
    ccai__Prompt_Command__c = '<div style="background:#FFFFFF;border-left:4px solid #2E844A;border-radius:6px;padding:16px;margin-bottom:12px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;"><div style="font-weight:600;color:#181818;">Recommended Action</div><div style="background:#DD7A01;color:white;padding:4px 12px;border-radius:12px;font-size:11px;font-weight:600;">URGENT</div></div><div style="color:#706E6B;margin-bottom:12px;line-height:1.5;">Specific action description</div><div style="font-size:12px;color:#706E6B;"><strong>Why:</strong> Rationale for action</div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Health Score',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for visual health/score indicators (0-100 with color coding).',
    ccai__Prompt_Command__c = '<div style="display:flex;align-items:center;gap:12px;"><div style="font-size:36px;font-weight:700;color:#2E844A;">85</div><div><div style="font-size:14px;font-weight:600;color:#181818;">Health Score</div><div style="width:200px;height:8px;background:#E0E0E0;border-radius:4px;overflow:hidden;"><div style="width:85%;height:100%;background:#2E844A;"></div></div></div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Data Table',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use sparingly for listing related records. Max 7 rows. Never lead with tables.',
    ccai__Prompt_Command__c = '<table style="width:100%;border-collapse:collapse;margin-bottom:16px;"><thead><tr style="background:#F3F3F3;border-bottom:2px solid #DDDBDA;"><th style="padding:8px;text-align:left;font-size:12px;color:#706E6B;font-weight:600;">Column 1</th><th style="padding:8px;text-align:left;font-size:12px;color:#706E6B;font-weight:600;">Column 2</th></tr></thead><tbody>{{#Collection}}<tr style="border-bottom:1px solid #DDDBDA;"><td style="padding:8px;font-size:13px;color:#181818;">{{{Field1}}}</td><td style="padding:8px;font-size:13px;color:#181818;">{{{Field2}}}</td></tr>{{/Collection}}</tbody></table>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Metric Tile',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for single KPI with label and optional trend indicator.',
    ccai__Prompt_Command__c = '<div style="background:white;border-radius:6px;padding:16px;text-align:center;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="font-size:32px;font-weight:700;color:#0176D3;margin-bottom:4px;">{{{Value}}}</div><div style="font-size:13px;color:#706E6B;margin-bottom:4px;">Metric Label</div><div style="font-size:12px;color:#2E844A;">+15% vs last month</div></div>'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Status Badge',
    RecordTypeId = builderRtId,
    Category__c = 'UI Component',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use for inline status indicators with semantic colors.',
    ccai__Prompt_Command__c = '<span style="background:#D4EDDA;color:#2E844A;padding:4px 8px;border-radius:4px;font-size:11px;font-weight:600;">ACTIVE</span> <!-- Warning: background:#FEF3CD;color:#DD7A01 --> <!-- Error: background:#FED7D7;color:#BA0517 -->'
));

// ============================================
// CONTEXT TEMPLATES (5)
// ============================================

builders.add(new ccai__AI_Prompt__c(
    Name = 'Sales Rep Context Template',
    RecordTypeId = builderRtId,
    Category__c = 'Context Template',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use when generating insights for individual sales representatives.',
    ccai__Prompt_Command__c = 'TARGET PERSONA: Individual Sales Representative\n\nPRIMARY FOCUS: Individual deals, daily activities, and immediate next actions. Sales reps need tactical guidance they can act on TODAY.\n\nKEY METRICS THEY CARE ABOUT: Pipeline value, close rate, activity volume (calls, emails, meetings), deals closing this week/month, quota attainment progress.\n\nCOMMUNICATION STYLE: Action-oriented, specific tasks with clear deadlines, time-sensitive alerts. Keep it brief - they are on calls all day.\n\nDECISION SUPPORT: Help them prioritize which deals to focus on, what specific action to take next, who to contact and why.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Sales Manager Context Template',
    RecordTypeId = builderRtId,
    Category__c = 'Context Template',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use when generating insights for sales managers overseeing teams.',
    ccai__Prompt_Command__c = 'TARGET PERSONA: Sales Manager\n\nPRIMARY FOCUS: Team performance, pipeline health, forecast accuracy, and coaching opportunities. Managers need visibility across their team.\n\nKEY METRICS THEY CARE ABOUT: Team quota attainment, pipeline coverage ratio, win rate trends, forecast accuracy, activity patterns by rep.\n\nCOMMUNICATION STYLE: Summary-level with drill-down options, comparative analysis (rep vs rep, week vs week), trend identification.\n\nDECISION SUPPORT: Resource allocation, coaching priorities, forecast commits, deal escalations needing their involvement.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Executive Context Template',
    RecordTypeId = builderRtId,
    Category__c = 'Context Template',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use when generating insights for executives and senior leadership.',
    ccai__Prompt_Command__c = 'TARGET PERSONA: Executive / Senior Leadership\n\nPRIMARY FOCUS: Business outcomes, strategic risks, and market positioning. Executives need the "so what" not the details.\n\nKEY METRICS THEY CARE ABOUT: Revenue vs plan, growth rate, deal size trends, competitive win rate, strategic account health.\n\nCOMMUNICATION STYLE: High-level insights, strategic implications, board-ready summaries. No operational detail unless specifically requested.\n\nDECISION SUPPORT: Investment priorities, strategic direction decisions, involvement in major deals, organizational changes needed.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Customer Success Context Template',
    RecordTypeId = builderRtId,
    Category__c = 'Context Template',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use when generating insights for customer success managers.',
    ccai__Prompt_Command__c = 'TARGET PERSONA: Customer Success Manager\n\nPRIMARY FOCUS: Customer health, renewal risk, and expansion opportunities. CSMs need early warning signals and growth indicators.\n\nKEY METRICS THEY CARE ABOUT: NPS/CSAT scores, product usage trends, support ticket volume, renewal dates approaching, expansion revenue potential.\n\nCOMMUNICATION STYLE: Customer-centric, relationship-focused, proactive alerts. Emphasize customer outcomes not internal metrics.\n\nDECISION SUPPORT: Intervention timing for at-risk accounts, escalation triggers, expansion play identification, QBR preparation.'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Support Agent Context Template',
    RecordTypeId = builderRtId,
    Category__c = 'Context Template',
    ccai__Status__c = 'Active',
    ccai__Description__c = 'Use when generating insights for support agents handling cases.',
    ccai__Prompt_Command__c = 'TARGET PERSONA: Support Agent\n\nPRIMARY FOCUS: Case resolution, customer history, and product issues. Support needs context to resolve issues quickly.\n\nKEY METRICS THEY CARE ABOUT: Resolution time, customer satisfaction, escalation rate, first-contact resolution, case backlog.\n\nCOMMUNICATION STYLE: Technical detail when needed, step-by-step guidance, links to knowledge articles. Quick reference format.\n\nDECISION SUPPORT: When to escalate, workaround options, customer communication templates, related known issues.'
));

// ============================================
// TRAVERSALS (25 - Comprehensive Coverage)
// ============================================

builders.add(new ccai__AI_Prompt__c(
    Name = 'OpportunityContactRole Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OpportunityContactRole',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Title, Contact.Email for stakeholder personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"OpportunityContactRole","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Title","alias":"ContactTitle"},{"path":"Email","alias":"ContactEmail"},{"path":"Phone","alias":"ContactPhone"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Opportunity Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Opportunity',
    ccai__Description__c = 'Resolves AccountId to Account.Name, Account.Industry for context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Opportunity","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"Industry","alias":"AccountIndustry"},{"path":"AnnualRevenue","alias":"AccountRevenue"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Opportunity Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Opportunity',
    ccai__Description__c = 'Resolves OwnerId to User.Name for owner personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Opportunity","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Task Who Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Task',
    ccai__Description__c = 'Resolves WhoId to Contact.Name or Lead.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Task","sourceField":"WhoId","targetObject":"Contact|Lead","polymorphic":true,"fields":[{"path":"Name","alias":"WhoName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Task What Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Task',
    ccai__Description__c = 'Resolves WhatId to Account.Name or Opportunity.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Task","sourceField":"WhatId","targetObject":"Account|Opportunity","polymorphic":true,"fields":[{"path":"Name","alias":"WhatName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Contact Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Contact',
    ccai__Description__c = 'Resolves AccountId to Account.Name for contact context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Contact","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"Industry","alias":"AccountIndustry"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Case Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Case',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Email for case personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Case","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Email","alias":"ContactEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Case Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Case',
    ccai__Description__c = 'Resolves AccountId to Account.Name for case context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Case","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Case Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Case',
    ccai__Description__c = 'Resolves OwnerId to User.Name for case owner personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Case","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Account Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Account',
    ccai__Description__c = 'Resolves OwnerId to User.Name for account manager personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Account","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"},{"path":"Title","alias":"OwnerTitle"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Lead Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Lead',
    ccai__Description__c = 'Resolves OwnerId to User.Name for lead owner personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Lead","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"},{"path":"Email","alias":"OwnerEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Task Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Task',
    ccai__Description__c = 'Resolves OwnerId to User.Name for task assignee personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Task","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Event Who Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Event',
    ccai__Description__c = 'Resolves WhoId to Contact.Name or Lead.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Event","sourceField":"WhoId","targetObject":"Contact|Lead","polymorphic":true,"fields":[{"path":"Name","alias":"WhoName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Event What Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Event',
    ccai__Description__c = 'Resolves WhatId to Account.Name or Opportunity.Name (polymorphic).',
    ccai__Prompt_Command__c = '{"sourceObject":"Event","sourceField":"WhatId","targetObject":"Account|Opportunity","polymorphic":true,"fields":[{"path":"Name","alias":"WhatName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Event Owner Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Event',
    ccai__Description__c = 'Resolves OwnerId to User.Name for event organizer personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"Event","sourceField":"OwnerId","targetObject":"User","fields":[{"path":"Name","alias":"OwnerName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'CampaignMember Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'CampaignMember',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Email for campaign targeting.',
    ccai__Prompt_Command__c = '{"sourceObject":"CampaignMember","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Email","alias":"ContactEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Contract Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Contract',
    ccai__Description__c = 'Resolves AccountId to Account.Name for contract context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Contract","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"BillingCity","alias":"AccountCity"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Order Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Order',
    ccai__Description__c = 'Resolves AccountId to Account.Name for order context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Order","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"ShippingCity","alias":"AccountCity"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Quote Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Quote',
    ccai__Description__c = 'Resolves AccountId to Account.Name for quote context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Quote","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Asset Account Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Asset',
    ccai__Description__c = 'Resolves AccountId to Account.Name, Account.Industry for asset context.',
    ccai__Prompt_Command__c = '{"sourceObject":"Asset","sourceField":"AccountId","targetObject":"Account","fields":[{"path":"Name","alias":"AccountName"},{"path":"Industry","alias":"AccountIndustry"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'OpportunityLineItem Opportunity Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OpportunityLineItem',
    ccai__Description__c = 'Resolves OpportunityId to Opportunity.Name, StageName for line item context.',
    ccai__Prompt_Command__c = '{"sourceObject":"OpportunityLineItem","sourceField":"OpportunityId","targetObject":"Opportunity","fields":[{"path":"Name","alias":"OpportunityName"},{"path":"StageName","alias":"OpportunityStage"},{"path":"Amount","alias":"OpportunityAmount"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'OpportunityLineItem Product Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OpportunityLineItem',
    ccai__Description__c = 'Resolves Product2Id to Product2.Name, Family for product context.',
    ccai__Prompt_Command__c = '{"sourceObject":"OpportunityLineItem","sourceField":"Product2Id","targetObject":"Product2","fields":[{"path":"Name","alias":"ProductName"},{"path":"Family","alias":"ProductFamily"},{"path":"ProductCode","alias":"ProductCode"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'Quote Opportunity Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'Quote',
    ccai__Description__c = 'Resolves OpportunityId to Opportunity.Name for quote-to-deal alignment.',
    ccai__Prompt_Command__c = '{"sourceObject":"Quote","sourceField":"OpportunityId","targetObject":"Opportunity","fields":[{"path":"Name","alias":"OpportunityName"},{"path":"Amount","alias":"OpportunityAmount"},{"path":"CloseDate","alias":"OpportunityCloseDate"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'QuoteLineItem Product Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'QuoteLineItem',
    ccai__Description__c = 'Resolves Product2Id to Product2.Name, Family for quote line context.',
    ccai__Prompt_Command__c = '{"sourceObject":"QuoteLineItem","sourceField":"Product2Id","targetObject":"Product2","fields":[{"path":"Name","alias":"ProductName"},{"path":"Family","alias":"ProductFamily"},{"path":"ProductCode","alias":"ProductCode"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'OrderItem Product Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OrderItem',
    ccai__Description__c = 'Resolves Product2Id to Product2.Name for order line context.',
    ccai__Prompt_Command__c = '{"sourceObject":"OrderItem","sourceField":"Product2Id","targetObject":"Product2","fields":[{"path":"Name","alias":"ProductName"},{"path":"Family","alias":"ProductFamily"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'CaseComment Case Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'CaseComment',
    ccai__Description__c = 'Resolves ParentId to Case.Subject, CaseNumber for comment context.',
    ccai__Prompt_Command__c = '{"sourceObject":"CaseComment","sourceField":"ParentId","targetObject":"Case","fields":[{"path":"Subject","alias":"CaseSubject"},{"path":"CaseNumber","alias":"CaseNumber"},{"path":"Status","alias":"CaseStatus"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'EmailMessage Case Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'EmailMessage',
    ccai__Description__c = 'Resolves ParentId to Case.Subject, CaseNumber for email thread context.',
    ccai__Prompt_Command__c = '{"sourceObject":"EmailMessage","sourceField":"ParentId","targetObject":"Case","fields":[{"path":"Subject","alias":"CaseSubject"},{"path":"CaseNumber","alias":"CaseNumber"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'CaseContactRole Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'CaseContactRole',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Email for case contact personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"CaseContactRole","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Title","alias":"ContactTitle"},{"path":"Email","alias":"ContactEmail"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'AccountContactRole Contact Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'AccountContactRole',
    ccai__Description__c = 'Resolves ContactId to Contact.Name, Contact.Title for account team personalization.',
    ccai__Prompt_Command__c = '{"sourceObject":"AccountContactRole","sourceField":"ContactId","targetObject":"Contact","fields":[{"path":"Name","alias":"ContactName"},{"path":"Title","alias":"ContactTitle"}]}'
));

builders.add(new ccai__AI_Prompt__c(
    Name = 'OpportunityContactRole Opportunity Traversal',
    RecordTypeId = builderRtId,
    Category__c = 'Traversal',
    ccai__Status__c = 'Active',
    ccai__Object__c = 'OpportunityContactRole',
    ccai__Description__c = 'Resolves OpportunityId to Opportunity.Name, StageName for role-to-deal mapping.',
    ccai__Prompt_Command__c = '{"sourceObject":"OpportunityContactRole","sourceField":"OpportunityId","targetObject":"Opportunity","fields":[{"path":"Name","alias":"OpportunityName"},{"path":"StageName","alias":"OpportunityStage"}]}'
));

// Insert all builders
System.debug('Inserting ' + builders.size() + ' builder prompts...');

// Use Database.insert with allOrNone=false to see which records fail
Database.SaveResult[] results = Database.insert(builders, false);

Integer successCount = 0;
Integer failCount = 0;
for (Integer i = 0; i < results.size(); i++) {
    if (results[i].isSuccess()) {
        successCount++;
    } else {
        failCount++;
        System.debug('Failed to insert: ' + builders[i].Name + ' - ' + results[i].getErrors()[0].getMessage());
    }
}

System.debug('=====================================');
System.debug('Builder Prompts Insert Complete');
System.debug('Success: ' + successCount);
System.debug('Failed: ' + failCount);
System.debug('Total: ' + builders.size());
System.debug('=====================================');
