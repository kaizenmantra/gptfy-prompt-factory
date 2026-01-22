// Create 3 ContentNotes with rich context

List<ContentNote> notes = new List<ContentNote>();

// Note 1: CFO Budget Concerns
ContentNote note1 = new ContentNote();
note1.Title = 'CFO Budget Concerns - Jan 15 Call';
note1.Content = Blob.valueOf(
    'Spoke with Sarah Johnson (CFO) after the benefits review meeting. Key takeaways:\n\n' +
    '- Budget is tight - they are comparing our solution to status quo AND Aetna\n' +
    '- Wants to see 3-year TCO, not just Year 1 costs\n' +
    '- Emphasized need for HIPAA compliance documentation for legal team\n' +
    '- Mentioned they are concerned about hidden costs (implementation, training, support)\n' +
    '- Said she needs to present business case to the board by Feb 15\n\n' +
    'ACTION: Prepare comprehensive TCO analysis including all soft costs'
);
notes.add(note1);

// Note 2: HR Director Champion
ContentNote note2 = new ContentNote();
note2.Title = 'HR Director is Champion - Wellness Program';
note2.Content = Blob.valueOf(
    'Lisa Martinez (HR Director) is clearly our internal champion. She is excited about:\n\n' +
    '- Wellness program features (fitness tracking, health coaching, mental health support)\n' +
    '- Modern member portal (mobile app, telemedicine, digital ID cards)\n' +
    '- Employee engagement tools\n\n' +
    'She told me their current provider (legacy insurance company) has terrible technology. ' +
    'Employees constantly complain about the clunky portal and poor customer service.\n\n' +
    'She is willing to advocate internally and help us navigate the approval process. ' +
    'She has good relationship with CFO and can influence decision.\n\n' +
    'ACTION: Keep her updated on progress. Send her case studies on employee satisfaction improvements.'
);
notes.add(note2);

// Note 3: Competitive Threat - Aetna
ContentNote note3 = new ContentNote();
note3.Title = 'Competitive Threat - Aetna in Play';
note3.Content = Blob.valueOf(
    'Learned from VP Operations (Michael Chen) that Aetna is also competing for this deal. Competitive intel:\n\n' +
    '- Aetna came in 15% cheaper on Year 1 pricing\n' +
    '- BUT: Their digital platform is dated, no wellness programs\n' +
    '- McDonald\'s franchise is unhappy with Aetna\'s customer service on another contract\n' +
    '- Aetna is pushing hard on brand recognition and network size\n\n' +
    'OUR DIFFERENTIATORS:\n' +
    '- Superior digital member experience (our strongest advantage)\n' +
    '- Comprehensive wellness programs (HR Director loves this)\n' +
    '- Better customer support (we can prove this with NPS scores)\n' +
    '- More flexible plans for franchise/multi-location setup\n\n' +
    'ACTION: Position on value, not price. Emphasize TCO over 3 years, not just Year 1. ' +
    'Focus on employee satisfaction and retention benefits.'
);
notes.add(note3);

insert notes;

// Query ContentDocuments created for these notes
List<ContentDocument> docs = [SELECT Id, LatestPublishedVersionId FROM ContentDocument 
                               WHERE LatestPublishedVersionId IN :new Set<Id>{note1.Id, note2.Id, note3.Id}];

// Create ContentDocumentLinks
List<ContentDocumentLink> links = new List<ContentDocumentLink>();
for (ContentDocument doc : docs) {
    ContentDocumentLink link = new ContentDocumentLink();
    link.ContentDocumentId = doc.Id;
    link.LinkedEntityId = '006QH00000HjgvlYAB';
    link.ShareType = 'V';
    link.Visibility = 'AllUsers';
    links.add(link);
}
insert links;

System.debug('✅ Created 3 notes and linked to opportunity');
System.debug('Note 1: ' + note1.Id);
System.debug('Note 2: ' + note2.Id);
System.debug('Note 3: ' + note3.Id);
