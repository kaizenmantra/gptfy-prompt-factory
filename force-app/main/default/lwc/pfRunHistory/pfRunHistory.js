import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecentRuns from '@salesforce/apex/PromptFactoryController.getRecentRuns';
import { refreshApex } from '@salesforce/apex';

/**
 * Component to display recent pipeline run history
 * Shows a collapsible list of prior runs with status and actions
 */
export default class PfRunHistory extends NavigationMixin(LightningElement) {
    @api recordLimit = 10;

    // Note: Boolean public properties should default to false per LWC rules
    _collapsible = false;
    @api
    get collapsible() {
        return this._collapsible;
    }
    set collapsible(value) {
        this._collapsible = value === true || value === 'true';
    }

    runs = [];
    error = null;
    isCollapsed = false;
    wiredRunsResult;

    @wire(getRecentRuns, { recordLimit: '$recordLimit' })
    wiredRuns(result) {
        this.wiredRunsResult = result;
        const { data, error } = result;

        if (data) {
            this.runs = data.map((run, index) => ({
                ...run,
                key: run.id || index,
                formattedDate: this.formatDate(run.createdDate),
                statusClass: this.getStatusClass(run.status),
                statusIcon: this.getStatusIcon(run.status),
                statusVariant: this.getStatusVariant(run.status),
                qualityDisplay: run.qualityScore ? `${run.qualityScore}/10` : '-',
                stageDisplay: `${run.currentStage || 0}/12`
            }));
            this.error = null;
        } else if (error) {
            this.error = error.body?.message || error.message || 'Error loading runs';
            this.runs = [];
        }
    }

    /**
     * Format date for display
     */
    formatDate(dateString) {
        if (!dateString) return '-';

        const date = new Date(dateString);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins}m ago`;
        if (diffHours < 24) return `${diffHours}h ago`;
        if (diffDays < 7) return `${diffDays}d ago`;

        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    /**
     * Get CSS class for status badge
     */
    getStatusClass(status) {
        const statusLower = (status || '').toLowerCase();
        switch (statusLower) {
            case 'completed':
                return 'status-badge status-completed';
            case 'in progress':
            case 'running':
            case 'queued':
                return 'status-badge status-running';
            case 'failed':
                return 'status-badge status-failed';
            case 'aborted':
                return 'status-badge status-aborted';
            default:
                return 'status-badge status-pending';
        }
    }

    /**
     * Get icon for status
     */
    getStatusIcon(status) {
        const statusLower = (status || '').toLowerCase();
        switch (statusLower) {
            case 'completed':
                return 'utility:success';
            case 'in progress':
            case 'running':
            case 'queued':
                return 'utility:sync';
            case 'failed':
                return 'utility:error';
            case 'aborted':
                return 'utility:ban';
            default:
                return 'utility:record';
        }
    }

    /**
     * Get icon variant for status
     */
    getStatusVariant(status) {
        const statusLower = (status || '').toLowerCase();
        switch (statusLower) {
            case 'completed':
                return 'success';
            case 'failed':
                return 'error';
            case 'aborted':
                return 'warning';
            default:
                return '';
        }
    }

    /**
     * Handle toggle collapse
     */
    handleToggle() {
        if (this.collapsible) {
            this.isCollapsed = !this.isCollapsed;
        }
    }

    /**
     * Handle refresh button click
     */
    handleRefresh() {
        return refreshApex(this.wiredRunsResult);
    }

    /**
     * Navigate to run record
     */
    handleViewRun(event) {
        const runId = event.currentTarget.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: runId,
                objectApiName: 'PF_Run__c',
                actionName: 'view'
            }
        });
    }

    /**
     * Load this run into the wizard
     */
    handleLoadRun(event) {
        event.stopPropagation();
        const runId = event.currentTarget.dataset.id;

        // Dispatch event to parent to load this run
        this.dispatchEvent(new CustomEvent('loadrun', {
            detail: { runId },
            bubbles: true,
            composed: true
        }));
    }

    // Computed properties
    get hasRuns() {
        return this.runs && this.runs.length > 0;
    }

    get hasError() {
        return this.error !== null;
    }

    get containerClass() {
        return this.isCollapsed ? 'history-panel collapsed' : 'history-panel';
    }

    get collapseIconName() {
        return this.isCollapsed ? 'utility:chevronright' : 'utility:chevrondown';
    }

    get collapseLabel() {
        return this.isCollapsed ? 'Expand' : 'Collapse';
    }

    get runCount() {
        return this.runs.length;
    }

    get showContent() {
        return !this.isCollapsed;
    }
}