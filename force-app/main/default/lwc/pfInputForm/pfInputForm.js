import { LightningElement, api } from 'lwc';

/**
 * Input form component for pipeline configuration
 * Collects user inputs and validates before starting pipeline
 */
export default class PfInputForm extends LightningElement {
    @api promptName = '';
    @api rootObject = '';
    @api sampleRecordId = '';
    @api businessContext = '';
    @api outputFormat = '';
    @api aiModelId = '';
    @api aiModelOptions = [];
    @api companyUrl = '';
    @api disabled = false;

    // Picklist options
    rootObjectOptions = [
        { label: 'Account', value: 'Account' },
        { label: 'Opportunity', value: 'Opportunity' },
        { label: 'Case', value: 'Case' },
        { label: 'Lead', value: 'Lead' },
        { label: 'Contact', value: 'Contact' },
        { label: 'Campaign', value: 'Campaign' },
        { label: 'Quote', value: 'Quote' },
        { label: 'Order', value: 'Order' },
        { label: 'Contract', value: 'Contract' },
        { label: 'Asset', value: 'Asset' }
    ];

    outputFormatOptions = [
        { label: 'Dashboard', value: 'Dashboard' },
        { label: 'Report', value: 'Report' },
        { label: 'Narrative Summary', value: 'Narrative' },
        { label: 'Structured List', value: 'List' },
        { label: 'Executive Brief', value: 'Brief' },
        { label: 'Action Items', value: 'Actions' }
    ];

    /**
     * Handle input field changes
     */
    handlePromptNameChange(event) {
        this.dispatchInputChange('promptName', event.target.value);
    }

    handleRootObjectChange(event) {
        this.dispatchInputChange('rootObject', event.detail.value);
    }

    handleSampleRecordIdChange(event) {
        this.dispatchInputChange('sampleRecordId', event.target.value);
    }

    handleBusinessContextChange(event) {
        this.dispatchInputChange('businessContext', event.target.value);
    }

    handleOutputFormatChange(event) {
        this.dispatchInputChange('outputFormat', event.detail.value);
    }

    handleAIModelChange(event) {
        this.dispatchInputChange('aiModelId', event.detail.value);
    }

    handleCompanyUrlChange(event) {
        this.dispatchInputChange('companyUrl', event.target.value);
    }

    /**
     * Dispatch input change event to parent
     */
    dispatchInputChange(field, value) {
        this.dispatchEvent(
            new CustomEvent('inputchange', {
                detail: { field, value }
            })
        );
    }

    /**
     * Handle Start Pipeline button click
     */
    handleStartPipeline() {
        // Validate required fields
        if (!this.validateInputs()) {
            return;
        }

        // Dispatch event to parent
        this.dispatchEvent(new CustomEvent('startpipeline'));
    }

    /**
     * Validate all required inputs
     */
    validateInputs() {
        let isValid = true;
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');

        inputs.forEach(input => {
            if (input.required && !input.value) {
                input.reportValidity();
                isValid = false;
            }
        });

        return isValid;
    }

    /**
     * Check if form is complete and valid
     */
    @api
    get isFormValid() {
        return (
            this.promptName &&
            this.rootObject &&
            this.businessContext &&
            this.outputFormat
        );
    }

    /**
     * Computed property for Start button disabled state
     */
    @api
    get isStartDisabled() {
        return this.disabled || !this.isFormValid;
    }

    /**
     * Get character count for business context
     */
    @api
    get contextCharCount() {
        return this.businessContext ? this.businessContext.length : 0;
    }

    /**
     * Show character count warning if too short
     */
    @api
    get showContextWarning() {
        return this.contextCharCount > 0 && this.contextCharCount < 50;
    }

    /**
     * Helper text for business context
     */
    @api
    get contextHelpText() {
        const minChars = 50;
        const remaining = minChars - this.contextCharCount;

        if (this.showContextWarning) {
            return `Please provide more detail (${remaining} more characters recommended for quality results)`;
        }

        return 'Describe the business use case, target audience, and desired insights. More context leads to better results.';
    }
}