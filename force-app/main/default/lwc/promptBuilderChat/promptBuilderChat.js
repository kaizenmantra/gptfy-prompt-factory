import { LightningElement, track } from 'lwc';
import initializeSession from '@salesforce/apex/PromptBuilderController.initializeSession';
import chat from '@salesforce/apex/PromptBuilderController.chat';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Interactive Prompt Builder Component
 * Phase 1: Setup - Object selection, record selection, business context
 * Phase 2: Chat - Interactive conversation with LLM (to be implemented)
 * Phase 3: Deploy - Create DCM and Prompt records (to be implemented)
 */
export default class PromptBuilderChat extends LightningElement {
    // Phase 1: Setup Form Fields
    @track rootObject = '';
    @track recordIdsInput = '';
    @track businessContext = '';

    // Session State
    @track sessionId = null;
    @track sessionData = {};

    // Chat State
    @track messages = [];
    @track chatInput = '';
    @track isChatLoading = false;

    // UI State
    @track isLoading = false;
    @track errorMessage = '';

    // Object Options (Common Salesforce Objects)
    objectOptions = [
        { label: 'Account', value: 'Account' },
        { label: 'Opportunity', value: 'Opportunity' },
        { label: 'Case', value: 'Case' },
        { label: 'Lead', value: 'Lead' },
        { label: 'Contact', value: 'Contact' },
        { label: 'Campaign', value: 'Campaign' },
        { label: 'Quote', value: 'Quote' },
        { label: 'Order', value: 'Order' },
        { label: 'Contract', value: 'Contract' },
        { label: 'Asset', value: 'Asset' },
        { label: 'Product', value: 'Product2' }
    ];

    /**
     * Handle object selection change
     */
    handleObjectChange(event) {
        this.rootObject = event.detail.value;
        this.clearError();
    }

    /**
     * Handle record IDs input change
     */
    handleRecordIdsChange(event) {
        this.recordIdsInput = event.target.value;
        this.clearError();
    }

    /**
     * Handle business context change
     */
    handleBusinessContextChange(event) {
        this.businessContext = event.target.value;
        this.clearError();
    }

    /**
     * Handle Initialize Session button click
     */
    handleInitializeSession() {
        // Validate inputs
        if (!this.validateInputs()) {
            return;
        }

        // Parse record IDs
        const recordIds = this.parseRecordIds();
        if (!recordIds || recordIds.length === 0) {
            this.showError('Please provide at least one valid record ID');
            return;
        }

        if (recordIds.length > 5) {
            this.showError('Maximum 5 record IDs allowed');
            return;
        }

        // Call Apex controller
        this.isLoading = true;
        this.clearError();

        initializeSession({
            rootObject: this.rootObject,
            sampleRecordIds: recordIds,
            businessContext: this.businessContext
        })
            .then(result => {
                if (result.success) {
                    this.sessionId = result.sessionId;
                    this.sessionData = {
                        objectLabel: result.objectInfo.label,
                        fieldCount: result.objectInfo.fieldCount,
                        sampleRecordCount: result.sampleRecordCount
                    };

                    this.showSuccess('Session initialized successfully!');
                    console.log('Session initialized:', result);
                } else {
                    this.showError('Failed to initialize session');
                }
            })
            .catch(error => {
                this.showError(this.getErrorMessage(error));
                console.error('Error initializing session:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Parse comma-separated record IDs and trim whitespace
     */
    parseRecordIds() {
        if (!this.recordIdsInput) {
            return [];
        }

        return this.recordIdsInput
            .split(',')
            .map(id => id.trim())
            .filter(id => id.length > 0 && this.isValidRecordId(id));
    }

    /**
     * Validate Salesforce record ID format (15 or 18 characters)
     */
    isValidRecordId(id) {
        return /^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(id);
    }

    /**
     * Validate all required inputs
     */
    validateInputs() {
        let isValid = true;

        // Get all required inputs
        const inputs = this.template.querySelectorAll('[required]');

        inputs.forEach(input => {
            if (!input.value) {
                if (input.reportValidity) {
                    input.reportValidity();
                }
                isValid = false;
            }
        });

        if (!isValid) {
            this.showError('Please fill in all required fields');
        }

        return isValid;
    }

    /**
     * Check if Initialize button should be disabled
     */
    get isInitializeDisabled() {
        return (
            this.isLoading ||
            !this.rootObject ||
            !this.recordIdsInput ||
            !this.businessContext
        );
    }

    /**
     * Show error message
     */
    showError(message) {
        this.errorMessage = message;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }

    /**
     * Clear error message
     */
    clearError() {
        this.errorMessage = '';
    }

    /**
     * Show success message
     */
    showSuccess(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            })
        );
    }

    /**
     * Extract error message from Apex error
     */
    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        } else if (error.message) {
            return error.message;
        }
        return 'An unknown error occurred';
    }

    /**
     * Phase 2: Chat Methods
     */

    /**
     * Check if there are any messages
     */
    get hasMessages() {
        return this.messages && this.messages.length > 0;
    }

    /**
     * Check if send button should be disabled
     */
    get isSendDisabled() {
        return this.isChatLoading || !this.chatInput || this.chatInput.trim().length === 0;
    }

    /**
     * Handle chat input change
     */
    handleChatInputChange(event) {
        this.chatInput = event.target.value;
    }

    /**
     * Handle Start Analysis button click
     */
    handleStartChat() {
        this.sendChatMessage('START');
    }

    /**
     * Handle Send button click
     */
    handleSendMessage() {
        if (this.chatInput && this.chatInput.trim().length > 0) {
            this.sendChatMessage(this.chatInput);
            this.chatInput = '';
        }
    }

    /**
     * Send message to AI
     */
    sendChatMessage(userMessage) {
        this.isChatLoading = true;
        this.clearError();

        // Add user message to conversation (except for START)
        if (userMessage !== 'START') {
            this.addMessage('user', userMessage);
        }

        // Call chat method
        chat({
            sessionId: this.sessionId,
            userMessage: userMessage
        })
            .then(result => {
                if (result.success) {
                    // Add AI response to conversation
                    this.addMessage('assistant', result.message);
                    console.log('Chat response received:', result);
                } else {
                    this.showError('Failed to get response from AI');
                }
            })
            .catch(error => {
                this.showError(this.getErrorMessage(error));
                console.error('Error in chat:', error);
            })
            .finally(() => {
                this.isChatLoading = false;
            });
    }

    /**
     * Add message to conversation
     */
    addMessage(sender, content) {
        const message = {
            id: Date.now() + '-' + sender,
            sender: sender === 'user' ? 'You' : 'AI Assistant',
            content: this.formatMessageContent(content),
            icon: sender === 'user' ? 'utility:user' : 'utility:bot',
            cssClass: sender === 'user' ? 'message user-message' : 'message ai-message'
        };

        this.messages = [...this.messages, message];
    }

    /**
     * Format message content for display
     * Converts markdown to HTML for rich text display
     */
    formatMessageContent(content) {
        if (!content) return '';

        // Convert markdown to HTML (basic conversion)
        let formatted = content;

        // Headers
        formatted = formatted.replace(/### (.*)/g, '<h3>$1</h3>');
        formatted = formatted.replace(/## (.*)/g, '<h2>$1</h2>');
        formatted = formatted.replace(/# (.*)/g, '<h1>$1</h1>');

        // Bold
        formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');

        // Lists
        formatted = formatted.replace(/^- (.*)/gm, '<li>$1</li>');
        formatted = formatted.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');

        // Line breaks
        formatted = formatted.replace(/\n/g, '<br/>');

        return formatted;
    }
}
