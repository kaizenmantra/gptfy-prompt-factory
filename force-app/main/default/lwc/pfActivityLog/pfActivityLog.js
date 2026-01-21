import { LightningElement, api } from 'lwc';

/**
 * Activity Log component - Terminal-style log viewer
 * Shows pipeline activity in a clean, command-line format
 */
export default class PfActivityLog extends LightningElement {
    @api runId = null;
    @api logs = [];

    /**
     * Process logs for terminal-style display
     */
    get processedLogs() {
        if (!this.logs || this.logs.length === 0) {
            return [];
        }

        return this.logs.map((log, index) => {
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
        if (this.logs && this.logs.length > 0) {
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
        return this.logs && this.logs.length > 0;
    }

    @api
    get logCount() {
        return this.logs ? this.logs.length : 0;
    }
}