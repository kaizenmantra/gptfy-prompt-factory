# PRD: Salesforce Test Data Generator

## Product Requirements Document
**Version:** 1.0
**Author:** Claude Opus
**Date:** 2026-01-23
**Status:** Ready for Implementation

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Goals & Success Metrics](#3-goals--success-metrics)
4. [User Stories](#4-user-stories)
5. [Functional Requirements](#5-functional-requirements)
6. [Data Model & Generation Strategy](#6-data-model--generation-strategy)
7. [Technical Architecture](#7-technical-architecture)
8. [Technology Stack](#8-technology-stack)
9. [API & Integration Design](#9-api--integration-design)
10. [Security & Configuration](#10-security--configuration)
11. [Implementation Phases](#11-implementation-phases)
12. [Future Roadmap](#12-future-roadmap)
13. [Appendix](#13-appendix)

---

## 1. Executive Summary

### 1.1 Purpose
Build a reusable Salesforce test data generation tool that creates realistic, industry-specific demo data with rich unstructured content. The tool combines Snowfakery for structured data generation with OpenAI GPT-4o for generating realistic descriptions, comments, and activity narratives.

### 1.2 Key Value Propositions
- **Realistic Data**: LLM-generated descriptions that sound like real business scenarios
- **Industry-Specific**: Tailored content for Insurance, Financial Services, High Tech, and Field Service
- **Relationship Integrity**: Proper parent-child relationships (Account → Contact → OpportunityContactRole)
- **Variable Density**: Configurable field population rates to test field density features
- **Reusable**: Works across any Salesforce org, not tied to a specific project
- **Cloud-Ready**: Designed for eventual Azure deployment with web UI

### 1.3 Primary Use Case
Generate 100+ Accounts with related Contacts, Opportunities, Cases, Activities, and junction objects to test GPTfy Prompt Factory's field density calculations, parent traversal resolution, and AI-generated analysis quality.

---

## 2. Problem Statement

### 2.1 Current State
- Salesforce dev/test orgs have minimal or unrealistic test data
- Manual data creation is time-consuming and inconsistent
- Generic fake data (Lorem ipsum) doesn't test AI analysis capabilities
- Field population is either 100% or 0%, not realistic distribution
- No easy way to regenerate data for different scenarios

### 2.2 Impact
- Cannot properly test field density features (always shows 100% or 0%)
- Cannot validate parent traversal (Owner.Name, Account.Industry)
- Cannot assess quality of AI-generated insights on realistic content
- Demo environments look fake and unconvincing

### 2.3 Desired State
- Rich, realistic test data that mirrors production patterns
- Variable field population to test density calculations
- Industry-specific content for targeted demos
- Repeatable generation process for CI/CD and fresh orgs

---

## 3. Goals & Success Metrics

### 3.1 Primary Goals

| Goal | Description | Priority |
|------|-------------|----------|
| G1 | Generate 100 Accounts across 4 industries | P0 |
| G2 | Create related objects with proper relationships | P0 |
| G3 | Use LLM for realistic unstructured content | P0 |
| G4 | Support variable field density (25/50/75/100%) | P1 |
| G5 | Load data into Salesforce org via SFDX/API | P0 |
| G6 | Reusable across multiple Salesforce projects | P1 |

### 3.2 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Records Generated | 100 Accounts, 400 Contacts, 250 Opps, 200 Cases, 500 Activities | Count query |
| Field Density Variance | 25-100% across different fields | SchemaHelper.calculateFieldDensity() |
| LLM Content Quality | Descriptions sound realistic and industry-specific | Manual review |
| Generation Time | < 10 minutes for full dataset | Script timing |
| Load Success Rate | 100% records loaded without errors | SFDX output |

---

## 4. User Stories

### 4.1 Developer Stories

```
US-1: As a developer, I want to generate realistic test data
      so that I can test field density calculations accurately.

US-2: As a developer, I want industry-specific data
      so that I can demo to Insurance/FinServ/Tech customers.

US-3: As a developer, I want to run generation via CLI
      so that I can integrate it into CI/CD pipelines.

US-4: As a developer, I want to configure the number of records
      so that I can generate small or large datasets.

US-5: As a developer, I want to target different Salesforce orgs
      so that I can populate dev, QA, and demo environments.
```

### 4.2 QA Stories

```
US-6: As a QA engineer, I want consistent test data
      so that I can reproduce test scenarios reliably.

US-7: As a QA engineer, I want to clear and regenerate data
      so that I can start fresh for regression testing.
```

### 4.3 Future Stories (Web UI)

```
US-8: As a team member, I want a web interface
      so that I can generate data without CLI knowledge.

US-9: As a team lead, I want to save generation presets
      so that the team can reuse common configurations.
```

---

## 5. Functional Requirements

### 5.1 Data Generation

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Generate Account records with industry-specific names and details | P0 |
| FR-2 | Generate Contact records linked to Accounts with realistic titles | P0 |
| FR-3 | Generate Opportunity records linked to Accounts with stage distribution | P0 |
| FR-4 | Generate Case records linked to Accounts and Contacts | P0 |
| FR-5 | Generate Task records linked to Accounts/Contacts/Opportunities | P0 |
| FR-6 | Generate Event records for meetings and demos | P1 |
| FR-7 | Generate OpportunityContactRole junction records | P0 |
| FR-8 | Generate CaseComment records with realistic content | P1 |
| FR-9 | Support 4 industries: Insurance, Financial Services, High Tech, Field Service | P0 |
| FR-10 | Implement 3-tier field density: Rich (25%), Moderate (50%), Sparse (25%) | P0 |

### 5.2 LLM Content Generation

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-11 | Use OpenAI GPT-4o for Account descriptions | P0 |
| FR-12 | Use OpenAI GPT-4o for Opportunity descriptions and NextStep | P0 |
| FR-13 | Use OpenAI GPT-4o for Case descriptions and subjects | P0 |
| FR-14 | Use OpenAI GPT-4o for Task subjects and descriptions | P0 |
| FR-15 | Use OpenAI GPT-4o for CaseComment bodies | P1 |
| FR-16 | Use OpenAI GPT-4o for Activity descriptions | P1 |
| FR-17 | Generate content that reflects industry context | P0 |
| FR-18 | Generate content that references realistic business scenarios | P0 |

### 5.3 Salesforce Integration

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-19 | Load generated data into Salesforce via SFDX CLI | P0 |
| FR-20 | Support authentication via existing SFDX auth (sfdx force:org:display) | P0 |
| FR-21 | Handle Salesforce API limits gracefully (batch inserts) | P0 |
| FR-22 | Provide clear error messages for failed record inserts | P1 |
| FR-23 | Support data cleanup (delete generated records) | P1 |

### 5.4 Configuration

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-24 | Configure record counts via CLI arguments or config file | P0 |
| FR-25 | Configure target Salesforce org alias | P0 |
| FR-26 | Configure industry distribution | P1 |
| FR-27 | Configure field density tiers | P1 |
| FR-28 | Support dry-run mode (generate without loading) | P1 |

---

## 6. Data Model & Generation Strategy

### 6.1 Record Counts (Default Configuration)

| Object | Count | Parent | Relationship |
|--------|-------|--------|--------------|
| Account | 100 | - | - |
| Contact | 400 | Account | AccountId (4 per Account avg) |
| Opportunity | 250 | Account | AccountId (2-3 per Account avg) |
| OpportunityContactRole | 500 | Opportunity, Contact | OpportunityId, ContactId |
| Case | 200 | Account, Contact | AccountId, ContactId |
| CaseComment | 400 | Case | ParentId (2 per Case avg) |
| Task | 400 | Various | WhatId, WhoId |
| Event | 150 | Various | WhatId, WhoId |

**Total: ~2,400 records**

### 6.2 Industry Distribution

| Industry | Account Count | Characteristics |
|----------|---------------|-----------------|
| Insurance | 25 | Claims, policies, members, providers, compliance |
| Financial Services | 25 | Wealth management, lending, investments, regulations |
| High Tech | 25 | SaaS, implementations, renewals, integrations |
| Field Service | 25 | Equipment, maintenance, dispatch, SLAs, warranties |

### 6.3 Field Density Strategy

Records are assigned to density tiers to create realistic field population patterns:

| Tier | % of Records | Fields Populated | Example |
|------|--------------|------------------|---------|
| **Rich** | 25% | All fields including optional | Full description, phone, website, annual revenue, all dates |
| **Moderate** | 50% | Required + key optional | Name, industry, some description, partial contact info |
| **Sparse** | 25% | Required only | Name, minimal other fields |

**Field-Level Expected Density After Generation:**

| Field | Expected Density | Tier Coverage |
|-------|------------------|---------------|
| Name | 100% | All tiers |
| Industry | 100% | All tiers |
| Phone | 75% | Rich + Moderate |
| Website | 75% | Rich + Moderate |
| Description | 50% | Rich + half of Moderate |
| AnnualRevenue | 40% | Rich + some Moderate |
| NumberOfEmployees | 25% | Rich only |

### 6.4 Opportunity Stage Distribution

| Stage | % of Records | Business Meaning |
|-------|--------------|------------------|
| Prospecting | 15% | Early pipeline |
| Qualification | 15% | Validating fit |
| Needs Analysis | 15% | Discovery phase |
| Value Proposition | 10% | Solution positioning |
| Proposal/Price Quote | 15% | Active deals |
| Negotiation/Review | 10% | Late stage |
| Closed Won | 12% | Won business |
| Closed Lost | 8% | Lost deals |

### 6.5 Case Status Distribution

| Status | % of Records | Priority Mix |
|--------|--------------|--------------|
| New | 20% | Mix of all priorities |
| Working | 35% | Weighted toward Medium/High |
| Escalated | 10% | Mostly High priority |
| On Hold | 10% | Mix |
| Closed | 25% | Mix |

### 6.6 Activity Distribution

| Activity Type | Count | Typical Subject |
|---------------|-------|-----------------|
| Task - Call | 150 | "Follow up call with {Contact.Name}" |
| Task - Email | 100 | "Send proposal to {Account.Name}" |
| Task - Meeting Prep | 50 | "Prepare for QBR" |
| Task - Follow Up | 100 | "Next steps after demo" |
| Event - Meeting | 100 | "Discovery call with {Account.Name}" |
| Event - Demo | 50 | "Product demo for {Opportunity.Name}" |

---

## 7. Technical Architecture

### 7.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Salesforce Test Data Generator                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   CLI/API    │───▶│  Orchestrator │───▶│   Loader     │       │
│  │   Interface  │    │    Engine     │    │   Module     │       │
│  └──────────────┘    └──────┬───────┘    └──────┬───────┘       │
│                             │                    │                │
│         ┌───────────────────┼───────────────────┼──────┐        │
│         │                   │                   │      │        │
│         ▼                   ▼                   ▼      │        │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐ │        │
│  │  Snowfakery  │    │   OpenAI     │    │   SFDX    │ │        │
│  │   Generator  │    │   Enricher   │    │   CLI     │ │        │
│  └──────────────┘    └──────────────┘    └───────────┘ │        │
│         │                   │                   │      │        │
│         └───────────────────┼───────────────────┘      │        │
│                             │                          │        │
│                             ▼                          │        │
│                      ┌──────────────┐                  │        │
│                      │  JSON/CSV    │                  │        │
│                      │   Output     │                  │        │
│                      └──────────────┘                  │        │
│                                                        │        │
└────────────────────────────────────────────────────────┴────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │   Salesforce Org     │
                    │   (agentictso)       │
                    └──────────────────────┘
```

### 7.2 Component Descriptions

| Component | Responsibility | Technology |
|-----------|----------------|------------|
| **CLI Interface** | Accept commands, parse arguments, display progress | Python Click/Typer |
| **Orchestrator Engine** | Coordinate generation flow, manage dependencies | Python |
| **Snowfakery Generator** | Generate structured records with relationships | Snowfakery (Python) |
| **OpenAI Enricher** | Generate realistic unstructured content | OpenAI Python SDK |
| **Loader Module** | Insert records into Salesforce | simple-salesforce or SFDX |
| **JSON/CSV Output** | Intermediate storage, debugging, dry-run | Standard file I/O |

### 7.3 Data Flow

```
1. User invokes CLI with configuration
        │
        ▼
2. Orchestrator loads industry templates
        │
        ▼
3. Snowfakery generates base records (structured fields)
        │
        ▼
4. Records assigned to density tiers (Rich/Moderate/Sparse)
        │
        ▼
5. OpenAI enriches records needing descriptions
   └─► Batched API calls (10-20 records per prompt)
   └─► Industry-specific context in system prompt
        │
        ▼
6. Enriched records merged with base records
        │
        ▼
7. Records ordered by dependency (Accounts first, then Contacts, etc.)
        │
        ▼
8. Loader inserts records in batches (200 per batch)
   └─► Captures Salesforce IDs
   └─► Updates child records with parent IDs
        │
        ▼
9. Summary report generated
```

### 7.4 Directory Structure

```
sfdc-test-data-generator/
├── README.md                     # Project documentation
├── pyproject.toml                # Python project config (Poetry)
├── requirements.txt              # Dependencies (pip fallback)
├── .env.example                  # Environment template
├── .gitignore
│
├── src/
│   ├── __init__.py
│   ├── cli.py                    # CLI entry point (Typer)
│   ├── orchestrator.py           # Main coordination logic
│   ├── config.py                 # Configuration management
│   │
│   ├── generators/
│   │   ├── __init__.py
│   │   ├── snowfakery_runner.py  # Snowfakery integration
│   │   ├── openai_enricher.py    # OpenAI content generation
│   │   └── density_assigner.py   # Field density tier logic
│   │
│   ├── loaders/
│   │   ├── __init__.py
│   │   ├── salesforce_loader.py  # simple-salesforce integration
│   │   └── sfdx_loader.py        # SFDX CLI fallback
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── account.py            # Account data model
│   │   ├── contact.py            # Contact data model
│   │   ├── opportunity.py        # Opportunity data model
│   │   ├── case.py               # Case data model
│   │   └── activity.py           # Task/Event data model
│   │
│   └── utils/
│       ├── __init__.py
│       ├── logging.py            # Logging configuration
│       └── salesforce_auth.py    # SFDX auth helper
│
├── recipes/
│   ├── base_recipe.yml           # Core Snowfakery recipe
│   ├── account_recipe.yml        # Account-specific generation
│   ├── full_org_recipe.yml       # Complete dataset recipe
│   └── minimal_recipe.yml        # Quick test (10 accounts)
│
├── templates/
│   ├── industries/
│   │   ├── insurance.yml         # Insurance industry config
│   │   ├── financial_services.yml
│   │   ├── high_tech.yml
│   │   └── field_service.yml
│   │
│   └── prompts/
│       ├── account_description.txt    # OpenAI prompt templates
│       ├── opportunity_description.txt
│       ├── case_description.txt
│       ├── task_description.txt
│       └── case_comment.txt
│
├── tests/
│   ├── __init__.py
│   ├── test_generators.py
│   ├── test_loaders.py
│   └── test_orchestrator.py
│
├── output/                       # Generated files (gitignored)
│   ├── .gitkeep
│   └── *.json
│
└── scripts/
    ├── generate.sh               # Quick generation script
    ├── load.sh                   # Quick load script
    └── cleanup.sh                # Delete generated records
```

---

## 8. Technology Stack

### 8.1 Technology Decision Matrix

| Concern | Option A | Option B | Decision | Rationale |
|---------|----------|----------|----------|-----------|
| **Language** | Python | Node.js | **Python** | Snowfakery is Python; native integration, no subprocess calls |
| **CLI Framework** | Click | Typer | **Typer** | Modern, type hints, auto-help generation |
| **SF Integration** | simple-salesforce | SFDX CLI | **Both** | simple-salesforce primary, SFDX fallback |
| **OpenAI SDK** | openai (official) | langchain | **openai** | Lighter weight, direct control |
| **Web Framework** | Flask | FastAPI | **FastAPI** | Async support, auto OpenAPI docs, modern |
| **Package Manager** | pip | Poetry | **Poetry** | Better dependency management, lock files |
| **Config Format** | .env + YAML | JSON | **.env + YAML** | Human-readable, industry standard |

### 8.2 Core Dependencies

```toml
# pyproject.toml
[tool.poetry.dependencies]
python = "^3.10"
snowfakery = "^3.6"
openai = "^1.0"
simple-salesforce = "^1.12"
typer = "^0.9"
pyyaml = "^6.0"
python-dotenv = "^1.0"
rich = "^13.0"          # Beautiful CLI output
pydantic = "^2.0"       # Data validation

[tool.poetry.group.dev.dependencies]
pytest = "^7.0"
pytest-asyncio = "^0.21"
black = "^23.0"
ruff = "^0.1"

[tool.poetry.group.web.dependencies]  # Future web UI
fastapi = "^0.104"
uvicorn = "^0.24"
```

### 8.3 Azure Deployment Considerations

For future cloud deployment on Azure Container Apps:

| Component | Azure Service | Notes |
|-----------|---------------|-------|
| Container Runtime | Azure Container Apps | Serverless, auto-scale |
| Secrets | Azure Key Vault | Store OpenAI keys, SF credentials |
| Storage | Azure Blob Storage | Store generated files, logs |
| CI/CD | GitHub Actions | Build and deploy container |
| Monitoring | Azure Monitor | Logs, metrics, alerts |

**Container Configuration (future):**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN pip install poetry && poetry install --no-dev
COPY . .
EXPOSE 8000
CMD ["uvicorn", "src.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 9. API & Integration Design

### 9.1 CLI Interface

```bash
# Primary Commands

# Generate full dataset and load to Salesforce
sfdc-datagen generate --org agentictso --accounts 100

# Generate with specific industries
sfdc-datagen generate --org agentictso --accounts 100 \
  --industries insurance,finserv,hightech,fieldservice

# Generate to file only (dry run)
sfdc-datagen generate --output ./output/data.json --dry-run

# Load existing file to Salesforce
sfdc-datagen load --org agentictso --file ./output/data.json

# Clean up generated data
sfdc-datagen cleanup --org agentictso --prefix "TESTDATA_"

# Show configuration
sfdc-datagen config show

# Validate Salesforce connection
sfdc-datagen validate --org agentictso
```

### 9.2 Configuration Schema

```yaml
# config.yml
generation:
  accounts: 100
  contacts_per_account: 4
  opportunities_per_account: 2.5
  cases_per_account: 2
  activities_per_account: 5

industries:
  - name: insurance
    weight: 25
    template: templates/industries/insurance.yml
  - name: financial_services
    weight: 25
    template: templates/industries/financial_services.yml
  - name: high_tech
    weight: 25
    template: templates/industries/high_tech.yml
  - name: field_service
    weight: 25
    template: templates/industries/field_service.yml

density:
  rich: 25      # Fully populated
  moderate: 50  # Key fields
  sparse: 25    # Minimal

openai:
  model: gpt-4o
  temperature: 0.7
  batch_size: 10  # Records per API call

salesforce:
  batch_size: 200  # Records per insert
  retry_attempts: 3
```

### 9.3 OpenAI Prompt Templates

**Account Description Prompt:**
```
templates/prompts/account_description.txt
---
Generate a realistic business description for a {industry} company.

Company Name: {name}
Industry: {industry}
Type: {type}
Annual Revenue: {annual_revenue}

Write 2-3 sentences describing:
1. What the company does
2. Their market position or specialty
3. A current business challenge or initiative

Keep it professional and realistic. No marketing fluff.
Output only the description text, no labels or formatting.
```

**Case Description Prompt:**
```
templates/prompts/case_description.txt
---
Generate a realistic support case description for a {industry} company.

Company: {account_name}
Contact: {contact_name}, {contact_title}
Case Subject: {subject}
Priority: {priority}

Write 2-4 sentences describing:
1. The specific issue or request
2. Business impact or urgency
3. Any relevant context

Use professional tone. Reference industry-specific terminology.
Output only the description text.
```

### 9.4 Snowfakery Recipe Structure

```yaml
# recipes/base_recipe.yml
- snowfakery_version: 3

# ===== ACCOUNTS =====
- object: Account
  nickname: BaseAccount
  count: ${{accounts}}
  fields:
    Name:
      fake: company
    Industry: ${{industry}}
    Type:
      random_choice:
        - Customer
        - Prospect
        - Partner
    Phone:
      if:
        - choice:
            when: ${{density_tier != 'sparse'}}
            pick:
              fake: phone_number
    Website:
      if:
        - choice:
            when: ${{density_tier != 'sparse'}}
            pick:
              fake: url
    AnnualRevenue:
      if:
        - choice:
            when: ${{density_tier == 'rich'}}
            pick:
              random_number:
                min: 1000000
                max: 500000000
    # Description populated by OpenAI enricher (placeholder)
    Description: __LLM_PLACEHOLDER__

# ===== CONTACTS =====
- object: Contact
  count: ${{contacts_per_account}}
  fields:
    FirstName:
      fake: first_name
    LastName:
      fake: last_name
    Title:
      random_choice: ${{industry_titles}}
    Email:
      fake: company_email
    Phone:
      if:
        - choice:
            when: ${{density_tier != 'sparse'}}
            pick:
              fake: phone_number
    AccountId:
      reference: BaseAccount
```

### 9.5 simple-salesforce Integration

```python
# src/loaders/salesforce_loader.py

from simple_salesforce import Salesforce
from typing import List, Dict
import os

class SalesforceLoader:
    def __init__(self, org_alias: str = None):
        # Get credentials from SFDX
        self.sf = self._connect_via_sfdx(org_alias)

    def _connect_via_sfdx(self, org_alias: str) -> Salesforce:
        """Connect using existing SFDX authentication."""
        import subprocess
        import json

        cmd = f"sf org display --target-org {org_alias} --json"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        org_info = json.loads(result.stdout)["result"]

        return Salesforce(
            instance_url=org_info["instanceUrl"],
            session_id=org_info["accessToken"]
        )

    def bulk_insert(self, object_name: str, records: List[Dict], batch_size: int = 200) -> List[str]:
        """Insert records in batches, return Salesforce IDs."""
        all_ids = []

        for i in range(0, len(records), batch_size):
            batch = records[i:i + batch_size]
            results = getattr(self.sf.bulk, object_name).insert(batch)

            for result in results:
                if result["success"]:
                    all_ids.append(result["id"])
                else:
                    raise Exception(f"Insert failed: {result['errors']}")

        return all_ids

    def delete_by_prefix(self, object_name: str, name_prefix: str):
        """Delete records matching name prefix (cleanup)."""
        query = f"SELECT Id FROM {object_name} WHERE Name LIKE '{name_prefix}%'"
        records = self.sf.query_all(query)["records"]

        if records:
            ids = [r["Id"] for r in records]
            getattr(self.sf.bulk, object_name).delete(ids)
```

---

## 10. Security & Configuration

### 10.1 Environment Variables

```bash
# .env.example

# OpenAI Configuration (Azure or Direct)
OPENAI_API_KEY=sk-...
OPENAI_API_BASE=https://your-resource.openai.azure.com/  # Optional for Azure
OPENAI_API_VERSION=2024-02-01  # Optional for Azure
OPENAI_MODEL=gpt-4o

# Salesforce Configuration (via SFDX)
SF_ORG_ALIAS=agentictso
# Or direct credentials (not recommended):
# SF_INSTANCE_URL=https://your-instance.salesforce.com
# SF_ACCESS_TOKEN=...

# Generation Settings
DEFAULT_ACCOUNT_COUNT=100
DEFAULT_BATCH_SIZE=200
LOG_LEVEL=INFO
```

### 10.2 Credential Management

| Environment | Method | Notes |
|-------------|--------|-------|
| Local Dev | .env file + SFDX auth | Use `sf org login web` |
| CI/CD | GitHub Secrets | Inject as environment variables |
| Azure | Key Vault | Managed identity access |

### 10.3 Security Considerations

1. **Never commit credentials** - .env in .gitignore
2. **Use SFDX auth** - Leverages existing secure auth flow
3. **Rotate API keys** - Regular rotation schedule
4. **Audit logging** - Log all Salesforce operations
5. **Data classification** - Generated data is non-sensitive test data

---

## 11. Implementation Phases

### Phase 1: Core Generation (MVP)
**Timeline: 3-4 hours**

| Task | Description | Deliverable |
|------|-------------|-------------|
| 1.1 | Project setup (Poetry, directory structure) | Working project skeleton |
| 1.2 | Snowfakery recipe for Accounts, Contacts, Opportunities | YAML recipes |
| 1.3 | CLI interface with Typer | `sfdc-datagen generate` command |
| 1.4 | Salesforce loader (simple-salesforce) | Working data insertion |
| 1.5 | Basic industry templates (4 industries) | YAML industry configs |

**Exit Criteria:** Can generate 100 accounts with related records and load to Salesforce.

### Phase 2: LLM Enrichment
**Timeline: 2-3 hours**

| Task | Description | Deliverable |
|------|-------------|-------------|
| 2.1 | OpenAI integration module | `openai_enricher.py` |
| 2.2 | Prompt templates for each object type | Template files |
| 2.3 | Batch processing (10 records per call) | Efficient API usage |
| 2.4 | Integration with orchestrator | Enriched descriptions |

**Exit Criteria:** Generated records have realistic, industry-specific descriptions.

### Phase 3: Density & Completeness
**Timeline: 1-2 hours**

| Task | Description | Deliverable |
|------|-------------|-------------|
| 3.1 | Density tier assignment logic | `density_assigner.py` |
| 3.2 | Update recipes for conditional fields | Modified YAML |
| 3.3 | Add remaining objects (Cases, Tasks, Events, CaseComments) | Complete dataset |
| 3.4 | OpportunityContactRole generation | Junction records |

**Exit Criteria:** Full dataset with variable field density.

### Phase 4: Polish & Testing
**Timeline: 1-2 hours**

| Task | Description | Deliverable |
|------|-------------|-------------|
| 4.1 | Error handling and retry logic | Robust loader |
| 4.2 | Progress indicators (Rich library) | Beautiful CLI output |
| 4.3 | Cleanup command | `sfdc-datagen cleanup` |
| 4.4 | Documentation (README) | Usage instructions |
| 4.5 | Test with agentictso org | Validated dataset |

**Exit Criteria:** Production-ready tool, documented, tested.

### Total Estimated Implementation: 7-11 hours

---

## 12. Future Roadmap

### 12.1 Web UI (V2)

```
┌─────────────────────────────────────────────────────────────┐
│  Salesforce Test Data Generator                    [Login]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Configuration                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Target Org: [agentictso    ▼]  [Validate Connection] │   │
│  │                                                       │   │
│  │ Account Count: [100    ]                              │   │
│  │                                                       │   │
│  │ Industries:                                           │   │
│  │ [✓] Insurance        [✓] Financial Services          │   │
│  │ [✓] High Tech        [✓] Field Service               │   │
│  │                                                       │   │
│  │ Field Density:                                        │   │
│  │ Rich [25%]  Moderate [50%]  Sparse [25%]             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [Generate & Load]  [Generate Only]  [Load from File]      │
│                                                             │
│  Progress                                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ████████████████░░░░░░░░  65%                        │   │
│  │ Generating Opportunities... (162/250)                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**FastAPI Backend:**
```python
# src/api.py (future)
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel

app = FastAPI(title="SFDC Test Data Generator")

class GenerationRequest(BaseModel):
    org_alias: str
    account_count: int = 100
    industries: list[str] = ["insurance", "financial_services", "high_tech", "field_service"]
    density: dict = {"rich": 25, "moderate": 50, "sparse": 25}

@app.post("/generate")
async def generate_data(request: GenerationRequest, background_tasks: BackgroundTasks):
    job_id = create_job_id()
    background_tasks.add_task(run_generation, job_id, request)
    return {"job_id": job_id, "status": "started"}

@app.get("/status/{job_id}")
async def get_status(job_id: str):
    return get_job_status(job_id)
```

### 12.2 Additional Features (V3+)

| Feature | Description | Priority |
|---------|-------------|----------|
| Preset Management | Save/load generation configurations | Medium |
| Multi-org Support | Generate to multiple orgs in parallel | Low |
| Custom Objects | Support for custom Salesforce objects | Medium |
| Data Masking | Generate from production data patterns | Low |
| Scheduled Generation | Cron-based data refresh | Low |
| Slack Integration | Notify when generation completes | Low |

---

## 13. Appendix

### 13.1 Industry Template Example

```yaml
# templates/industries/insurance.yml
name: Insurance
weight: 25

company_name_patterns:
  - "{fake.last_name} Insurance Group"
  - "{fake.state} Health Alliance"
  - "BlueCross of {fake.state}"
  - "{fake.company} Benefits"
  - "United {fake.last_name} Insurance"

titles:
  - Chief Claims Officer
  - VP of Underwriting
  - Director of Member Services
  - Claims Manager
  - Provider Relations Manager
  - Compliance Officer
  - Actuary
  - Benefits Administrator

opportunity_types:
  - Group Health Plan Renewal
  - Medicare Advantage Enrollment
  - Workers Compensation Policy
  - Dental/Vision Add-on
  - Claims Platform Upgrade

case_subjects:
  - "Claim denial appeal - Policy #{fake.random_number}"
  - "Provider network inquiry"
  - "Prior authorization request"
  - "Member eligibility verification"
  - "Premium payment issue"
  - "Coordination of benefits question"
  - "ID card reissue request"

description_context: |
  This is a health insurance company focused on providing
  coverage to individuals and employer groups. They deal with
  claims processing, provider networks, member services, and
  regulatory compliance (HIPAA, ACA, state insurance regulations).
```

### 13.2 Sample Generated Output

**Account (Rich Tier, Insurance):**
```json
{
  "Name": "BlueCross of California",
  "Industry": "Insurance",
  "Type": "Customer",
  "Phone": "(415) 555-0192",
  "Website": "https://www.bluecrossca.example.com",
  "AnnualRevenue": 45000000,
  "NumberOfEmployees": 2300,
  "Description": "Regional health insurance provider serving 2.3 million members across Northern California. Specializes in employer-sponsored group plans and Medicare Advantage products. Currently modernizing their claims processing platform to reduce adjudication time from 14 days to under 48 hours."
}
```

**Opportunity (Moderate Tier, High Tech):**
```json
{
  "Name": "Acme Corp - Enterprise Platform Renewal",
  "AccountId": "001...",
  "Amount": 450000,
  "StageName": "Negotiation/Review",
  "CloseDate": "2026-04-15",
  "Probability": 75,
  "NextStep": "Legal review of updated MSA; procurement needs revised payment terms for Q2 budget alignment",
  "Description": "Three-year enterprise renewal with 20% expansion for additional user licenses. Customer is evaluating competitive bids but our technical integration depth gives us advantage. Key stakeholder (CTO) is champion; need to secure CFO sign-off on multi-year commitment."
}
```

**Case (Sparse Tier, Field Service):**
```json
{
  "Subject": "Equipment malfunction - Unit #4521",
  "AccountId": "001...",
  "ContactId": "003...",
  "Status": "New",
  "Priority": "High",
  "Description": "HVAC unit showing E-47 error code. Customer reports intermittent cooling failures in server room. SLA requires 4-hour response for critical infrastructure."
}
```

### 13.3 OpenAI Token Estimation

| Object | Records | Avg Tokens/Record | Total Tokens |
|--------|---------|-------------------|--------------|
| Account descriptions | 100 | 150 | 15,000 |
| Opportunity descriptions | 250 | 120 | 30,000 |
| Case descriptions | 200 | 100 | 20,000 |
| Task descriptions | 400 | 50 | 20,000 |
| Case comments | 400 | 80 | 32,000 |
| **Total** | | | **~117,000** |

**Estimated Cost (GPT-4o):**
- Input: ~20,000 tokens (prompts) × $0.005/1K = $0.10
- Output: ~117,000 tokens × $0.015/1K = $1.76
- **Total: ~$2 per full generation**

### 13.4 Glossary

| Term | Definition |
|------|------------|
| Snowfakery | Python tool for generating fake relational data with YAML recipes |
| Density Tier | Classification of records by how many fields are populated |
| simple-salesforce | Python library for Salesforce REST API |
| SFDX | Salesforce CLI tool for org management and deployment |
| GPTfy | AI prompt platform for Salesforce |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-23 | Claude Opus | Initial PRD |

---

**End of Document**
