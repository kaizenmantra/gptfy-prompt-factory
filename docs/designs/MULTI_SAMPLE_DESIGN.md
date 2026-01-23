# Multi-Sample Data Structure Design

**Task**: 2.1 - Design multi-sample data structure for Stage 4
**Author**: Opus
**Date**: 2026-01-23
**Status**: Design Complete

---

## Overview

This document defines the data structures and flow for supporting multiple sample records (MVP: 3 records) in the Prompt Factory pipeline. The goal is to enable richer data pattern analysis by examining multiple records instead of one.

---

## Current State (Single Sample)

### Input Flow
```
User Input: sampleRecordId = "006ABC123"
     ↓
PF_Run__c.Sample_Record_Id__c = "006ABC123"
     ↓
Stage 4: Query data for ONE record
     ↓
Output: dataAvailability = { "Task": 5, "Contact": 3, "OpportunityContactRole": 2 }
```

### Limitations
- Single snapshot: Can't detect patterns across records
- No variance analysis: "Amount = $500K" tells us nothing about typical deals
- Field relevance guessing: We don't know if a field is usually populated or just happened to be

---

## New Design (Multi-Sample)

### Input Flow
```
User Input: sampleRecordIds = "006ABC123, 006DEF456, 006GHI789"
     ↓
PF_Run__c.Sample_Record_Ids__c = "006ABC123,006DEF456,006GHI789"  (new field)
     ↓
Stage 4: Query data for EACH record, then AGGREGATE
     ↓
Output: multiSampleProfile = {
    sampleCount: 3,
    samples: [...],           // Per-sample detail
    aggregated: {...},        // Cross-sample aggregation
    patterns: {...}           // Detected patterns
}
```

---

## Data Structures

### 1. Input: Sample Record IDs

**Field on PF_Run__c:**
```
Field Name: Sample_Record_Ids__c
Type: Long Text Area (1000 chars)
Format: Comma-separated Salesforce IDs
Example: "006ABC123,006DEF456,006GHI789"
```

**Parsing in Apex:**
```apex
List<String> sampleIds = new List<String>();
if (String.isNotBlank(sampleRecordIdsRaw)) {
    for (String id : sampleRecordIdsRaw.split(',')) {
        String trimmedId = id.trim();
        if (String.isNotBlank(trimmedId) && trimmedId.length() >= 15) {
            sampleIds.add(trimmedId);
        }
    }
}
// Limit to 5 samples max (MVP: 3)
if (sampleIds.size() > 5) {
    sampleIds = sampleIds.subList(0, 5);
}
```

### 2. Stage 4 Output: MultiSampleProfile

```apex
/**
 * Multi-sample data profile returned by Stage 4
 */
public class MultiSampleProfile {
    // Basic info
    public Integer sampleCount;                    // Number of samples analyzed
    public String rootObject;                      // e.g., "Opportunity"
    public List<String> sampleIds;                 // IDs analyzed

    // Per-sample data
    public List<SampleData> samples;               // Detailed per-sample info

    // Aggregated metrics
    public Map<String, ObjectAggregation> objectAggregations;  // Per object

    // Detected patterns
    public List<DataPattern> patterns;             // Cross-sample patterns

    // Summary for LLM
    public String analysisSummary;                 // Human-readable summary
}

/**
 * Data from a single sample record
 */
public class SampleData {
    public String recordId;
    public String recordName;                      // e.g., "Acme Corp - Enterprise Deal"
    public Map<String, Integer> childRecordCounts; // Object → count for this sample
    public Map<String, Object> keyFieldValues;     // Important field values (Amount, Stage, etc.)
}

/**
 * Aggregated metrics for one object across all samples
 */
public class ObjectAggregation {
    public String objectName;
    public Integer samplesWithData;                // How many samples have this object (e.g., 3/3)
    public Integer minCount;                       // Min records across samples
    public Integer maxCount;                       // Max records across samples
    public Decimal avgCount;                       // Average records
    public Integer totalCount;                     // Sum of all records
    public Boolean isConsistent;                   // Same count across all samples?
}

/**
 * A detected cross-sample pattern
 */
public class DataPattern {
    public String patternType;                     // CONSISTENCY, VARIANCE, GAP, ANOMALY
    public String description;                     // Human-readable description
    public String objectName;                      // Related object (optional)
    public String fieldName;                       // Related field (optional)
    public String severity;                        // INFO, WARNING, INSIGHT
}
```

### 3. Example Output

```json
{
    "sampleCount": 3,
    "rootObject": "Opportunity",
    "sampleIds": ["006ABC123", "006DEF456", "006GHI789"],

    "samples": [
        {
            "recordId": "006ABC123",
            "recordName": "Acme Corp - Enterprise Deal",
            "childRecordCounts": {
                "Task": 5,
                "OpportunityContactRole": 3,
                "OpportunityLineItem": 2
            },
            "keyFieldValues": {
                "Amount": 500000,
                "StageName": "Negotiation",
                "Probability": 75,
                "CloseDate": "2026-02-15"
            }
        },
        {
            "recordId": "006DEF456",
            "recordName": "Beta Inc - Renewal",
            "childRecordCounts": {
                "Task": 2,
                "OpportunityContactRole": 1,
                "OpportunityLineItem": 5
            },
            "keyFieldValues": {
                "Amount": 200000,
                "StageName": "Qualification",
                "Probability": 20,
                "CloseDate": "2026-03-30"
            }
        },
        {
            "recordId": "006GHI789",
            "recordName": "Gamma LLC - Expansion",
            "childRecordCounts": {
                "Task": 8,
                "OpportunityContactRole": 4,
                "OpportunityLineItem": 0
            },
            "keyFieldValues": {
                "Amount": 1200000,
                "StageName": "Qualification",
                "Probability": 25,
                "CloseDate": "2026-04-30"
            }
        }
    ],

    "objectAggregations": {
        "Task": {
            "objectName": "Task",
            "samplesWithData": 3,
            "minCount": 2,
            "maxCount": 8,
            "avgCount": 5.0,
            "totalCount": 15,
            "isConsistent": false
        },
        "OpportunityContactRole": {
            "objectName": "OpportunityContactRole",
            "samplesWithData": 3,
            "minCount": 1,
            "maxCount": 4,
            "avgCount": 2.67,
            "totalCount": 8,
            "isConsistent": false
        },
        "OpportunityLineItem": {
            "objectName": "OpportunityLineItem",
            "samplesWithData": 2,
            "minCount": 0,
            "maxCount": 5,
            "avgCount": 2.33,
            "totalCount": 7,
            "isConsistent": false
        }
    },

    "patterns": [
        {
            "patternType": "VARIANCE",
            "description": "Amount varies significantly: $200K to $1.2M (6x range)",
            "fieldName": "Amount",
            "severity": "INSIGHT"
        },
        {
            "patternType": "CONSISTENCY",
            "description": "2/3 samples are in early stage (Qualification)",
            "fieldName": "StageName",
            "severity": "INSIGHT"
        },
        {
            "patternType": "GAP",
            "description": "OpportunityLineItem missing in 1/3 samples",
            "objectName": "OpportunityLineItem",
            "severity": "WARNING"
        },
        {
            "patternType": "VARIANCE",
            "description": "Task count varies 2-8 across samples (inconsistent activity)",
            "objectName": "Task",
            "severity": "INFO"
        }
    ],

    "analysisSummary": "Analyzed 3 Opportunity records. Amount ranges $200K-$1.2M. 2/3 in Qualification stage. All have Tasks and ContactRoles. 1/3 missing LineItems."
}
```

---

## Stage 4 Changes

### New Method: `profileMultipleSamples()`

```apex
/**
 * Profile data across multiple sample records
 * @param rootObject The root object type (e.g., "Opportunity")
 * @param sampleIds List of sample record IDs
 * @param selectedObjects Objects to profile
 * @param grandchildren Grandchild object info
 * @param runId Run ID for logging
 * @param result StageResult for deferred logging
 * @return MultiSampleProfile with aggregated data
 */
private MultiSampleProfile profileMultipleSamples(
    String rootObject,
    List<String> sampleIds,
    List<String> selectedObjects,
    List<Map<String, String>> grandchildren,
    Id runId,
    StageResult result
) {
    MultiSampleProfile profile = new MultiSampleProfile();
    profile.sampleCount = sampleIds.size();
    profile.rootObject = rootObject;
    profile.sampleIds = sampleIds;
    profile.samples = new List<SampleData>();

    // Step 1: Query each sample individually
    for (String sampleId : sampleIds) {
        SampleData sample = querySampleData(rootObject, sampleId, selectedObjects, grandchildren);
        profile.samples.add(sample);
    }

    // Step 2: Aggregate across samples
    profile.objectAggregations = aggregateObjectData(profile.samples, selectedObjects);

    // Step 3: Detect patterns
    profile.patterns = detectPatterns(profile);

    // Step 4: Build summary
    profile.analysisSummary = buildAnalysisSummary(profile);

    return profile;
}
```

### Key Fields to Capture

For the root object, capture these fields for pattern analysis:

```apex
// Standard fields to query on root object samples
private static final List<String> ROOT_OBJECT_KEY_FIELDS = new List<String>{
    'Name', 'Amount', 'StageName', 'Probability', 'CloseDate',
    'CreatedDate', 'LastModifiedDate', 'OwnerId', 'Type', 'LeadSource'
};
```

---

## Stage 5 Changes

Stage 5 should use multi-sample data for smarter field selection:

### New Input from Stage 4
```apex
// In Stage 5 execute()
MultiSampleProfile multiSample = (MultiSampleProfile) inputs.get('multiSampleProfile');
```

### Enhanced AI Prompt for Field Selection

```
You are selecting fields for a prompt that will analyze {rootObject} records.

DATA AVAILABILITY ACROSS {sampleCount} SAMPLES:
{For each object in objectAggregations}
- {objectName}: Present in {samplesWithData}/{sampleCount} samples, avg {avgCount} records
{End for}

DETECTED PATTERNS:
{For each pattern in patterns}
- {description}
{End for}

Select fields that:
1. Are likely populated (prefer objects with high samplesWithData)
2. Can reveal the patterns detected (variance, gaps, consistency)
3. Are relevant to the business context: {businessContext}

For each object, select 10-15 fields that will be most valuable for analysis.
```

---

## Stage 7/8 Changes

The meta-prompt should include multi-sample context:

### Data Payload Section

```
=== DATA CONTEXT ===
Analyzed {sampleCount} {rootObject} records to understand data patterns.

SAMPLE OVERVIEW:
{For each sample in samples}
- {recordName}: {Amount}, {StageName}, {Task count} tasks, {ContactRole count} contacts
{End for}

KEY PATTERNS DETECTED:
{For each pattern in patterns}
- {description}
{End for}

OBJECT AVAILABILITY:
{For each object in objectAggregations}
- {objectName}: {samplesWithData}/{sampleCount} samples have data (avg {avgCount} records)
{End for}

=== YOUR ANALYSIS TASK ===
Using the patterns above, generate insights that are:
1. Grounded in cross-sample data (not single-record observations)
2. Highlighting variance and anomalies (what stands out?)
3. Actionable (what should the user do based on patterns?)
```

---

## Backward Compatibility

The design maintains backward compatibility:

```apex
// In Stage 4 execute()
List<String> sampleIds = parseSampleIds(inputs);

if (sampleIds.size() == 1) {
    // Single sample: Use existing logic (backward compatible)
    Map<String, Integer> dataAvailability = performParentSpecificCountQueries(...);
    result.outputs.put('dataAvailability', dataAvailability);
    result.outputs.put('sampleRecordId', sampleIds.get(0));
} else {
    // Multi-sample: Use new aggregation logic
    MultiSampleProfile profile = profileMultipleSamples(...);
    result.outputs.put('multiSampleProfile', profile);

    // Also provide legacy format for downstream stages not yet updated
    result.outputs.put('dataAvailability', profile.getLegacyDataAvailability());
    result.outputs.put('sampleRecordId', sampleIds.get(0));  // Primary sample
}
```

---

## Implementation Tasks (For Sonnet)

Based on this design, Sonnet should implement:

### Task 2.2: Update LWC Input
- Add text input for comma-separated IDs
- Basic validation (format check)
- Help text explaining multi-sample feature

### Task 2.3: Update Controller
- Parse comma-separated IDs
- Store in PF_Run__c (may need new field)
- Pass to Stage 4

### Task 2.4: Update Stage 4
- Implement `MultiSampleProfile` class (inner class or separate)
- Implement `profileMultipleSamples()` method
- Implement `aggregateObjectData()` method
- Implement `detectPatterns()` method
- Maintain backward compatibility

### Task 2.5 (Opus): Update Stage 5 Scoring
- Use multi-sample data for field relevance
- Enhanced AI prompt for field selection
- Weight by samplesWithData ratio

---

## Testing Considerations

### Test Data Setup
Need 3 Opportunity records with varying characteristics:
1. High-value deal in late stage with many tasks
2. Low-value deal in early stage with few tasks
3. Mid-value deal with some missing related objects

### Validation Criteria
1. All 3 samples queried successfully
2. Object aggregations calculated correctly
3. Patterns detected match expected (based on test data)
4. Backward compatibility: Single sample still works

---

## Future Enhancements (Not in MVP)

1. **Field-level analysis**: Track field population rate across samples
2. **Value distribution**: Min/max/avg for numeric fields
3. **Configurable sample count**: Allow 1-10 samples
4. **Smart sample selection**: Auto-suggest samples with diverse characteristics
5. **Caching**: Cache schema queries across samples

---

**Design Complete. Ready for implementation by Sonnet (Tasks 2.2-2.4) and Opus (Task 2.5).**
