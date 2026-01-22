# Implementation Roadmap

**Date**: January 22, 2026  
**Status**: Ready for Phase 1 Implementation  
**Based On**: Phase 0/0B/0C Results + User Technical Guidance

---

## Executive Summary

**Where We Are**:
- ✅ Phase 0/0B/0C Complete (19 variants tested, patterns extracted)
- ✅ Quality Rules Documented (evidence binding, information hierarchy, picklist intelligence)
- ✅ Architectural Strategy Updated
- ✅ User feedback incorporated

**What's Next**: Implement quality rules into production pipeline (Stage08/Stage12)

**Estimated Timeline**: 2 sprints (2-3 weeks)

---

## Sprint 1: Core Quality Rules (Week 1)

**Goal**: Integrate evidence binding, information hierarchy, and basic picklist context into Stage08

**Total Effort**: 10-12 hours

---

### Task 1.1: Evidence Binding v2 Integration (3 hours)

**Objective**: Inject evidence binding rules into prompt assembly

**Implementation**:

1. **Create Static Resource** (30 min)
   ```
   File: evidence_binding_rules
   Content: Condensed version of evidence_binding_v2.md
   Type: Text
   ```

2. **Update Stage08_PromptAssembly.cls** (1.5 hrs)
   ```apex
   private String loadEvidenceBindingRules() {
       // Load from static resource or inline
       return 'EVIDENCE BINDING RULES:\n\n' +
              'Every claim must be traceable. No claim should lead with its source.\n\n' +
              'FORMAT LEVELS:\n' +
              '1. EMBEDDED (80%): "This $1.5M deal needs CFO engagement"\n' +
              '2. PARENTHETICAL (15%): "No sponsor. (Source: Contact Roles)"\n' +
              '3. INLINE (5%): "Stage stalled" → Based on: Stage Age = 45 days\n' +
              '4. COLLAPSIBLE (always): <details><summary>Data Sources</summary>...</details>\n\n' +
              'NEVER:\n' +
              '- Start sentences with "Evidence:"\n' +
              '- Use API field names in visible text\n' +
              '- List field values without insight\n\n' +
              'ALWAYS:\n' +
              '- Lead with the "so what"\n' +
              '- Weave numbers into natural sentences\n' +
              '- Provide collapsible data sources at end\n';
   }
   
   // In prompt assembly method
   String finalPrompt = 
       businessContext +
       '\n\n' + loadEvidenceBindingRules() +
       '\n\n' + analyticalPatterns +
       '\n\n' + dataPayload;
   ```

3. **Test** (1 hr)
   - Unit test: Verify rules injected
   - Integration test: Generate prompt for test opportunity
   - Validate output doesn't have "Evidence:" prefix

**Success Criteria**:
- ✅ Evidence rules injected into every prompt
- ✅ No "Evidence:" anti-pattern in generated outputs
- ✅ Data sources section at end (collapsible)

---

### Task 1.2: Information Hierarchy Integration (2 hours)

**Objective**: Inject information hierarchy rules into prompt assembly

**Implementation**:

1. **Create Static Resource** (30 min)
   ```
   File: information_hierarchy_rules
   Content: Condensed version of information_hierarchy.md
   Type: Text
   ```

2. **Update Stage08_PromptAssembly.cls** (1 hr)
   ```apex
   private String loadInformationHierarchyRules() {
       return 'INFORMATION HIERARCHY RULES:\n\n' +
              'Lead with insight, support with evidence. Surface urgency, bury detail.\n\n' +
              'ABOVE-THE-FOLD PRIORITIES (first 400px):\n' +
              '1. ZONE 1 (0-100px): Critical alerts - overdue/deal-killer items\n' +
              '2. ZONE 2 (100-200px): Key metrics - 4-6 stat cards\n' +
              '3. ZONE 3 (200-350px): Executive summary - 2-3 sentence bottom line\n\n' +
              'BELOW-THE-FOLD (scroll for detail):\n' +
              '4. ZONE 4 (350-400px): Section headers with counts\n' +
              '5. ZONE 5 (400px+): Detailed analysis\n' +
              '6. ZONE 6 (end): Data sources (collapsible)\n\n' +
              'CRITICAL RULES:\n' +
              '- If urgent items exist, they MUST be in Zone 1\n' +
              '- Maximum 2-3 alerts above fold\n' +
              '- Every risk needs a mitigation\n' +
              '- Every action needs owner + date\n';
   }
   ```

3. **Test** (30 min)
   - Verify hierarchy rules injected
   - Generate sample output, check zone compliance

**Success Criteria**:
- ✅ Hierarchy rules injected into every prompt
- ✅ Critical alerts appear above fold in generated outputs
- ✅ Executive summary visible without scrolling

---

### Task 1.3: Basic Picklist Context (4 hours)

**Objective**: Extract and inject OpportunityStage picklist context (simplified version)

**Implementation**:

1. **Update Stage05_FieldSelection.cls** (2 hrs)
   ```apex
   /**
    * @description Extract basic picklist metadata for Opportunity.StageName
    * @return Map with stage values and probabilities
    */
   private Map<String, Object> extractOpportunityStageContext() {
       Map<String, Object> context = new Map<String, Object>();
       
       // Get picklist values from Describe
       Schema.DescribeFieldResult stageField = 
           Opportunity.StageName.getDescribe();
       List<Schema.PicklistEntry> entries = stageField.getPicklistValues();
       
       // Query OpportunityStage for probability mapping
       Map<String, OpportunityStage> stageMap = new Map<String, OpportunityStage>();
       for (OpportunityStage stage : [
           SELECT ApiName, MasterLabel, DefaultProbability, SortOrder
           FROM OpportunityStage
           WHERE IsActive = true
           ORDER BY SortOrder
       ]) {
           stageMap.put(stage.MasterLabel, stage);
       }
       
       // Build value list with probabilities
       List<Map<String, Object>> valueList = new List<Map<String, Object>>();
       Integer order = 1;
       for (Schema.PicklistEntry entry : entries) {
           if (entry.isActive()) {
               Map<String, Object> valueData = new Map<String, Object>();
               valueData.put('value', entry.getValue());
               valueData.put('label', entry.getLabel());
               valueData.put('order', order++);
               
               // Add probability if available
               if (stageMap.containsKey(entry.getLabel())) {
                   valueData.put('probability', 
                       stageMap.get(entry.getLabel()).DefaultProbability);
               }
               
               valueList.add(valueData);
           }
       }
       
       context.put('fieldName', 'StageName');
       context.put('values', valueList);
       context.put('totalValues', valueList.size());
       
       return context;
   }
   
   // In execute() method, store in outputs
   result.outputs.put('opportunityStageContext', extractOpportunityStageContext());
   ```

2. **Update Stage08_PromptAssembly.cls** (1.5 hrs)
   ```apex
   /**
    * @description Build field context section for picklists
    * @param stageContext Map from Stage05
    * @param currentStage Current opportunity stage
    * @return Formatted context block
    */
   private String buildPicklistContextSection(
       Map<String, Object> stageContext,
       String currentStage
   ) {
       if (stageContext == null) return '';
       
       StringBuilder context = new StringBuilder();
       context.append('=== FIELD CONTEXT ===\n\n');
       context.append('FIELD: Opportunity.StageName\n');
       context.append('Current Value: "' + currentStage + '"\n\n');
       
       List<Object> values = (List<Object>) stageContext.get('values');
       Integer totalValues = (Integer) stageContext.get('totalValues');
       Integer currentPosition = null;
       
       context.append('Available Values (' + totalValues + ' total):\n');
       
       for (Object valueObj : values) {
           Map<String, Object> valueData = (Map<String, Object>) valueObj;
           String value = (String) valueData.get('value');
           Integer order = (Integer) valueData.get('order');
           Decimal probability = (Decimal) valueData.get('probability');
           
           String marker = '';
           if (value == currentStage) {
               marker = ' ← CURRENT';
               currentPosition = order;
           }
           
           context.append('  ' + order + '. ' + value);
           if (probability != null) {
               context.append(' (' + probability.intValue() + '% probability)');
           }
           context.append(marker + '\n');
       }
       
       // Add analysis
       if (currentPosition != null) {
           context.append('\nAnalysis: ');
           if (currentPosition <= totalValues / 3) {
               context.append('This is an EARLY stage ');
           } else if (currentPosition <= 2 * totalValues / 3) {
               context.append('This is a MID stage ');
           } else {
               context.append('This is a LATE stage ');
           }
           context.append('(position ' + currentPosition + ' of ' + totalValues + ').\n');
           context.append('IMPORTANT: When evaluating probability, consider the expected ');
           context.append('probability for this stage. A "low" probability may be NORMAL ');
           context.append('for an early stage.\n');
       }
       
       context.append('\n---\n\n');
       return context.toString();
   }
   
   // In prompt assembly
   String finalPrompt = 
       businessContext +
       '\n\n' + buildPicklistContextSection(stageContext, currentStage) +
       '\n\n' + evidenceBindingRules +
       '\n\n' + hierarchyRules +
       '\n\n' + analyticalPatterns +
       '\n\n' + dataPayload;
   ```

3. **Test** (30 min)
   - Unit test: Verify stage context extraction
   - Integration test: Verify injected into prompt
   - Validate output understands stage-appropriate probability

**Success Criteria**:
- ✅ OpportunityStage context extracted in Stage05
- ✅ Context injected into Stage08 prompt
- ✅ LLM understands stage 2 of 6 vs stage 5 of 6
- ✅ False positive rate reduced (20% not flagged as risk in early stage)

---

### Task 1.4: Update Stage12 Quality Audit (2 hours)

**Objective**: Add compliance checks for evidence binding and hierarchy

**Implementation**:

1. **Add Evidence Binding Check** (1 hr)
   ```apex
   /**
    * @description Score evidence appropriateness (v2 compliance)
    * @param output Generated HTML
    * @return Score 1-10
    */
   private Decimal scoreEvidenceAppropriate(String output) {
       // Check for anti-patterns
       Boolean hasEvidenceFirst = output.contains('Evidence:');
       Boolean hasAPINames = Pattern.matches('.*Opportunity\\.[A-Z].*', output);
       
       // Check for collapsible data sources
       Boolean hasCollapsibleSource = output.contains('<details>') && 
                                      output.contains('Data Sources');
       
       // Check for natural embedding (numbers in sentences without "Evidence:")
       Boolean hasNaturalEmbedding = Pattern.matches('.*\\$[0-9,\\.]+.*', output) &&
                                     !output.contains('Evidence: Amount');
       
       if (hasEvidenceFirst) return 3.0; // Fails v2 - evidence-first anti-pattern
       if (hasAPINames) return 5.0; // API names in user-facing text
       if (!hasCollapsibleSource) return 6.0; // Missing data sources section
       if (hasNaturalEmbedding && hasCollapsibleSource) return 9.0; // Excellent v2 compliance
       
       return 7.0; // Acceptable
   }
   ```

2. **Add Hierarchy Check** (1 hr)
   ```apex
   /**
    * @description Score information hierarchy compliance
    * @param output Generated HTML
    * @return Score 1-10
    */
   private Decimal scoreHierarchyCompliance(String output) {
       // Extract first 500 characters (above-the-fold approximation)
       String aboveFold = output.substring(0, Math.min(500, output.length()));
       
       // Check for critical alerts in Zone 1
       Boolean hasEarlyAlerts = aboveFold.containsIgnoreCase('CRITICAL') ||
                                aboveFold.containsIgnoreCase('WARNING') ||
                                aboveFold.contains('alert');
       
       // Check for stat cards or metrics in Zone 2
       Boolean hasEarlyMetrics = aboveFold.contains('stat') ||
                                 aboveFold.matches('.*\\$[0-9,\\.]+.*') ||
                                 aboveFold.contains('%');
       
       // Check if "Evidence:" or detailed citations appear early (bad)
       Boolean hasBuriedLead = aboveFold.contains('Evidence:');
       
       if (hasBuriedLead) return 4.0; // Evidence leading - hierarchy violated
       if (!hasEarlyMetrics) return 6.0; // Missing key metrics above fold
       if (hasEarlyAlerts && hasEarlyMetrics) return 9.0; // Excellent hierarchy
       
       return 7.0; // Acceptable
   }
   ```

3. **Update Weighted Score Calculation**
   ```apex
   private Decimal calculateOverallScore(Map<String, Object> scorecard) {
       Decimal evidenceBinding = scoreEvidenceAppropriate(output) * 0.20; // 20% weight
       Decimal diagnosticDepth = getScore(scorecard, 'diagnosticDepth') * 0.15;
       Decimal visualQuality = getScore(scorecard, 'visualQuality') * 0.15;
       Decimal hierarchyCompliance = scoreHierarchyCompliance(output) * 0.10; // 10% weight
       Decimal dataAccuracy = getScore(scorecard, 'dataAccuracy') * 0.10;
       Decimal personaFit = getScore(scorecard, 'personaFit') * 0.10;
       Decimal actionability = getScore(scorecard, 'actionability') * 0.10;
       Decimal businessValue = getScore(scorecard, 'businessValue') * 0.10;
       
       return (evidenceBinding + diagnosticDepth + visualQuality + hierarchyCompliance +
               dataAccuracy + personaFit + actionability + businessValue).setScale(2);
   }
   ```

**Success Criteria**:
- ✅ Evidence binding scored accurately
- ✅ Hierarchy compliance scored accurately
- ✅ Overall score reflects quality rule compliance

---

### Task 1.5: Validation Testing (1-2 hours)

**Objective**: Regenerate Phase 0C outputs and compare

**Test Cases**:

1. **Regenerate V36 (Risk + Metrics + Visual)**
   - Old score: 75.0/100
   - Expected new score: 78-82/100
   - Expected improvements: No "Evidence:" prefix, critical risks above fold

2. **Regenerate V30 (Tables Only)**
   - Old score: 61.7/100
   - Expected new score: 65-70/100
   - Expected improvements: Better hierarchy, summary before details

3. **Regenerate V24 (Timeline Isolated)**
   - Old score: 71.2/100
   - Expected new score: 73-77/100
   - Expected improvements: Stage-aware timeline analysis

**Validation**:
- Compare old vs new HTML outputs
- Measure false positive rate (20% probability flagged as risk)
- User visual review of 2-3 key outputs

**Success Criteria**:
- ✅ Average score improvement: +3 to +5 points
- ✅ False positive rate: <10% (down from ~30%)
- ✅ User feedback: "Better scannability, more accurate insights"

---

## Sprint 2: Advanced Features (Week 2)

**Goal**: Implement full picklist intelligence architecture and priority scoring

**Total Effort**: 16-20 hours

---

### Task 2.1: Full Picklist Intelligence Architecture (12-16 hours)

**Objective**: Implement 3-layer picklist metadata system

**Implementation**: Follow [`picklist_intelligence_architecture.md`](./picklist_intelligence_architecture.md)

**Key Deliverables**:

1. **Custom Object**: `Picklist_Value_Info__c` (2 hrs)
   - All fields defined
   - External ID on `Unique_Key__c`
   - Page layout and security

2. **Custom Metadata Type**: `Picklist_Annotation__mdt` (1 hr)
   - For admin-defined annotations
   - Example records for testing

3. **Named Credential**: `SalesforceOrgAPI` (1 hr)
   - OAuth setup
   - Test connectivity

4. **Apex Classes**: (6-8 hrs)
   - `PicklistIntelligenceService` (discover fields)
   - `SpecialPicklistRegistry` (identify special fields)
   - `OpportunityStageEnricher`, `CaseStatusEnricher`, `LeadStatusEnricher`
   - `PicklistMetadataSyncJob` (scheduled sync)
   - `PicklistIntelligenceAPI` (runtime queries)

5. **Integration**: (2-3 hrs)
   - Update Stage05 to trigger sync
   - Update Stage08 to query cached metadata
   - Test with Opportunity, Case, Lead

6. **Testing**: (1-2 hrs)
   - Unit tests for all classes
   - Integration test with real data
   - Validate cache populated correctly

**Success Criteria**:
- ✅ Picklist metadata synced to local cache
- ✅ Stage08 queries cache (no runtime callouts)
- ✅ Works for Opportunity, Case, Lead
- ✅ Extensible to custom picklists via annotations

---

### Task 2.2: AI Priority Scoring (3-4 hours)

**Objective**: Add intelligent sorting of findings by business impact

**Implementation**:

1. **Update Prompt Template** (1 hr)
   ```
   After completing your analysis, score each risk/finding on business impact (1-10):
   - 10: Deal-killing issue (overdue deliverable blocking approval)
   - 7-9: Significant gap (missing champion, budget concern)
   - 4-6: Moderate concern (slow velocity)
   - 1-3: Minor observation
   
   Then sort your findings by score (highest first). Only show top 3 in Zone 1 (alerts).
   ```

2. **Update Stage08** (1 hr)
   - Add priority scoring instruction to prompt
   - Test with sample opportunities

3. **Validate Sorting** (1-2 hrs)
   - Generate outputs for 5 different opportunities
   - Verify critical items appear first
   - Validate sorting logic

**Success Criteria**:
- ✅ LLM scores findings 1-10
- ✅ Findings sorted by impact score
- ✅ Top 3 in Zone 1 (alerts)
- ✅ Lower priority in Zone 5 (detailed analysis)

---

### Task 2.3: Historical Velocity Benchmarking (2 hours)

**Objective**: Add "typical duration" to stage context

**Implementation**:

1. **Query Historical Data** (1 hr)
   ```apex
   /**
    * @description Calculate average days-in-stage for closed-won opportunities
    * @return Map of stage name to avg days
    */
   private Map<String, Decimal> calculateHistoricalVelocity() {
       Map<String, List<Decimal>> stageDurations = new Map<String, List<Decimal>>();
       
       List<OpportunityFieldHistory> history = [
           SELECT Field, OldValue, NewValue, CreatedDate, OpportunityId
           FROM OpportunityFieldHistory
           WHERE Field = 'StageName'
           AND OpportunityId IN (
               SELECT Id FROM Opportunity 
               WHERE IsWon = true 
               AND CloseDate >= LAST_N_DAYS:180
           )
           ORDER BY OpportunityId, CreatedDate
       ];
       
       // Calculate days in each stage
       // ... (complex logic to parse history)
       
       // Average by stage
       Map<String, Decimal> avgDays = new Map<String, Decimal>();
       for (String stage : stageDurations.keySet()) {
           List<Decimal> days = stageDurations.get(stage);
           Decimal sum = 0;
           for (Decimal d : days) sum += d;
           avgDays.put(stage, sum / days.size());
       }
       
       return avgDays;
   }
   ```

2. **Add to Field Context** (30 min)
   ```apex
   // In buildPicklistContextSection()
   if (historicalVelocity.containsKey(value)) {
       context.append(' (Typical duration: ' + 
                     historicalVelocity.get(value).intValue() + ' days)');
   }
   ```

3. **Test** (30 min)
   - Verify calculation
   - Validate injected into context
   - Test with opportunities at different stages

**Success Criteria**:
- ✅ Historical velocity calculated
- ✅ Added to stage context
- ✅ LLM uses to assess if stage duration is normal or concerning

---

## Sprint 3: Polish & Production (Week 3 - Optional)

**Goal**: Refine based on user feedback, add monitoring

**Tasks**:

1. **User Feedback Loop** (2 hrs)
   - Generate 10 sample outputs
   - User reviews for quality
   - Collect feedback on false positives, scannability, accuracy

2. **Iteration Based on Feedback** (4-6 hrs)
   - Adjust quality rules if needed
   - Refine picklist context format
   - Tune priority scoring thresholds

3. **Monitoring Dashboard** (2-3 hrs)
   - Track Stage12 scores over time
   - Alert on quality degradation
   - Compare before/after Phase 1 metrics

4. **Documentation** (2 hrs)
   - Update admin guide
   - Create troubleshooting guide
   - Document known limitations

---

## Success Metrics

### Sprint 1 Targets

**Quality Scores** (Stage12):
- Average score: 75+ (up from 73.3 baseline)
- Evidence binding dimension: 8.0+ (was N/A)
- Hierarchy compliance: 8.0+ (was N/A)

**False Positive Rate**:
- Target: <10% (down from ~30%)
- Test: 20% probability in early stage not flagged as risk

**User Feedback**:
- "Better scannability" - 4/5 rating
- "More accurate insights" - 4/5 rating
- "Fewer false alarms" - 4/5 rating

---

### Sprint 2 Targets

**Picklist Intelligence**:
- 3+ object types supported (Opportunity, Case, Lead)
- Cache refresh time: <5 minutes for 100 fields
- Runtime query time: <50ms

**Priority Scoring**:
- 90%+ of critical items appear in Zone 1
- User agreement with priority ranking: 80%+

**Historical Velocity**:
- Calculation accuracy: 90%+ match manual analysis
- Velocity insights in 80%+ of opportunity outputs

---

### Sprint 3 Targets

**Production Readiness**:
- Zero critical bugs
- Performance: <3 second prompt generation
- Monitoring: Daily quality score tracking
- Documentation: 90%+ admin questions answerable from docs

---

## Risk Mitigation

### Risk 1: LLM Ignores Quality Rules

**Mitigation**:
- Use strong directive language ("NEVER", "ALWAYS", "MUST")
- Include anti-pattern examples (what NOT to do)
- Test with multiple prompts to validate consistency

**Backup Plan**: Add post-processing rules in Apex to enforce format

---

### Risk 2: Picklist Sync Job Fails

**Mitigation**:
- Implement robust error handling
- Log failures to custom object
- Alert admin if sync fails 3 times in a row

**Backup Plan**: Fall back to Describe API at runtime if cache is stale

---

### Risk 3: Performance Degradation

**Mitigation**:
- Profile Stage08 execution time before/after
- Set timeout limits on picklist sync
- Use selective SOQL queries (indexed fields only)

**Backup Plan**: Implement async prompt generation if >5 seconds

---

## Decision Points

### Decision 1: Picklist Scope

**Options**:
- A) Sprint 1: Opportunity.StageName only
- B) Sprint 1: Opportunity + Case + Lead
- C) Sprint 2: Full architecture with all picklists

**Recommendation**: **Option A** (Sprint 1), **Option C** (Sprint 2)
- Rationale: Start simple, prove value, then scale

---

### Decision 2: Quality Rule Format

**Options**:
- A) Static Resources (deployable, version-controlled)
- B) Custom Metadata (admin-editable, no deployment)
- C) Inline in Apex (fastest, no external dependency)

**Recommendation**: **Option C** (Sprint 1), **Option A** (Sprint 2)
- Rationale: Inline for speed, migrate to Static Resources for maintainability

---

### Decision 3: Testing Approach

**Options**:
- A) Unit tests only
- B) Unit tests + integration tests
- C) Unit tests + integration tests + user validation

**Recommendation**: **Option C**
- Rationale: Quality is subjective; need user feedback

---

## Next Steps

**Immediate Actions**:

1. **Review This Roadmap** (30 min)
   - User confirms priorities
   - Adjust timeline if needed
   - Approve Sprint 1 scope

2. **Create Sprint 1 Tasks** (15 min)
   - Add tasks to project board
   - Assign ownership
   - Set deadlines

3. **Begin Task 1.1** (Evidence Binding)
   - Estimated start: Today
   - Estimated completion: 3 hours

**Weekly Checkpoints**:
- Monday: Sprint planning
- Wednesday: Mid-sprint review
- Friday: Sprint demo + retrospective

---

**Document Created**: January 22, 2026  
**Status**: Ready for User Review & Approval  
**Recommended Start Date**: Immediately (Sprint 1, Task 1.1)
