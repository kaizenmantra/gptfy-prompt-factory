// Update Opportunity with enriched Description and NextStep

Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = '006QH00000HjgvlYAB'];

opp.Description = 'McDonald\'s franchise group (50 locations, 2,500 employees) seeking comprehensive employee health insurance. ' +
    'Currently evaluating our solution vs. Aetna vs. status quo. ' +
    'CFO (Sarah Johnson) focused on 3-year TCO and HIPAA compliance - budget approval needed by Feb 15. ' +
    'HR Director (Lisa Martinez) is internal champion, loves wellness programs. ' +
    'VP Operations (Michael Chen) is final decision maker. ' +
    'KEY RISKS: (1) Overdue ROI analysis requested by CFO, (2) Aetna is 15% cheaper on Year 1, (3) Budget constraints. ' +
    'KEY OPPORTUNITIES: (1) Superior digital platform, (2) Wellness programs, (3) Champion advocacy, (4) Poor experience with Aetna on other contracts.';

opp.NextStep = 'CFO Meeting on Jan 27 - present 3-year TCO analysis, HIPAA compliance documentation, and competitive comparison to Aetna. ' +
    'Must address budget concerns and demonstrate value over price.';

update opp;

System.debug('✅ Opportunity updated with enriched Description and NextStep');
System.debug('Description length: ' + opp.Description.length());
System.debug('NextStep length: ' + opp.NextStep.length());
