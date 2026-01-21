import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import Apex methods
import generatePromptDetails from '@salesforce/apex/P_PromptBuilderController.generatePromptDetails';
import createPromptWithMapping from '@salesforce/apex/P_PromptBuilderController.createPromptWithMapping';
import getExistingPrompts from '@salesforce/apex/P_PromptBuilderController.getExistingPrompts';

// Import Static Resource
import GPTFY_LOGO from '@salesforce/resourceUrl/gptfylogo';

export default class P_promptBuilder extends NavigationMixin(LightningElement) {
    @track userInput = '';
    @track isProcessing = false;
    @track currentPlaceholder = '';
    
    gptfyLogoUrl = GPTFY_LOGO;
    
    placeholderTexts = [
        'Create a prompt to analyze account sentiment based on opportunities and cases...',
        'Build a prompt for case intent analysis including email threads and activities...',
        'Generate a prompt to provide next best action recommendations for opportunities...',
        'Design a prompt to summarize contact interactions and engagement history...'
    ];
    
    currentPlaceholderIndex = 0;
    placeholderInterval;
    typingTimeout;
    currentCharIndex = 0;
    isUserTyping = false;
    
    pillSuggestions = [
        { label: 'Account Analysis' },
        { label: 'Case Insights' },
        { label: 'Opportunity Recommendations' },
        { label: 'Contact Summary' }
    ];
    
    @track showPromptOverride = false;
    
    hasRendered = false;
    
    // ==================== LIFECYCLE HOOKS ====================
    
    connectedCallback() {
        this.resetComponentState();
        this.startPlaceholderAnimation();
    }
    
    renderedCallback() {
        // Force reset on first render to handle cached component state
        if (!this.hasRendered) {
            this.hasRendered = true;
            this.resetComponentState();
        }
    }
    
    disconnectedCallback() {
        this.stopPlaceholderAnimation();
        this.hasRendered = false;
    }
    
    resetComponentState() {
        this.isProcessing = false;
        this.showPromptOverride = false;
        this.userInput = '';
        this.isUserTyping = false;
    }
    
    // ==================== PLACEHOLDER ANIMATION ====================
    
    startPlaceholderAnimation() {
        this.currentPlaceholder = '';
        this.typePlaceholder();
    }
    
    typePlaceholder() {
        if (this.isUserTyping) {
            this.scheduleNextPlaceholder();
            return;
        }
        
        const currentText = this.placeholderTexts[this.currentPlaceholderIndex];
        
        if (this.currentCharIndex < currentText.length) {
            this.currentPlaceholder = currentText.substring(0, this.currentCharIndex + 1);
            this.currentCharIndex++;
            
            this.typingTimeout = setTimeout(() => {
                this.typePlaceholder();
            }, 30);
        } else {
            this.scheduleNextPlaceholder();
        }
    }
    
    scheduleNextPlaceholder() {
        this.typingTimeout = setTimeout(() => {
            if (!this.isUserTyping) {
                this.currentPlaceholderIndex = (this.currentPlaceholderIndex + 1) % this.placeholderTexts.length;
                this.currentCharIndex = 0;
                this.currentPlaceholder = '';
                this.typePlaceholder();
            } else {
                this.scheduleNextPlaceholder();
            }
        }, 3000);
    }
    
    stopPlaceholderAnimation() {
        if (this.typingTimeout) {
            clearTimeout(this.typingTimeout);
        }
        if (this.placeholderInterval) {
            clearInterval(this.placeholderInterval);
        }
    }
    
    // ==================== EVENT HANDLERS ====================
    
    handleInputChange(event) {
        this.userInput = event.target.value;
        this.isUserTyping = this.userInput.length > 0;
    }
    
    handleKeyDown(event) {
        if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) {
            event.preventDefault();
            this.handleSubmit();
        }
    }
    
    handlePillClick(event) {
        const label = event.currentTarget.dataset.label;
        
        const prompts = {
            'Account Analysis': 'Create a prompt that analyzes the overall health and sentiment of an Account by examining:\n\n1. All related Opportunities (open, closed-won, closed-lost) with their stages, amounts, and close dates\n2. All Cases associated with the account including status, priority, and resolution time\n3. Recent activities and engagement history\n4. Account revenue trends and growth patterns\n\nThe prompt should provide:\n- Account health score and sentiment analysis\n- Risk factors and warning signs\n- Growth opportunities and upsell potential\n- Actionable recommendations for account management\n\nTarget Object: Account',
            'Case Insights': 'Create a prompt that provides comprehensive case analysis by examining:\n\n1. Case details including subject, description, status, and priority\n2. All related email messages and their sentiment\n3. Case history and timeline of activities\n4. Customer communication patterns\n5. Related knowledge articles and solutions\n\nThe prompt should deliver:\n- Case intent and root cause analysis\n- Customer sentiment throughout the case lifecycle\n- Predicted resolution time and next best actions\n- Recommendations for case closure and follow-up\n\nTarget Object: Case',
            'Opportunity Recommendations': 'Create a prompt that analyzes opportunities and provides strategic guidance by examining:\n\n1. Opportunity details including stage, amount, probability, and close date\n2. Historical win/loss patterns for similar opportunities\n3. Competitor information and deal risks\n4. Related contacts and their engagement levels\n5. Product mix and pricing analysis\n\nThe prompt should provide:\n- Win probability assessment and risk factors\n- Competitive positioning and differentiation strategies\n- Next best actions to move the deal forward\n- Pricing and discount recommendations\n- Timeline and milestone suggestions\n\nTarget Object: Opportunity',
            'Contact Summary': 'Create a prompt that generates a comprehensive contact profile by analyzing:\n\n1. Contact information and role within the organization\n2. All interactions including emails, calls, and meetings\n3. Engagement frequency and communication preferences\n4. Related opportunities and their outcomes\n5. Sentiment analysis from communications\n6. Social media presence and professional background\n\nThe prompt should deliver:\n- Contact engagement score and relationship strength\n- Communication preferences and best times to reach\n- Key interests and pain points\n- Influence level within the organization\n- Personalized engagement recommendations\n\nTarget Object: Contact'
        };
        
        const selectedPrompt = prompts[label] || '';
        
        this.userInput = selectedPrompt;
        this.isUserTyping = true;
        
        const textarea = this.template.querySelector('.search-input');
        if (textarea) {
            textarea.value = selectedPrompt;
            textarea.focus();
            textarea.scrollTop = 0;
        }
    }
    
    async handleSubmit() {
        if (!this.userInput || this.userInput.trim() === '') {
            this.showToast('Warning', 'Please describe the prompt you want to create', 'warning');
            return;
        }
        
        this.isProcessing = true;
        
        try {
            const existingPrompts = await getExistingPrompts();
            const existingPromptsJson = JSON.stringify(existingPrompts);
            
            const aiResponse = await generatePromptDetails({ 
                userInput: this.userInput,
                existingPromptsJson: existingPromptsJson
            });
            
            const parsedResponse = this.parseAIResponse(aiResponse);
            
            if (!parsedResponse) {
                let responsePreview = '';
                try {
                    responsePreview = typeof aiResponse === 'string' 
                        ? aiResponse.substring(0, 500) 
                        : JSON.stringify(aiResponse).substring(0, 500);
                } catch (e) {
                    responsePreview = String(aiResponse).substring(0, 500);
                }
                throw new Error('Failed to parse AI response. Response preview: ' + responsePreview);
            }
            
            const promptId = await createPromptWithMapping({
                promptName: parsedResponse.name,
                targetObject: parsedResponse.targetObject,
                description: parsedResponse.description,
                promptCommand: parsedResponse.promptCommand,
                dataContextMapping: JSON.stringify(parsedResponse.dataContextMapping)
            });
            
            this.showToast('Success', 'Prompt created successfully! Redirecting...', 'success');
            this.navigateToPromptRecord(promptId);
            
        } catch (error) {
            let errorMessage = 'Failed to create prompt. ';
            if (error.body?.message) {
                errorMessage += error.body.message;
            } else if (error.message) {
                errorMessage += error.message;
            }
            
            this.showToast('Error', errorMessage, 'error');
        } finally {
            this.isUserTyping = false;
            const textarea = this.template.querySelector('.search-input');
            if (textarea) {
                textarea.value = '';
                textarea.focus();
                textarea.scrollTop = 0;
            }
            this.startPlaceholderAnimation();
            this.isProcessing = false;
        }   
    }
    
    handleBuildYourOwn() {
        this.showPromptOverride = true;
    }
    
    handlePromptOverrideCancel() {
        this.showPromptOverride = false;
    }
    
    // ==================== HELPER METHODS ====================
    
    parseAIResponse(response) {
        try {
            let content = null;
            
            if (typeof response === 'string') {
                content = response;
            } else if (typeof response === 'object' && response !== null) {
                if (response.data && response.data.value && response.data.value.choices) {
                    const choices = response.data.value.choices;
                    if (choices.length > 0 && choices[0].message) {
                        content = choices[0].message.content;
                    }
                } else if (response.choices && response.choices.length > 0) {
                    content = response.choices[0].message?.content || response.choices[0].text;
                } else if (response.output) {
                    content = response.output;
                } else if (response.content) {
                    content = response.content;
                } else if (response.text) {
                    content = response.text;
                } else {
                    content = JSON.stringify(response);
                }
            }
            
            if (!content || content.trim() === '') {
                return null;
            }
            
            content = content.trim();
            
            if (content.startsWith('```json')) {
                content = content.substring(7);
            } else if (content.startsWith('```')) {
                content = content.substring(3);
            }
            
            if (content.endsWith('```')) {
                content = content.substring(0, content.length - 3);
            }
            
            content = content.trim();
            
            const promptDetails = JSON.parse(content);
            
            if (!promptDetails.name || !promptDetails.targetObject || !promptDetails.promptCommand) {
                return null;
            }
            
            return promptDetails;
            
        } catch (error) {
            return null;
        }
    }
    
    navigateToPromptRecord(promptId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: promptId,
                objectApiName: 'AI_Prompt__c',
                actionName: 'view'
            }
        });
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: variant === 'error' ? 'sticky' : 'dismissable'
        });
        this.dispatchEvent(event);
    }
}