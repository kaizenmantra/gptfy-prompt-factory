This is a solid foundation! I can see you've built a comprehensive MEDDIC analyzer. Let me provide detailed recommendations across multiple dimensions to elevate this from good to exceptional.

---

# MEDDIC Prompt Enhancement Recommendations

## Table of Contents

1. [UI/UX Improvements](#1-uiux-improvements)
2. [Prescriptive Guidance Enhancements](#2-prescriptive-guidance-enhancements)
3. [Sales Rep Specific Improvements](#3-sales-rep-specific-improvements)
4. [Leadership/Manager Specific Improvements](#4-leadershipmanager-specific-improvements)
5. [Data Quality & Intelligence Enhancements](#5-data-quality--intelligence-enhancements)
6. [Revised Prompt Command](#6-revised-prompt-command)
7. [Alternative Output Formats](#7-alternative-output-formats)

---

# 1. UI/UX Improvements

## 1.1 Current Issues Identified

| Issue | Impact | Priority |
|-------|--------|----------|
| Dense text blocks | Reduces scannability | HIGH |
| Inconsistent color usage | Confuses status interpretation | HIGH |
| Missing visual progress indicators | Hard to gauge element health at a glance | MEDIUM |
| No trend indicators | Can't see if deal is improving or declining | MEDIUM |
| Section hierarchy unclear | Important info may be missed | MEDIUM |
| No mobile optimization consideration | Field reps can't use effectively | LOW |

## 1.2 Recommended Visual Hierarchy

**New Information Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│  1. DEAL HEALTH DASHBOARD (5-second view)                       │
│     - Overall score gauge                                       │
│     - Traffic light status                                      │
│     - Single most important action                              │
├─────────────────────────────────────────────────────────────────┤
│  2. MEDDIC SCORECARD (30-second view)                          │
│     - Visual element bars                                       │
│     - Stage alignment indicator                                 │
│     - Score trend arrows                                        │
├─────────────────────────────────────────────────────────────────┤
│  3. RISK & OPPORTUNITY SUMMARY (1-minute view)                 │
│     - Critical blockers                                         │
│     - Positive momentum signals                                 │
│     - Competitive position                                      │
├─────────────────────────────────────────────────────────────────┤
│  4. DETAILED ANALYSIS (Deep dive)                              │
│     - Element-by-element breakdown                              │
│     - Stakeholder map                                           │
│     - Activity analysis                                         │
├─────────────────────────────────────────────────────────────────┤
│  5. ACTION PLAN (Execution focus)                              │
│     - Prioritized actions with scripts                          │
│     - Meeting agendas                                           │
│     - Manager coaching points                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 1.3 Enhanced Color System

**Recommended Color Palette:**

```css
/* Status Colors - More intuitive */
--strong: #2e844a;      /* Green - On track */
--good: #7cc47f;        /* Light green - Progressing well */
--caution: #f4bc25;     /* Amber - Needs attention */
--at-risk: #dd7a01;     /* Orange - At risk */
--critical: #c23934;    /* Red - Critical issue */

/* VusionGroup Brand */
--primary: #0176d3;     /* Primary blue */
--dark: #16325c;        /* Dark blue */
--light-bg: #f0f7ff;    /* Light blue background */

/* Semantic Colors */
--trend-up: #2e844a;    /* Improving */
--trend-down: #c23934;  /* Declining */
--trend-flat: #706e6b;  /* No change */
```

## 1.4 New Visual Components

### 1.4.1 Deal Health Gauge (Add to top)

```html
<!-- DEAL HEALTH GAUGE - Add at very top -->
<div style="display: flex; justify-content: center; margin-bottom: 20px;">
  <div style="text-align: center; padding: 20px; background: linear-gradient(135deg, #f0f7ff 0%, #ffffff 100%); border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
    
    <!-- Circular Score Gauge -->
    <div style="position: relative; width: 120px; height: 120px; margin: 0 auto;">
      <svg viewBox="0 0 36 36" style="transform: rotate(-90deg);">
        <!-- Background circle -->
        <circle cx="18" cy="18" r="15.9" fill="none" stroke="#e0e0e0" stroke-width="3"/>
        <!-- Score circle - stroke-dasharray = score percentage -->
        <circle cx="18" cy="18" r="15.9" fill="none" 
                stroke="[COLOR_BASED_ON_SCORE]" 
                stroke-width="3" 
                stroke-dasharray="[SCORE], 100"
                stroke-linecap="round"/>
      </svg>
      <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #16325c;">
        80%
      </div>
    </div>
    
    <!-- Status Label -->
    <div style="margin-top: 10px; font-size: 14px; color: #706e6b;">MEDDIC Score</div>
    <div style="font-size: 18px; font-weight: 600; color: #f4bc25;">⚠️ CAUTION</div>
    
    <!-- Trend Indicator -->
    <div style="margin-top: 5px; font-size: 12px; color: #2e844a;">
      ↑ +5% from last analysis
    </div>
  </div>
</div>
```

### 1.4.2 Visual Progress Bars for MEDDIC Elements

```html
<!-- MEDDIC Element with Visual Bar -->
<div style="margin-bottom: 15px;">
  <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
    <span style="font-weight: 600; color: #16325c;">
      <span style="display: inline-block; width: 24px; height: 24px; background: #0176d3; color: white; border-radius: 50%; text-align: center; line-height: 24px; font-size: 12px; margin-right: 8px;">M</span>
      Metrics
    </span>
    <span style="font-weight: bold;">75%</span>
  </div>
  
  <!-- Progress Bar -->
  <div style="background: #e0e0e0; border-radius: 10px; height: 12px; overflow: hidden;">
    <div style="background: linear-gradient(90deg, #7cc47f 0%, #2e844a 100%); width: 75%; height: 100%; border-radius: 10px; transition: width 0.5s;"></div>
  </div>
  
  <!-- Stage Threshold Marker -->
  <div style="position: relative; margin-top: -12px;">
    <div style="position: absolute; left: 65%; width: 2px; height: 16px; background: #16325c; top: -2px;">
      <span style="position: absolute; top: 18px; left: -20px; font-size: 10px; color: #706e6b;">Stage Min</span>
    </div>
  </div>
  
  <!-- Quick Status -->
  <div style="display: flex; justify-content: space-between; margin-top: 15px; font-size: 12px; color: #706e6b;">
    <span>✓ ROI documented</span>
    <span style="color: #dd7a01;">⚠ Customer validation pending</span>
  </div>
</div>
```

### 1.4.3 Stakeholder Influence Map (Visual)

```html
<!-- STAKEHOLDER INFLUENCE QUADRANT -->
<div style="margin: 20px 0;">
  <h3 style="color: #16325c; margin-bottom: 15px;">Stakeholder Influence Map</h3>
  
  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2px; background: #e0e0e0; padding: 2px; border-radius: 8px;">
    
    <!-- High Influence + Supporter -->
    <div style="background: #d4edda; padding: 15px; border-radius: 6px 0 0 0;">
      <div style="font-size: 11px; color: #155724; margin-bottom: 8px;">HIGH INFLUENCE + SUPPORTIVE</div>
      <div style="font-weight: 600;">Jennifer Martinez</div>
      <div style="font-size: 12px; color: #666;">Champion • Promoter</div>
    </div>
    
    <!-- High Influence + Neutral/Negative -->
    <div style="background: #fff3cd; padding: 15px; border-radius: 0 6px 0 0;">
      <div style="font-size: 11px; color: #856404; margin-bottom: 8px;">HIGH INFLUENCE + NEEDS WORK</div>
      <div style="font-weight: 600; color: #c23934;">David Chen ⚠️</div>
      <div style="font-size: 12px; color: #666;">Economic Buyer • Neutral</div>
    </div>
    
    <!-- Low Influence + Supporter -->
    <div style="background: #e8f5e9; padding: 15px; border-radius: 0 0 0 6px;">
      <div style="font-size: 11px; color: #2e844a; margin-bottom: 8px;">LOWER INFLUENCE + SUPPORTIVE</div>
      <div style="font-weight: 600;">Sarah Williams</div>
      <div style="font-size: 12px; color: #666;">User • Supporter</div>
    </div>
    
    <!-- Low Influence + Neutral/Negative -->
    <div style="background: #f8f9fa; padding: 15px; border-radius: 0 0 6px 0;">
      <div style="font-size: 11px; color: #706e6b; margin-bottom: 8px;">LOWER INFLUENCE + NEUTRAL</div>
      <div style="font-weight: 600;">Robert Johnson</div>
      <div style="font-size: 12px; color: #666;">Technical Buyer • Neutral</div>
    </div>
    
  </div>
</div>
```

### 1.4.4 Timeline/Momentum Indicator

```html
<!-- DEAL MOMENTUM TIMELINE -->
<div style="margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
  <h3 style="color: #16325c; margin-bottom: 15px;">Deal Momentum</h3>
  
  <div style="display: flex; align-items: center; justify-content: space-between;">
    
    <!-- Days in Stage -->
    <div style="text-align: center;">
      <div style="font-size: 28px; font-weight: bold; color: #0176d3;">23</div>
      <div style="font-size: 12px; color: #706e6b;">Days in Stage</div>
      <div style="font-size: 11px; color: #2e844a;">✓ Within avg (30 days)</div>
    </div>
    
    <!-- Activity Trend -->
    <div style="text-align: center;">
      <div style="font-size: 28px; font-weight: bold; color: #2e844a;">↑</div>
      <div style="font-size: 12px; color: #706e6b;">Activity Trend</div>
      <div style="font-size: 11px; color: #2e844a;">+40% vs last month</div>
    </div>
    
    <!-- Days to Close -->
    <div style="text-align: center;">
      <div style="font-size: 28px; font-weight: bold; color: #f4bc25;">12</div>
      <div style="font-size: 12px; color: #706e6b;">Days to Close Date</div>
      <div style="font-size: 11px; color: #dd7a01;">⚠ Tight timeline</div>
    </div>
    
    <!-- Stakeholder Engagement -->
    <div style="text-align: center;">
      <div style="font-size: 28px; font-weight: bold; color: #2e844a;">5</div>
      <div style="font-size: 12px; color: #706e6b;">Active Stakeholders</div>
      <div style="font-size: 11px; color: #2e844a;">✓ Multi-threaded</div>
    </div>
    
  </div>
</div>
```

## 1.5 Improved Action Card Design

```html
<!-- PRIORITY ACTION CARD -->
<div style="border-left: 4px solid #c23934; background: linear-gradient(90deg, #fef2f2 0%, #ffffff 100%); padding: 15px; margin-bottom: 15px; border-radius: 0 8px 8px 0;">
  
  <div style="display: flex; justify-content: space-between; align-items: start;">
    <div>
      <span style="background: #c23934; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600;">CRITICAL</span>
      <span style="background: #0176d3; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-left: 5px;">Economic Buyer</span>
    </div>
    <span style="color: #706e6b; font-size: 12px;">Due: This Week</span>
  </div>
  
  <h4 style="color: #16325c; margin: 10px 0 5px 0;">Schedule meeting with David Chen to validate budget authority</h4>
  
  <p style="color: #706e6b; font-size: 13px; margin: 0 0 10px 0;">
    David Chen has been marked as Neutral. Need to convert to Supporter before advancing to Budget Approved stage.
  </p>
  
  <!-- Success Criteria -->
  <div style="background: white; padding: 10px; border-radius: 6px; margin-bottom: 10px;">
    <div style="font-size: 11px; color: #706e6b; margin-bottom: 5px;">SUCCESS CRITERIA:</div>
    <ul style="margin: 0; padding-left: 20px; font-size: 13px;">
      <li>Confirm David has budget authority for this fiscal year</li>
      <li>Understand his specific concerns/requirements</li>
      <li>Get verbal support for the business case</li>
    </ul>
  </div>
  
  <!-- Talk Track -->
  <details style="cursor: pointer;">
    <summary style="color: #0176d3; font-weight: 600; font-size: 13px;">📝 Suggested Talk Track</summary>
    <div style="background: #f8f9fa; padding: 10px; margin-top: 10px; border-radius: 6px; font-size: 13px; font-style: italic;">
      "David, Jennifer mentioned you're evaluating the ROI for this initiative. I'd love to walk you through the business case we've built together and understand what success metrics matter most to you. Could we schedule 30 minutes this week?"
    </div>
  </details>
  
</div>
```

---

# 2. Prescriptive Guidance Enhancements

## 2.1 Current Gaps in Guidance

| Gap | Impact | Recommendation |
|-----|--------|----------------|
| Generic recommendations | Reps don't know exactly what to do | Add specific scripts and templates |
| Missing meeting agendas | Reps unprepared for key meetings | Generate meeting agendas for recommended actions |
| No objection handling | Reps struggle with resistance | Add common objections and responses |
| Missing email templates | Delays in outreach | Provide ready-to-send email drafts |
| No competitive playbooks | Lose deals to competitors | Add competitive positioning guidance |
| Missing discovery questions | Incomplete MEDDIC data gathering | Add questions to ask for each element |

## 2.2 Enhanced Guidance Components

### 2.2.1 Meeting Agenda Generator

**Add to Action Plan section:**

```html
<!-- SUGGESTED MEETING AGENDA -->
<div style="background: #f0f7ff; padding: 15px; border-radius: 8px; margin-top: 15px;">
  <h4 style="color: #16325c; margin: 0 0 10px 0;">📅 Suggested Meeting Agenda: David Chen (EB)</h4>
  
  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6; width: 80px;"><strong>5 min</strong></td>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6;">
        <strong>Opening & Context</strong><br>
        <span style="color: #706e6b;">Reference Jennifer's endorsement, acknowledge his time</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6;"><strong>10 min</strong></td>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6;">
        <strong>Business Case Review</strong><br>
        <span style="color: #706e6b;">Walk through ROI: labor savings, pricing accuracy, payback period</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6;"><strong>10 min</strong></td>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6;">
        <strong>His Priorities & Concerns</strong><br>
        <span style="color: #706e6b;">Ask: "What would make this a clear yes for you?"</span>
      </td>
    </tr>
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6;"><strong>5 min</strong></td>
      <td style="padding: 8px; border-bottom: 1px solid #dee2e6;">
        <strong>Next Steps & Timeline</strong><br>
        <span style="color: #706e6b;">Confirm budget approval process and timeline</span>
      </td>
    </tr>
  </table>
  
  <div style="margin-top: 10px; padding: 10px; background: white; border-radius: 6px;">
    <strong style="color: #16325c;">🎯 Meeting Objective:</strong> 
    Move David from Neutral to Supporter by validating the business case addresses his priorities
  </div>
</div>
```

### 2.2.2 Discovery Questions by MEDDIC Element

**Add to detailed element analysis:**

```html
<!-- DISCOVERY QUESTIONS - ECONOMIC BUYER -->
<div style="margin-top: 15px; padding: 15px; background: #fff3cd; border-radius: 8px;">
  <h4 style="color: #856404; margin: 0 0 10px 0;">🔍 Discovery Questions to Ask</h4>
  
  <div style="font-size: 13px;">
    <p style="margin: 5px 0;"><strong>Budget Authority:</strong></p>
    <ul style="margin: 5px 0 15px 0; padding-left: 20px;">
      <li>"Who else needs to approve investments of this size?"</li>
      <li>"What's your approval limit, and does this fall within it?"</li>
      <li>"Is this budgeted for this fiscal year, or would it come from next year's budget?"</li>
    </ul>
    
    <p style="margin: 5px 0;"><strong>Decision Criteria:</strong></p>
    <ul style="margin: 5px 0 15px 0; padding-left: 20px;">
      <li>"What metrics will you use to determine if this was a successful investment?"</li>
      <li>"Are there any concerns the board has raised about this type of initiative?"</li>
    </ul>
    
    <p style="margin: 5px 0;"><strong>Personal Win:</strong></p>
    <ul style="margin: 5px 0 0 0; padding-left: 20px;">
      <li>"How does this initiative align with your strategic priorities this year?"</li>
      <li>"What would a successful ESL rollout mean for your operational goals?"</li>
    </ul>
  </div>
</div>
```

### 2.2.3 Objection Handling Guide

**Add new section:**

```html
<!-- OBJECTION HANDLING -->
<div style="border-left: 4px solid #0176d3; padding: 15px; margin: 20px 0;">
  <h2 style="color: #16325c;">ANTICIPATED OBJECTIONS & RESPONSES</h2>
  
  <p style="color: #706e6b; font-size: 13px;">Based on stakeholder analysis and stage, prepare for these likely objections:</p>
  
  <!-- Objection 1 -->
  <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0;">
    <div style="display: flex; align-items: start;">
      <span style="background: #c23934; color: white; padding: 4px 8px; border-radius: 4px; font-size: 11px; margin-right: 10px;">LIKELY</span>
      <div>
        <strong style="color: #16325c;">"The ROI looks good, but I need to see proof from similar retailers."</strong>
        <p style="color: #706e6b; font-size: 13px; margin: 8px 0;">
          <em>This objection is common when EB is Neutral and Metrics validation is incomplete.</em>
        </p>
      </div>
    </div>
    
    <div style="background: white; padding: 10px; border-radius: 6px; margin-top: 10px;">
      <strong style="color: #2e844a;">✓ Recommended Response:</strong>
      <p style="font-size: 13px; margin: 8px 0 0 0;">
        "That's a great point, David. We have several grocery retailers similar to FreshMarket who've achieved [X]% labor savings. I can arrange a reference call with [Similar Customer] who completed their rollout last quarter. Would that help validate the business case for your board?"
      </p>
    </div>
    
    <div style="margin-top: 10px; font-size: 12px; color: #706e6b;">
      <strong>Supporting Evidence Available:</strong> Carrefour case study, Walmart reference, ROI calculator
    </div>
  </div>
  
  <!-- Objection 2 -->
  <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0;">
    <div style="display: flex; align-items: start;">
      <span style="background: #f4bc25; color: #16325c; padding: 4px 8px; border-radius: 4px; font-size: 11px; margin-right: 10px;">POSSIBLE</span>
      <div>
        <strong style="color: #16325c;">"We're also looking at [Competitor]. Why should we choose VusionGroup?"</strong>
      </div>
    </div>
    
    <div style="background: white; padding: 10px; border-radius: 6px; margin-top: 10px;">
      <strong style="color: #2e844a;">✓ Recommended Response:</strong>
      <p style="font-size: 13px; margin: 8px 0 0 0;">
        "I appreciate you being transparent about that. The key differentiators for retailers like FreshMarket are: [1] Our VusionCloud platform that enables future capabilities like retail media and dynamic pricing, [2] Our 350+ global retail deployments including [similar customers], and [3] Our North America support infrastructure. What specific criteria are most important to you?"
      </p>
    </div>
  </div>
  
</div>
```

### 2.2.4 Email Templates

**Add to Action Plan:**

```html
<!-- EMAIL TEMPLATE -->
<details style="margin-top: 15px;">
  <summary style="color: #0176d3; font-weight: 600; cursor: pointer;">
    📧 Email Template: Request Meeting with David Chen
  </summary>
  
  <div style="background: #f8f9fa; padding: 15px; margin-top: 10px; border-radius: 8px; font-size: 13px;">
    <p style="margin: 0 0 10px 0;"><strong>Subject:</strong> FreshMarket ESL Initiative - Business Case Review</p>
    
    <div style="background: white; padding: 15px; border-radius: 6px; border: 1px solid #dee2e6;">
      <p>Hi David,</p>
      
      <p>Jennifer Martinez mentioned you're reviewing the business case for our electronic shelf label initiative. I'd love to walk you through the ROI analysis we've developed together and understand your priorities for this investment.</p>
      
      <p>Specifically, I'd like to cover:</p>
      <ul>
        <li>The projected labor savings and payback period</li>
        <li>How other grocery retailers have measured success</li>
        <li>Any questions or concerns from your perspective</li>
      </ul>
      
      <p>Would you have 30 minutes this week or early next week? I'm flexible on timing.</p>
      
      <p>Best regards,<br>[Your Name]</p>
    </div>
    
    <div style="margin-top: 10px; display: flex; gap: 10px;">
      <button style="background: #0176d3; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;">📋 Copy to Clipboard</button>
      <button style="background: white; color: #0176d3; border: 1px solid #0176d3; padding: 8px 16px; border-radius: 4px; cursor: pointer;">✏️ Customize</button>
    </div>
  </div>
</details>
```

### 2.2.5 Competitive Positioning Guide

**Add new section based on Competitor__c field:**

```html
<!-- COMPETITIVE INTELLIGENCE -->
<div style="border-left: 4px solid #dd7a01; padding: 15px; margin: 20px 0;">
  <h2 style="color: #16325c;">COMPETITIVE POSITIONING</h2>
  
  <div style="display: flex; gap: 20px; margin-bottom: 15px;">
    <div style="flex: 1; background: #fff3cd; padding: 15px; border-radius: 8px;">
      <h4 style="margin: 0 0 10px 0; color: #856404;">Primary Competitor</h4>
      <div style="font-size: 18px; font-weight: bold; color: #16325c;">Pricer</div>
      <div style="font-size: 13px; color: #706e6b;">Threat Level: Medium</div>
    </div>
    
    <div style="flex: 1; background: #d4edda; padding: 15px; border-radius: 8px;">
      <h4 style="margin: 0 0 10px 0; color: #155724;">Our Win Rate vs Pricer</h4>
      <div style="font-size: 18px; font-weight: bold; color: #2e844a;">68%</div>
      <div style="font-size: 13px; color: #706e6b;">Last 12 months</div>
    </div>
  </div>
  
  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
    <tr style="background: #16325c; color: white;">
      <th style="padding: 10px; text-align: left;">Criteria</th>
      <th style="padding: 10px; text-align: center;">VusionGroup</th>
      <th style="padding: 10px; text-align: center;">Pricer</th>
      <th style="padding: 10px; text-align: left;">Talking Point</th>
    </tr>
    <tr style="background: #f8f9fa;">
      <td style="padding: 10px; border-bottom: 1px solid #dee2e6;">Platform Capabilities</td>
      <td style="padding: 10px; text-align: center; border-bottom: 1px solid #dee2e6; color: #2e844a;">★★★★★</td>
      <td style="padding: 10px; text-align: center; border-bottom: 1px solid #dee2e6; color: #dd7a01;">★★★☆☆</td>
      <td style="padding: 10px; border-bottom: 1px solid #dee2e6;">VusionCloud enables retail media, dynamic pricing, inventory</td>
    </tr>
    <tr>
      <td style="padding: 10px; border-bottom: 1px solid #dee2e6;">Grocery Experience</td>
      <td style="padding: 10px; text-align: center; border-bottom: 1px solid #dee2e6; color: #2e844a;">★★★★★</td>
      <td style="padding: 10px; text-align: center; border-bottom: 1px solid #dee2e6; color: #2e844a;">★★★★☆</td>
      <td style="padding: 10px; border-bottom: 1px solid #dee2e6;">350+ retail deployments globally including [similar customers]</td>
    </tr>
    <tr style="background: #f8f9fa;">
      <td style="padding: 10px; border-bottom: 1px solid #dee2e6;">Initial Price</td>
      <td style="padding: 10px; text-align: center; border-bottom: 1px solid #dee2e6; color: #dd7a01;">★★★☆☆</td>
      <td style="padding: 10px; text-align: center; border-bottom: 1px solid #dee2e6; color: #2e844a;">★★★★☆</td>
      <td style="padding: 10px; border-bottom: 1px solid #dee2e6;">Focus on TCO, future capabilities, avoid hardware-only comparison</td>
    </tr>
  </table>
  
  <div style="background: #e8f5e9; padding: 15px; border-radius: 8px; margin-top: 15px;">
    <h4 style="color: #155724; margin: 0 0 10px 0;">💡 Win Strategy vs Pricer</h4>
    <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
      <li><strong>Don't compete on price alone</strong> - Shift conversation to TCO and future value</li>
      <li><strong>Leverage platform story</strong> - Pricer is hardware-focused, we're platform-focused</li>
      <li><strong>Reference similar wins</strong> - [Grocery Customer X] chose us over Pricer because...</li>
      <li><strong>Technical differentiation</strong> - Emphasize VusionCloud capabilities for future use cases</li>
    </ol>
  </div>
</div>
```

---

# 3. Sales Rep Specific Improvements

## 3.1 "What Do I Do Next?" Section

**Add a clear, unambiguous next step:**

```html
<!-- SINGLE MOST IMPORTANT ACTION -->
<div style="background: linear-gradient(135deg, #c23934 0%, #a31d1d 100%); color: white; padding: 20px; border-radius: 12px; margin: 20px 0; text-align: center;">
  <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 1px; opacity: 0.9;">YOUR #1 PRIORITY THIS WEEK</div>
  <h2 style="margin: 10px 0; font-size: 22px;">Get David Chen from Neutral → Supporter</h2>
  <p style="margin: 10px 0 15px 0; opacity: 0.9;">Schedule and complete an EB validation meeting before Friday</p>
  <div style="display: inline-flex; gap: 10px;">
    <span style="background: rgba(255,255,255,0.2); padding: 8px 16px; border-radius: 20px; font-size: 13px;">📅 Book Meeting</span>
    <span style="background: rgba(255,255,255,0.2); padding: 8px 16px; border-radius: 20px; font-size: 13px;">📧 Send Email</span>
  </div>
</div>
```

## 3.2 Deal Qualification Checklist

**Add interactive checklist:**

```html
<!-- STAGE ADVANCEMENT CHECKLIST -->
<div style="border-left: 4px solid #0176d3; padding: 15px; margin: 20px 0;">
  <h2 style="color: #16325c;">READY FOR BUDGET APPROVED?</h2>
  <p style="color: #706e6b; font-size: 13px;">Complete these items before advancing from Proposal Development:</p>
  
  <div style="margin: 15px 0;">
    <!-- Completed Items -->
    <div style="display: flex; align-items: center; padding: 10px; background: #d4edda; border-radius: 6px; margin-bottom: 8px;">
      <span style="color: #2e844a; font-size: 18px; margin-right: 10px;">✓</span>
      <span style="flex: 1;">Champion identified and validated (Jennifer Martinez)</span>
      <span style="color: #2e844a; font-size: 12px;">COMPLETE</span>
    </div>
    
    <div style="display: flex; align-items: center; padding: 10px; background: #d4edda; border-radius: 6px; margin-bottom: 8px;">
      <span style="color: #2e844a; font-size: 18px; margin-right: 10px;">✓</span>
      <span style="flex: 1;">Decision criteria documented and addressed</span>
      <span style="color: #2e844a; font-size: 12px;">COMPLETE</span>
    </div>
    
    <div style="display: flex; align-items: center; padding: 10px; background: #d4edda; border-radius: 6px; margin-bottom: 8px;">
      <span style="color: #2e844a; font-size: 18px; margin-right: 10px;">✓</span>
      <span style="flex: 1;">Pain points documented with business impact</span>
      <span style="color: #2e844a; font-size: 12px;">COMPLETE</span>
    </div>
    
    <!-- Incomplete Items -->
    <div style="display: flex; align-items: center; padding: 10px; background: #fff3cd; border-radius: 6px; margin-bottom: 8px;">
      <span style="color: #856404; font-size: 18px; margin-right: 10px;">○</span>
      <span style="flex: 1;"><strong>Economic Buyer engaged and supportive</strong></span>
      <span style="background: #dd7a01; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">ACTION NEEDED</span>
    </div>
    
    <div style="display: flex; align-items: center; padding: 10px; background: #f8f9fa; border-radius: 6px; margin-bottom: 8px;">
      <span style="color: #706e6b; font-size: 18px; margin-right: 10px;">○</span>
      <span style="flex: 1;">Metrics validated by customer</span>
      <span style="color: #706e6b; font-size: 12px;">IN PROGRESS</span>
    </div>
    
    <div style="display: flex; align-items: center; padding: 10px; background: #f8f9fa; border-radius: 6px; margin-bottom: 8px;">
      <span style="color: #706e6b; font-size: 18px; margin-right: 10px;">○</span>
      <span style="flex: 1;">Budget approval timeline confirmed</span>
      <span style="color: #706e6b; font-size: 12px;">NOT STARTED</span>
    </div>
  </div>
  
  <div style="background: #f0f7ff; padding: 10px; border-radius: 6px;">
    <strong>Stage Advancement Status:</strong> 
    <span style="color: #dd7a01;">⚠️ 3 of 6 requirements met - NOT READY</span>
  </div>
</div>
```

## 3.3 Activity Recommendations

**Add specific activity suggestions:**

```html
<!-- RECOMMENDED ACTIVITIES -->
<div style="margin: 20px 0;">
  <h3 style="color: #16325c;">Suggested Activities for This Deal</h3>
  
  <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px;">
    
    <!-- Activity Card 1 -->
    <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-top: 3px solid #c23934;">
      <div style="font-size: 12px; color: #c23934; font-weight: 600;">URGENT</div>
      <h4 style="margin: 8px 0; color: #16325c;">EB Validation Meeting</h4>
      <p style="font-size: 12px; color: #706e6b; margin: 0;">30-minute call with David Chen to validate budget authority</p>
      <div style="margin-top: 10px;">
        <span style="background: #0176d3; color: white; padding: 4px 8px; border-radius: 4px; font-size: 11px; cursor: pointer;">+ Log Activity</span>
      </div>
    </div>
    
    <!-- Activity Card 2 -->
    <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-top: 3px solid #f4bc25;">
      <div style="font-size: 12px; color: #856404; font-weight: 600;">THIS WEEK</div>
      <h4 style="margin: 8px 0; color: #16325c;">ROI Workshop</h4>
      <p style="font-size: 12px; color: #706e6b; margin: 0;">Work with Jennifer to finalize business case numbers</p>
      <div style="margin-top: 10px;">
        <span style="background: #0176d3; color: white; padding: 4px 8px; border-radius: 4px; font-size: 11px; cursor: pointer;">+ Log Activity</span>
      </div>
    </div>
    
    <!-- Activity Card 3 -->
    <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-top: 3px solid #0176d3;">
      <div style="font-size: 12px; color: #0176d3; font-weight: 600;">NEXT 14 DAYS</div>
      <h4 style="margin: 8px 0; color: #16325c;">Reference Call</h4>
      <p style="font-size: 12px; color: #706e6b; margin: 0;">Arrange reference call with similar grocery customer</p>
      <div style="margin-top: 10px;">
        <span style="background: #0176d3; color: white; padding: 4px 8px; border-radius: 4px; font-size: 11px; cursor: pointer;">+ Log Activity</span>
      </div>
    </div>
    
  </div>
</div>
```

---

# 4. Leadership/Manager Specific Improvements

## 4.1 Enhanced Manager Guidance Section

```html
<!-- MANAGER DEAL REVIEW GUIDE -->
<div style="border-left: 4px solid #16325c; padding: 15px; margin: 20px 0; background: linear-gradient(90deg, #f0f7ff 0%, #ffffff 100%);">
  <h2 style="color: #16325c;">MANAGER DEAL REVIEW GUIDE</h2>
  
  <!-- Forecast Recommendation -->
  <div style="background: white; padding: 15px; border-radius: 8px; margin-bottom: 15px; border: 1px solid #dee2e6;">
    <div style="display: flex; justify-content: space-between; align-items: center;">
      <div>
        <div style="font-size: 12px; color: #706e6b;">FORECAST RECOMMENDATION</div>
        <div style="font-size: 20px; font-weight: bold; color: #f4bc25;">BEST CASE</div>
      </div>
      <div style="text-align: right;">
        <div style="font-size: 12px; color: #706e6b;">CONFIDENCE LEVEL</div>
        <div style="font-size: 20px; font-weight: bold; color: #16325c;">65%</div>
      </div>
    </div>
    <p style="font-size: 13px; color: #706e6b; margin: 10px 0 0 0;">
      Based on 80% MEDDIC score at Proposal Development stage. Key risk: Economic Buyer engagement. 
      Move to Commit when EB status changes to Supporter.
    </p>
  </div>
  
  <!-- Deal Review Questions -->
  <div style="background: white; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
    <h4 style="color: #16325c; margin: 0 0 10px 0;">🔍 Questions to Ask in Deal Review</h4>
    
    <div style="margin-bottom: 15px;">
      <div style="font-weight: 600; color: #c23934; margin-bottom: 5px;">Critical Questions (Must Ask)</div>
      <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
        <li>"What's our plan to convert David Chen from Neutral to Supporter?"</li>
        <li>"Has Jennifer confirmed David has budget authority for this fiscal year?"</li>
        <li>"What's preventing us from getting a meeting with David this week?"</li>
      </ol>
    </div>
    
    <div style="margin-bottom: 15px;">
      <div style="font-weight: 600; color: #f4bc25; margin-bottom: 5px;">Validation Questions</div>
      <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
        <li>"Is the December 22 close date realistic given we need EB sign-off?"</li>
        <li>"What's the competitive situation? Are they actively evaluating alternatives?"</li>
        <li>"Has the customer committed to any mutual milestones?"</li>
      </ol>
    </div>
    
    <div>
      <div style="font-weight: 600; color: #0176d3; margin-bottom: 5px;">Coaching Opportunities</div>
      <ol style="margin: 0; padding-left: 20px; font-size: 13px;">
        <li>"How can I help you get access to David Chen?"</li>
        <li>"Would an executive sponsor call help accelerate this?"</li>
      </ol>
    </div>
  </div>
  
  <!-- Manager Actions -->
  <div style="background: white; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
    <h4 style="color: #16325c; margin: 0 0 10px 0;">📋 Manager Action Items</h4>
    
    <div style="display: flex; gap: 10px; flex-wrap: wrap;">
      <div style="background: #f8f9fa; padding: 10px 15px; border-radius: 6px; font-size: 13px;">
        <input type="checkbox" style="margin-right: 8px;"> Review in next pipeline call
      </div>
      <div style="background: #fef2f2; padding: 10px 15px; border-radius: 6px; font-size: 13px;">
        <input type="checkbox" style="margin-right: 8px;"> Offer exec sponsor support
      </div>
      <div style="background: #f8f9fa; padding: 10px 15px; border-radius: 6px; font-size: 13px;">
        <input type="checkbox" style="margin-right: 8px;"> Coach on EB engagement
      </div>
    </div>
  </div>
  
  <!-- Escalation Assessment -->
  <div style="display: flex; gap: 15px;">
    <div style="flex: 1; background: #d4edda; padding: 15px; border-radius: 8px;">
      <div style="font-size: 12px; color: #155724;">ESCALATION REQUIRED</div>
      <div style="font-size: 18px; font-weight: bold; color: #155724;">NO</div>
      <div style="font-size: 12px; color: #706e6b;">Rep has clear action plan</div>
    </div>
    
    <div style="flex: 1; background: #f8f9fa; padding: 15px; border-radius: 8px;">
      <div style="font-size: 12px; color: #706e6b;">RESOURCE NEEDS</div>
      <div style="font-size: 18px; font-weight: bold; color: #16325c;">None</div>
      <div style="font-size: 12px; color: #706e6b;">SE support not required</div>
    </div>
    
    <div style="flex: 1; background: #f8f9fa; padding: 15px; border-radius: 8px;">
      <div style="font-size: 12px; color: #706e6b;">NEXT REVIEW</div>
      <div style="font-size: 18px; font-weight: bold; color: #16325c;">7 Days</div>
      <div style="font-size: 12px; color: #706e6b;">Track EB meeting outcome</div>
    </div>
  </div>
  
</div>
```

## 4.2 Pipeline Quality Indicators

```html
<!-- PIPELINE QUALITY ASSESSMENT -->
<div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
  <h3 style="color: #16325c; margin: 0 0 15px 0;">Pipeline Quality Indicators</h3>
  
  <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px;">
    
    <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
      <div style="font-size: 28px; font-weight: bold; color: #2e844a;">A</div>
      <div style="font-size: 12px; color: #706e6b;">Deal Grade</div>
      <div style="font-size: 11px; color: #2e844a;">Top quartile MEDDIC</div>
    </div>
    
    <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
      <div style="font-size: 28px; font-weight: bold; color: #0176d3;">68%</div>
      <div style="font-size: 12px; color: #706e6b;">Win Probability</div>
      <div style="font-size: 11px; color: #706e6b;">Based on similar deals</div>
    </div>
    
    <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
      <div style="font-size: 28px; font-weight: bold; color: #f4bc25;">1.2x</div>
      <div style="font-size: 12px; color: #706e6b;">Coverage Contribution</div>
      <div style="font-size: 11px; color: #706e6b;">Weighted pipeline value</div>
    </div>
    
    <div style="text-align: center; padding: 15px; background: white; border-radius: 8px;">
      <div style="font-size: 28px; font-weight: bold; color: #2e844a;">+12%</div>
      <div style="font-size: 12px; color: #706e6b;">Score Trend</div>
      <div style="font-size: 11px; color: #2e844a;">Improving vs 30 days ago</div>
    </div>
    
  </div>
</div>
```

## 4.3 Historical Comparison (if available)

```html
<!-- DEAL TRAJECTORY -->
<div style="margin: 20px 0;">
  <h3 style="color: #16325c;">Deal Score Trajectory</h3>
  
  <div style="background: #f8f9fa; padding: 15px; border-radius: 8px;">
    <!-- Simple text-based trend since we can't do JS charts -->
    <table style="width: 100%; font-size: 13px;">
      <tr>
        <th style="text-align: left; padding: 8px;">Date</th>
        <th style="text-align: center; padding: 8px;">MEDDIC Score</th>
        <th style="text-align: center; padding: 8px;">Stage</th>
        <th style="text-align: left; padding: 8px;">Key Change</th>
      </tr>
      <tr style="background: white;">
        <td style="padding: 8px;">Nov 15, 2024</td>
        <td style="padding: 8px; text-align: center;">55%</td>
        <td style="padding: 8px; text-align: center;">Analysis</td>
        <td style="padding: 8px;">Initial qualification</td>
      </tr>
      <tr>
        <td style="padding: 8px;">Nov 30, 2024</td>
        <td style="padding: 8px; text-align: center;">65% <span style="color: #2e844a;">↑</span></td>
        <td style="padding: 8px; text-align: center;">Analysis</td>
        <td style="padding: 8px;">Champion validated</td>
      </tr>
      <tr style="background: white;">
        <td style="padding: 8px;">Dec 5, 2024</td>
        <td style="padding: 8px; text-align: center;">75% <span style="color: #2e844a;">↑</span></td>
        <td style="padding: 8px; text-align: center;">Proposal Dev</td>
        <td style="padding: 8px;">EB identified, criteria documented</td>
      </tr>
      <tr>
        <td style="padding: 8px;">Dec 10, 2024</td>
        <td style="padding: 8px; text-align: center;"><strong>80%</strong> <span style="color: #2e844a;">↑</span></td>
        <td style="padding: 8px; text-align: center;">Proposal Dev</td>
        <td style="padding: 8px;">Decision process mapped</td>
      </tr>
    </table>
    
    <div style="margin-top: 15px; padding: 10px; background: #d4edda; border-radius: 6px;">
      <strong style="color: #155724;">📈 Trend Analysis:</strong> 
      <span style="color: #155724;">Deal is progressing well - score improved 25 points in 25 days. On track if EB engagement improves.</span>
    </div>
  </div>
</div>
```

---

# 5. Data Quality & Intelligence Enhancements

## 5.1 Data Completeness Indicator

```html
<!-- DATA QUALITY ASSESSMENT -->
<div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
  <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
    <h3 style="color: #16325c; margin: 0;">Data Quality Assessment</h3>
    <span style="background: #7cc47f; color: white; padding: 4px 12px; border-radius: 20px; font-size: 12px;">GOOD - 78%</span>
  </div>
  
  <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px;">
    
    <div>
      <div style="font-size: 12px; color: #706e6b; margin-bottom: 5px;">ClosePlan Data</div>
      <div style="background: #e0e0e0; border-radius: 10px; height: 8px; overflow: hidden;">
        <div style="background: #2e844a; width: 85%; height: 100%;"></div>
      </div>
      <div style="font-size: 11px; color: #706e6b; margin-top: 3px;">85% complete</div>
    </div>
    
    <div>
      <div style="font-size: 12px; color: #706e6b; margin-bottom: 5px;">Stakeholder Data</div>
      <div style="background: #e0e0e0; border-radius: 10px; height: 8px; overflow: hidden;">
        <div style="background: #2e844a; width: 90%; height: 100%;"></div>
      </div>
      <div style="font-size: 11px; color: #706e6b; margin-top: 3px;">90% complete</div>
    </div>
    
    <div>
      <div style="font-size: 12px; color: #706e6b; margin-bottom: 5px;">Activity Data</div>
      <div style="background: #e0e0e0; border-radius: 10px; height: 8px; overflow: hidden;">
        <div style="background: #7cc47f; width: 70%; height: 100%;"></div>
      </div>
      <div style="font-size: 11px; color: #706e6b; margin-top: 3px;">70% complete</div>
    </div>
    
  </div>
  
  <div style="margin-top: 15px; padding: 10px; background: white; border-radius: 6px; font-size: 12px;">
    <strong>Missing Data:</strong> 
    <span style="color: #dd7a01;">No activities logged with Economic Buyer</span> • 
    <span style="color: #706e6b;">Competitor details incomplete</span>
  </div>
</div>
```

## 5.2 Similar Deals Reference

**Add to prompt to reference historical wins:**

```html
<!-- SIMILAR DEALS REFERENCE -->
<div style="border-left: 4px solid #0176d3; padding: 15px; margin: 20px 0;">
  <h2 style="color: #16325c;">SIMILAR DEALS REFERENCE</h2>
  <p style="color: #706e6b; font-size: 13px;">Based on industry, deal size, and stage progression:</p>
  
  <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px;">
    
    <!-- Won Deal -->
    <div style="background: #d4edda; padding: 15px; border-radius: 8px;">
      <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
        <span style="background: #2e844a; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">WON</span>
        <span style="font-size: 12px; color: #155724;">Similar: 87%</span>
      </div>
      <h4 style="margin: 0 0 5px 0; color: #155724;">Regional Grocery Chain A</h4>
      <div style="font-size: 12px; color: #706e6b;">$1.2M • 450 stores • 8 months</div>
      <div style="margin-top: 10px; font-size: 12px;">
        <strong>What worked:</strong> Early EB engagement, strong ROI case, pilot success
      </div>
    </div>
    
    <!-- Lost Deal -->
    <div style="background: #fef2f2; padding: 15px; border-radius: 8px;">
      <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
        <span style="background: #c23934; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">LOST</span>
        <span style="font-size: 12px; color: #c23934;">Similar: 82%</span>
      </div>
      <h4 style="margin: 0 0 5px 0; color: #c23934;">Regional Grocery Chain B</h4>
      <div style="font-size: 12px; color: #706e6b;">$800K • 200 stores • Lost to Pricer</div>
      <div style="margin-top: 10px; font-size: 12px;">
        <strong>Why lost:</strong> EB stayed Neutral, price-focused evaluation, no champion access to EB
      </div>
    </div>
    
  </div>
  
  <div style="background: #fff3cd; padding: 10px; border-radius: 6px; margin-top: 15px; font-size: 13px;">
    <strong>⚠️ Pattern Alert:</strong> Lost deal had similar EB engagement issue. Prioritize EB conversion to avoid same outcome.
  </div>
</div>
```

---

# 6. Revised Prompt Command

Here's the enhanced prompt command incorporating all recommendations:

```
I am a MEDDIC compliance analyst and sales strategist for VusionGroup retail technology sales. Analyze the provided Opportunity data and generate a comprehensive, actionable MEDDIC compliance report.

## ANALYSIS FRAMEWORK

### PRIMARY OUTPUT SECTIONS (in order):

1. **DEAL HEALTH DASHBOARD** (5-second view)
   - Visual gauge showing overall MEDDIC score (0-100)
   - Traffic light status: 🟢 GREEN (75+), 🟡 YELLOW (50-74), 🔴 RED (<50)
   - Single most critical action required
   - Score trend vs. stage expectation

2. **YOUR #1 PRIORITY** (Immediate action callout)
   - Single most important action in bold, prominent box
   - Why this matters
   - Success criteria
   - Due date (This Week / Next 14 Days / This Month)

3. **MEDDIC SCORECARD** (30-second view)
   - Visual progress bars for each element (M, E, D-C, D-P, I, C)
   - Stage threshold markers showing minimum required
   - Quick status indicators (✓ Complete, ⚠ Needs Work, ✗ Missing)
   - Element-specific one-line summary

4. **STAGE ALIGNMENT ANALYSIS**
   - Current stage vs. MEDDIC score alignment
   - Stage advancement checklist with status
   - Blockers preventing advancement
   - Estimated time to next stage

5. **RISK & OPPORTUNITY ASSESSMENT**
   - Critical risks (🔴) with evidence and required action
   - Warnings (🟡) with evidence and recommended action
   - Positive indicators (🟢) to leverage
   - Competitive position summary

6. **STAKEHOLDER INFLUENCE MAP**
   - 2x2 grid: High/Low Influence × Supportive/Needs Work
   - Key stakeholders with role, support status, and relationship strength
   - Missing roles highlighted
   - Engagement recommendations

7. **DETAILED ELEMENT ANALYSIS** (Deep dive for each MEDDIC element)
   For each element provide:
   - Score (0-100) with visual bar
   - Status: STRONG / PROGRESSING / AT RISK / MISSING
   - Evidence from data (cite specific fields/records)
   - Gaps identified
   - Discovery questions to ask
   - Specific actions to improve

8. **ACTION PLAN** (Execution-focused)
   Priority 1 (This Week):
   - Action with owner, success criteria, talk track
   - Meeting agenda if meeting required
   - Email template if outreach required
   
   Priority 2 (Next 14 Days):
   - Actions with owner and validation method
   
   Priority 3 (This Month):
   - Longer-term strategic actions

9. **OBJECTION HANDLING GUIDE**
   - Top 2-3 anticipated objections based on data
   - Recommended response for each
   - Supporting evidence/resources available

10. **COMPETITIVE POSITIONING** (if competitor identified)
    - Competitor strengths and weaknesses vs. VusionGroup
    - Win strategy recommendations
    - Talk tracks for competitive situations

11. **MANAGER DEAL REVIEW GUIDE**
    - Forecast recommendation with confidence level
    - Questions to ask in deal review
    - Coaching opportunities
    - Escalation assessment
    - Resource needs
    - Next review timing

12. **DATA QUALITY INDICATOR**
    - Completeness score for ClosePlan, Stakeholders, Activities
    - Missing data that would improve analysis

## SCORING METHODOLOGY

### Element Weights:
- M (Metrics): 15%
- E (Economic Buyer): 20%
- D (Decision Criteria): 15%
- D (Decision Process): 15%
- I (Identify Pain): 15%
- C (Champion): 20%

### Stage Thresholds:
| Stage | Min Score | Key Requirements |
|-------|-----------|------------------|
| New/Interest | 35% | Pain confirmed, Champion identified |
| Analysis in progress | 50% | Pain documented, Champion validated, EB identified |
| Proposal sent | 65% | EB engaged, Criteria confirmed, Process mapped |
| Budget approved | 75% | Metrics validated, All criteria addressed |
| Verbal agreement | 85% | EB committed, All elements strong |

### Risk Indicators:
CRITICAL (score penalty -15):
- No Champion AND Stage >= Analysis
- No EB engagement AND Stage >= Proposal
- No activity 30+ days
- Champion status = Neutral/Resistor

WARNING (flag only):
- EB Neutral disposition
- Champion Low influence
- No mutual milestones in Events
- Close date pushed 2+ times

## DATA SOURCES TO USE:

Primary:
- Opportunity fields: StageName, Amount, CloseDate, Probability, Description
- TSPC__Deals__r: ClosePlan master record
- TSPC__Deals__r.TSPC__Stakeholders__r: Buying committee (Role, SupportStatus, Relationship, HasPower, DecisionStatus, Goal)
- TSPC__Deals__r.TSPC__DealQuestions__r: MEDDIC scorecard (Text, Score, MaxScore, Answer, Notes)
- TSPC__Deals__r.TSPC__Events__r: Mutual action plan (Name, Status, Stage, IsMutual, StartDate, EndDate)
- OpportunityContactRoles: Contact roles
- ActivityHistories/Tasks/Events: Engagement history

Secondary:
- Account: Industry, store count (NombresMagasins__c)
- Competitor__c, DB_Competitor__c: Competitive intelligence

## VUSIONGROUP CONTEXT:

Business: Retail IoT and digitalization (ESL, Captana, VusionCloud, etc.)
Target: Large retail chains (grocery, specialty, mass merchants)
Sales Cycle: 6-24 months
Key Value Drivers: Labor efficiency, pricing accuracy, sustainability, omnichannel
Competitors: Pricer, Displaydata, Hanshow, Solum

Typical Buying Committee:
- VP Merchandising
- Store Operations Director
- IT/Infrastructure
- Finance/Procurement
- Sustainability Officer

## OUTPUT FORMATTING:

Generate well-formed HTML with:
- VusionGroup colors (#0176d3 blue, #16325c dark blue, #c23934 red, #2e844a green, #f4bc25 amber)
- Visual progress bars for scores
- Collapsible sections for talk tracks and templates (use <details><summary>)
- Clear visual hierarchy
- Mobile-friendly layouts where possible

CRITICAL: Output must be ONE CONTINUOUS HTML STRING with no newlines between tags.

## GROUNDING RULES:

- Base ALL insights on provided data - cite specific evidence
- Do NOT hallucinate or invent data points
- Be specific in recommendations - avoid generic advice
- Consider stage context when evaluating completeness
- Tailor guidance to retail technology sales context
- Provide actionable talk tracks and scripts
- Include success criteria for every action
- Flag data quality issues transparently
- Prioritize ruthlessly - what's the ONE thing that matters most?
```

---

# 7. Alternative Output Formats

## 7.1 Canvas Prompt Option

Consider creating a **GPTfy Canvas** with multiple prompt elements for a dashboard view:

| Element | Prompt | Refresh |
|---------|--------|---------|
| Deal Health Score | Quick MEDDIC score calculation | Real-time |
| Stage Alignment | Stage vs. score comparison | On demand |
| Priority Actions | Top 3 actions only | On demand |
| Risk Summary | Critical risks only | On demand |
| Full Analysis | Complete MEDDIC report | On demand |

## 7.2 JSON Output for Automation

Create a JSON-type prompt that outputs structured data for:
- Automated task creation based on actions
- Score tracking in custom fields
- Dashboard/reporting integration
- Slack/email notifications for critical risks

## 7.3 Role-Based Variants

Consider creating separate prompts or prompt components for:

| Audience | Focus | Length |
|----------|-------|--------|
| **Sales Rep** | Actions, scripts, next steps | Full detail |
| **Sales Manager** | Forecast, coaching, risks | Summary + questions |
| **VP Sales** | Pipeline quality, trends | Executive summary |

---

# Summary: Top 10 Recommendations

| Priority | Recommendation | Impact |
|----------|----------------|--------|
| 1 | Add visual MEDDIC score gauge at top | Instant deal health visibility |
| 2 | Add "Your #1 Priority" prominent callout | Clear action focus |
| 3 | Include talk tracks and email templates | Faster execution |
| 4 | Add meeting agendas for recommended actions | Better prepared reps |
| 5 | Include objection handling guide | Higher conversion |
| 6 | Enhance stakeholder influence map | Better stakeholder strategy |
| 7 | Add stage advancement checklist | Clear progression path |
| 8 | Include discovery questions by element | Better data collection |
| 9 | Add competitive positioning section | Win more competitive deals |
| 10 | Enhance manager guidance with coaching questions | Better deal reviews |

---

Would you like me to:
1. **Create a complete revised prompt** with all enhancements integrated?
2. **Design specific HTML templates** for any of the new components?
3. **Create a Canvas prompt configuration** for dashboard-style output?
4. **Develop the JSON output schema** for automation use cases?