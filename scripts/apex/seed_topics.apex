// Seed Topics for Builder Prompt Classification
// Run this once to create all foundational topics

List<Topic> topicsToCreate = new List<Topic>();
Set<String> existingTopics = new Set<String>();

// Get existing topics to avoid duplicates
for (Topic t : [SELECT Name FROM Topic]) {
    existingTopics.add(t.Name);
}

// Helper method to add topic if it doesn't exist
void addTopic(String topicName, String description) {
    if (!existingTopics.contains(topicName)) {
        topicsToCreate.add(new Topic(
            Name = topicName,
            Description = description
        ));
    }
}

// Pattern Types (8)
addTopic('Risk Assessment', 'Analyzes risks, gaps, and missing stakeholders');
addTopic('Timeline Analysis', 'Analyzes deal velocity, stage duration, and activity patterns');
addTopic('Metrics Calculation', 'Calculates key metrics and KPIs');
addTopic('Stakeholder Mapping', 'Identifies stakeholder gaps and engagement patterns');
addTopic('Root Cause Analysis', 'Diagnoses underlying issues and patterns');
addTopic('Executive Summary', 'Creates high-level executive summaries');
addTopic('Next Action', 'Recommends specific next steps and actions');
addTopic('Win Loss Analysis', 'Analyzes win/loss patterns and predictive signals');

// UI Component Types (7)
addTopic('Stat Card', 'Large number tiles for key metrics');
addTopic('Alert Box', 'Colored alert boxes for risks, warnings, successes');
addTopic('Progress Bar', 'Visual progress indicators');
addTopic('Timeline Visual', 'Timeline and milestone visualizations');
addTopic('Table', 'Structured data tables');
addTopic('Card Layout', 'Card-based layouts for content grouping');
addTopic('Page Header', 'Page headers with gradients and branding');

// Quality Rules (4)
addTopic('Evidence Binding', 'Citation and evidence binding rules');
addTopic('Information Hierarchy', '6-zone priority system for content layout');
addTopic('Insight-Led Design', 'Insight-first, evidence-supported approach');
addTopic('Priority Scoring', 'Business impact scoring and sorting');

// Priority Levels (3)
addTopic('P0', 'Highest priority - always include');
addTopic('P1', 'High priority - frequently used');
addTopic('P2', 'Medium priority - situational use');

// Maturity Levels (3)
addTopic('Production-Ready', 'Validated and ready for production use');
addTopic('Phase-1-Ready', 'Ready for Phase 1 implementation');
addTopic('Experimental', 'Experimental - testing phase');

// Object Context (6)
addTopic('Opportunity', 'For Opportunity object analysis');
addTopic('Case', 'For Case object analysis');
addTopic('Account', 'For Account object analysis');
addTopic('Contact', 'For Contact object analysis');
addTopic('Lead', 'For Lead object analysis');
addTopic('Multi-Object', 'Works across multiple objects');

// Industry Context (5)
addTopic('Healthcare', 'Healthcare industry heuristics and patterns');
addTopic('Financial Services', 'Financial services industry context');
addTopic('Manufacturing', 'Manufacturing industry context');
addTopic('Technology', 'Technology industry context');
addTopic('Retail', 'Retail industry context');

// Visual Hierarchy (2)
addTopic('Above-the-Fold', 'Content that should appear above the fold');
addTopic('Below-the-Fold', 'Content that can appear below the fold');

// Personas (2)
addTopic('Sales', 'Sales rep persona - action-oriented');
addTopic('Executive', 'Executive persona - high-level insights');

// Insert topics
if (!topicsToCreate.isEmpty()) {
    insert topicsToCreate;
    System.debug('✅ Created ' + topicsToCreate.size() + ' new topics');
    System.debug('Topics created: ' + topicsToCreate);
} else {
    System.debug('ℹ️ All topics already exist');
}

// Query all topics for verification
List<Topic> allTopics = [SELECT Name, Description FROM Topic ORDER BY Name];
System.debug('📊 Total topics in org: ' + allTopics.size());
