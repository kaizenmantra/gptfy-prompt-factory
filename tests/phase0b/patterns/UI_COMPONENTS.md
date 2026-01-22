# UI/HTML COMPONENTS - EXTRACTED FROM PRODUCTION PROMPTS

**Date**: January 22, 2026  
**Source**: 10 Salesforce AI prompts (9 pre-packaged + 1 MEDDIC sample)  
**Purpose**: Reusable HTML/CSS components for prompt output formatting

---

## COMPONENT 1: Stat Card / Metric Tile

**Component ID**: `stat_card`  
**Category**: Data Display  
**Frequency**: Used in 2 prompts (Account 360 - Reimagined, MEDDIC)  
**Complexity**: Low

### Description
Displays a single key metric with label and value, often used in dashboard layouts with multiple cards.

### HTML/CSS Code

```html
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
  <div style="color: #000000; font-size: 0.875rem; font-weight: bold;">{{METRIC_LABEL}}</div>
  <div style="font-size: 1rem; font-weight: 500; color: {{VALUE_COLOR}};">{{METRIC_VALUE}}</div>
</div>
```

### Merge Fields
- `{{METRIC_LABEL}}`: Label/name of the metric (e.g., "Total Open Opportunities")
- `{{METRIC_VALUE}}`: Value to display (e.g., "5", "$1,450,000", "High")
- `{{VALUE_COLOR}}`: Color for value (e.g., `#28a745` for green, `#dc3545` for red, `#FF9800` for orange)

### Visual Style (Insight-Dense)
- **Background**: White (#ffffff)
- **Spacing**: Compact (0.75rem padding) to avoid excessive white space.
- **Hierarchy**: Primary focus is the Metric Label (Executive Scan-ability), Secondary is the Value.
- **Evidence**: Small font (10px), subtle color (#706E6B), placed at the bottom to avoid clutter.

### Layout Context
Typically used in a flex container for responsive grid:

```html
<div style="display: flex; flex-wrap: wrap; gap: 1rem; justify-content: space-between;">
  <!-- Multiple stat cards here -->
</div>
```

### Color Scheme Recommendations
- **Success/Positive**: `#28a745` (green)
- **Warning/Medium**: `#FF9800` (orange)
- **Error/Critical**: `#dc3545` (red)
- **Neutral/Info**: `#0176D3` (blue)
- **Default Text**: `#000000` (black)

### Used In
- Account 360 View - Reimagined (9 stat cards: Total Open Opportunities, Total Value, Frustration Level, etc.)
- Can be adapted for any dashboard or scorecard view

### Variations

**Variation A: Multi-value Stat Card (for distributions)**
```html
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
  <div style="color: #000000; font-size: 0.875rem; font-weight: bold;">{{METRIC_LABEL}}</div>
  <div style="font-size: 1rem; font-weight: 500;">
    <span style="color: #28a745;">{{VALUE_1}}</span> |
    <span style="color: #FF9800;">{{VALUE_2}}</span> |
    <span style="color: #dc3545;">{{VALUE_3}}</span>
  </div>
</div>
```

Example: Sentiment Distribution (Pos: 5 | Neu: 3 | Neg: 2)

**Variation B: Stat Card with Link**
```html
<div style="flex: 1 1 calc(25% - 1rem); background: #ffffff; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); text-align: center;">
  <div style="color: #000000; font-size: 0.875rem; font-weight: bold;">{{METRIC_LABEL}}</div>
  <div style="font-size: 1rem; font-weight: 500;">
    <a href="{{LINK_URL}}" style="color: {{VALUE_COLOR}}; text-decoration: underline;">{{METRIC_VALUE}}</a>
  </div>
</div>
```

Example: Most Urgent Case (links to case record)

---

## COMPONENT 2: Data Table (Salesforce Style)

**Component ID**: `data_table_slds`  
**Category**: Data Display  
**Frequency**: Used in 6 prompts (Account 360 variants, MEDDIC)  
**Complexity**: Medium

### Description
Responsive data table with Salesforce Lightning Design System (SLDS) styling, supporting row hover effects and alternating row colors.

### HTML/CSS Code

```html
<table style="width: 100%; border-collapse: collapse; background: white; font-size: 0.875rem;">
  <thead>
    <tr style="background-color: #f8f9fa;">
      <th style="padding: 0.75rem; text-align: left; font-weight: 600; color: #16325c; border-bottom: 2px solid #dee2e6;">{{HEADER_1}}</th>
      <th style="padding: 0.75rem; text-align: left; font-weight: 600; color: #16325c; border-bottom: 2px solid #dee2e6;">{{HEADER_2}}</th>
      <!-- Additional headers -->
    </tr>
  </thead>
  <tbody>
    <tr style="border-bottom: 1px solid #dee2e6;">
      <td style="padding: 0.75rem;">{{VALUE_1}}</td>
      <td style="padding: 0.75rem;">{{VALUE_2}}</td>
      <!-- Additional cells -->
    </tr>
    <!-- Additional rows -->
  </tbody>
</table>
```

### Merge Fields
- `{{HEADER_N}}`: Column header labels
- `{{VALUE_N}}`: Cell values (can include links, formatted text, etc.)

### Visual Style
- **Background**: White (#ffffff) for table, Light gray (#f8f9fa) for header row
- **Header Text**: Dark blue (#16325c), weight 600, 0.75rem padding
- **Header Border**: 2px solid #dee2e6 at bottom
- **Row Border**: 1px solid #dee2e6 between rows
- **Cell Padding**: 0.75rem (12px)
- **Font Size**: 0.875rem (14px)
- **Hover Effect**: Optional (see variation below)

### Layout Context
Typically wrapped in a card container:

```html
<div style="background: #ffffff; padding: 1rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 1rem;">
  <div style="color: #16325c; font-size: 1.25rem; font-weight: bold; margin-bottom: 0.75rem;">{{TABLE_TITLE}}</div>
  <!-- Table here -->
</div>
```

### Used In
- Account 360 View (Contacts table, Opportunities table, Cases table, Tasks table)
- MEDDIC Compliance Analyzer (Stakeholder map table, MEDDIC summary table)

### Variations

**Variation A: Table with Row Hover Effect**
```html
<tr style="border-bottom: 1px solid #dee2e6; transition: background-color 0.2s;">
  <td style="padding: 0.75rem;">{{VALUE}}</td>
</tr>
```

Add this to `<style>` block (if allowed):
```css
tr:hover {
  background-color: #f8f9fa;
}
```

**Variation B: Table with Inline Links**
```html
<td style="padding: 0.75rem;">
  <a href="/{{RECORD_ID}}" target="_blank" style="color: #0176D3; text-decoration: underline;">{{DISPLAY_TEXT}}</a>
</td>
```

**Variation C: Table with Status Badges**
```html
<td style="padding: 0.75rem;">
  <span style="display: inline-block; padding: 4px 12px; border-radius: 4px; font-size: 0.75rem; font-weight: 600; background-color: {{BADGE_BG_COLOR}}; color: {{BADGE_TEXT_COLOR}};">{{STATUS}}</span>
</td>
```

Color schemes for badges:
- **Success**: Background `#d4edda`, Text `#155724`
- **Warning**: Background `#fff3cd`, Text `#856404`
- **Danger**: Background `#f8d7da`, Text `#721c24`
- **Info**: Background `#d1ecf1`, Text `#0c5460`

**Variation D: Table with Right-Aligned Numeric Columns**
```html
<th style="padding: 0.75rem; text-align: right; font-weight: 600; color: #16325c; border-bottom: 2px solid #dee2e6;">{{NUMERIC_HEADER}}</th>
```
```html
<td style="padding: 0.75rem; text-align: right;">{{NUMERIC_VALUE}}</td>
```

---

## COMPONENT 3: Card Container

**Component ID**: `card_container`  
**Category**: Layout/Structure  
**Frequency**: Used in 3 prompts (Account 360, MEDDIC)  
**Complexity**: Low

### Description
White card container with shadow for grouping related content, commonly used for sections.

### HTML/CSS Code

```html
<div style="background: #ffffff; padding: 1rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 1rem;">
  <div style="color: #16325c; font-size: 1.25rem; font-weight: bold; margin-bottom: 0.75rem;">{{CARD_TITLE}}</div>
  <div style="color: #333; line-height: 1.6;">
    {{CARD_CONTENT}}
  </div>
</div>
```

### Merge Fields
- `{{CARD_TITLE}}`: Section title/header
- `{{CARD_CONTENT}}`: Body content (text, table, list, etc.)

### Visual Style
- **Background**: White (#ffffff)
- **Padding**: 1rem (16px)
- **Border Radius**: 8px (rounded corners)
- **Shadow**: Medium (0 2px 4px)
- **Margin Bottom**: 1rem (16px) for spacing between cards
- **Title**: Dark blue (#16325c), 1.25rem, bold
- **Content**: Dark gray (#333), line-height 1.6

### Layout Context
Used as wrapper for major sections (Executive Summary, Tables, Risk Assessment, etc.)

Can be nested in a main container:

```html
<div style="font-family: system-ui, sans-serif; width: 100%; max-width: 1200px; margin: 0 auto; padding: 20px; border-radius: 8px; background: #B0C4DF;">
  <!-- Multiple card containers here -->
</div>
```

### Used In
- Account 360 View - Reimagined (Executive Summary card, Opportunities card, Cases card)
- MEDDIC Compliance Analyzer (sections for each MEDDIC element)

### Variations

**Variation A: Card with Accent Border**
```html
<div style="background: #ffffff; padding: 1rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 1rem; border-left: 4px solid {{ACCENT_COLOR}};">
  <!-- Content -->
</div>
```

Accent colors:
- **Info**: `#0176D3` (blue)
- **Success**: `#28a745` (green)
- **Warning**: `#FF9800` (orange)
- **Danger**: `#dc3545` (red)

**Variation B: Card with Colored Background**
```html
<div style="background: #f0f7ff; padding: 1rem; border-radius: 6px; border-left: 4px solid #0176d3; margin-bottom: 2rem;">
  <p style="margin: 0;"><strong>{{LABEL}}:</strong> {{VALUE}} | <strong>{{LABEL_2}}:</strong> {{VALUE_2}}</p>
</div>
```

Used for summary callouts or key takeaways (light blue background with blue border).

---

## COMPONENT 4: Page Header with Gradient

**Component ID**: `page_header_gradient`  
**Category**: Header/Title  
**Frequency**: Used in 2 prompts (Account 360, Phase 0 baseline)  
**Complexity**: Low

### Description
Full-width header with linear gradient background for page title and metadata.

### HTML/CSS Code

```html
<div style="background: linear-gradient(135deg, #0176D3, #014486); color: white; padding: 20px; border-radius: 8px 8px 0 0;">
  <h1 style="margin: 0 0 4px 0; font-size: 20px; font-weight: 600;">{{PAGE_TITLE}}</h1>
  <p style="margin: 0; font-size: 12px; opacity: 0.9;">{{SUBTITLE_1}}</p>
  <p style="margin: 0; font-size: 12px;">{{SUBTITLE_2}}</p>
  <p style="margin: 0; font-size: 12px;">{{SUBTITLE_3}}</p>
</div>
```

### Merge Fields
- `{{PAGE_TITLE}}`: Main page title (e.g., Account Name, Opportunity Name)
- `{{SUBTITLE_1}}`: First subtitle line (e.g., Industry | Type)
- `{{SUBTITLE_2}}`: Second subtitle line (e.g., Location)
- `{{SUBTITLE_3}}`: Third subtitle line (e.g., Contact info, Website)

### Visual Style
- **Background**: Linear gradient from Primary Blue (#0176D3) to Dark Blue (#014486), 135deg angle
- **Text Color**: White
- **Padding**: 20px
- **Border Radius**: 8px 8px 0 0 (rounded top corners only)
- **Title**: 20px, weight 600, margin 0 0 4px 0
- **Subtitles**: 12px, opacity 0.9 for first line, margin 0

### Layout Context
Typically paired with a stat card row below it (both in rounded container):

```html
<!-- Header here -->
<div style="display: flex; gap: 16px; justify-content: space-around; flex-wrap: wrap; background: white; padding: 16px; border-radius: 0 0 8px 8px; margin-bottom: 12px;">
  <!-- Stat cards here -->
</div>
```

### Used In
- Phase 0 baseline prompt (Account header)
- Can be adapted for any page title (Opportunity, Case, Account 360)

### Variations

**Variation A: Header with Link in Subtitle**
```html
<p style="margin: 0; font-size: 12px;">{{LABEL}}: <a href="{{URL}}" style="color: #1B96FF;" target="_blank">{{LINK_TEXT}}</a></p>
```

**Variation B: Single-Line Title (Simpler)**
```html
<div style="font-size: 1.75rem; font-weight: bold; color: #16325c; margin-bottom: 2rem;">
  {{PAGE_TITLE}}
</div>
```

(No gradient, used in Account 360 - Reimagined)

---

## COMPONENT 5: Alert/Info Box

**Component ID**: `alert_box`  
**Category**: Notification/Message  
**Frequency**: Used in 1 prompt (MEDDIC)  
**Complexity**: Low

### Description
Colored box for highlighting important information, summaries, or callouts.

### HTML/CSS Code

```html
<div style="background-color: {{ALERT_BG_COLOR}}; padding: 1rem; border-radius: 6px; border-left: 4px solid {{ALERT_BORDER_COLOR}}; margin-bottom: 2rem;">
  <p style="margin: 0; color: {{ALERT_TEXT_COLOR}};">{{ALERT_CONTENT}}</p>
</div>
```

### Merge Fields
- `{{ALERT_CONTENT}}`: Message text or HTML content
- `{{ALERT_BG_COLOR}}`: Background color
- `{{ALERT_BORDER_COLOR}}`: Left border accent color
- `{{ALERT_TEXT_COLOR}}`: Text color

### Visual Style
- **Background**: Light color matching alert type
- **Border Left**: 4px solid, darker shade of background
- **Padding**: 1rem (16px)
- **Border Radius**: 6px (rounded corners)
- **Margin Bottom**: 2rem (32px) for spacing

### Color Schemes by Alert Type

**Info (Blue)**:
- Background: `#f0f7ff`
- Border: `#0176d3`
- Text: `#014486` or default

**Success (Green)**:
- Background: `#d4edda`
- Border: `#28a745`
- Text: `#155724`

**Warning (Orange)**:
- Background: `#fff3cd`
- Border: `#FF9800`
- Text: `#856404`

**Danger (Red)**:
- Background: `#f8d7da`
- Border: `#dc3545`
- Text: `#721c24`

### Used In
- MEDDIC Compliance Analyzer (overall MEDDIC score summary, stage alignment)

### Variations

**Variation A: Alert with Bold Label**
```html
<div style="background-color: #f0f7ff; padding: 1rem; border-radius: 6px; border-left: 4px solid #0176d3; margin-bottom: 2rem;">
  <p style="margin: 0;"><strong>{{LABEL}}:</strong> {{VALUE}} | <strong>{{LABEL_2}}:</strong> {{VALUE_2}}</p>
</div>
```

**Variation B: Multi-line Alert**
```html
<div style="background-color: #fff3cd; padding: 1rem; border-radius: 6px; border-left: 4px solid #FF9800; margin-bottom: 1rem;">
  <p style="margin: 0 0 0.5rem 0; font-weight: bold; color: #856404;">⚠️ Warning</p>
  <p style="margin: 0; color: #856404;">{{WARNING_MESSAGE}}</p>
</div>
```

---

## COMPONENT 6: MEDDIC Summary Table

**Component ID**: `meddic_summary_table`  
**Category**: Data Display (Specialized)  
**Frequency**: Used in 1 prompt (MEDDIC) but highly specialized  
**Complexity**: High

### Description
Specialized table for displaying MEDDIC compliance scores with status indicators, evidence, and gaps.

### HTML/CSS Code

```html
<table style="width: 100%; border-collapse: collapse; margin-bottom: 2rem;">
  <thead>
    <tr style="background-color: #16325c; color: white;">
      <th style="padding: 12px; text-align: left;">Element</th>
      <th style="padding: 12px; text-align: center;">Score</th>
      <th style="padding: 12px; text-align: center;">Status</th>
      <th style="padding: 12px; text-align: left;">Key Evidence</th>
      <th style="padding: 12px; text-align: left;">Primary Gap</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background-color: #f8f9fa;">
      <td style="padding: 12px; border-bottom: 1px solid #dee2e6;"><strong>M - Metrics</strong></td>
      <td style="padding: 12px; text-align: center; border-bottom: 1px solid #dee2e6;">{{M_SCORE}}</td>
      <td style="padding: 12px; text-align: center; border-bottom: 1px solid #dee2e6;">{{M_STATUS_ICON}}</td>
      <td style="padding: 12px; border-bottom: 1px solid #dee2e6;">{{M_EVIDENCE}}</td>
      <td style="padding: 12px; border-bottom: 1px solid #dee2e6;">{{M_GAP}}</td>
    </tr>
    <!-- Repeat for E, D-Criteria, D-Process, I, C -->
  </tbody>
</table>
```

### Merge Fields (per MEDDIC element)
- `{{X_SCORE}}`: Numeric score (0-100)
- `{{X_STATUS_ICON}}`: Visual indicator (🟢 STRONG / 🟡 AT RISK / 🔴 MISSING)
- `{{X_EVIDENCE}}`: Brief evidence citation
- `{{X_GAP}}`: Primary gap description

### Visual Style
- **Header Background**: Dark blue (#16325c)
- **Header Text**: White
- **Row Background**: Alternating (white, light gray #f8f9fa)
- **Border**: 1px solid #dee2e6 between rows
- **Padding**: 12px
- **Font**: Default (inherits from container)

### Status Icons
- 🟢 **STRONG** (76-100 score)
- 🟡 **AT RISK** (26-75 score)
- 🔴 **MISSING** (0-25 score)

### Layout Context
Placed after MEDDIC Compliance Summary heading, before detailed element analysis.

### Used In
- MEDDIC Compliance Analyzer (dedicated MEDDIC summary table)

### Adaptability
Can be adapted for other scoring frameworks (BANT, CHAMP, etc.) by changing:
- Element column values
- Number of rows
- Scoring criteria/thresholds

---

## COMPONENT 7: Empty State Message

**Component ID**: `empty_state`  
**Category**: Placeholder/Message  
**Frequency**: Used in 2 prompts (Account 360 variants)  
**Complexity**: Low

### Description
Placeholder message displayed in tables when no data is available.

### HTML/CSS Code

```html
<tr>
  <td style="color: #A8A8A8; font-style: italic; text-align: center; padding: 20px;" colspan="{{COLUMN_COUNT}}">{{EMPTY_MESSAGE}}</td>
</tr>
```

### Merge Fields
- `{{EMPTY_MESSAGE}}`: Message to display (e.g., "No contacts found", "No opportunities found")
- `{{COLUMN_COUNT}}`: Number of columns in the table (for colspan)

### Visual Style
- **Text Color**: Gray (#A8A8A8)
- **Font Style**: Italic
- **Text Align**: Center
- **Padding**: 20px (generous padding for visual breathing room)

### Logic Context
Typically used with conditional logic (Mustache/Handlebars):

```html
{{#Contact}}
<tr>
  <td>{{Name}}</td>
  <!-- Additional data cells -->
</tr>
{{/Contact}}
{{^Contact}}
<tr>
  <td style="color: #A8A8A8; font-style: italic; text-align: center; padding: 20px;" colspan="4">No contacts found</td>
</tr>
{{/Contact}}
```

### Used In
- Account 360 View (Contacts table, Opportunities table, Cases table, Tasks table)
- Phase 0 baseline prompt (Account relationships)

---

## COMPONENT 8: Section Title with Underline

**Component ID**: `section_title_underline`  
**Category**: Header/Title  
**Frequency**: Used in 1 prompt (MEDDIC)  
**Complexity**: Low

### Description
Section heading with decorative bottom border for visual hierarchy.

### HTML/CSS Code

```html
<h2 style="font-weight: 600; color: #16325c; font-size: 1.5rem; margin-bottom: 1rem; border-bottom: 2px solid #0176d3; padding-bottom: 0.5rem;">
  {{SECTION_ICON}} {{SECTION_TITLE}}
</h2>
```

### Merge Fields
- `{{SECTION_ICON}}`: Optional emoji icon (e.g., 📊, ⚠️, ✅)
- `{{SECTION_TITLE}}`: Section title text

### Visual Style
- **Font Weight**: 600 (semi-bold)
- **Color**: Dark blue (#16325c)
- **Font Size**: 1.5rem (24px)
- **Margin Bottom**: 1rem (16px)
- **Border Bottom**: 2px solid Primary Blue (#0176d3)
- **Padding Bottom**: 0.5rem (8px) - space between text and border

### Used In
- MEDDIC Compliance Analyzer (📊 MEDDIC Compliance Summary)

### Variations

**Variation A: Without Icon**
```html
<h2 style="font-weight: 600; color: #16325c; font-size: 1.5rem; margin-bottom: 1rem; border-bottom: 2px solid #0176d3; padding-bottom: 0.5rem;">{{SECTION_TITLE}}</h2>
```

**Variation B: Smaller Section (h3)**
```html
<h3 style="font-weight: 600; color: #16325c; font-size: 1.25rem; margin-bottom: 0.75rem; border-bottom: 1px solid #dee2e6; padding-bottom: 0.5rem;">{{SECTION_TITLE}}</h3>
```

---

## COMPONENT 9: Full Page Container

**Component ID**: `page_container`  
**Category**: Layout/Structure  
**Frequency**: Used in 2 prompts (Account 360, MEDDIC)  
**Complexity**: Low

### Description
Outer container for entire page content with background color and responsive width.

### HTML/CSS Code

```html
<div style="font-family: system-ui, sans-serif; width: 100%; max-width: 1200px; margin: 0 auto; padding: 20px; border-radius: 8px; background: #B0C4DF;">
  {{PAGE_CONTENT}}
</div>
```

### Merge Fields
- `{{PAGE_CONTENT}}`: All page content (headers, cards, tables, etc.)

### Visual Style
- **Font Family**: system-ui, sans-serif (system default)
- **Width**: 100% with max-width 1200px (responsive, centered)
- **Margin**: 0 auto (centers container)
- **Padding**: 20px
- **Border Radius**: 8px (rounded corners)
- **Background**: Light blue-gray (#B0C4DF)

### Layout Context
This is the outermost container for the entire page. All other components nest inside it.

### Used In
- Account 360 View - Reimagined (full page wrapper)
- Can be used for any full-page AI-generated output

### Variations

**Variation A: White Background (Phase 0 Baseline)**
```html
<div style="font-family: 'Salesforce Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; max-width: 100%; background: #F3F3F3; color: #181818; font-size: 14px; line-height: 1.5; padding: 16px;">
  {{PAGE_CONTENT}}
</div>
```

**Variation B: No Background (Transparent)**
```html
<div style="font-family: system-ui, sans-serif; width: 100%; max-width: 1200px; margin: 0 auto; padding: 20px;">
  {{PAGE_CONTENT}}
</div>
```

---

## COMPONENT 10: Inline Status Badge

**Component ID**: `status_badge`  
**Category**: Data Display (Inline)  
**Frequency**: Implied in 2 prompts (Account 360)  
**Complexity**: Low

### Description
Small colored badge for displaying status, sentiment, or category inline with text or in table cells.

### HTML/CSS Code

```html
<span style="display: inline-block; padding: 4px 12px; border-radius: 4px; font-size: 0.75rem; font-weight: 600; background-color: {{BADGE_BG_COLOR}}; color: {{BADGE_TEXT_COLOR}};">{{BADGE_TEXT}}</span>
```

### Merge Fields
- `{{BADGE_TEXT}}`: Text to display in badge
- `{{BADGE_BG_COLOR}}`: Background color
- `{{BADGE_TEXT_COLOR}}`: Text color

### Visual Style
- **Display**: inline-block
- **Padding**: 4px 12px (vertical, horizontal)
- **Border Radius**: 4px (slightly rounded)
- **Font Size**: 0.75rem (12px)
- **Font Weight**: 600 (semi-bold)

### Color Schemes by Type

**Success/Positive**:
- Background: `#d4edda`
- Text: `#155724`
- Example: "Closed Won", "Resolved", "Positive"

**Warning/Medium**:
- Background: `#fff3cd`
- Text: `#856404`
- Example: "In Progress", "Neutral", "Medium"

**Danger/Negative**:
- Background: `#f8d7da`
- Text: `#721c24`
- Example: "At Risk", "Negative", "High Priority"

**Info/Default**:
- Background: `#d1ecf1`
- Text: `#0c5460`
- Example: "New", "Pending", "Information"

### Used In
- Account 360 (implied for status/sentiment display in tables)
- Can be used anywhere inline status indicators are needed

### Variations

**Variation A: Bold Text (for emphasis)**
```html
<span style="display: inline-block; padding: 4px 12px; border-radius: 4px; font-size: 0.875rem; font-weight: 700; background-color: {{BADGE_BG_COLOR}}; color: {{BADGE_TEXT_COLOR}};">{{BADGE_TEXT}}</span>
```

**Variation B: Larger Badge (for standalone use)**
```html
<span style="display: inline-block; padding: 6px 16px; border-radius: 6px; font-size: 1rem; font-weight: 600; background-color: {{BADGE_BG_COLOR}}; color: {{BADGE_TEXT_COLOR}};">{{BADGE_TEXT}}</span>
```

---

## COMPONENT 11: Lead-Sourcing Executive Layout (NEW)

**Component ID**: `executive_top_down`  
**Category**: Layout/Structure  
**Purpose**: Surface the "Lead" (Critical Insights) immediately to ensure high-value diagnoses are above the fold.

### HTML Structure
```html
<div class="executive-container" style="font-family: 'Salesforce Sans', sans-serif;">
  <!-- TOP: Critical Alerts (The Lead) -->
  <div class="critical-alerts" style="margin-bottom: 20px;">
    {{#risk_indicator}}
    <div style="background:#FFF1F1; border-left:4px solid #BA0517; padding:12px 16px; margin-bottom:12px; border-radius:4px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
       <div style="font-weight:700; color:#BA0517; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">{{RISK_TITLE}}</div>
       <div style="font-size:13px; color:#181818; margin-top: 4px; line-height: 1.4;">{{RISK_INSIGHT}}</div>
       <div style="font-size:11px; color:#706E6B; margin-top: 8px; border-top: 1px solid #F3F3F3; padding-top: 4px;">Evidence: {{EVIDENCE_CITATION}}</div>
    </div>
    {{/risk_indicator}}
  </div>

  <!-- MIDDLE: Supporting Summary -->
  <div style="background:white; padding:16px; border:1px solid #DDDBDA; border-radius:8px; margin-bottom:20px;">
    <div style="font-weight:700; color:#16325c; font-size: 13px; margin-bottom: 8px; text-transform: uppercase;">Executive Summary</div>
    <div style="font-size:13px; line-height:1.5; color:#181818;">{{EXECUTIVE_SUMMARY}}</div>
  </div>

  <!-- BOTTOM: Secondary Metrics (Compact) -->
  <div style="display:flex; gap:12px; flex-wrap: wrap;">
    {{#stat_card}}
    <div style="flex: 1; min-width: 120px; background:#F3F3F3; padding:10px; border-radius:4px; text-align:center;">
       <div style="font-size:10px; color:#706E6B; text-transform:uppercase;">{{LABEL}}</div>
       <div style="font-size:14px; font-weight:700; color:#16325c;">{{VALUE}}</div>
    </div>
    {{/stat_card}}
  </div>
</div>
```

---

## COMPONENT 12: Horizontal Milestone Timeline (NEW)

**Component ID**: `horizontal_timeline`  
**Category**: Visualization/Metaphor  
**Purpose**: Replace vertical lists with a spatial metaphor for progression, making it easier to see "where we are" and "what's next".

### HTML Structure
```html
<div style="padding: 20px; background: white; border: 1px solid #DDDBDA; border-radius: 8px;">
  <div style="font-weight:700; color:#16325c; font-size: 13px; margin-bottom: 20px; text-transform: uppercase;">Deal Progression Timeline</div>
  
  <div style="display:flex; justify-content:space-between; align-items:flex-start; position:relative; margin: 0 10px;">
    <!-- Connecting Line -->
    <div style="position:absolute; top:12px; left:0; right:0; height:2px; background:#DDDBDA; z-index:0;"></div>
    
    {{#milestone}}
    <div style="flex:1; text-align:center; position:relative; z-index:1;">
      <!-- Node -->
      <div style="width:24px; height:24px; border-radius:12px; background:{{NODE_COLOR}}; border:4px solid white; margin:0 auto 8px; box-shadow:0 0 0 1px #DDDBDA;"></div>
      
      <!-- Labels -->
      <div style="font-size:11px; font-weight:700; color:#181818; line-height: 1.2; padding: 0 4px;">{{LABEL}}</div>
      <div style="font-size:10px; color:{{STATUS_COLOR}}; margin-top: 2px;">{{STATUS_TEXT}}</div>
      <div style="font-size:9px; color:#706E6B; margin-top: 2px;">{{DATE}}</div>
    </div>
    {{/milestone}}
  </div>
</div>
```

---

## SUMMARY: COMPONENT USAGE MATRIX

| Component | Account 360 | MEDDIC | Case Analysis | Opportunity |
|-----------|-------------|--------|---------------|-------------|
| Stat Card | ✅ High | ✅ Medium | ✅ Medium | ✅ High |
| Data Table | ✅ Very High | ✅ High | ✅ High | ✅ High |
| Card Container | ✅ High | ✅ High | ✅ Medium | ✅ High |
| Page Header (Gradient) | ✅ High | ❌ | ❌ | ✅ High |
| Alert/Info Box | ❌ | ✅ Medium | ✅ Low | ✅ Medium |
| MEDDIC Summary Table | ❌ | ✅ Very High | ❌ | ✅ Low* |
| Empty State | ✅ High | ❌ | ✅ Medium | ✅ Medium |
| Section Title | ❌ | ✅ High | ✅ Low | ✅ Medium |
| Page Container | ✅ High | ✅ High | ✅ High | ✅ High |
| Status Badge | ✅ Medium | ✅ Low | ✅ High | ✅ Medium |

*MEDDIC Summary Table only if using MEDDIC methodology

---

## COMPONENT COMBINATION RECOMMENDATIONS

### For Account 360 View:
```
Page Container
├── Page Header (Gradient)
├── Stat Cards (Flex Row) [4-6 cards]
├── Card Container (Executive Summary)
├── Card Container (Opportunities Table)
├── Card Container (Cases Table)
└── Card Container (Tasks/Events Tables)
```

### For Opportunity Analysis (MEDDIC):
```
Page Container
├── Section Title (MEDDIC Compliance Summary)
├── MEDDIC Summary Table
├── Alert Box (Overall Score & Recommendation)
├── Card Container (Each MEDDIC Element Details)
│   ├── Section Title (Element Name)
│   ├── Data Table (Evidence)
│   └── Status Badges (inline)
└── Card Container (Priority Actions)
```

### For Case Analysis:
```
Page Container
├── Card Container (Case Summary)
│   └── Stat Cards (Sentiment, Days Open, Priority)
├── Card Container (Intent Analysis)
├── Card Container (Root Cause & Corrective Action)
└── Alert Box (Next Best Action)
```

### For Dashboard/Scorecard:
```
Page Container
├── Page Header (with Title)
├── Stat Cards (Primary Metrics) [6-9 cards in responsive grid]
├── Card Container (Key Insights)
└── Card Container (Action Items Table)
```

---

## STYLING CONSISTENCY GUIDE

### Salesforce Brand Colors

**Primary Palette**:
- Primary Blue: `#0176D3`
- Dark Blue: `#014486` or `#16325c`
- Light Blue: `#1B96FF` or `#f0f7ff`

**Semantic Colors**:
- Success Green: `#28a745` or `#2E844A`
- Warning Orange: `#FF9800` or `#DD7A01`
- Error Red: `#dc3545` or `#BA0517`

**Neutral Colors**:
- Text Primary: `#181818` or `#000000`
- Text Secondary: `#706E6B` or `#5C5C5C`
- Background: `#F3F3F3` or `#B0C4DF`
- Card Background: `#FFFFFF`
- Border: `#DDDBDA` or `#dee2e6`
- Gray Text: `#A8A8A8`

### Typography

**Font Families**:
- Primary: `'Salesforce Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif`
- Fallback: `system-ui, sans-serif`

**Font Sizes**:
- Page Title (h1): `1.75rem` or `20px`
- Section Title (h2): `1.5rem` or `1.25rem`
- Body Text: `14px` or `0.875rem`
- Small Text: `12px` or `0.75rem`

**Font Weights**:
- Normal: `400`
- Medium: `500`
- Semi-Bold: `600`
- Bold: `700` or `bold`

### Spacing

**Padding**:
- Small: `0.5rem` (8px)
- Medium: `1rem` (16px)
- Large: `1.5rem` (24px) or `20px`

**Margin**:
- Between elements: `1rem` (16px)
- Between sections: `2rem` (32px) or `12px`

**Gap** (Flex/Grid):
- Small: `0.5rem` (8px)
- Medium: `1rem` (16px)
- Large: `1.5rem` (24px)

### Borders & Shadows

**Border Radius**:
- Small (badges, buttons): `4px`
- Medium (cards): `6px` or `8px`
- None (tables): `0`

**Shadows**:
- Subtle (stat cards): `0 1px 2px rgba(0,0,0,0.1)`
- Medium (main cards): `0 2px 4px rgba(0,0,0,0.1)`
- None (nested elements): none

**Border Widths**:
- Thin (table cells): `1px`
- Medium (table headers): `2px`
- Thick (accent borders): `4px`

---

## CRITICAL OUTPUT RULES (from prompts)

All UI components MUST follow these rules when used in GPTfy:

1. **SINGLE LINE**: Output must be one continuous line with NO newline characters
2. **NO STYLE BLOCKS**: Do NOT include `<style>` tags (use inline styles only)
3. **NO CSS CLASSES**: Do NOT use `class` attributes (no stylesheets available)
4. **NO SCRIPT TAGS**: Do NOT include JavaScript
5. **NO MARKDOWN**: Do NOT wrap in code blocks or markdown formatting
6. **START WITH DIV**: Output must begin with a `<div>` element with inline styles
7. **END WITH DIV**: Output must end with closing `</div>` tag
8. **NO PLACEHOLDERS**: Never use bracket-X, TBD, TODO, or similar
9. **NO NULL VALUES**: Handle missing data gracefully (omit section or use default)
10. **NO EMOJIS**: Avoid emoji characters (use text indicators instead)

---

**End of UI Components Library**  
**Total Components Extracted**: 10  
**Ready for Phase 1 Implementation**: ✅
