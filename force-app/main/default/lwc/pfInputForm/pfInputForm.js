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
        const value = event.target.value;
        // Basic validation: check if it looks like valid Salesforce IDs
        if (value) {
            const ids = value.split(',').map(id => id.trim()).filter(id => id.length > 0);
            if (ids.length > 5) {
                event.target.setCustomValidity('Maximum 5 sample records allowed');
            } else if (ids.some(id => id.length < 15)) {
                event.target.setCustomValidity('Each ID must be at least 15 characters');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }
        this.dispatchInputChange('sampleRecordId', value);
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

    /**
     * Helper text for sample record IDs (multi-sample feature)
     */
    @api
    get sampleRecordHelp() {
        return 'Optional: Provide 1-3 record IDs (comma-separated) for richer data pattern analysis. Example: 006ABC123, 006DEF456, 006GHI789';
    }

    /**
     * Get count of sample IDs entered
     */
    @api
    get sampleIdCount() {
        if (!this.sampleRecordId) {
            return 0;
        }
        return this.sampleRecordId.split(',').map(id => id.trim()).filter(id => id.length >= 15).length;
    }
}