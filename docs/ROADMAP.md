# GPTfy Prompt Factory - Product Roadmap

**Version:** 1.0
**Last Updated:** December 29, 2024
**Status:** Draft

---

## Executive Vision

Transform GPTfy prompt development from a manual, error-prone process into a **self-service, template-driven system** that enables rapid creation of AI-powered visualizations and reports directly within Salesforce.

### End-State Vision

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        GPTFY PROMPT FACTORY - VISION                             │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   Salesforce Admin selects:                                                     │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐           │
│   │ Template Type   │ +  │ Data Context    │ +  │ Brand Theme     │           │
│   │ "Deal Health"   │    │ "Opportunity"   │    │ "Corporate"     │           │
│   └─────────────────┘    └─────────────────┘    └─────────────────┘           │
│            │                      │                      │                     │
│            └──────────────────────┼──────────────────────┘                     │
│                                   ▼                                            │
│                    ┌─────────────────────────────┐                             │
│                    │   GPTfy Prompt Factory      │                             │
│                    │   (Apex + Static Resources) │                             │
│                    └─────────────────────────────┘                             │
│                                   │                                            │
│                                   ▼                                            │
│                    ┌─────────────────────────────┐                             │
│                    │  Production-Ready Prompt    │                             │
│                    │  + Configured DCM           │                             │
│                    └─────────────────────────────┘                             │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Roadmap Phases

```
═══════════════════════════════════════════════════════════════════════════════════
                              IMPLEMENTATION ROADMAP
═══════════════════════════════════════════════════════════════════════════════════

    PHASE 1              PHASE 2              PHASE 3              PHASE 4
    MVP Local            Template             Salesforce           Self-Service
    Tooling              Library              Native               Platform
    ─────────────────────────────────────────────────────────────────────────────►

    ┌─────────┐          ┌─────────┐          ┌─────────┐          ┌─────────┐
    │ Scripts │          │ Template│          │ Static  │          │ LWC UI  │
    │ + JSON  │    →     │ Catalog │    →     │ Resource│    →     │ Builder │
    │ Config  │          │ + Types │          │ + Apex  │          │         │
    └─────────┘          └─────────┘          └─────────┘          └─────────┘

    Week 1-2             Week 3-4             Week 5-8             Week 9+
    ─────────────────────────────────────────────────────────────────────────────►

═══════════════════════════════════════════════════════════════════════════════════
```

---

## Phase 1: MVP Local Tooling (Current Sprint)

### Objective
Create working local scripts that automate prompt development and establish the template structure.

### Deliverables

```
project/
├── scripts/
│   ├── generate-prompt.sh      # Assemble prompt from template + config
│   ├── iterate-prompt.sh       # Test → Validate → Report (enhanced)
│   ├── validate-output.sh      # Standalone HTML validation
│   └── deploy-prompt.sh        # Deploy to Salesforce via Apex
│
├── templates/
│   ├── sections/
│   │   ├── guardrails.txt      # Section 4 - Standard (never modify)
│   │   └── styling.txt         # Section 2 - Standard GPTfy styles
│   │
│   └── components/
│       ├── header.html         # Reusable header pattern
│       ├── stat-box.html       # KPI stat box
│       ├── card.html           # Generic card with status
│       ├── table.html          # Data table
│       ├── heatmap.html        # Activity heatmap
│       ├── timeline.html       # Timeline visualization
│       ├── progress-bar.html   # Progress indicator
│       └── insights.html       # Insight cards (critical/warning/info)
│
├── prompts/
│   └── meddic/
│       ├── config.json         # Prompt configuration
│       ├── section-1-goal.txt  # Business context
│       ├── section-3-data.txt  # Data mappings
│       └── mockup.html         # Target output
│
└── config/
    └── environments/
        ├── pocgptfy.env        # Sandbox config
        └── production.env      # Production config
```

### Config Schema (config.json)

```json
{
  "promptName": "MEDDIC Deal Intelligence",
  "version": "1.0.0",
  "description": "Deal health assessment using MEDDIC methodology",

  "salesforce": {
    "promptId": "a8Jbd0000003IrdEAE",
    "promptRequestId": "40ccdca557b58fee933893f24e06094ab3159",
    "testRecordId": "006bd00000E13aAAAR"
  },

  "template": {
    "type": "deal-intelligence",
    "components": ["header", "stat-strip", "heatmap", "cards", "table", "insights", "manager-section"],
    "theme": "default"
  },

  "dataContext": {
    "primaryObject": "Opportunity",
    "relationships": [
      {"name": "TSPC__Deals__r", "limit": 1},
      {"name": "TSPC__DealQuestionCategories__r", "limit": 10},
      {"name": "TSPC__Stakeholders__r", "limit": 20}
    ]
  },

  "validation": {
    "requiredElements": ["header", "stats", "health-bar", "meddic-cards"],
    "elementCounts": {
      "heatmap-cells-per-row": 12,
      "insight-cards": 3
    }
  }
}
```

### Success Criteria - Phase 1
- [ ] Can generate prompt from config + templates in <1 minute
- [ ] Can test prompt and get validation results in single command
- [ ] MEDDIC prompt working as reference implementation
- [ ] Documentation complete for team use

---

## Phase 2: Template Library & Catalog (Weeks 3-4)

### Objective
Build a catalog of reusable templates and visualization types that cover common GPTfy use cases.

### Template Types Catalog

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          TEMPLATE TYPE CATALOG                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  SALES & REVENUE                                                                │
│  ├── deal-intelligence      │ MEDDIC/BANT deal health assessment               │
│  ├── pipeline-summary       │ Pipeline overview with stage analysis            │
│  ├── forecast-card          │ Forecast confidence and commit analysis          │
│  └── win-loss-analysis      │ Deal outcome analysis with factors               │
│                                                                                 │
│  CUSTOMER SUCCESS                                                               │
│  ├── account-health         │ Customer 360 health dashboard                    │
│  ├── renewal-risk           │ Renewal risk assessment                          │
│  ├── adoption-scorecard     │ Product adoption metrics                         │
│  └── nps-summary            │ NPS trends and feedback analysis                 │
│                                                                                 │
│  SERVICE & SUPPORT                                                              │
│  ├── case-summary           │ Case resolution summary                          │
│  ├── escalation-brief       │ Escalation context and history                   │
│  ├── sla-dashboard          │ SLA compliance visualization                     │
│  └── agent-performance      │ Agent metrics and trends                         │
│                                                                                 │
│  MARKETING                                                                      │
│  ├── lead-scorecard         │ Lead qualification summary                       │
│  ├── campaign-performance   │ Campaign ROI and metrics                         │
│  └── engagement-timeline    │ Contact engagement history                       │
│                                                                                 │
│  ANALYTICS & INSIGHTS                                                           │
│  ├── activity-timeline      │ Chronological activity visualization            │
│  ├── trend-analysis         │ Metric trends over time                          │
│  ├── comparison-card        │ A vs B comparison                                │
│  └── infographic            │ General data infographic                         │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Visualization Components Library

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                       VISUALIZATION COMPONENTS                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  HEADERS & NAVIGATION                                                           │
│  ├── gradient-header        │ Blue gradient with title/subtitle                │
│  ├── simple-header          │ Clean header with badge                          │
│  └── tabbed-header          │ Header with tab navigation                       │
│                                                                                 │
│  DATA DISPLAY                                                                   │
│  ├── stat-box               │ Single KPI with label                            │
│  ├── stat-strip             │ Horizontal row of KPIs                           │
│  ├── stat-grid              │ Grid layout of KPIs                              │
│  ├── data-table             │ Sortable data table                              │
│  ├── key-value-list         │ Label: Value pairs                               │
│  └── comparison-table       │ Side-by-side comparison                          │
│                                                                                 │
│  VISUALIZATIONS                                                                 │
│  ├── heatmap                │ Activity/engagement heatmap                      │
│  ├── progress-bar           │ Horizontal progress indicator                    │
│  ├── progress-ring          │ Circular progress indicator                      │
│  ├── timeline               │ Vertical timeline of events                      │
│  ├── horizontal-timeline    │ Horizontal timeline                              │
│  ├── funnel                 │ Funnel/stage visualization                       │
│  ├── gauge                  │ Score gauge (0-100)                              │
│  └── sparkline              │ Mini inline chart                                │
│                                                                                 │
│  CARDS & CONTAINERS                                                             │
│  ├── status-card            │ Card with status border                          │
│  ├── insight-card           │ Critical/Warning/Info insight                    │
│  ├── action-card            │ Card with action items                           │
│  ├── expandable-card        │ Collapsible content section                      │
│  └── grid-container         │ Responsive grid layout                           │
│                                                                                 │
│  STATUS & INDICATORS                                                            │
│  ├── status-badge           │ AT RISK / WARNING / HEALTHY                      │
│  ├── health-bar             │ Full-width status indicator                      │
│  ├── traffic-light          │ Red/Yellow/Green indicator                       │
│  └── score-pill             │ Inline score display                             │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Template Definition Schema

```json
{
  "templateId": "deal-intelligence",
  "name": "Deal Intelligence Report",
  "description": "Comprehensive deal health assessment with MEDDIC analysis",
  "category": "sales",
  "version": "1.0.0",

  "components": [
    {
      "id": "header",
      "type": "gradient-header",
      "config": {
        "titleField": "Name",
        "subtitleFormat": "Generated: {{TODAY}}",
        "badge": "Deal Intelligence Report"
      }
    },
    {
      "id": "snapshot",
      "type": "key-value-list",
      "config": {
        "layout": "horizontal",
        "items": [
          {"label": "Account", "field": "Account.Name"},
          {"label": "Stage", "field": "StageName"},
          {"label": "Amount", "field": "Amount", "format": "currency"}
        ]
      }
    },
    {
      "id": "stats",
      "type": "stat-strip",
      "config": {
        "items": [
          {"label": "MEDDIC Score", "field": "TSPC__ScorecardScoreRatio__c", "format": "percent"},
          {"label": "Days in Stage", "field": "TSPC__Age__c", "format": "days"}
        ]
      }
    },
    {
      "id": "heatmap",
      "type": "heatmap",
      "config": {
        "rows": ["Deal Health", "Champion", "Econ Buyer"],
        "columns": 12,
        "columnLabels": "weeks"
      }
    }
  ],

  "requiredObjects": ["Opportunity"],
  "optionalObjects": ["TSPC__Deal__c", "TSPC__Stakeholder__c"],

  "themes": ["default", "compact", "detailed"]
}
```

### Success Criteria - Phase 2
- [ ] 10+ template types defined
- [ ] 20+ reusable components
- [ ] Template schema validated
- [ ] 3 working templates beyond MEDDIC

---

## Phase 3: Salesforce Native (Weeks 5-8)

### Objective
Move templates and assembly logic into Salesforce as Static Resources and Apex, enabling prompt generation without external tools.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      SALESFORCE NATIVE ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  STATIC RESOURCES                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ GPTfy_Template_Library (ZIP)                                            │   │
│  │ ├── templates/                                                          │   │
│  │ │   ├── deal-intelligence.json                                          │   │
│  │ │   ├── account-health.json                                             │   │
│  │ │   └── ...                                                             │   │
│  │ ├── components/                                                         │   │
│  │ │   ├── header.html                                                     │   │
│  │ │   ├── stat-box.html                                                   │   │
│  │ │   └── ...                                                             │   │
│  │ ├── themes/                                                             │   │
│  │ │   ├── default.json                                                    │   │
│  │ │   ├── corporate.json                                                  │   │
│  │ │   └── ...                                                             │   │
│  │ └── guardrails.txt                                                      │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  CUSTOM METADATA TYPES                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ GPTfy_Prompt_Template__mdt                                              │   │
│  │ ├── DeveloperName: deal_intelligence                                    │   │
│  │ ├── Label: Deal Intelligence Report                                     │   │
│  │ ├── Template_Type__c: deal-intelligence                                 │   │
│  │ ├── Category__c: Sales                                                  │   │
│  │ ├── Primary_Object__c: Opportunity                                      │   │
│  │ ├── Components__c: header,stats,heatmap,cards,table                     │   │
│  │ ├── Theme__c: default                                                   │   │
│  │ └── Is_Active__c: true                                                  │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  APEX CLASSES                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ GPTfyPromptFactory                                                      │   │
│  │ ├── generatePrompt(templateName, objectName, config)                    │   │
│  │ ├── getAvailableTemplates(objectName)                                   │   │
│  │ ├── validatePromptOutput(html)                                          │   │
│  │ └── getComponentLibrary()                                               │   │
│  │                                                                         │   │
│  │ GPTfyTemplateService                                                    │   │
│  │ ├── loadTemplate(templateId)                                            │   │
│  │ ├── loadComponent(componentId)                                          │   │
│  │ ├── loadTheme(themeId)                                                  │   │
│  │ └── assemblePrompt(template, components, theme, dataMapping)            │   │
│  │                                                                         │   │
│  │ GPTfyOutputValidator                                                    │   │
│  │ ├── validateStructure(html)                                             │   │
│  │ ├── validateStyles(html)                                                │   │
│  │ ├── checkPlaceholders(html)                                             │   │
│  │ └── compareToMockup(html, mockupId)                                     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Apex Interface Design

```apex
/**
 * GPTfy Prompt Factory - Main Entry Point
 * Generates prompts from templates stored in Static Resources
 */
public class GPTfyPromptFactory {

    /**
     * Generate a prompt from a template
     * @param templateName - Developer name of the template (e.g., 'deal_intelligence')
     * @param config - Optional configuration overrides
     * @return Assembled prompt text ready for ccai__AI_Prompt__c
     */
    public static String generatePrompt(String templateName, Map<String, Object> config) {
        // 1. Load template definition from Static Resource
        // 2. Load components based on template
        // 3. Load theme (default or specified)
        // 4. Load guardrails (always included)
        // 5. Assemble sections
        // 6. Return complete prompt
    }

    /**
     * Get available templates for an object
     * @param objectApiName - Salesforce object API name
     * @return List of available template metadata
     */
    public static List<GPTfy_Prompt_Template__mdt> getAvailableTemplates(String objectApiName) {
        return [
            SELECT DeveloperName, Label, Description__c, Category__c, Components__c
            FROM GPTfy_Prompt_Template__mdt
            WHERE Primary_Object__c = :objectApiName
            AND Is_Active__c = true
        ];
    }

    /**
     * Create a new AI Prompt record from template
     * @param templateName - Template to use
     * @param promptName - Name for the new prompt
     * @param dcmId - Data Context Mapping ID
     * @return Created ccai__AI_Prompt__c record
     */
    public static ccai__AI_Prompt__c createPromptFromTemplate(
        String templateName,
        String promptName,
        Id dcmId
    ) {
        String promptText = generatePrompt(templateName, null);

        ccai__AI_Prompt__c prompt = new ccai__AI_Prompt__c(
            Name = promptName,
            ccai__Prompt_Command__c = promptText,
            ccai__Data_Context_Mapping__c = dcmId,
            ccai__Status__c = 'Draft'
        );

        insert prompt;
        return prompt;
    }
}
```

### Invocable Action for Flow

```apex
/**
 * Invocable action to generate prompts from Flow
 */
public class GPTfyPromptFactoryInvocable {

    public class Request {
        @InvocableVariable(required=true label='Template Name')
        public String templateName;

        @InvocableVariable(label='Prompt Name')
        public String promptName;

        @InvocableVariable(label='Data Context Mapping ID')
        public Id dcmId;

        @InvocableVariable(label='Theme')
        public String theme;
    }

    public class Result {
        @InvocableVariable(label='Prompt ID')
        public Id promptId;

        @InvocableVariable(label='Prompt Text')
        public String promptText;

        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Generate GPTfy Prompt from Template'
        description='Creates a new AI Prompt using the GPTfy Prompt Factory template library'
    )
    public static List<Result> generatePrompts(List<Request> requests) {
        // Implementation
    }
}
```

### Success Criteria - Phase 3
- [ ] Static Resource with template library deployed
- [ ] Custom Metadata Type for template configuration
- [ ] Apex classes for prompt generation
- [ ] Invocable action working in Flow
- [ ] 5+ templates available in Salesforce

---

## Phase 4: Self-Service Platform (Week 9+)

### Objective
Build a user-friendly LWC interface that allows admins and power users to create, customize, and deploy prompts without code.

### UI Components

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        PROMPT FACTORY UI - WIREFRAME                             │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  GPTfy Prompt Factory                                    [+ New Prompt]  │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────────────────────────────────────────┐  │
│  │ TEMPLATE        │  │                                                     │  │
│  │ GALLERY         │  │              PREVIEW PANEL                          │  │
│  │                 │  │                                                     │  │
│  │ ┌─────────────┐ │  │  ┌─────────────────────────────────────────────┐   │  │
│  │ │ Deal Intel  │ │  │  │                                             │   │  │
│  │ │ [Preview]   │ │  │  │        Live Preview of Selected            │   │  │
│  │ └─────────────┘ │  │  │              Template                       │   │  │
│  │ ┌─────────────┐ │  │  │                                             │   │  │
│  │ │ Account 360 │ │  │  │                                             │   │  │
│  │ │ [Preview]   │ │  │  │                                             │   │  │
│  │ └─────────────┘ │  │  │                                             │   │  │
│  │ ┌─────────────┐ │  │  └─────────────────────────────────────────────┘   │  │
│  │ │ Case Summary│ │  │                                                     │  │
│  │ │ [Preview]   │ │  │  ┌─────────────────────────────────────────────┐   │  │
│  │ └─────────────┘ │  │  │ CONFIGURATION                               │   │  │
│  │                 │  │  │                                             │   │  │
│  │ Categories:     │  │  │ Object: [Opportunity      ▼]               │   │  │
│  │ ☑ Sales        │  │  │ Theme:  [Default           ▼]               │   │  │
│  │ ☑ Service      │  │  │ DCM:    [MEDDIC Analysis   ▼]               │   │  │
│  │ ☐ Marketing    │  │  │                                             │   │  │
│  │ ☐ Success      │  │  │ Components:                                  │   │  │
│  │                 │  │  │ ☑ Header  ☑ Stats  ☑ Heatmap               │   │  │
│  │                 │  │  │ ☑ Cards   ☑ Table  ☑ Insights              │   │  │
│  │                 │  │  │                                             │   │  │
│  │                 │  │  │         [Generate Prompt]                   │   │  │
│  │                 │  │  └─────────────────────────────────────────────┘   │  │
│  └─────────────────┘  └─────────────────────────────────────────────────────┘  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### LWC Component Structure

```
force-app/main/default/lwc/
├── gptfyPromptFactory/           # Main container
│   ├── gptfyPromptFactory.html
│   ├── gptfyPromptFactory.js
│   └── gptfyPromptFactory.css
│
├── gptfyTemplateGallery/         # Template selection gallery
│   ├── gptfyTemplateGallery.html
│   └── gptfyTemplateGallery.js
│
├── gptfyTemplateCard/            # Individual template card
│   ├── gptfyTemplateCard.html
│   └── gptfyTemplateCard.js
│
├── gptfyPreviewPanel/            # Live preview of template
│   ├── gptfyPreviewPanel.html
│   └── gptfyPreviewPanel.js
│
├── gptfyConfigPanel/             # Configuration options
│   ├── gptfyConfigPanel.html
│   └── gptfyConfigPanel.js
│
└── gptfyComponentSelector/       # Component toggle grid
    ├── gptfyComponentSelector.html
    └── gptfyComponentSelector.js
```

### Features

| Feature | Description | Priority |
|---------|-------------|----------|
| Template Gallery | Browse and filter templates by category/object | P0 |
| Live Preview | See template output with sample data | P0 |
| Component Toggle | Enable/disable template components | P1 |
| Theme Selector | Choose color scheme / branding | P1 |
| DCM Picker | Select or create Data Context Mapping | P0 |
| One-Click Deploy | Generate and create prompt record | P0 |
| Test Mode | Execute prompt and view result | P1 |
| Custom Field Mapping | Map fields to template placeholders | P2 |
| Template Editor | Advanced users can edit template JSON | P2 |
| Export/Import | Share templates between orgs | P2 |

### Success Criteria - Phase 4
- [ ] LWC app deployed and accessible
- [ ] Non-technical users can create prompts
- [ ] Template gallery with 15+ templates
- [ ] Live preview working
- [ ] Integration with existing GPTfy infrastructure

---

## Template Library - Full Catalog

### Sales Templates

| Template ID | Name | Components | Description |
|-------------|------|------------|-------------|
| `deal-intelligence` | Deal Intelligence | header, snapshot, stats, heatmap, cards, table, insights, manager | MEDDIC/BANT deal health |
| `pipeline-snapshot` | Pipeline Snapshot | header, stats, funnel, stage-table, forecast | Pipeline overview |
| `opportunity-brief` | Opportunity Brief | header, key-values, timeline, next-steps | Quick opp summary |
| `forecast-card` | Forecast Card | header, gauge, confidence, factors, recommendation | Forecast analysis |
| `competitive-analysis` | Competitive Analysis | header, comparison-table, strengths, threats | Competitor comparison |
| `win-loss-report` | Win/Loss Report | header, outcome, factors, timeline, lessons | Deal retrospective |

### Customer Success Templates

| Template ID | Name | Components | Description |
|-------------|------|------------|-------------|
| `account-health` | Account Health 360 | header, health-score, stats, engagement, risks, actions | Customer health |
| `renewal-risk` | Renewal Risk Card | header, gauge, risk-factors, timeline, mitigation | Renewal analysis |
| `adoption-scorecard` | Adoption Scorecard | header, stats, feature-usage, trends, recommendations | Usage analysis |
| `qbr-summary` | QBR Summary | header, highlights, metrics, roadmap, action-items | QBR preparation |
| `nps-dashboard` | NPS Dashboard | header, score, trends, feedback, themes | NPS analysis |
| `churn-predictor` | Churn Predictor | header, risk-score, indicators, engagement, actions | Churn risk |

### Service Templates

| Template ID | Name | Components | Description |
|-------------|------|------------|-------------|
| `case-summary` | Case Summary | header, details, timeline, resolution, satisfaction | Case resolution |
| `escalation-brief` | Escalation Brief | header, severity, history, impact, actions | Escalation context |
| `sla-dashboard` | SLA Dashboard | header, stats, compliance, breaches, trends | SLA monitoring |
| `knowledge-suggestion` | Knowledge Suggestion | header, issue, solutions, articles, confidence | KB recommendations |
| `agent-summary` | Agent Summary | header, metrics, trends, cases, coaching | Agent performance |

### Marketing Templates

| Template ID | Name | Components | Description |
|-------------|------|------------|-------------|
| `lead-scorecard` | Lead Scorecard | header, score, factors, engagement, recommendation | Lead qualification |
| `campaign-performance` | Campaign Performance | header, stats, funnel, roi, insights | Campaign analysis |
| `engagement-timeline` | Engagement Timeline | header, timeline, channels, scores, next-best | Contact engagement |
| `abm-dashboard` | ABM Dashboard | header, account-score, contacts, engagement, actions | ABM analysis |

### Generic/Analytics Templates

| Template ID | Name | Components | Description |
|-------------|------|------------|-------------|
| `activity-timeline` | Activity Timeline | header, timeline, filters, summary | Activity history |
| `trend-analysis` | Trend Analysis | header, sparklines, comparison, insights | Metric trends |
| `comparison-card` | Comparison Card | header, side-by-side, differences, recommendation | A vs B compare |
| `data-infographic` | Data Infographic | header, stats, visuals, callouts | General infographic |
| `summary-card` | Summary Card | header, key-values, status, actions | Generic summary |

---

## Component Specifications

### Header Component

```json
{
  "componentId": "gradient-header",
  "name": "Gradient Header",
  "description": "Blue gradient header with title, subtitle, and badge",
  "category": "header",

  "parameters": {
    "title": {"type": "field", "required": true},
    "subtitle": {"type": "template", "default": "Generated: {{TODAY}}"},
    "badge": {"type": "string", "required": true},
    "showLogo": {"type": "boolean", "default": false}
  },

  "html": "<div style=\"background:linear-gradient(135deg,#16325c,#0176d3);padding:20px;border-radius:8px 8px 0 0;display:flex;justify-content:space-between;align-items:center;\"><div><div style=\"color:#fff;font-size:20px;font-weight:700;\">{{title}}</div><div style=\"color:rgba(255,255,255,0.8);font-size:12px;\">{{subtitle}}</div></div><div style=\"background:rgba(255,255,255,0.15);color:#fff;padding:6px 12px;border-radius:4px;font-size:12px;font-weight:600;\">{{badge}}</div></div>"
}
```

### Stat Box Component

```json
{
  "componentId": "stat-box",
  "name": "Stat Box",
  "description": "Single KPI display with value and label",
  "category": "data-display",

  "parameters": {
    "value": {"type": "field", "required": true},
    "label": {"type": "string", "required": true},
    "format": {"type": "enum", "options": ["number", "percent", "currency", "days"], "default": "number"},
    "status": {"type": "enum", "options": ["default", "critical", "warning", "good"], "default": "default"}
  },

  "html": "<div style=\"flex:1;background:#f8f9fa;border-radius:8px;padding:12px 16px;text-align:center;min-width:100px;\"><div style=\"font-size:20px;font-weight:700;color:{{statusColor}};\">{{formattedValue}}</div><div style=\"font-size:11px;color:#666;text-transform:uppercase;\">{{label}}</div></div>",

  "statusColors": {
    "default": "#16325c",
    "critical": "#c23934",
    "warning": "#dd7a01",
    "good": "#2e844a"
  }
}
```

### Heatmap Component

```json
{
  "componentId": "heatmap",
  "name": "Engagement Heatmap",
  "description": "Activity heatmap with configurable rows and columns",
  "category": "visualization",

  "parameters": {
    "title": {"type": "string", "default": "Engagement Timeline"},
    "rows": {"type": "array", "required": true},
    "columns": {"type": "number", "default": 12},
    "columnLabels": {"type": "enum", "options": ["weeks", "months", "days", "custom"], "default": "weeks"},
    "colorScheme": {"type": "enum", "options": ["green", "blue", "purple", "gold"], "default": "green"}
  },

  "rowColors": {
    "Deal Health": "#4caf50",
    "Champion": "#ffd700",
    "Econ Buyer": "#6a0dad"
  }
}
```

---

## Theme System

### Default Theme

```json
{
  "themeId": "default",
  "name": "GPTfy Default",

  "colors": {
    "primary": "#16325c",
    "accent": "#0176d3",
    "success": "#2e844a",
    "warning": "#dd7a01",
    "critical": "#c23934",
    "background": "#f8f9fa",
    "surface": "#ffffff",
    "border": "#e0e5ee",
    "text": "#333333",
    "textSecondary": "#666666"
  },

  "typography": {
    "fontFamily": "Arial, sans-serif",
    "headerSize": "20px",
    "bodySize": "14px",
    "smallSize": "11px"
  },

  "spacing": {
    "containerPadding": "20px",
    "cardPadding": "16px",
    "gap": "16px",
    "borderRadius": "8px"
  },

  "gradients": {
    "header": "linear-gradient(135deg,#16325c,#0176d3)"
  }
}
```

### Corporate Theme (Example Custom)

```json
{
  "themeId": "corporate",
  "name": "Corporate Blue",
  "extends": "default",

  "colors": {
    "primary": "#003366",
    "accent": "#0066cc"
  },

  "gradients": {
    "header": "linear-gradient(135deg,#003366,#0066cc)"
  }
}
```

---

## Migration Path

### From Local Scripts to Salesforce

```
PHASE 1 (Local)                    PHASE 3 (Salesforce)
─────────────────                  ────────────────────

templates/                    →    StaticResource: GPTfy_Template_Library
├── components/                    ├── templates/
└── sections/                      ├── components/
                                   └── themes/

config.json                   →    GPTfy_Prompt_Template__mdt
                                   (Custom Metadata Type)

scripts/                      →    Apex Classes
├── generate-prompt.sh             ├── GPTfyPromptFactory
├── iterate-prompt.sh              ├── GPTfyTemplateService
└── validate-output.sh             └── GPTfyOutputValidator
```

---

## Success Metrics

| Phase | Metric | Target |
|-------|--------|--------|
| Phase 1 | Prompt creation time | <5 minutes |
| Phase 1 | First-pass success rate | >70% |
| Phase 2 | Template library size | 10+ templates |
| Phase 2 | Component library size | 20+ components |
| Phase 3 | Prompts created via Apex | 50+ |
| Phase 3 | Orgs using template library | 5+ |
| Phase 4 | Self-service prompt creation | 80% of new prompts |
| Phase 4 | Admin satisfaction score | >4.0/5.0 |

---

## Appendix: Future Enhancements

### AI-Assisted Template Creation
- Describe desired output in natural language
- AI suggests template and components
- Auto-generate data mappings from object schema

### Template Marketplace
- Share templates between customers
- Rate and review templates
- GPTfy-certified templates

### Analytics & Optimization
- Track which templates are most used
- A/B test template variations
- Suggest optimizations based on output quality

### Multi-Language Support
- Localized templates
- RTL language support
- Currency/date formatting by locale

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 29, 2024 | GPTfy Team | Initial roadmap |

---

*This roadmap is part of the `Automated-Prompt-Creation` feature branch.*
