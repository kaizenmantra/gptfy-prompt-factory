# GPTfy Prompt Factory

**AI-Powered Prompt Builder for Salesforce**

An intelligent prompt creation and management system that uses natural language processing to generate comprehensive AI prompts with automatic data context mapping.

---

## 🎯 Overview

GPTfy Prompt Factory is a Salesforce application that revolutionizes how users create and manage AI prompts. Instead of manually configuring complex prompt structures, users simply describe what they want in natural language, and the AI generates production-ready prompts with:

- Intelligent field selection
- Proper data relationships
- Comprehensive instructions
- Data extraction mappings
- Deployment configurations

---

## ✨ Key Features

### 1. **AI-Powered Prompt Generation**
- Natural language input → Complete prompt configuration
- Automated data context mapping
- Smart field recommendations based on Salesforce schema
- Production-ready output in seconds

### 2. **Prompt Catalogue Management**
- Visual card-based interface
- Purpose-driven organization
- Metrics tracking (prompts deployed, time saved, cost savings)
- Multi-stage deployment workflow

### 3. **Configuration & Deployment**
- Profile-based access control
- Record type filtering
- Visibility condition builder
- Bulk prompt deployment

### 4. **Build Your Own Mode**
- Advanced manual prompt builder for power users
- Full control over all prompt parameters
- Data extraction mapping configuration

---

## 🏗️ Architecture

### Components

#### Lightning Web Components (6)
- `p_promptBuilder` - Main AI-powered wizard interface
- `p_PromptCatalogue` - Catalogue management with metrics
- `p_PromptsTable` - Table view for prompt selection
- `p_PromptCatalogueDeployment` - Deployment configuration
- `aIPromptOverride` - Advanced manual prompt builder
- `aiPromptWhereClauseFormulaComponent` - Formula builder for visibility conditions

#### Apex Controllers (15+)
- `P_PromptBuilderController` - AI generation and prompt creation
- `P_PromptsTableController` - Table data management
- `CatalogController` - Catalogue operations
- `AddCardController` - Card configuration
- `AIPromptController` - Core prompt operations
- Plus utility classes: `FLSCheck`, `AIConstants`, `GPTfyException`, etc.

#### Custom Objects
- `AI_Prompt__c` - Main prompt storage
- `AI_Connection__c` - AI service configuration
- `AI_Data_Extraction_Mapping__c` - Data context mappings
- `AI_Data_Extraction_Detail__c` - Child relationships
- `AI_Data_Extraction_Field__c` - Field mappings
- `AI_Card_Configuration__c` - Catalogue card metadata

---

## 🚀 Quick Start

### Prerequisites
- Salesforce DX CLI installed
- **GPTfy Managed Package** (namespace: `ccai__`) installed in target org
- Salesforce API v64.0 or higher
- Lightning Experience enabled

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/[your-org]/gptfy-prompt-factory.git
cd gptfy-prompt-factory
```

2. **Authenticate to your Salesforce org**
```bash
sf org login web --alias prompt-factory-org
```

3. **Verify GPTfy Package is Installed**
```bash
sf data query --query "SELECT Id FROM ccai__AI_Prompt__c LIMIT 1" --target-org prompt-factory-org
```
If this fails, install the GPTfy package first.

4. **Deploy to Salesforce**
```bash
sf project deploy start --target-org prompt-factory-org
```

5. **Assign Permissions**
```bash
# For administrators
sf org assign permset --name Prompt_Factory_Admin --target-org prompt-factory-org

# For standard users
sf org assign permset --name Prompt_Factory_User --target-org prompt-factory-org
```

6. **Access the Wizard**
Navigate to: **Platform App → Prompt Factory Wizard tab**

📖 **See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for detailed instructions**

---

## 💡 Usage

### Creating a Prompt with AI

1. Navigate to the Prompt Factory app or add the component to any Lightning page
2. In the search box, describe what you want your prompt to do:
   ```
   Create a prompt to analyze account sentiment based on 
   opportunities and cases, providing risk factors and 
   recommendations
   ```
3. Press Enter or click the send button
4. The AI will generate a complete prompt with:
   - Structured prompt command
   - Data context mapping
   - Field selections
   - Target object configuration
5. Review and save the generated prompt

### Using the Catalogue

1. Navigate to the Prompt Catalogue
2. Browse available prompts by purpose
3. Select prompts to deploy
4. Configure profiles and visibility conditions
5. Deploy to make available to users

### Advanced Mode ("Build Your Own")

1. Click "Build Your Own" in the prompt builder
2. Manually configure all aspects:
   - Prompt command
   - Object and fields
   - Data extraction mappings
   - Advanced parameters (temperature, tokens, etc.)

---

## 🔧 Configuration

### AI Connection Setup

Create an `AI_Connection__c` record with:
- **Name**: "Response API"
- **Named Credential**: Your named credential name
- **Model**: gpt-4 or compatible model
- **Endpoint URL**: /v1/responses (or your API endpoint)
- **Max Tokens**: 3000 (recommended)
- **Temperature**: 0.7 (recommended)

### Named Credential

Set up a Named Credential in Salesforce with:
- External Site URL: Your AI API base URL
- Authentication: API Key or OAuth
- Custom Headers as needed

---

## 📊 Data Model

### Core Objects

**AI_Prompt__c**
- Stores prompt configurations
- Links to AI connections and data mappings
- Supports profile/record type filtering
- Visibility condition formulas

**AI_Data_Extraction_Mapping__c**
- Master record for data context
- Defines primary object
- Contains child relationships and fields

**AI_Data_Extraction_Detail__c**
- Defines child relationships (max 3)
- Supports WHERE clauses, ORDER BY, LIMIT
- Validates against Salesforce schema

**AI_Data_Extraction_Field__c**
- Individual field mappings
- Type: FIELD or OBJECT (label)
- Send_To_AI__c flag

---

## 🎨 UI Components

### Prompt Builder Interface

The main interface features:
- Animated placeholder text with examples
- Quick-access pill suggestions for common use cases
- Real-time AI generation with loading states
- Error handling and validation

### Catalogue View

Multi-stage workflow:
1. **Purpose Selection** - Browse by category
2. **Configuration** - Select prompts from table
3. **Deployment** - Configure profiles and visibility

---

## 🧪 Testing

Run all tests:
```bash
sf apex run test --target-org prompt-factory-org --test-level RunLocalTests --result-format human
```

Test coverage:
- P_PromptBuilderControllerTest
- P_PromptsTableController_Test
- P_PromptCatalogueController_Test
- CatalogControllerTest
- AddCardControllerTest
- FLSCheckTest
- GPTfyExceptionTest

---

## 🔐 Security

### Field-Level Security
All DML operations enforce FLS through the `FLSCheck` utility class.

### Profile-Based Access
Prompts support profile-based visibility using:
- `Profiles__c` field (semicolon-separated)
- `Record_Type__c` field (semicolon-separated)
- `Visibility_Condition__c` formula field

### Data Sovereignty
- Supports customer-hosted AI endpoints
- No data leaves Salesforce unless explicitly configured
- Audit trails via standard Salesforce tracking

---

## 📝 API Version

**Current API Version**: 62.0

---

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Add tests (maintain >75% coverage)
4. Submit a pull request

---

## 📄 License

[Your License Here]

---

## 🙋 Support

For issues and questions:
- GitHub Issues: [Your Issues URL]
- Documentation: [Your Docs URL]
- Contact: [Your Contact Email]

---

## 🗺️ Roadmap

- [ ] Multi-language support
- [ ] Prompt versioning and rollback
- [ ] A/B testing capabilities
- [ ] Enhanced analytics dashboard
- [ ] Prompt marketplace/sharing

---

## ⚡ Performance

- Prompt generation: < 5 seconds typical
- Supports up to 3 child relationships per prompt
- Validates all fields against Salesforce schema
- Automatic cleanup of invalid/stale configurations

---

## 🎓 Best Practices

1. **Start with Natural Language**: Let AI handle the heavy lifting
2. **Test Before Deploying**: Use the testing console to validate prompts
3. **Limit Child Relationships**: Max 3 for optimal performance
4. **Use Visibility Conditions**: Fine-tune access beyond profiles
5. **Monitor Metrics**: Track time saved and ROI

---

Built with ❤️ by the GPTfy Team
