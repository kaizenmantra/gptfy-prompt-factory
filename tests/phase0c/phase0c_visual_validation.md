# Phase 0C Visual Validation Checklist

**Purpose**: Reconcile automated scoring with human judgment before finalizing pattern library.

**Time Required**: 30 minutes

---

## Open These 6 Outputs in Browser

### Critical Comparisons:

**1. V30 (Tables Baseline) vs V28 (Stat Cards)**
- File: `tests/phase0c/outputs/output_30_tables_only.html`
- File: `tests/phase0c/outputs/output_28_statcards_4to6.html`
- **Question**: Does the +14.5 point delta feel right visually? Would an executive prefer Stat Cards?

**2. V31 (Alert Boxes) - The Anomaly**
- File: `tests/phase0c/outputs/output_31_alertboxes.html`
- **Question**: Why did this score -1.0 below baseline? Is the output actually bad, or is the scoring wrong?
- **Compare to**: Phase 0B V15 output (which used Alert Boxes and scored 75/100)

**3. V24 (Timeline) - Highest Pattern Score**
- File: `tests/phase0c/outputs/output_24_timeline_isolated.html`
- **Question**: Does this output feel like "79/100" quality? What makes it strong?

**4. V21 (Risk Isolated) - Underperformer**
- File: `tests/phase0c/outputs/output_21_risk_isolated.html`
- **Question**: Why only 64.5? Is the analytical content weak, or is it just missing visual enhancement?

**5. V36 (Risk+Metrics+Visual) - Best Combo**
- File: `tests/phase0c/outputs/output_36_risk_metrics_visual.html`
- **Question**: Does this replicate V15's quality? Is 77.5 the right score?

**6. V39 (3-Pattern Test) - Overload Test**
- File: `tests/phase0c/outputs/output_39_three_pattern_test.html`
- **Question**: Does this feel "noisy"? Does the 60.0 score make sense?

---

## Human Scoring (5-point scale for each)

| Output | Executive Appeal | Scan-ability | Diagnostic Depth | Evidence Binding | Overall |
|--------|------------------|--------------|------------------|------------------|---------|
| V30 (Tables) | /5 | /5 | /5 | /5 | /20 |
| V28 (Stat Cards) | /5 | /5 | /5 | /5 | /20 |
| V31 (Alert Boxes) | /5 | /5 | /5 | /5 | /20 |
| V24 (Timeline) | /5 | /5 | /5 | /5 | /20 |
| V21 (Risk) | /5 | /5 | /5 | /5 | /20 |
| V36 (Combo) | /5 | /5 | /5 | /5 | /20 |
| V39 (3-Pattern) | /5 | /5 | /5 | /5 | /20 |

---

## Questions to Answer

1. **Does V28 (Stat Cards) look noticeably better than V30 (Tables)?**
   - If YES: Stat Cards are P0 for the library
   - If NO: Re-examine the +14.5 delta claim

2. **Is V31 (Alert Boxes) actually bad, or is the scoring missing something?**
   - If BAD: Remove Alert Boxes from library
   - If GOOD: Fix the scoring methodology before trusting it

3. **Does V36 feel like enterprise-quality output?**
   - If YES: Risk+Metrics+Visual is your "golden recipe"
   - If NO: More iteration needed

4. **Does V39 feel "overloaded" compared to V36?**
   - If YES: Validates 2-pattern limit
   - If NO: Maybe 3 patterns work in some scenarios

---

## Decision Gate

**If human review aligns with automated scoring (±10 points)**:
→ Proceed to building the pattern library

**If human review diverges significantly**:
→ Refine scoring methodology OR weight human judgment higher

---

## Commands to Open Outputs

```bash
# On Mac
open tests/phase0c/outputs/output_30_tables_only.html
open tests/phase0c/outputs/output_28_statcards_4to6.html
open tests/phase0c/outputs/output_31_alertboxes.html
open tests/phase0c/outputs/output_24_timeline_isolated.html
open tests/phase0c/outputs/output_21_risk_isolated.html
open tests/phase0c/outputs/output_36_risk_metrics_visual.html
open tests/phase0c/outputs/output_39_three_pattern_test.html
```
