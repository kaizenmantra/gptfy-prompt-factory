import { LightningElement, track, wire } from 'lwc';
import startPipelineRun from '@salesforce/apex/PromptFactoryController.startPipelineRun';
import getPipelineStatus from '@salesforce/apex/PromptFactoryController.getPipelineStatus';
import abortPipeline from '@salesforce/apex/PromptFactoryController.abortPipeline';
import getAIModelOptions from '@salesforce/apex/PromptFactoryController.getAIModelOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Main container component for the Prompt Factory Pipeline wizard.
 * Manages the 12-stage pipeline execution and orchestrates child components.
 */
export default class PromptFactoryWizard extends LightningElement {
    @track runId = null;
    @track currentStage = 0;
    @track stageStatuses = Array(12).fill('pending');
    @track pipelineStatus = 'draft';
    @track inputData = {
        promptName: '',
        rootObject: '',
        sampleRecordId: '',
        businessContext: '',
        outputFormat: '',
        aiModelId: '',
        companyUrl: ''
    };
    @track logs = [];
    @track isLoading = false;
    @track errorMessage = '';
    @track qualityScorecard = null;
    @track aiModelOptions = [];
    @track activeTab = 'configuration'; // 'configuration' or 'activity'

    pollingInterval = null;
    POLLING_INTERVAL_MS = 2000;

    /**
     * Wire adapter to fetch AI Model options from GPTfy
     */
    @wire(getAIModelOptions)
    wiredAIModels({ error, data }) {
        if (data) {
            this.aiModelOptions = data;
        } else if (error) {
            console.warn('Could not load AI Models:', error);
            this.aiModelOptions = [];
        }
    }

    /**
     * Initialize component on mount
     */
    connectedCallback() {
        // Component initialization
        this.resetWizardState();
    }

    /**
     * Clean up polling on component unmount
     */
    disconnectedCallback() {
        this.stopPolling();
    }

    /**
     * Reset wizard to initial state
     */
    resetWizardState() {
        this.runId = null;
        this.currentStage = 0;
        this.stageStatuses = Array(12).fill('pending');
        this.pipelineStatus = 'draft';
        this.logs = [];
        this.errorMessage = '';
        this.qualityScorecard = null;
        this.activeTab = 'configuration';
    }

    /**
     * Handle input changes from pfInputForm
     * @param {CustomEvent} event - Contains field name and value
     */
    handleInputChange(event) {
        const { field, value } = event.detail;
        this.inputData = { ...this.inputData, [field]: value };
    }

    /**
     * Handle Start Pipeline button click
     * Validates inputs and initiates pipeline run
     */
    async handleStartPipeline(event) {
        this.isLoading = true;
        this.errorMessage = '';

        try {
            // Validate required fields
            if (!this.inputData.promptName || !this.inputData.rootObject ||
                !this.inputData.businessContext || !this.inputData.outputFormat) {
                throw new Error('Please fill in all required fields');
            }

            // Call Apex to start pipeline - returns Id directly
            const runId = await startPipelineRun({
                promptName: this.inputData.promptName,
                rootObject: this.inputData.rootObject,
                sampleRecordId: this.inputData.sampleRecordId || null,
                businessContext: this.inputData.businessContext,
                outputFormat: this.inputData.outputFormat,
                aiModelId: this.inputData.aiModelId || null
            });

            this.runId = runId;
            this.pipelineStatus = 'running';
            this.activeTab = 'activity'; // Auto-switch to activity tab when running

            // Show success toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Pipeline Started',
                    message: `Run ID: ${runId}`,
                    variant: 'success'
                })
            );

            // Start polling for status updates
            this.startPolling();

        } catch (error) {
            this.errorMessage = error.body?.message || error.message || 'Failed to start pipeline';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Starting Pipeline',
                    message: this.errorMessage,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Start polling for pipeline status updates
     */
    startPolling() {
        if (this.pollingInterval) {
            return; // Already polling
        }

        this.pollingInterval = setInterval(() => {
            this.refreshStatus();
        }, this.POLLING_INTERVAL_MS);

        // Immediate first refresh
        this.refreshStatus();
    }

    /**
     * Stop polling for status updates
     */
    stopPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }
    }

    /**
     * Refresh pipeline status from server
     */
    async refreshStatus() {
        if (!this.runId) {
            return;
        }

        try {
            const result = await getPipelineStatus({ runId: this.runId });

            // Update state from server response
            this.currentStage = result.currentStage;
            this.pipelineStatus = result.status?.toLowerCase() || 'pending';
            this.logs = result.logs || [];
            // Use full qualityScorecard from backend, fallback to score-only for backward compatibility
            this.qualityScorecard = result.qualityScorecard || (result.qualityScore ? { overallScore: result.qualityScore } : null);

            // Transform stages array into stageStatuses array for progress tracker
            // The progress tracker expects: Array(12).fill('pending'|'running'|'completed'|'failed')
            const newStageStatuses = Array(12).fill('pending');
            if (result.stages && Array.isArray(result.stages)) {
                result.stages.forEach(stage => {
                    const idx = Math.floor(stage.stageNumber) - 1; // Convert 1-based to 0-based
                    if (idx >= 0 && idx < 12) {
                        // Map stage status to progress tracker status
                        const status = stage.status?.toLowerCase() || 'pending';
                        if (status === 'completed') {
                            newStageStatuses[idx] = 'completed';
                        } else if (status === 'in progress' || status === 'running') {
                            newStageStatuses[idx] = 'running';
                        } else if (status === 'failed') {
                            newStageStatuses[idx] = 'failed';
                        } else if (status === 'warning') {
                            // Warning stages are treated as completed but with warnings
                            newStageStatuses[idx] = 'warning';
                        } else if (status === 'skipped') {
                            newStageStatuses[idx] = 'skipped';
                        }
                    }
                });
            }
            this.stageStatuses = newStageStatuses;

            // Check if pipeline has completed or failed
            const statusLower = result.status?.toLowerCase();
            if (statusLower === 'completed' || statusLower === 'failed' || statusLower === 'aborted') {
                this.stopPolling();

                // Show completion toast
                const variant = statusLower === 'completed' ? 'success' : 'error';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: `Pipeline ${result.status}`,
                        message: this.getCompletionMessage(statusLower),
                        variant: variant
                    })
                );
            }

        } catch (error) {
            console.error('Error refreshing status:', error);
            // Don't show toast on polling errors to avoid spam
            // Just log to console
        }
    }

    /**
     * Get completion message based on status
     * @param {string} status - Pipeline status
     * @returns {string} - User-friendly message
     */
    getCompletionMessage(status) {
        switch (status) {
            case 'completed':
                return 'All stages completed successfully. Check the quality scorecard below.';
            case 'failed':
                return 'Pipeline failed. Check the activity log for details.';
            case 'aborted':
                return 'Pipeline was aborted by user.';
            default:
                return '';
        }
    }

    /**
     * Handle abort pipeline button click
     */
    async handleAbortPipeline() {
        if (!this.runId) {
            return;
        }

        // Confirm with user
        const confirmed = confirm('Are you sure you want to abort this pipeline run?');
        if (!confirmed) {
            return;
        }

        this.isLoading = true;

        try {
            await abortPipeline({ runId: this.runId });

            this.stopPolling();
            this.pipelineStatus = 'aborted';

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Pipeline Aborted',
                    message: 'The pipeline run has been aborted.',
                    variant: 'warning'
                })
            );

            // Final status refresh
            await this.refreshStatus();

        } catch (error) {
            this.errorMessage = error.body?.message || error.message || 'Failed to abort pipeline';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Aborting Pipeline',
                    message: this.errorMessage,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handle stage click from progress tracker
     * @param {CustomEvent} event - Contains clicked stage index
     */
    handleStageClick(event) {
        const stageIndex = event.detail.stageIndex;

        // Only allow navigation to completed stages
        if (this.stageStatuses[stageIndex] === 'completed') {
            this.currentStage = stageIndex;
        }
    }

    /**
     * Handle reset wizard action
     */
    handleResetWizard() {
        // Confirm with user if pipeline is running
        if (this.pipelineStatus === 'running') {
            const confirmed = confirm('This will stop the current run. Are you sure?');
            if (!confirmed) {
                return;
            }
        }

        this.stopPolling();
        this.resetWizardState();

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Wizard Reset',
                message: 'Start a new pipeline run.',
                variant: 'info'
            })
        );
    }

    // Computed properties for template rendering
    get isRunning() {
        return this.pipelineStatus === 'running';
    }

    get isCompleted() {
        return this.pipelineStatus === 'completed';
    }

    get isFailed() {
        return this.pipelineStatus === 'failed';
    }

    get isAborted() {
        return this.pipelineStatus === 'aborted';
    }

    get isDraft() {
        return this.pipelineStatus === 'draft';
    }

    get canAbort() {
        return this.isRunning;
    }

    get canReset() {
        return !this.isDraft;
    }

    get showQualityScorecard() {
        return this.isCompleted && this.qualityScorecard;
    }

    get hasError() {
        return this.errorMessage !== '';
    }

    // Tab management
    get isConfigurationTab() {
        return this.activeTab === 'configuration';
    }

    get isActivityTab() {
        return this.activeTab === 'activity';
    }

    get isHistoryTab() {
        return this.activeTab === 'history';
    }

    get configurationTabClass() {
        return this.activeTab === 'configuration'
            ? 'slds-tabs_default__item slds-is-active'
            : 'slds-tabs_default__item';
    }

    get activityTabClass() {
        return this.activeTab === 'activity'
            ? 'slds-tabs_default__item slds-is-active'
            : 'slds-tabs_default__item';
    }

    get historyTabClass() {
        return this.activeTab === 'history'
            ? 'slds-tabs_default__item slds-is-active'
            : 'slds-tabs_default__item';
    }

    handleTabClick(event) {
        const tabName = event.currentTarget.dataset.tab;
        this.activeTab = tabName;
    }
}