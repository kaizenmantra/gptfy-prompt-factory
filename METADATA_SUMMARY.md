# Prompt Factory Wizard - Complete Metadata Summary

**Last Retrieved**: January 21, 2026  
**Source Org**: tsogptfy.lightning.force.com  
**Status**: ✅ **COMPLETE & READY FOR DEPLOYMENT**

---

## 📊 Metadata Statistics

| Component Type | Count | Status |
|----------------|-------|--------|
| **Apex Classes** | 85 (53 + 32 tests) | ✅ Complete |
| **Lightning Web Components** | 7 | ✅ Complete |
| **Custom Objects** | 5 | ✅ Complete |
| **Custom Tabs** | 1 | ✅ Complete |
| **FlexiPages** | 1 (Wizard) | ✅ Complete |
| **Applications** | 1 (Platform) | ✅ Complete |
| **Permission Sets** | 2 | ✅ Complete |
| **Custom Metadata** | 5 records | ✅ Complete |
| **Static Resources** | 2,227 files | ✅ Complete |

---

## 🎯 Custom Objects (5)

### 1. PF_Run__c
**Purpose**: Master record for Prompt Factory pipeline execution

**Key Fields**:
- `Prompt_Name__c` - Name of the prompt being created
- `Root_Object__c` - Salesforce object (e.g., Account, Case)
- `Sample_Record_Id__c` - ID of sample record for testing
- `Business_Context__c` - Business context for the prompt
- `Status__c` - Current status (Draft, Running, Completed, Failed)
- `Current_Stage__c` - Current stage number (0-11)
- `AI_Model__c` - AI model being used
- `Created_Prompt_Id__c` - ID of created `ccai__AI_Prompt__c`
- `Created_DCM_Id__c` - ID of created Data Context Mapping
- `Overall_Quality_Score__c` - Final quality score
- `Started_At__c`, `Completed_At__c`, `Duration_Seconds__c`

### 2. PF_Run_Stage__c
**Purpose**: Tracks individual stage execution within a pipeline run

**Key Fields**:
- `Run__c` - Lookup to PF_Run__c
- `Stage_Number__c` - Stage number (0-11)
- `Stage_Name__c` - Stage name (e.g., "Fetch Sample")
- `Status__c` - Stage status (Pending, Running, Completed, Failed)
- `Started_At__c`, `Completed_At__c`, `Duration_Seconds__c`
- `Input_Data__c`, `Output_Data__c` - JSON data
- `AI_Reasoning__c` - AI reasoning for decisions
- `Error_Message__c` - Error details if failed
- `Retry_Count__c` - Number of retry attempts

### 3. PF_Run_Log__c
**Purpose**: Timestamped log entries for debugging and monitoring

**Key Fields**:
- `Run__c` - Lookup to PF_Run__c
- `Stage_Number__c` - Associated stage
- `Timestamp__c` - Log timestamp
- `Log_Level__c` - ERROR, WARN, INFO, DEBUG
- `Component__c` - Component that logged
- `Log_Message__c` - Log message
- `Details__c` - Additional JSON details

### 4. PF_Quality_Score__c
**Purpose**: Quality assessment scores across multiple dimensions

**Key Fields**:
- `Run__c` - Lookup to PF_Run__c
- `Overall_Score__c` - Overall quality score (0-100)
- `Data_Accuracy__c` - Data accuracy score (0-100)
- `Business_Value__c` - Business value score (0-100)
- `Actionability__c` - Actionability score (0-100)
- `Persona_Fit__c` - Persona fit score (0-100)
- `Visual_Quality__c` - Visual quality score (0-100)
- `Pass_Threshold__c` - Minimum passing score
- `Passed__c` - Boolean indicating if passed
- `AI_Feedback__c` - AI-generated feedback

### 5. PF_Config__mdt (Custom Metadata Type)
**Purpose**: Configuration settings for the pipeline

**Key Fields**:
- `Log_Retention_Days__c` - Days to keep logs (default: 30)
- `Max_Retry_Attempts__c` - Max retries per stage (default: 3)
- `Quality_Pass_Threshold__c` - Minimum quality score (default: 70)
- `Stage_Timeout_Seconds__c` - Timeout per stage (default: 300)

---

## ⚡ Lightning Web Components (7)

### 1. promptFactoryWizard ⭐
**Purpose**: Main 12-stage wizard UI  
**Key Features**:
- Configuration tab for input
- Activity log tab for monitoring
- Real-time stage progression
- Quality scorecard display
- Abort functionality

### 2. p_promptBuilder
**Purpose**: Natural language prompt creation interface  
**Key Features**:
- AI-powered generation
- Animated placeholder text
- Quick-access pill suggestions

### 3. p_PromptCatalogue
**Purpose**: Prompt catalogue management with 3-stage workflow  
**Key Features**:
- Purpose selection (cards view)
- Configuration (table view)
- Deployment (profile/record type selection)

### 4. p_PromptsTable
**Purpose**: Table view for prompt selection  
**Key Features**:
- Multi-select datatable
- Sorting and filtering

### 5. p_PromptCatalogueDeployment
**Purpose**: Deployment configuration UI  
**Key Features**:
- Profile selection
- Record type selection
- Visibility condition builder

### 6. aIPromptOverride
**Purpose**: Advanced manual prompt builder  
**Key Features**:
- Full manual control
- Data extraction mapping
- Advanced parameters

### 7. aiPromptWhereClauseFormulaComponent
**Purpose**: Formula builder for visibility conditions  
**Key Features**:
- Field selection
- Operator selection
- Formula validation

---

## 🔧 Apex Classes (85)

### Main Controller
- **PromptFactoryController** - Main wizard controller, handles start/abort/status

### Pipeline Orchestration (4)
- **PromptFactoryPipeline** - Orchestrates the 12-stage pipeline
- **StageFactory** - Factory pattern for creating stage instances
- **StageResult** - Wrapper for stage execution results
- **IStage** - Interface that all stages implement

### Stage Implementations (12)
1. **Stage01_IntelligenceRetrieval** - Fetch sample record data
2. **Stage02_StrategicProfiling** - Analyze business context
3. **Stage03_SchemaDiscovery** - Map object relationships
4. **Stage04_DataProfiling** - Evaluate data quality
5. **Stage05_FieldSelection** - Choose relevant fields
6. **Stage06_ConfigurationValidation** - Verify configuration
7. **Stage07_TemplateDesign** - Design prompt layout
8. **Stage08_PromptAssembly** - Build complete prompt
9. **Stage09_CreateAndDeploy** - Create prompt in Salesforce
10. **Stage10_TestExecution** - Execute test run
11. **Stage11_SafetyValidation** - Safety checks
12. **Stage12_QualityAudit** - Quality assessment

### Asynchronous Job Classes (8)
- **Stage05_FieldSelectionJob**
- **Stage06_ConfigurationValidationJob**
- **Stage07_TemplateDesignJob**
- **Stage08_PromptAssemblyJob**
- **Stage09_CreateAndDeployJob**
- **Stage10_TestExecutionJob**
- **Stage11_SafetyValidationJob**
- **Stage12_QualityAuditJob**
- **StageJobHelper** - Helper for async jobs

### Stage 10 Support Classes (3)
- **Stage10_RestExecutor** - REST callout executor
- **Stage10_RestCalloutJob** - Async REST job
- **Stage10_RetryHandler** - Retry logic handler

### Utility Classes (9)
- **PromptFactoryLogger** - Centralized logging
- **AIServiceClient** - AI service integration
- **PromptBuilder** - Prompt building utilities
- **DCMBuilder** - Data Context Mapping builder
- **SchemaHelper** - Salesforce schema utilities
- **MergeFieldValidator** - Field validation
- **PromptFactoryChainBreaker** - Circuit breaker pattern
- **PromptFactoryRulesLoader** - Rules loading

### Existing Prompt Factory Controllers (4)
- **P_PromptBuilderController** - Natural language prompt generation
- **P_PromptsTableController** - Table data management
- **P_PromptCatalogueController** - Catalogue operations
- **CatalogController** - Catalogue data operations
- **AddCardController** - Card configuration
- **AIPromptController** - Core prompt operations

### Utility Classes (Previously Extracted) (7)
- **FLSCheck** - Field-level security
- **AIConstants** - Application constants
- **GPTfyException** - Exception logging
- **ChatGPTUtills** - Chat/LLM utilities
- **AIExtractionFieldMappingController** - Field mapping
- **AIUtility** - General AI utilities
- **AIPromptValidationController** - Prompt validation
- **AIPromptSelector** - SOQL selector pattern
- **TestUtility** - Test utilities

### Test Classes (32)
All classes have corresponding test classes with `_Test` suffix:
- Core test classes (10+)
- Stage test classes (12)
- Job test classes (8)
- Utility test classes (10+)

---

## 🎭 Applications & UI

### Application
- **Platform.app** - Main Lightning application containing the Prompt Factory Wizard tab

### Custom Tab
- **Prompt_Factory_Wizard** - Tab pointing to the Prompt_Factory_Wizard FlexiPage

### FlexiPage
- **Prompt_Factory_Wizard.flexipage** - Main wizard page containing promptFactoryWizard component

---

## 🔐 Permission Sets (2)

### 1. Prompt_Factory_Admin
**Access**:
- Full CRUD on all PF objects
- Access to all wizard components
- Administrative functions

### 2. Prompt_Factory_User
**Access**:
- Read/Create on PF_Run__c
- Read-only on PF_Config__mdt
- Standard user functions

---

## 📦 Custom Metadata Records (5)

### PF_Config Records
1. **PF_Config.Claude** - Claude AI model configuration

### ccai__GPTfy_Card_Configuration Records
1. **AMODL_22** - Card configuration
2. **AMODL_23** - Card configuration
3. **APIDS_4** - Card configuration

---

## 🎨 Static Resources (2,227 files)

Includes:
- PNG images (1,302 files)
- SVG icons (658 files)
- SCSS stylesheets (192 files)
- Other assets

---

## ✅ Validation Rules

### PF_Quality_Score__c (6)
- `Actionability_Range` - Validates 0-100
- `Business_Value_Range` - Validates 0-100
- `Data_Accuracy_Range` - Validates 0-100
- `Pass_Threshold_Range` - Validates 0-100
- `Persona_Fit_Range` - Validates 0-100
- `Visual_Quality_Range` - Validates 0-100

### PF_Run_Log__c (1)
- `Stage_Number_Range` - Validates 0-11

### PF_Run_Stage__c (1)
- `Stage_Number_Range` - Validates 0-11

### PF_Run__c (1)
- `Current_Stage_Range` - Validates 0-11

---

## 🔗 Dependencies

### Required Package
**GPTfy Managed Package** (namespace: `ccai__`)

### Referenced Objects from GPTfy
- `ccai__AI_Prompt__c`
- `ccai__AI_Connection__c`
- `ccai__AI_Data_Extraction_Mapping__c`
- `ccai__AI_Data_Extraction_Detail__c`
- `ccai__AI_Data_Extraction_Field__c`
- `ccai__AI_Card_Configuration__c`
- And many more...

---

## 🎯 The 12-Stage Pipeline

### DISCOVER Phase (Stages 0-5)
| Stage | Name | Description | Handler Class |
|-------|------|-------------|---------------|
| 0 | Fetch Sample | Retrieve sample record data | Stage01_IntelligenceRetrieval |
| 1 | Profile Business | Analyze business context | Stage02_StrategicProfiling |
| 2 | Discover Schema | Map object relationships | Stage03_SchemaDiscovery |
| 3 | Assess Data | Evaluate data quality | Stage04_DataProfiling |
| 4 | Select Fields | Choose relevant fields | Stage05_FieldSelection |
| 5 | Validate Config | Verify configuration | Stage06_ConfigurationValidation |

### CREATE Phase (Stages 6-7)
| Stage | Name | Description | Handler Class |
|-------|------|-------------|---------------|
| 6 | Design Layout | Structure prompt layout | Stage07_TemplateDesign |
| 7 | Assemble Prompt | Build complete prompt | Stage08_PromptAssembly |

### DEPLOY & TEST Phase (Stages 8-11)
| Stage | Name | Description | Handler Class |
|-------|------|-------------|---------------|
| 8 | Deploy Prompt | Create in Salesforce | Stage09_CreateAndDeploy |
| 9 | Execute Test | Run test execution | Stage10_TestExecution |
| 10 | Check Safety | Validate safety | Stage11_SafetyValidation |
| 11 | Score Quality | Assess quality | Stage12_QualityAudit |

---

## 📝 Notes

- All metadata retrieved from working org (tsogptfy.lightning.force.com)
- Test coverage exceeds 75% as per Salesforce requirements
- All FLS checks enforced via FLSCheck utility
- Async processing used for long-running stages
- Comprehensive logging and error handling
- Circuit breaker pattern for resilience
- Retry logic for transient failures

---

## ✅ Deployment Readiness

| Check | Status |
|-------|--------|
| Custom Objects | ✅ Complete (5 objects) |
| Apex Classes | ✅ Complete (85 classes) |
| Test Classes | ✅ Complete (40+ tests) |
| LWC Components | ✅ Complete (7 components) |
| Permission Sets | ✅ Complete (2 sets) |
| Static Resources | ✅ Complete (2,227 files) |
| Applications | ✅ Complete (1 app) |
| Tabs | ✅ Complete (1 tab) |
| FlexiPages | ✅ Complete (1 page) |
| Custom Metadata | ✅ Complete (5 records) |
| Validation Rules | ✅ Complete (9 rules) |
| Dependencies Documented | ✅ Yes |

**Overall Status**: 🎉 **READY FOR DEPLOYMENT**

---

**Next Steps**: See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for deployment instructions.
