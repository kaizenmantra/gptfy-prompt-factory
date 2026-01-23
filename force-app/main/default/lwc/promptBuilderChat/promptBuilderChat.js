import { LightningElement, track } from 'lwc';
import initializeSession from '@salesforce/apex/PromptBuilderController.initializeSession';
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
}
