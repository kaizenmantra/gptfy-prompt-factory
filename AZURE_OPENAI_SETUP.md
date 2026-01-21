# Azure OpenAI GPT-4o Integration Setup Guide

## Overview
This feature branch adds Azure OpenAI GPT-4o support to the Prompt Factory Wizard, allowing you to use Azure-hosted OpenAI models instead of Claude AI.

## What's New

### 1. Azure OpenAI Custom Setting
A new custom setting `Azure_OpenAI_Credentials__c` has been created with the following fields:
- **API_Endpoint__c**: Full Azure OpenAI endpoint URL
- **API_Key__c**: Your Azure OpenAI API key
- **Deployment_Name__c**: Your deployment name (e.g., "gpt-4o-for-coding")
- **Max_Tokens__c**: Maximum tokens (default: 4096)
- **Temperature__c**: Temperature setting (default: 0.7)

### 2. Enhanced AIServiceClient
The `AIServiceClient` class now supports:
- **Automatic Provider Detection**: Automatically uses Azure OpenAI if configured, falls back to Claude
- **Azure OpenAI Methods**:
  - `callAzureOpenAI()` - Basic Azure OpenAI call
  - `callAzureOpenAIJSON()` - JSON extraction with Azure OpenAI
- **Universal Methods** (recommended):
  - `callAI()` - Automatically routes to configured provider
  - `callAIJSON()` - JSON extraction with auto-routing

### 3. Tested Connection
✅ Successfully tested connection to your Azure OpenAI endpoint:
- Endpoint: `https://saura-m51w47qu-eastus2.cognitiveservices.azure.com`
- Deployment: `gpt-4o-for-coding`
- Model: `gpt-4o-2024-11-20`
- Response: "Hello! How can I assist you today?"

## Deployment Instructions

### Step 1: Deploy to Salesforce

```bash
# Deploy the new Azure OpenAI components
sf project deploy start \\
  --source-dir force-app/main/default/objects/Azure_OpenAI_Credentials__c \\
  --source-dir force-app/main/default/classes/AIServiceClient.cls \\
  --source-dir force-app/main/default/customMetadata/PF_Config.Azure_OpenAI_GPT4o.md-meta.xml \\
  --target-org agentictso \\
  --test-level NoTestRun
```

### Step 2: Configure Azure OpenAI Credentials

Navigate to **Setup → Custom Settings → Azure OpenAI Credentials → Manage**

Click **New** and enter:

| Field | Value |
|-------|-------|
| **API Endpoint** | `https://saura-m51w47qu-eastus2.cognitiveservices.azure.com/openai/deployments/gpt-4o-for-coding/chat/completions?api-version=2024-12-01-preview` |
| **API Key** | `9FzRxq2nMHNzlduqmGEozrwJ5o9Ittb57A0SGOPTzwVvS7Otjb6NJQQJ99ALACHYHv6XJ3w3AAAAACOGIjot` |
| **Deployment Name** | `gpt-4o-for-coding` |
| **Max Tokens** | `4096` |
| **Temperature** | `0.7` |

### Step 3: Add Remote Site Setting

Navigate to **Setup → Security → Remote Site Settings → New**

| Field | Value |
|-------|-------|
| **Remote Site Name** | `Azure_OpenAI` |
| **Remote Site URL** | `https://saura-m51w47qu-eastus2.cognitiveservices.azure.com` |
| **Active** | ✅ Checked |

### Step 4: Test the Integration

1. Navigate to the **Prompt Factory Wizard** tab
2. Start a new pipeline run
3. The wizard will automatically use Azure OpenAI GPT-4o

## Code Changes

### Backward Compatibility
✅ All existing Claude AI functionality remains intact
✅ Existing code continues to work without modification
✅ Automatic provider detection ensures seamless transition

### Migration Path
To migrate existing code to use the universal methods:

**Before:**
```apex
AIServiceClient.callClaude(prompt);
AIServiceClient.callClaudeJSON(systemPrompt, userPrompt, maxTokens);
```

**After (recommended):**
```apex
AIServiceClient.callAI(prompt);
AIServiceClient.callAIJSON(systemPrompt, userPrompt, maxTokens);
```

## Testing

### Manual Test
```bash
# Test Azure OpenAI connection
curl -X POST "https://saura-m51w47qu-eastus2.cognitiveservices.azure.com/openai/deployments/gpt-4o-for-coding/chat/completions?api-version=2024-12-01-preview" \\
  -H "Content-Type: application/json" \\
  -H "api-key: 9FzRxq2nMHNzlduqmGEozrwJ5o9Ittb57A0SGOPTzwVvS7Otjb6NJQQJ99ALACHYHv6XJ3w3AAAAACOGIjot" \\
  -d '{
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Say hello in one sentence."}
    ],
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

### Apex Test
```apex
// Test Azure OpenAI call
AIServiceClient.AIResponse response = AIServiceClient.callAzureOpenAI('Hello, how are you?');
System.debug('Response: ' + response.content);
System.debug('Tokens: ' + response.inputTokens + ' in, ' + response.outputTokens + ' out');
```

## Architecture

### Provider Detection Logic
1. Check if `Azure_OpenAI_Credentials__c` is configured
2. If yes → Use Azure OpenAI
3. If no → Check if `Claude_API_Credentials__c` is configured
4. If yes → Use Claude AI
5. If no → Default to Azure OpenAI (will fail gracefully with error message)

### Request Format

**Azure OpenAI:**
```json
{
  "messages": [
    {"role": "system", "content": "System prompt"},
    {"role": "user", "content": "User prompt"}
  ],
  "max_tokens": 4096,
  "temperature": 0.7
}
```

**Response Format:**
```json
{
  "id": "chatcmpl-...",
  "choices": [{
    "message": {
      "content": "Response text"
    }
  }],
  "usage": {
    "prompt_tokens": 23,
    "completion_tokens": 10
  }
}
```

## Troubleshooting

### Error: "Azure OpenAI credentials not configured"
→ Complete Step 2 above to configure the custom setting

### Error: "Unauthorized endpoint"
→ Add the Remote Site Setting (Step 3)

### Error: "Invalid API key"
→ Verify the API key in the custom setting matches your Azure portal

### Provider Not Switching
→ Clear the default provider: `AIServiceClient.setDefaultProvider(AIServiceClient.AIProvider.AUTO)`

## Rollback Instructions

To revert to Claude AI only:
1. Delete the `Azure_OpenAI_Credentials__c` custom setting record
2. The system will automatically fall back to Claude AI
3. Or explicitly set: `AIServiceClient.setDefaultProvider(AIServiceClient.AIProvider.CLAUDE)`

## Next Steps

1. ✅ Test the deployment in agentictso org
2. Monitor token usage and costs in Azure portal
3. Adjust max_tokens and temperature as needed
4. Consider adding rate limiting if needed

---
**Branch**: `feature/azure-openai-4o`  
**Date**: January 21, 2026  
**Tested**: ✅ Connection verified  
**Status**: Ready for deployment
