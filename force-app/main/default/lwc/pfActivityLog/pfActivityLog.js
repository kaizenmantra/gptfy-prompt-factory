import { LightningElement, api, track } from 'lwc';
import getActivityLogs from '@salesforce/apex/PromptFactoryController.getActivityLogs';

/**
 * Activity Log component - Terminal-style log viewer
 * Shows pipeline activity in a clean, command-line format
 * V2.6: Auto-loads historical logs when viewing completed runs (imperative call)
 */
export default class PfActivityLog extends LightningElement {
    @api logs = [];
    @track historicalLogs = [];
    _runId = null;
    _hasLoadedHistory = false;

    @api
    get runId() {
        return this._runId;
    }
    set runId(value) {
        const oldValue = this._runId;
        this._runId = value;

        // Only load historical logs if runId changed and no live logs are being passed
        if (value && value !== oldValue && (!this.logs || this.logs.length === 0)) {
            this._hasLoadedHistory = false;
            this.loadHistoricalLogs();
        }
    }

    /**
     * Imperatively load historical logs
     * Only called when viewing a completed run (no live logs passed)
     */
    async loadHistoricalLogs() {
        if (this._hasLoadedHistory || !this._runId) {
            return;
        }

        try {
            const data = await getActivityLogs({ runId: this._runId, lastCount: 100 });
            if (data && data.length > 0) {
                this.historicalLogs = data.map(log => ({
                    timestamp: log.timestamp,
                    stage: log.stageNumber ? `Stage ${Math.floor(log.stageNumber)}` : 'Pipeline',
                    level: log.logLevel || 'INFO',
                    message: log.logMessage || ''
                }));
            }
            this._hasLoadedHistory = true;
        } catch (error) {
            console.warn('Could not load historical logs:', error);
            this.historicalLogs = [];
        }
    }

    /**
     * Get effective logs - prefer props, fallback to historical
     */
    get effectiveLogs() {
        // If logs were passed as props, use those
        if (this.logs && this.logs.length > 0) {
            return this.logs;
        }
        // Otherwise use historical logs from wire
        return this.historicalLogs;
    }

    /**
     * Process logs for terminal-style display
     * V2.6: Uses effectiveLogs to support both live and historical logs
     */
    get processedLogs() {
        const logs = this.effectiveLogs;
        if (!logs || logs.length === 0) {
            return [];
        }

        return logs.map((log, index) => {
            const level = (log.level || 'INFO').toUpperCase();
            const stage = log.stage || log.stageName || '';
            const timestamp = this.formatTimestamp(log.timestamp);

            // Create prefix like: [10:30:45] Stage 1 ▸
            let prefix = `[${timestamp}]`;
            if (stage) {
                prefix += ` ${stage}`;
            }
            prefix += ' ▸';

            return {
                key: `log-${index}-${Date.now()}`,
                prefix: prefix,
                message: log.message || '',
                lineClass: this.getLineClass(level)
            };
        });
    }

    /**
     * Format timestamp for display
     */
    formatTimestamp(timestamp) {
        if (!timestamp) {
            return new Date().toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });
        }

        try {
            const date = new Date(timestamp);
            return date.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });
        } catch (e) {
            return timestamp;
        }
    }

    /**
     * Get CSS class based on log level
     */
    getLineClass(level) {
        const baseClass = 'terminal-line';
        switch (level) {
            case 'ERROR':
                return `${baseClass} line-error`;
            case 'WARNING':
            case 'WARN':
                return `${baseClass} line-warning`;
            case 'SUCCESS':
                return `${baseClass} line-success`;
            default:
                return baseClass;
        }
    }

    /**
     * Scroll to bottom after logs update
     */
    renderedCallback() {
        const logs = this.effectiveLogs;
        if (logs && logs.length > 0) {
            this.scrollToBottom();
        }
    }

    /**
     * Auto-scroll to bottom of terminal
     */
    scrollToBottom() {
        const terminal = this.template.querySelector('.terminal-output');
        if (terminal) {
            terminal.scrollTop = terminal.scrollHeight;
        }
    }

    // Computed properties
    @api
    get hasLogs() {
        const logs = this.effectiveLogs;
        return logs && logs.length > 0;
    }

    @api
    get logCount() {
        const logs = this.effectiveLogs;
        return logs ? logs.length : 0;
    }
}