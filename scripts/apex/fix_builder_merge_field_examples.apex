// Fix builder records that contain example merge fields
// GPTfy validates ALL merge fields in prompts, so examples cause validation errors

System.debug('=== Fixing Builder Merge Field Examples ===');

// 1. Fix Stats Strip - replace {{{Value}}} with static example
List<ccai__AI_Prompt__c> statsStrip = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Name = 'Stats Strip' AND ccai__Status__c = 'Active'
];
if (!statsStrip.isEmpty()) {
    statsStrip[0].ccai__Prompt_Command__c = '<div style="display:flex;gap:16px;margin-bottom:20px;"><div style="flex:1;background:white;border-radius:6px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,0.1);"><div style="font-size:28px;font-weight:700;color:#0176D3;margin-bottom:4px;">$15M</div><div style="font-size:13px;color:#706E6B;">Annual Revenue</div></div></div>';
    System.debug('Fixed Stats Strip');
}

// 2. Fix Data Table - replace {{{Field1}}}, {{{Field2}}} with static examples
List<ccai__AI_Prompt__c> dataTable = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Name = 'Data Table' AND ccai__Status__c = 'Active'
];
if (!dataTable.isEmpty()) {
    // Keep Collection iteration but use descriptive placeholders
    dataTable[0].ccai__Prompt_Command__c = '<table style="width:100%;border-collapse:collapse;margin-bottom:16px;"><thead><tr style="background:#F3F3F3;border-bottom:2px solid #DDDBDA;"><th style="padding:8px;text-align:left;font-size:12px;color:#706E6B;font-weight:600;">Name</th><th style="padding:8px;text-align:left;font-size:12px;color:#706E6B;font-weight:600;">Value</th></tr></thead><tbody><tr style="border-bottom:1px solid #DDDBDA;"><td style="padding:8px;font-size:13px;color:#181818;">Sample Name</td><td style="padding:8px;font-size:13px;color:#181818;">Sample Value</td></tr></tbody></table>';
    System.debug('Fixed Data Table - removed placeholder merge fields');
}

// 3. Fix Metric Tile if it has {{{Value}}}
List<ccai__AI_Prompt__c> metricTile = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Name = 'Metric Tile' AND ccai__Status__c = 'Active'
];
if (!metricTile.isEmpty() && metricTile[0].ccai__Prompt_Command__c.contains('{{{Value}}}')) {
    metricTile[0].ccai__Prompt_Command__c = metricTile[0].ccai__Prompt_Command__c.replace('{{{Value}}}', '$250K');
    System.debug('Fixed Metric Tile');
}

// 4. Fix Output Rules - replace triple-brace examples with backtick syntax
List<ccai__AI_Prompt__c> outputRules = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Name = 'GPTfy Merge Field Syntax Rules' AND ccai__Status__c = 'Active'
];
if (!outputRules.isEmpty()) {
    String rules = '=== GPTfy MERGE FIELD SYNTAX RULES ===\n\n';
    rules += 'CRITICAL: Follow these rules exactly when generating prompts with merge fields.\n\n';
    rules += '--- RULE 1: Triple Braces for Values ---\n';
    rules += 'Use triple braces like `{{{FieldName}}}` to output raw values.\n';
    rules += 'Double braces HTML-escape special characters (avoid).\n\n';
    rules += '--- RULE 2: Primary Object Fields - No Prefix ---\n';
    rules += 'Root object fields use just the field name (no object prefix).\n';
    rules += 'Example: `Name`, `Industry`, `AnnualRevenue`\n\n';
    rules += '--- RULE 3: Parent Lookup Fields - Dot Notation ---\n';
    rules += 'Use relationship name dot field: `Owner.Name`, `CreatedBy.Email`\n\n';
    rules += '--- RULE 4: Child Collections - Use DCM Relationship Name ---\n';
    rules += 'Use the EXACT relationshipName from the DCM configuration.\n';
    rules += 'Can be plural OR singular depending on DCM setup.\n';
    rules += 'Syntax: `{{#RelationshipName}}...{{/RelationshipName}}`\n\n';
    rules += '--- RULE 5: Child Fields - MUST Include Collection Prefix ---\n';
    rules += 'Inside iterations, fields MUST include the collection name.\n';
    rules += 'Syntax: `Collection.FieldName` inside the iteration block\n\n';
    rules += '--- RULE 6: Grandchild Fields - Chained Dot Notation ---\n';
    rules += 'For grandchildren, chain the relationship names.\n';
    rules += 'Pattern: `ParentRel.ChildRel.FieldName`\n\n';
    rules += '--- RULE 7: Empty State Handling ---\n';
    rules += 'Use `{{else}}` inside the block for empty state.\n';
    rules += 'Or use inverted section `{{^Collection}}` after the main block.\n\n';
    rules += '--- RULE 8: Conditional Rendering ---\n';
    rules += 'Use `{{#unless Field}}` for negation checks.\n\n';
    rules += '--- RULE 9: Table Structure ---\n';
    rules += 'Table headers MUST be OUTSIDE the iteration loop.\n';
    rules += 'Only row content goes inside the iteration.\n\n';
    rules += '--- OUTPUT FORMAT RULES ---\n';
    rules += '1. Output must be a SINGLE LINE of HTML - no newlines\n';
    rules += '2. Use ONLY inline styles - no CSS classes or style blocks\n';
    rules += '3. No script tags or event handlers\n';
    rules += '4. Start with <div style="..."> and end with </div>';

    outputRules[0].ccai__Prompt_Command__c = rules;
    System.debug('Fixed Output Rules - removed merge field examples');
}

// Update all modified records
List<ccai__AI_Prompt__c> toUpdate = new List<ccai__AI_Prompt__c>();
toUpdate.addAll(statsStrip);
toUpdate.addAll(dataTable);
toUpdate.addAll(metricTile);
toUpdate.addAll(outputRules);

if (!toUpdate.isEmpty()) {
    update toUpdate;
    System.debug('Updated ' + toUpdate.size() + ' builder records');
}

System.debug('=== Done ===');
