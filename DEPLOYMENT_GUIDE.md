# Prompt Factory Wizard - Deployment Guide

## 📋 Overview

This repository contains the **Prompt Factory Wizard** - a 12-stage AI-powered pipeline for creating, validating, and deploying Salesforce prompts. This solution sits on top of the GPTfy managed package (namespace: `ccai__`).

**Last Updated**: January 21, 2026  
**Source Org**: tsogptfy.lightning.force.com  
**API Version**: 64.0

---

## 🎯 What's Included

### Custom Objects (5)
These objects track the Prompt Factory pipeline execution:

1. **PF_Run__c** - Master record for pipeline execution
2. **PF_Run_Stage__c** - Individual stage execution tracking
3. **PF_Run_Log__c** - Timestamped log entries
4. **PF_Quality_Score__c** - Quality assessment scores
5. **PF_Config__mdt** - Configuration metadata type

### Lightning Web Components (1)
1. **promptFactoryWizard** - Main 12-stage wizard UI ⭐
   - Provides the complete interface for the Prompt Factory pipeline
   - Guides users through all 12 stages of prompt creation and validation

### Apex Classes (60 total: 35 implementation classes + 25 test classes = 120 files)

#### Main Controllers (4)
- **PromptFactoryController** - Main wizard controller ⭐
- **P_PromptBuilderController** - AI generation controller
- **P_PromptsTableController** - Table data management
- **P_PromptCatalogueController** - Catalogue operations

#### Supporting Controllers (4)
- **CatalogController** - Catalogue data operations
- **AddCardController** - Card configuration
- **AIPromptController** - Core prompt operations
- **AIExtractionFieldMappingController** - Field mapping

#### Pipeline Core (4)
- **PromptFactoryPipeline** - Pipeline orchestrator
- **StageFactory** - Stage factory pattern
- **StageResult** - Result wrapper
- **IStage** - Stage interface

#### Stage Implementations (12)
- **Stage01_IntelligenceRetrieval** through **Stage12_QualityAudit**

#### Async Job Classes (9)
- **Stage05_FieldSelectionJob** through **Stage12_QualityAuditJob**
- **StageJobHelper** - Job helper utilities

#### Stage 10 Support (3)
- **Stage10_RestExecutor**, **Stage10_RestCalloutJob**, **Stage10_RetryHandler**

#### Builders & Utilities (8)
- **PromptBuilder**, **DCMBuilder**, **SchemaHelper**, **MergeFieldValidator**
- **AIServiceClient**, **PromptFactoryLogger**
- **PromptFactoryChainBreaker**, **PromptFactoryRulesLoader**

#### Existing Utilities (9)
- **FLSCheck**, **AIConstants**, **GPTfyException**, **ChatGPTUtills**
- **AIUtility**, **AIPromptValidationController**, **AIPromptSelector**
- **TestUtility**, **TestAddCardController**

#### Test Classes (25)
All major classes have corresponding test classes with >75% coverage:
- Stage implementation tests (12)
- Core pipeline and utility tests (13)

### Applications & Pages
- **Platform.app** - Lightning application (includes Prompt Factory Wizard tab)
- **Prompt_Factory_Wizard.flexipage** - Main wizard page ⭐
- **Prompt_Factory_Wizard.tab** - Custom tab for the wizard

### Permission Sets (2)
- **Prompt_Factory_Admin** - Full administrative access
- **Prompt_Factory_User** - Standard user access

### Custom Metadata
- **PF_Config.Claude** - Claude AI model configuration
- **ccai__GPTfy_Card_Configuration** records (3)

### Static Resources (16 files)
- **PF_MergeFieldRules.json** - Merge field validation rules
- **PF_OutputValidationRules.json** - Output validation rules
- **PF_UIPatterns.json** - UI pattern configurations
- **AI Provider Logos** - Gemini, Grok, Perplexity, DeepSeek (5 images)

---

## 📦 Prerequisites

### Required Package
**GPTfy Managed Package** (namespace: `ccai__`) must be installed in the target org.

The package provides these objects that the wizard depends on:
- `ccai__AI_Prompt__c`
- `ccai__AI_Connection__c`
- `ccai__AI_Data_Extraction_Mapping__c`
- `ccai__AI_Data_Extraction_Detail__c`
- `ccai__AI_Data_Extraction_Field__c`
- `ccai__AI_Card_Configuration__c`
- And many more...

### Salesforce Requirements
- Salesforce API Version: 64.0 or higher
- Lightning Experience enabled
- Sufficient storage for custom objects and static resources

---

## 🚀 Deployment Steps

### 1. Authenticate to Target Org

```bash
cd /Users/sgupta/projects-sfdc/gptfy-prompt-factory
sf org login web --alias my-target-org
```

### 2. Verify GPTfy Package is Installed

```bash
sf data query --query "SELECT Id, Name FROM ccai__AI_Prompt__c LIMIT 1" --target-org my-target-org
```

If this query fails, the GPTfy package is not installed. Contact your Salesforce admin to install it first.

### 3. Deploy the Metadata

```bash
sf project deploy start --target-org my-target-org
```

### 4. Assign Permission Sets

```bash
# For administrators
sf org assign permset --name Prompt_Factory_Admin --target-org my-target-org

# For standard users
sf org assign permset --name Prompt_Factory_User --target-org my-target-org
```

### 5. Configure AI Connection

The wizard requires an AI model configuration:
1. Navigate to Setup → Custom Metadata Types → PF_Config
2. Verify the "Claude" record exists with proper settings
3. Ensure GPTfy AI connections are configured in `ccai__AI_Connection__c`

### 6. Access the Wizard

Navigate to: **Platform App → Prompt Factory Wizard tab**

Or directly: `https://[your-domain].lightning.force.com/lightning/n/Prompt_Factory_Wizard`

---

## 🎨 The 12-Stage Pipeline

The Prompt Factory Wizard executes these stages:

### DISCOVER Phase
1. **Stage 0: Fetch Sample** - Retrieve sample record data
2. **Stage 1: Profile Business** - Analyze business context
3. **Stage 2: Discover Schema** - Map object relationships
4. **Stage 3: Assess Data** - Evaluate data quality
5. **Stage 4: Select Fields** - Choose relevant fields
6. **Stage 5: Validate Config** - Verify configuration

### CREATE Phase
7. **Stage 6: Design Layout** - Structure prompt layout
8. **Stage 7: Assemble Prompt** - Build complete prompt

### DEPLOY & TEST Phase
9. **Stage 8: Deploy Prompt** - Create prompt in Salesforce
10. **Stage 9: Execute Test** - Run test execution
11. **Stage 10: Check Safety** - Validate safety checks
12. **Stage 11: Score Quality** - Assess quality metrics

---

## 🔧 Configuration

### Custom Metadata: PF_Config__mdt

Configure these settings:

| Field | Description | Default |
|-------|-------------|---------|
| `Log_Retention_Days__c` | Days to keep logs | 30 |
| `Max_Retry_Attempts__c` | Max retries per stage | 3 |
| `Quality_Pass_Threshold__c` | Minimum quality score | 70 |
| `Stage_Timeout_Seconds__c` | Timeout per stage | 300 |

### AI Model Configuration

Ensure the GPTfy package has AI connections configured with:
- Model name (e.g., Claude, GPT-4)
- API endpoint
- Authentication credentials
- Max tokens and temperature settings

---

## 🧪 Testing

### Run Apex Tests

```bash
sf apex run test --target-org my-target-org --test-level RunLocalTests --result-format human
```

### Test Classes Included (32 total)

#### Core Test Classes
- `PromptFactoryController_Test`
- `PromptFactoryPipeline_Test`
- `PromptFactoryLogger_Test`
- `P_PromptBuilderControllerTest`
- `P_PromptsTableController_Test`
- `P_PromptCatalogueController_Test`

#### Stage Test Classes (12)
- `Stage01_IntelligenceRetrieval_Test` through `Stage12_QualityAudit_Test`

#### Utility Test Classes
- `AIServiceClient_Test`, `DCMBuilder_Test`, `PromptBuilder_Test`
- `SchemaHelper_Test`, `MergeFieldValidator_Test`
- `StageFactory_Test`, `StageResult_Test`, `StageJobHelper_Test`
- `FLSCheckTest`, `GPTfyExceptionTest`, `ChatGPTUtillsTest`
- `CatalogControllerTest`, `AddCardControllerTest`, `AIPromptControllerTest`

### Manual Testing

1. Navigate to the Prompt Factory Wizard
2. Fill in the configuration:
   - Prompt Name
   - Root Object (e.g., Account)
   - Sample Record ID
   - Business Context
   - Output Format
3. Click "Start Pipeline Run"
4. Monitor the 12-stage execution
5. Review quality scores
6. Verify prompt creation in GPTfy

---

## 📊 Monitoring & Logs

### View Pipeline Runs

Query recent runs:
```sql
SELECT Id, Name, Prompt_Name__c, Status__c, Overall_Quality_Score__c, 
       Started_At__c, Completed_At__c, Duration_Seconds__c
FROM PF_Run__c
ORDER BY CreatedDate DESC
LIMIT 10
```

### View Stage Details

```sql
SELECT Stage_Number__c, Stage_Name__c, Status__c, Duration_Seconds__c, 
       Error_Message__c
FROM PF_Run_Stage__c
WHERE Run__c = 'a18XXXXXXXXXX'
ORDER BY Stage_Number__c
```

### View Logs

```sql
SELECT Timestamp__c, Log_Level__c, Component__c, Log_Message__c, Details__c
FROM PF_Run_Log__c
WHERE Run__c = 'a18XXXXXXXXXX'
ORDER BY Timestamp__c DESC
```

---

## 🔐 Security

### Field-Level Security
All DML operations enforce FLS through the `FLSCheck` utility class.

### Permission Sets
- **Prompt_Factory_Admin**: Full CRUD on all PF objects, access to all tabs
- **Prompt_Factory_User**: Read/Create on PF_Run__c, Read-only on configs

### Data Access
- Respects org-wide defaults
- Uses `with sharing` on all controllers
- Validates user permissions before operations

---

## 🐛 Troubleshooting

### Issue: "Entity of type 'CustomObject' named 'ccai__AI_Prompt__c' cannot be found"
**Solution**: Install the GPTfy managed package first.

### Issue: "Component promptFactoryWizard not found"
**Solution**: Ensure all LWC components are deployed. Run: `sf project deploy start --metadata "LightningComponentBundle"`

### Issue: "No AI Model options available"
**Solution**: Configure AI connections in the GPTfy package (`ccai__AI_Connection__c`).

### Issue: Pipeline stages fail with timeout
**Solution**: Increase `Stage_Timeout_Seconds__c` in PF_Config__mdt.

### Issue: Quality score always fails
**Solution**: Lower `Quality_Pass_Threshold__c` in PF_Config__mdt or improve prompt quality.

---

## 📝 Maintenance

### Regular Tasks
1. **Clean old logs**: Delete PF_Run_Log__c records older than retention period
2. **Archive completed runs**: Export and delete old PF_Run__c records
3. **Monitor quality scores**: Review trends in PF_Quality_Score__c
4. **Update AI models**: Keep GPTfy package and AI connections current

### Backup Strategy
- Export PF_Run__c records monthly
- Backup custom metadata configurations
- Document AI model configurations

---

## 🤝 Support

For issues and questions:
- Check the troubleshooting section above
- Review logs in PF_Run_Log__c
- Contact your Salesforce administrator
- Refer to GPTfy package documentation

---

## 📄 License

This solution is proprietary and requires the GPTfy managed package license.

---

## 🎉 Success Criteria

After deployment, you should be able to:
✅ Access the Prompt Factory Wizard tab  
✅ Start a new pipeline run  
✅ See all 12 stages execute  
✅ View real-time progress  
✅ Review quality scores  
✅ Access created prompts in GPTfy  
✅ Monitor logs and history  

---

**Built with ❤️ for Salesforce AI Excellence**
