// Add topic assignments to complete builders
System.debug('=== ADDING TOPICS TO COMPLETE BUILDERS ===');

// Get builder IDs
Map<String, Id> builderMap = new Map<String, Id>();
for (ccai__AI_Prompt__c b : [SELECT Id, Name FROM ccai__AI_Prompt__c 
                             WHERE RecordType.DeveloperName = 'Builder']) {
    builderMap.put(b.Name, b.Id);
}

// Get topic IDs
Map<String, Id> topicMap = new Map<String, Id>();
for (Topic t : [SELECT Id, Name FROM Topic 
                WHERE Name IN ('Evidence Binding', 'Insight-Led Design', 'P0', 
                              'Risk Assessment', 'Opportunity', 'Stat Card', 
                              'Alert Box', 'Above-the-Fold', 'Healthcare', 
                              'Context Template', 'P1')]) {
    topicMap.put(t.Name, t.Id);
}

System.debug('Builders found: ' + builderMap.size());
System.debug('Topics found: ' + topicMap.size());

List<TopicAssignment> assignments = new List<TopicAssignment>();

// Evidence Binding topics
if (builderMap.containsKey('Evidence Binding Rules v2')) {
    Id builderId = builderMap.get('Evidence Binding Rules v2');
    if (topicMap.containsKey('Evidence Binding')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Evidence Binding')));
    }
    if (topicMap.containsKey('Insight-Led Design')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Insight-Led Design')));
    }
    if (topicMap.containsKey('P0')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('P0')));
    }
}

// Risk Assessment topics
if (builderMap.containsKey('Risk Assessment Pattern')) {
    Id builderId = builderMap.get('Risk Assessment Pattern');
    if (topicMap.containsKey('Risk Assessment')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Risk Assessment')));
    }
    if (topicMap.containsKey('Opportunity')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Opportunity')));
    }
    if (topicMap.containsKey('P0')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('P0')));
    }
}

// Stat Card topics
if (builderMap.containsKey('Stat Card Component')) {
    Id builderId = builderMap.get('Stat Card Component');
    if (topicMap.containsKey('Stat Card')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Stat Card')));
    }
    if (topicMap.containsKey('Above-the-Fold')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Above-the-Fold')));
    }
    if (topicMap.containsKey('P0')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('P0')));
    }
}

// Alert Box topics
if (builderMap.containsKey('Alert Box Component')) {
    Id builderId = builderMap.get('Alert Box Component');
    if (topicMap.containsKey('Alert Box')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Alert Box')));
    }
    if (topicMap.containsKey('Above-the-Fold')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Above-the-Fold')));
    }
    if (topicMap.containsKey('P0')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('P0')));
    }
}

// Healthcare topics
if (builderMap.containsKey('Healthcare Payer Context')) {
    Id builderId = builderMap.get('Healthcare Payer Context');
    if (topicMap.containsKey('Healthcare')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Healthcare')));
    }
    if (topicMap.containsKey('Context Template')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('Context Template')));
    }
    if (topicMap.containsKey('P1')) {
        assignments.add(new TopicAssignment(EntityId = builderId, TopicId = topicMap.get('P1')));
    }
}

insert assignments;
System.debug('✅ Created ' + assignments.size() + ' topic assignments');
System.debug('✅ TOPICS ADDED TO ALL COMPLETE BUILDERS');
