// Update Evidence Binding builder with new specificity rules

// Get the builder
ccai__AI_Prompt__c evidenceBinding = [
    SELECT Id, Name
    FROM ccai__AI_Prompt__c
    WHERE Name = 'Evidence Binding Rules v2'
      AND RecordType.DeveloperName = 'Builder'
    LIMIT 1
];

// Read the new content (will be pasted manually)
String newContent = '# Evidence Binding Rules (v2)\n\nSee docs/quality-rules/evidence_binding_v2.md for full content';

System.debug('Found builder: ' + evidenceBinding.Id);
System.debug('This script requires manual content update due to size');
System.debug('Use Data Loader or Workbench to import from evidence_binding_v2.md');
System.debug('\nTo update manually:');
System.debug('1. Open: https://agentictso.lightning.force.com/lightning/r/ccai__AI_Prompt__c/' + evidenceBinding.Id + '/view');
System.debug('2. Click Edit');
System.debug('3. Paste content from: docs/quality-rules/evidence_binding_v2.md');
System.debug('4. Save');
