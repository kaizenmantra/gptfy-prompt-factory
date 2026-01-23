# UI Toolkit for Meta-Prompt

**Purpose**: Component library documentation for V2.0 meta-prompt Section 4
**Usage**: This content is injected into the meta-prompt to guide LLM component selection
**Date**: 2026-01-23

---

## Overview

This toolkit defines available UI components for dashboard generation. The LLM should use these strategically to create insight-driven dashboards (not table-heavy displays).

---

## Layout Components

### Dashboard Container
**Purpose**: Full-width responsive layout wrapper

**HTML Pattern**:
```html
<div style="max-width:1200px;margin:0 auto;padding:20px;background:#F3F3F3;font-family:'Salesforce Sans',Arial,sans-serif;">
  <!-- Content here -->
</div>
```

### Section Card
**Purpose**: White card with header and content area

**HTML Pattern**:
```html
<div style="background:white;border-radius:8px;padding:20px;margin-bottom:16px;box-shadow:0 2px 4px rgba(0,0,0,0.1);">
  <h2 style="margin:0 0 16px 0;font-size:18px;font-weight:600;color:#181818;">Section Title</h2>
  <!-- Content here -->
</div>
```

### Stats Strip
**Purpose**: Horizontal metrics display (3-5 key numbers)

**HTML Pattern**:
```html
<div style="display:flex;gap:16px;margin-bottom:20px;">
  <div style="flex:1;background:white;border-radius:6px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,0.1);">
    <div style="font-size:28px;font-weight:700;color:#0176D3;margin-bottom:4px;">{{{Value}}}</div>
    <div style="font-size:13px;color:#706E6B;">Label</div>
  </div>
  <!-- Repeat for each stat -->
</div>
```

### Two-Column Grid
**Purpose**: Side-by-side content areas

**HTML Pattern**:
```html
<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px;">
  <div><!-- Left column content --></div>
  <div><!-- Right column content --></div>
</div>
```

---

## Insight Components

### Alert Box
**Purpose**: Highlight critical information with semantic color

**Types**: Error (red), Warning (orange), Info (blue), Success (green)

**HTML Pattern**:
```html
<!-- ERROR -->
<div style="background:#FED7D7;border-left:4px solid #BA0517;padding:12px 16px;border-radius:4px;margin-bottom:12px;">
  <div style="font-weight:600;color:#BA0517;margin-bottom:4px;">Critical Issue</div>
  <div style="color:#54514C;">Description with specific evidence</div>
</div>

<!-- WARNING -->
<div style="background:#FEF3CD;border-left:4px solid #DD7A01;padding:12px 16px;border-radius:4px;margin-bottom:12px;">
  <div style="font-weight:600;color:#DD7A01;margin-bottom:4px;">Warning</div>
  <div style="color:#54514C;">Description with specific evidence</div>
</div>

<!-- INFO -->
<div style="background:#D7E9FC;border-left:4px solid #0176D3;padding:12px 16px;border-radius:4px;margin-bottom:12px;">
  <div style="font-weight:600;color:#0176D3;margin-bottom:4px;">Information</div>
  <div style="color:#54514C;">Description with specific evidence</div>
</div>
```

### Insight Card
**Purpose**: Analysis finding with evidence citation

**HTML Pattern**:
```html
<div style="background:white;border-radius:6px;padding:16px;margin-bottom:12px;border:1px solid #DDDBDA;">
  <div style="font-weight:600;color:#181818;margin-bottom:8px;">Insight Title</div>
  <div style="color:#706E6B;margin-bottom:12px;line-height:1.5;">
    Analysis text with specific evidence: Amount={{{Amount}}}, StageName={{{StageName}}}
  </div>
  <div style="font-size:12px;color:#706E6B;">
    <strong>Evidence:</strong> Task.Status='Overdue', Contact.LastActivityDate=null
  </div>
</div>
```

### Recommendation Card
**Purpose**: Action item with rationale and urgency

**HTML Pattern**:
```html
<div style="background:#FFFFFF;border-left:4px solid #2E844A;border-radius:6px;padding:16px;margin-bottom:12px;box-shadow:0 1px 3px rgba(0,0,0,0.1);">
  <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
    <div style="font-weight:600;color:#181818;">Recommended Action</div>
    <div style="background:#DD7A01;color:white;padding:4px 12px;border-radius:12px;font-size:11px;font-weight:600;">URGENT</div>
  </div>
  <div style="color:#706E6B;margin-bottom:12px;line-height:1.5;">
    Specific action: "Schedule call with {{{Contact.Name}}} by Friday"
  </div>
  <div style="font-size:12px;color:#706E6B;">
    <strong>Why:</strong> Task overdue 7 days, blocking deal progression
  </div>
</div>
```

### Health Score
**Purpose**: Visual indicator (0-100 with color coding)

**HTML Pattern**:
```html
<div style="display:flex;align-items:center;gap:12px;">
  <div style="font-size:36px;font-weight:700;color:#2E844A;">85</div>
  <div>
    <div style="font-size:14px;font-weight:600;color:#181818;">Health Score</div>
    <div style="width:200px;height:8px;background:#E0E0E0;border-radius:4px;overflow:hidden;">
      <div style="width:85%;height:100%;background:#2E844A;"></div>
    </div>
  </div>
</div>
```

---

## Data Components

### Data Table
**Purpose**: Listing related records (use sparingly!)

**HTML Pattern**:
```html
<table style="width:100%;border-collapse:collapse;margin-bottom:16px;">
  <thead>
    <tr style="background:#F3F3F3;border-bottom:2px solid #DDDBDA;">
      <th style="padding:8px;text-align:left;font-size:12px;color:#706E6B;font-weight:600;">Column 1</th>
      <th style="padding:8px;text-align:left;font-size:12px;color:#706E6B;font-weight:600;">Column 2</th>
    </tr>
  </thead>
  <tbody>
    {{#Collection}}
    <tr style="border-bottom:1px solid #DDDBDA;">
      <td style="padding:8px;font-size:13px;color:#181818;">{{{Field1}}}</td>
      <td style="padding:8px;font-size:13px;color:#181818;">{{{Field2}}}</td>
    </tr>
    {{/Collection}}
  </tbody>
</table>
```

### Metric Tile
**Purpose**: Single KPI with label and trend indicator

**HTML Pattern**:
```html
<div style="background:white;border-radius:6px;padding:16px;text-align:center;box-shadow:0 1px 3px rgba(0,0,0,0.1);">
  <div style="font-size:32px;font-weight:700;color:#0176D3;margin-bottom:4px;">{{{Value}}}</div>
  <div style="font-size:13px;color:#706E6B;margin-bottom:4px;">Metric Label</div>
  <div style="font-size:12px;color:#2E844A;">▲ 15% vs last month</div>
</div>
```

### Status Badge
**Purpose**: Inline status indicator with semantic color

**HTML Pattern**:
```html
<!-- Success -->
<span style="background:#D4EDDA;color:#2E844A;padding:4px 8px;border-radius:4px;font-size:11px;font-weight:600;">ACTIVE</span>

<!-- Warning -->
<span style="background:#FEF3CD;color:#DD7A01;padding:4px 8px;border-radius:4px;font-size:11px;font-weight:600;">AT RISK</span>

<!-- Error -->
<span style="background:#FED7D7;color:#BA0517;padding:4px 8px;border-radius:4px;font-size:11px;font-weight:600;">CRITICAL</span>
```

---

## Component Usage Rules

### Priority Order
1. **Lead with insights**: Start with Alert Boxes or Insight Cards
2. **Key metrics second**: Use Stats Strip for 3-5 critical numbers
3. **Recommendations third**: Use Recommendation Cards for actions
4. **Tables LAST**: Only if data warrants, and always with context paragraph

### When to Use Each

**Alert Box**:
- Critical issues requiring immediate attention
- Warnings about data gaps or risks
- Success confirmations

**Insight Card**:
- Analysis findings with supporting evidence
- Pattern observations across data
- Comparative insights (vs benchmark, vs previous)

**Recommendation Card**:
- Specific action items with owners and deadlines
- Next steps with clear rationale
- Prioritized by urgency (URGENT, HIGH, NORMAL)

**Data Table**:
- ONLY when listing records adds value
- Keep to 5-7 rows maximum
- Always add context paragraph BEFORE the table
- Never lead a dashboard with a table

### Anti-Patterns (DO NOT DO)

❌ **Table-First Dashboard**: Never start with tables
❌ **Data Dump**: Don't just display all available data
❌ **Generic Insights**: "Tasks need attention" - be specific!
❌ **Placeholder Text**: No TBD, TODO, or [Description]
❌ **Wall of Tables**: Use maximum 2-3 tables per dashboard

### Best Practices

✅ **Executive Summary First**: 2-3 sentence overview at top
✅ **Evidence Citations**: Always cite specific field:value
✅ **Action-Oriented**: Every insight should drive a decision
✅ **Visual Hierarchy**: Use size, color, spacing strategically
✅ **Responsive Design**: Components work on mobile and desktop

---

## Color Palette

### Semantic Colors
- **Primary (Blue)**: `#0176D3` - Links, primary actions
- **Success (Green)**: `#2E844A` - Positive metrics, success states
- **Warning (Orange)**: `#DD7A01` - Warnings, at-risk items
- **Error (Red)**: `#BA0517` - Critical issues, failures
- **Info (Light Blue)**: `#0176D3` (lighter: `#D7E9FC`) - Info alerts

### Neutral Colors
- **Text Primary**: `#181818` - Headings, primary text
- **Text Secondary**: `#706E6B` - Body text, labels
- **Text Tertiary**: `#54514C` - De-emphasized text
- **Background**: `#F3F3F3` - Page background
- **Card Background**: `#FFFFFF` - Card/component background
- **Border**: `#DDDBDA` - Borders, dividers

---

## Accessibility Notes

- Minimum font size: 11px (use 13-14px for body text)
- Color contrast: All text meets WCAG AA standards
- Touch targets: Minimum 44x44px for interactive elements
- Focus indicators: Not needed (output is read-only HTML)

---

**Usage in Meta-Prompt**: This entire document is compressed and injected into Section 4 (UI TOOLKIT) of the meta-prompt, giving the LLM a component library to work with during dashboard generation.
