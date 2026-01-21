# LLM Configuration Guide - Centralized AI Provider Management

**Date:** January 21, 2026  
**Feature:** Centralized LLM Configuration  
**Version:** 2.0

---

## Overview

The Prompt Factory Wizard now supports **multiple AI providers** with **centralized configuration**. You can easily switch between AI providers by simply checking/unchecking a checkbox - **no code changes required**!

### Supported AI Providers

1. **Azure OpenAI GPT-4o** - Microsoft Azure-hosted OpenAI model
2. **Claude AI** - Anthropic's Claude model (original implementation)

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Prompt Factory Wizard (All 12 Stages)                     │
│  ↓                                                          │
│  All stages call: AIServiceClient.callAI()                 │
│  ↓                                                          │
│  AIServiceClient.detectProvider()                          │
│  ↓                                                          │
│  Checks which credential has Default__c = true             │
│  ↓                                                          │
│  ┌─────────────────┐              ┌──────────────────────┐ │
│  │ Azure OpenAI?   │ YES ──────>  │ Use Azure OpenAI     │ │
│  │ Default = true  │              │ GPT-4o               │ │
│  └─────────────────┘              └──────────────────────┘ │
│  ↓ NO                                                      │
│  ┌─────────────────┐              ┌──────────────────────┐ │
│  │ Claude AI?      │ YES ──────>  │ Use Claude AI        │ │
│  │ Default = true  │              │                      │ │
│  └─────────────────┘              └──────────────────────┘ │
│  ↓ NO                                                      │
│  Fallback: Use first available provider                   │
└─────────────────────────────────────────────────────────────┘
```

### Configuration Flow

1. **Credentials are stored** in custom settings (hierarchy type)
2. **Default checkbox** determines which provider to use
3. **AIServiceClient automatically detects** the provider based on the Default checkbox
4. **All stage classes** use the universal `callAI()` method
5. **No code changes** needed to switch providers!

---

## Configuration Steps

### Option 1: Use Azure OpenAI GPT-4o

#### Step 1: Configure Azure OpenAI Credentials

Navigate to: **Setup → Custom Settings → Azure OpenAI Credentials → Manage**

Click "New" and enter:
- **API Endpoint**: Full Azure OpenAI endpoint URL
- **API Key**: Your Azure OpenAI API key
- **Deployment Name**: Your deployment name (e.g., `gpt-4o-for-coding`)
- **Max Tokens**: 4096
- **Temperature**: 0.7
- **Default**: ✅ **Check this box**

#### Step 2: Add Remote Site Setting

Navigate to: **Setup → Security → Remote Site Settings → New**

- **Remote Site Name**: `Azure_OpenAI`
- **Remote Site URL**: Your Azure endpoint base URL
- **Active**: ✅

#### Step 3: Uncheck Claude (if configured)

If you have Claude configured:
- Navigate to: **Setup → Custom Settings → Claude API Credentials → Manage**
- Edit the record
- **Default**: ❌ **Uncheck this box**

#### Done!
The Prompt Factory will now use Azure OpenAI GPT-4o for all AI operations.

---

### Option 2: Use Claude AI

#### Step 1: Configure Claude API Credentials

Navigate to: **Setup → Custom Settings → Claude API Credentials → Manage**

Click "New" and enter:
- **API Key**: Your Claude API key
- **API Endpoint**: Claude API endpoint
- **Max Tokens**: 16384
- **Temperature**: 0.7
- **Default**: ✅ **Check this box**

#### Step 2: Add Remote Site Setting

Navigate to: **Setup → Security → Remote Site Settings → New**

- **Remote Site Name**: `Claude_AI`
- **Remote Site URL**: `https://api.anthropic.com`
- **Active**: ✅

#### Step 3: Uncheck Azure (if configured)

If you have Azure configured:
- Navigate to: **Setup → Custom Settings → Azure OpenAI Credentials → Manage**
- Edit the record
- **Default**: ❌ **Uncheck this box**

#### Done!
The Prompt Factory will now use Claude AI for all AI operations.

---

## Switching Between Providers

### Quick Switch (30 seconds)

To switch from Azure to Claude (or vice versa):

1. **Uncheck the current default**
   - Go to the current provider's custom setting
   - Edit the record
   - Uncheck "Default"
   - Save

2. **Check the new default**
   - Go to the new provider's custom setting
   - Edit the record
   - Check "Default"
   - Save

3. **Test**
   - Start a new pipeline run in the Prompt Factory Wizard
   - The new provider will be used automatically!

**No deployment, no code changes, no restarts needed!** ✨

---

## Detection Logic

The system uses the following logic in `AIServiceClient.detectProvider()`:

```apex
1. Check if Azure OpenAI credentials exist AND Default__c = true
   → If yes, use Azure OpenAI GPT-4o

2. Check if Claude AI credentials exist AND Default__c = true
   → If yes, use Claude AI

3. Fallback: If neither is marked as default but credentials exist
   → Prefer Azure OpenAI (if configured)
   → Otherwise use Claude AI

4. If no credentials configured
   → Fail gracefully with clear error message
```

---

## Benefits of This Architecture

### ✅ Flexibility
- Switch AI providers in seconds
- No code deployment required
- No downtime

### ✅ Maintainability
- Single point of configuration
- Clear separation of concerns
- Easy to add new providers

### ✅ Testability
- Can quickly test different providers
- Easy A/B testing
- Simple rollback if needed

### ✅ Security
- Credentials stored in protected custom settings
- Hierarchy-based (can override at user/profile level)
- No hardcoded values

### ✅ Scalability
- Easy to add new AI providers
- Just add new custom setting and update `detectProvider()`
- Stage classes remain unchanged

---

## Stage Classes Updated

The following stage classes now use the universal `callAI()` method:

1. **Stage 2** - Strategic Profiling
2. **Stage 3** - Schema Discovery
3. **Stage 5** - Field Selection
4. **Stage 7** - Template Design
5. **Stage 12** - Quality Audit

All other stages that use AI will automatically benefit from this centralized configuration.

---

## Custom Settings Schema

### Azure_OpenAI_Credentials__c

| Field | Type | Description |
|-------|------|-------------|
| `API_Endpoint__c` | Text(255) | Full Azure OpenAI endpoint URL including deployment and API version |
| `API_Key__c` | Text(255) | Azure OpenAI API key |
| `Deployment_Name__c` | Text(100) | Deployment name (e.g., gpt-4o-for-coding) |
| `Max_Tokens__c` | Number(18,0) | Maximum tokens for responses (default: 4096) |
| `Temperature__c` | Number(3,2) | Temperature setting (0-1, default: 0.7) |
| `Default__c` | Checkbox | ✅ Check to make this the default AI provider |

### Claude_API_Credentials__c

| Field | Type | Description |
|-------|------|-------------|
| `API_Key__c` | Text(255) | Claude API key |
| `API_Endpoint__c` | Text(255) | Claude API endpoint URL |
| `Max_Tokens__c` | Number(18,0) | Maximum tokens for responses (default: 16384) |
| `Temperature__c` | Number(3,2) | Temperature setting (0-1, default: 0.7) |
| `Default__c` | Checkbox | ✅ Check to make this the default AI provider |

---

## Troubleshooting

### Issue: Pipeline fails with "API credentials not configured"

**Solution:**
1. Verify credentials exist: Setup → Custom Settings
2. Verify at least one has `Default__c = true`
3. Verify API key is present and valid
4. Check remote site settings are active

### Issue: Pipeline uses wrong AI provider

**Solution:**
1. Check which credential has `Default__c = true`
2. Only ONE provider should have Default checked
3. Clear any caches by logging out and back in
4. Start a NEW pipeline run (old runs use old settings)

### Issue: Both providers marked as default

**Solution:**
The system will prefer Azure OpenAI if both are marked as default. Uncheck one to avoid confusion.

### Issue: Neither provider marked as default

**Solution:**
The system will fall back to the first available provider (preferring Azure if both exist). For clarity, always mark one as default.

---

## Best Practices

### ✅ DO
- Keep only ONE provider marked as Default at a time
- Test new configurations with a sample pipeline run first
- Document which provider you're using in your org
- Monitor API usage and costs for each provider

### ❌ DON'T
- Don't mark both providers as Default
- Don't delete credentials while pipelines are running
- Don't forget to add remote site settings
- Don't hardcode provider selection in custom code

---

## Future Enhancements

Potential additions to this architecture:

1. **Additional Providers**
   - OpenAI (direct, not Azure)
   - Google Gemini
   - Mistral AI
   - Local LLMs

2. **Advanced Configuration**
   - Per-stage provider selection
   - Automatic failover between providers
   - Cost-based provider selection
   - Performance-based routing

3. **Monitoring**
   - Usage dashboard
   - Cost tracking
   - Performance metrics
   - Error rate monitoring

---

## Support

For questions or issues:
- Review this guide
- Check `AZURE_OPENAI_SETUP.md` for Azure-specific setup
- Check `AZURE_VALIDATION_REPORT.md` for validation details
- Review debug logs in PF_Run_Log__c records

---

**Last Updated:** January 21, 2026  
**Architecture Version:** 2.0 - Centralized LLM Configuration
