# PRD: Account 360 Activity Heatmap (Unified)

## Overview

A comprehensive visual engagement intelligence component for Account 360 that displays account activity patterns using GitHub-style contribution heatmaps. This unified specification supports two complementary visualization modes:

1. **Combined View** - Traditional GitHub-style calendar heatmap showing all activities aggregated by day
2. **Multi-Category View** - Activity type breakdown showing engagement patterns across different touchpoint categories

Both views provide instant insight into engagement cadence, activity intensity, and historical patterns directly within Salesforce Account records.

---

## Problem Statement

Sales and customer success teams lack a quick, visual way to understand account engagement patterns over time. Current approaches require:
- Manual review of activity timelines
- Running reports to aggregate activity counts
- Mental calculation to identify engagement trends
- Cross-referencing multiple related lists (Cases, Opportunities, Activities)

This leads to:
- Missed signals of declining engagement
- Inability to quickly assess account health
- Inconsistent engagement patterns across the team
- No visibility into which engagement channels are underutilized

---

## Solution

A dynamic, interactive heatmap visualization that:
1. Aggregates all account touchpoints (Tasks, Events, Cases, Opportunities, Emails) by date
2. Displays activity intensity using color-coded cells in a calendar grid
3. Provides hover tooltips with daily activity breakdowns
4. Adapts intelligently to the account's history and volume
5. Offers both combined and category-breakdown visualization modes

---

## User Stories

### As a Sales Rep
- I want to see at a glance how engaged an account has been over time
- I want to identify gaps in engagement that need attention
- I want to understand which days/weeks had the most activity
- I want to see if I'm doing enough calls vs emails for this account

### As a Sales Manager
- I want to quickly assess team engagement patterns across accounts
- I want to identify accounts that may be at risk due to low engagement
- I want to celebrate consistent engagement streaks
- I want to see the mix of engagement types across my team's accounts

### As a Customer Success Manager
- I want to track engagement health for my portfolio
- I want to identify seasonal patterns in customer engagement
- I want to spot early warning signs of churn (declining activity + rising cases)
- I want to correlate support ticket volume with engagement patterns

---

## Visualization Modes

### Mode 1: Combined View (GitHub-Style)

Traditional calendar heatmap with days of week as rows:

```
┌─────────────────────────────────────────────────────────────────────┐
│  HEADER (Account Name, Industry, Location)                          │
│  [Total Activities] [Active Days] [Longest Streak] [Avg/Day]        │
├─────────────────────────────────────────────────────────────────────┤
│  "X activities in the last Y"                    Less ▢▢▢▢▢ More    │
│                                                                      │
│       Jan    Feb    Mar    Apr    May    Jun    ...                 │
│  Mon  ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢                      │
│       ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢                      │
│  Wed  ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢                      │
│       ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢                      │
│  Fri  ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢                      │
│       ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢   ▢▢▢▢▢  ▢▢▢▢                      │
│                                                                      │
│  [Scale Info: level-0=0, level-1=1-2, level-2=3-4, ...]             │
└─────────────────────────────────────────────────────────────────────┘
```

**Best for:** Detailed daily engagement analysis, identifying specific gaps, streak tracking

### Mode 2: Multi-Category View (Activity Type Breakdown)

Category-based heatmap with activity types as rows and weeks as columns:

```
┌─────────────────────────────────────────────────────────────────────┐
│  HEADER (Account Name, Industry, Location)                          │
│  [Total Touchpoints] [Categories] [Most Active] [Trend]             │
├─────────────────────────────────────────────────────────────────────┤
│  "Account Engagement by Category"              [Combined] [By Type] │
│                                                                      │
│              Jan    Feb    Mar    Apr    May    Jun    ...          │
│  Activities  ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   (Blue)     │
│  Cases       ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   (Orange)   │
│  Opps        ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   (Green)    │
│  Emails      ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   (Teal)     │
│  Contacts    ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   ▢▢▢▢   (Purple)   │
│                                                                      │
│  [Legend: Each row scales independently based on its own data]      │
└─────────────────────────────────────────────────────────────────────┘
```

**Best for:** Understanding engagement mix, identifying underutilized channels, correlating support issues with sales activity

---

## Visual Design Specifications

### Color Palettes

#### Combined View (Single Green Gradient)

| Level | Color Code | Description |
|-------|------------|-------------|
| 0 | `#ebedf0` | No activity (light gray) |
| 1 | `#9be9a8` | Low activity (light green) |
| 2 | `#40c463` | Moderate activity (medium green) |
| 3 | `#30a14e` | High activity (dark green) |
| 4 | `#216e39` | Very high activity (darkest green) |

#### Multi-Category View (Color per Type)

| Category | Level 0 | Level 1 | Level 2 | Level 3 | Level 4 | Meaning |
|----------|---------|---------|---------|---------|---------|---------|
| Activities | `#ebedf0` | `#dbeafe` | `#93c5fd` | `#3b82f6` | `#1d4ed8` | Calls, meetings, tasks |
| Cases | `#ebedf0` | `#ffedd5` | `#fdba74` | `#f97316` | `#c2410c` | Support tickets |
| Opportunities | `#ebedf0` | `#dcfce7` | `#86efac` | `#22c55e` | `#15803d` | Deals, renewals |
| Emails | `#ebedf0` | `#ccfbf1` | `#5eead4` | `#14b8a6` | `#0f766e` | Email engagement |
| Contacts | `#ebedf0` | `#f3e8ff` | `#d8b4fe` | `#a855f7` | `#7c3aed` | New stakeholders |

### Cell Specifications

- **Size**: 12-14px square
- **Border Radius**: 2-3px
- **Gap**: 2px between cells
- **Hover Effect**: Scale to 1.5x with shadow

---

## Adaptive Scaling Logic

### Time Range Adaptation

The heatmap dynamically adjusts its time range based on account activity history:

| Account Age | Display Range | Granularity |
|-------------|---------------|-------------|
| < 2 months | Show all weeks with activity | Weekly |
| 2-6 months | Show from first activity to present | Weekly |
| 6-12 months | Show last 6 months or from first activity | Weekly |
| > 12 months | Show last 12 months (52 weeks max) | Weekly |

**Calculation:**
- Find the earliest ActivityDate from all related objects
- Find the latest ActivityDate (or use today if recent)
- Calculate weeks between: `Math.ceil((latestDate - earliestDate) / (7 * 24 * 60 * 60 * 1000))`
- Cap at 52 weeks maximum
- Minimum 4 weeks even for new accounts
- Pad the first week to start on Sunday

### Percentile-Based Color Intensity

Instead of fixed thresholds, colors are assigned based on the account's own activity distribution:

```javascript
// Calculate percentiles from non-zero activity days
const nonZeroDays = dailyCounts.filter(d => d > 0);
const p25 = percentile(nonZeroDays, 25);
const p50 = percentile(nonZeroDays, 50);
const p75 = percentile(nonZeroDays, 75);

// Assign levels
function getLevel(count) {
  if (count === 0) return 'level-0';
  if (count <= p25) return 'level-1';
  if (count <= p50) return 'level-2';
  if (count <= p75) return 'level-3';
  return 'level-4';
}
```

### Multi-Category Independent Scaling

In Multi-Category View, each row calculates its own percentile thresholds independently:

```javascript
// Each category scales to its own data
const activityScale = calculatePercentiles(activityCounts);
const caseScale = calculatePercentiles(caseCounts);
const oppScale = calculatePercentiles(oppCounts);
// etc.
```

This prevents high-volume categories (like emails) from drowning out lower-volume but equally important categories (like opportunities).

### Example Scale Variations

| Account Type | Activities | Cases | Opportunities |
|--------------|------------|-------|---------------|
| New SMB | 0/1/2/3/4+ | 0/1/2/3/4+ | 0/1/1/2/2+ |
| Growing Mid-Market | 0/1-3/4-6/7-10/11+ | 0/1/2-3/4-5/6+ | 0/1/2/3/4+ |
| Enterprise | 0/1-8/9-15/16-25/26+ | 0/1-3/4-6/7-10/11+ | 0/1-2/3-4/5-7/8+ |

---

## Data Requirements

### Salesforce Objects

**Primary Object**: Account

**Related Objects for Combined View**:
- Tasks (WhatId = Account.Id)
- Events (WhatId = Account.Id)

**Additional Objects for Multi-Category View**:
- Cases (AccountId = Account.Id)
- Opportunities (AccountId = Account.Id)
- Contacts (AccountId = Account.Id)
- EmailMessage (RelatedToId = Account.Id) - if Enhanced Email enabled

### Required Fields by Object

| Object | Field | Purpose |
|--------|-------|---------|
| **Account** | Id | Primary identifier |
| | Name | Display in header |
| | Industry | Display in header |
| | BillingCity | Display in header |
| | BillingState | Display in header |
| | CreatedDate | Account age calculation |
| | OwnerId / Owner.Name | Display in header |
| **Task** | ActivityDate | Aggregation key |
| | Subject | Tooltip detail |
| | Type | Activity categorization |
| | Status | Filter (Completed only) |
| | TaskSubtype | Email detection |
| **Event** | ActivityDate | Aggregation key |
| | Subject | Tooltip detail |
| | Type | Activity categorization |
| **Case** | CreatedDate | Aggregation key |
| | Subject | Tooltip detail |
| | Status | Status indicator |
| | Priority | Severity indicator |
| | CaseNumber | Reference |
| **Opportunity** | CreatedDate | Aggregation key |
| | Name | Tooltip detail |
| | StageName | Status indicator |
| | Amount | Value context |
| | CloseDate | Timeline reference |
| **Contact** | CreatedDate | Aggregation key |
| | Name | Tooltip detail |
| | Title | Role context |
| **EmailMessage** | MessageDate | Aggregation key |
| | Subject | Tooltip detail |
| | Status | Sent/Received |

### Data Context Mapping Configuration

```yaml
# GPTfy Data Context Mapping
Account:
  fields:
    - Name
    - Industry
    - BillingCity
    - BillingState
    - CreatedDate
    - Owner.Name

Tasks:
  relationship: WhatId
  fields:
    - ActivityDate
    - Subject
    - Type
    - Status
    - TaskSubtype

Events:
  relationship: WhatId
  fields:
    - ActivityDate
    - Subject
    - Type

Cases:
  relationship: AccountId
  fields:
    - CreatedDate
    - Subject
    - Status
    - Priority
    - CaseNumber

Opportunities:
  relationship: AccountId
  fields:
    - CreatedDate
    - Name
    - StageName
    - Amount
    - CloseDate

Contacts:
  relationship: AccountId
  fields:
    - CreatedDate
    - Name
    - Title
```

---

## Activity Categorization

### Combined View Categories

Group activities by type for breakdown and tooltips:

| Category | Detection Logic |
|----------|-----------------|
| Email | TaskSubtype = 'Email' OR Type contains 'Email' |
| Call | Type = 'Call' OR Type contains 'Call' |
| Meeting | Events OR Type = 'Meeting' |
| Task | Type = 'Task' OR Type = 'To Do' OR other Tasks |
| Note | Type = 'Note' |

### Multi-Category View Categories

Each category represents a distinct Salesforce object:

| Row | Source Object | What It Shows | Color Theme |
|-----|---------------|---------------|-------------|
| Activities | Task + Event | Calls, meetings, demos, tasks | Blue |
| Cases | Case | Support tickets, issues | Orange |
| Opportunities | Opportunity | Deals, renewals, upsells | Green |
| Emails | EmailMessage | Email engagement | Teal |
| Contacts | Contact | New stakeholders added | Purple |

---

## Metrics & Calculations

### Combined View Metrics

| Metric | Calculation |
|--------|-------------|
| Total Activities | Count of all Tasks + Events in time range |
| Active Days | Count of unique dates with >= 1 activity |
| Longest Streak | Maximum consecutive days with activity |
| Avg per Active Day | Total Activities / Active Days (round to 1 decimal) |
| Engagement Rate | (Active Days / Total Days in Range) x 100 (round to integer) |
| Monthly Average | Total Activities / Months in Range (round to integer) |

### Multi-Category View Metrics

| Metric | Calculation |
|--------|-------------|
| Total Touchpoints | Sum of all activities across all categories |
| Active Categories | Count of categories with >= 1 item |
| Most Active Category | Category with highest count |
| Trend | Comparison of last 4 weeks vs previous 4 weeks |
| Category Mix | Percentage breakdown by category |
| Engagement Score | Weighted score based on category diversity and volume |

### Engagement Score Formula

```
Engagement Score = (
  (Activities * 1.0) +
  (Cases * 0.5) +      // Cases indicate issues, weight lower
  (Opps * 2.0) +       // Opportunities are high value
  (Emails * 0.8) +
  (Contacts * 1.5)     // New contacts indicate expansion
) / Total Days * 100
```

---

## CSS Hover Mechanics

### Pure CSS Tooltip Implementation

Since GPTfy generates static HTML, tooltips are implemented using CSS pseudo-elements:

```html
<!-- Data stored in attribute -->
<div class="day level-3" data-tooltip="Jan 16 • 7 activities: 3 Emails, 2 Calls, 2 Tasks"></div>
```

```css
/* Tooltip appears on hover */
.day::after {
  content: attr(data-tooltip);
  position: absolute;
  bottom: calc(100% + 8px);
  left: 50%;
  transform: translateX(-50%);
  background: #1e293b;
  color: #fff;
  padding: 8px 12px;
  border-radius: 6px;
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.2s;
}

.day:hover::after {
  opacity: 1;
  visibility: visible;
}
```

### Edge Case Handling

To prevent tooltip clipping at container edges, cells receive positioning classes:

| Position | Class | Tooltip Behavior |
|----------|-------|------------------|
| Left edge (first 2 weeks) | `edge-left` | Aligns tooltip to left |
| Right edge (last 2 weeks) | `edge-right` | Aligns tooltip to right |
| Top row (Sun/Mon or first category) | `edge-top` | Shows tooltip below cell |
| Corners | `edge-top edge-left` | Combines both adjustments |

---

## Tooltip Content Format

### Combined View Tooltips

```
"Jan 15 • 7 activities: 3 Emails, 2 Calls, 2 Tasks"
"Jan 16 • 2 activities: 1 Email, 1 Call"
"Jan 17 • No activities"
"Jan 18 • 12 activities: 5 Emails, 4 Calls, 2 Meetings, 1 Task 🔥"
```

### Multi-Category View Tooltips

```
Activities: "Week of Jan 15 • 23 activities: 12 Calls, 8 Emails, 3 Meetings"
Cases: "Week of Jan 15 • 3 cases: 2 High Priority, 1 Medium"
Opps: "Week of Jan 15 • 2 opportunities: $125K Pipeline Added"
Emails: "Week of Jan 15 • 45 emails: 28 Sent, 17 Received"
Contacts: "Week of Jan 15 • 1 new contact: VP of Engineering"
```

---

## Technical Specifications

### HTML Structure - Combined View

```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; ...">
  <style>/* CSS rules */</style>

  <!-- Header -->
  <div style="background:linear-gradient(90deg,#032a5e,#0d47a1);...">
    <div>ACCOUNT ENGAGEMENT</div>
    <div>Acme Corporation</div>
    <div>Technology • San Francisco, CA</div>
  </div>

  <!-- Stats Strip -->
  <div style="display:flex;...">
    <div class="stat-box">156 TOTAL ACTIVITIES</div>
    <!-- more stat boxes -->
  </div>

  <!-- Heatmap Card -->
  <div class="card">
    <div class="heatmap-header">
      <div>156 activities in the last 12 weeks</div>
      <div class="legend">Less ▢▢▢▢▢ More</div>
    </div>
    <div class="month-labels">Oct Nov Dec</div>
    <div class="heatmap-container">
      <div class="day-labels">Mon Wed Fri</div>
      <div class="weeks-container">
        <div class="week">
          <div class="day level-2 edge-top edge-left"
               data-tooltip="Oct 7 • 3 activities: 2 Emails, 1 Call"></div>
          <!-- more days -->
        </div>
        <!-- more weeks -->
      </div>
    </div>
    <div class="scale-info">Adaptive Scale: 0 / 1-2 / 3-4 / 5-6 / 7+</div>
  </div>

  <!-- Activity Breakdown & Metrics Cards -->
  <div style="display:flex;gap:1rem;flex-wrap:wrap;">
    <!-- breakdown card -->
    <!-- metrics card -->
  </div>
</div>
```

### HTML Structure - Multi-Category View

```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; ...">
  <style>/* CSS rules including category-specific colors */</style>

  <!-- Header -->
  <div style="background:linear-gradient(90deg,#032a5e,#0d47a1);...">
    <div>ACCOUNT 360 ENGAGEMENT</div>
    <div>Acme Corporation</div>
    <div>Technology • San Francisco, CA</div>
  </div>

  <!-- Stats Strip -->
  <div style="display:flex;...">
    <div class="stat-box">847 TOTAL TOUCHPOINTS</div>
    <div class="stat-box">5 ACTIVE CATEGORIES</div>
    <!-- more stat boxes -->
  </div>

  <!-- Multi-Category Heatmap Card -->
  <div class="card">
    <div class="heatmap-header">
      <div>Account Engagement by Category</div>
      <div class="view-toggle">[Combined] [By Type]</div>
    </div>
    <div class="month-labels">Oct Nov Dec</div>
    <div class="category-heatmap">
      <!-- Activities Row -->
      <div class="category-row">
        <div class="category-label" style="color:#1d4ed8;">Activities</div>
        <div class="weeks-container">
          <div class="day activity-level-2" data-tooltip="Week of Oct 7 • 23 activities"></div>
          <!-- more weeks -->
        </div>
        <div class="category-legend">Less ▢▢▢▢▢ More</div>
      </div>

      <!-- Cases Row -->
      <div class="category-row">
        <div class="category-label" style="color:#c2410c;">Cases</div>
        <div class="weeks-container">
          <div class="day case-level-1" data-tooltip="Week of Oct 7 • 2 cases"></div>
          <!-- more weeks -->
        </div>
        <div class="category-legend">Less ▢▢▢▢▢ More</div>
      </div>

      <!-- Opportunities Row -->
      <!-- Emails Row -->
      <!-- Contacts Row -->
    </div>
    <div class="scale-info">Each row scales independently based on account data</div>
  </div>

  <!-- Category Summary Cards -->
  <div style="display:flex;gap:1rem;flex-wrap:wrap;">
    <!-- Per-category stats -->
  </div>
</div>
```

### CSS Requirements

- All styles must be inline or in a `<style>` block
- Container must have `overflow: visible` for tooltips
- Weeks container needs padding for tooltip clearance
- Z-index hierarchy for proper tooltip layering
- Category-specific color classes for multi-category view

### Performance Considerations

- Combined View: Maximum 52 weeks x 7 days = 364 cells
- Multi-Category View: Maximum 52 weeks x 5 categories = 260 cells
- Each cell is a simple div with data attribute
- No JavaScript required
- Estimated HTML size: 50-150KB depending on activity volume and view mode

---

## Acceptance Criteria

### Functional Requirements

- [ ] Combined heatmap displays activities for the appropriate time range
- [ ] Multi-category heatmap shows all 5 category rows
- [ ] Colors accurately reflect activity intensity relative to account history
- [ ] Each category row in multi-view scales independently
- [ ] Hovering on any cell shows tooltip with appropriate breakdown
- [ ] Edge tooltips are not clipped by container boundaries
- [ ] Summary metrics are accurately calculated for both views
- [ ] Activity breakdown percentages sum to 100%
- [ ] Empty accounts show appropriate message
- [ ] Fire emoji appears on level-4 days/weeks

### Visual Requirements

- [ ] Grid aligns properly with month labels
- [ ] Day/Category labels align with correct rows
- [ ] Color legend accurately reflects the scale used
- [ ] Category colors are visually distinct
- [ ] Hover effect (scale + shadow) is smooth
- [ ] Tooltip appears within 200ms of hover

### Responsive Requirements

- [ ] Heatmap scrolls horizontally on narrow screens
- [ ] Stats cards stack on mobile
- [ ] Minimum readable cell size maintained
- [ ] Category labels remain visible during scroll

---

## Implementation Phases

### Phase 1: Combined View (Current)
- GitHub-style daily calendar heatmap
- Tasks and Events only
- Percentile-based adaptive scaling
- CSS-only tooltips with edge handling
- Activity breakdown and engagement metrics

### Phase 2: Multi-Category View (Enhancement)
- Add Cases, Opportunities, Contacts, EmailMessage data
- Category rows with independent scaling
- Color-coded by category type
- Weekly aggregation for cleaner visualization
- Category-specific tooltips

### Phase 3: Advanced Features (Future)
- View toggle between Combined and Multi-Category
- Click-through to filtered activity list
- Comparison mode (vs. previous period)
- Predictive engagement scoring
- Anomaly detection (unusual gaps or spikes)
- Integration with account health scores
- Team aggregate view

---

## Sample Scenarios

### Scenario A: New SMB Account (6 weeks)
- **Combined View**: 23 total activities, Scale: 0/1/2/3/4+, 6 weeks displayed
- **Multi-Category View**: Activities: 20, Cases: 2, Opps: 1, Emails: 15, Contacts: 3

### Scenario B: Growing Mid-Market Account (4 months)
- **Combined View**: 156 total activities, Scale: 0/1-2/3-4/5-6/7+, 16 weeks displayed
- **Multi-Category View**: Activities: 89, Cases: 12, Opps: 4, Emails: 234, Contacts: 8

### Scenario C: Enterprise Account (12+ months)
- **Combined View**: 2,847 total activities, Scale: 0/1-5/6-9/10-15/16+, 52 weeks displayed
- **Multi-Category View**: Activities: 1,200, Cases: 87, Opps: 23, Emails: 4,500, Contacts: 45

### Scenario D: At-Risk Account Pattern
- Declining activity trend over last 8 weeks
- Rising case volume (orange row intensifying)
- No new opportunities (green row empty)
- Visual correlation immediately apparent in multi-category view

---

## Testing Checklist

### Combined View

- [ ] Heatmap renders with correct number of weeks
- [ ] Colors reflect percentile-based scaling
- [ ] Tooltips appear on hover for all cells
- [ ] Edge tooltips are not clipped
- [ ] Month labels align with correct weeks
- [ ] Day labels (Mon, Wed, Fri) align correctly
- [ ] Metrics calculate correctly
- [ ] Activity breakdown percentages sum to ~100%
- [ ] Empty accounts show appropriate message
- [ ] Fire emoji appears on level-4 days

### Multi-Category View

- [ ] All 5 category rows render correctly
- [ ] Each row uses its designated color palette
- [ ] Each row scales independently
- [ ] Week-level aggregation is accurate
- [ ] Category labels are readable
- [ ] Tooltips show category-specific information
- [ ] Edge handling works for all rows
- [ ] Category totals match individual cell sums
- [ ] Empty categories show level-0 throughout

---

## Troubleshooting

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Tooltips cut off | Missing edge classes | Verify edge class logic |
| All cells same color | Scale calculation error | Check percentile logic |
| Missing weeks | Date range calculation | Check earliest/latest date |
| No hover effect | CSS not included | Verify style block |
| Broken layout | Unclosed div tags | Validate HTML structure |
| Category colors wrong | CSS class mismatch | Check category-level-X classes |
| Row scaling identical | Using global instead of per-row percentiles | Verify independent calculation |

---

## References

- GitHub Contribution Graph: https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-profile/managing-contribution-settings-on-your-profile
- CSS-only Tooltips: https://developer.mozilla.org/en-US/docs/Web/CSS/::after
- GPTfy Prompt Configuration: Internal documentation
- Original PRDs: `prd-account-activity-heatmap.md`, `prd-github-activity-heatmap.md`
