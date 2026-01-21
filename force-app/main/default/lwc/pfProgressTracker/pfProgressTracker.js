import { LightningElement, api } from 'lwc';

/**
 * Progress Tracker component showing 12 pipeline stages
 * Organized into 4 phases: DISCOVER, MAP, CREATE, DEPLOY & TEST
 * Uses verb + context naming for clarity
 */
export default class PfProgressTracker extends LightningElement {
    @api stageStatuses = [];
    @api currentStage = 0;

    // Phase definitions with colors
    phases = {
        discover: { label: 'DISCOVER', colorClass: 'phase-violet' },
        map: { label: 'MAP', colorClass: 'phase-blue' },
        create: { label: 'CREATE', colorClass: 'phase-green' },
        deploy: { label: 'DEPLOY & TEST', colorClass: 'phase-amber' }
    };

    // Stage definitions with verb + context naming
    // Icons use standard SLDS utility icons
    stages = [
        // Row 1: DISCOVER + MAP phases (0-5)
        {
            index: 0,
            name: 'Fetch Sample',
            phase: 'discover',
            icon: 'utility:search',
            hoverText: 'Loads your sample record from Salesforce along with any web research on the company'
        },
        {
            index: 1,
            name: 'Profile Business',
            phase: 'discover',
            icon: 'utility:target',
            hoverText: 'AI analyzes the record to understand industry, persona, and business objectives'
        },
        {
            index: 2,
            name: 'Discover Schema',
            phase: 'map',
            icon: 'utility:merge',
            hoverText: 'Finds all child relationships and selects 8-10 most relevant objects'
        },
        {
            index: 3,
            name: 'Assess Data',
            phase: 'map',
            icon: 'utility:chart',
            hoverText: 'Checks which objects actually contain data for this record'
        },
        {
            index: 4,
            name: 'Select Fields',
            phase: 'map',
            icon: 'utility:table',
            hoverText: 'AI picks the 10-15 most relevant fields from each object'
        },
        {
            index: 5,
            name: 'Validate Config',
            phase: 'map',
            icon: 'utility:check',
            hoverText: 'Verifies DCM configuration and relationship mappings are correct'
        },
        // Row 2: CREATE + DEPLOY & TEST phases (6-11)
        {
            index: 6,
            name: 'Design Layout',
            phase: 'create',
            icon: 'utility:palette',
            hoverText: 'AI generates an HTML template with merge fields using SLDS styling'
        },
        {
            index: 7,
            name: 'Assemble Prompt',
            phase: 'create',
            icon: 'utility:builder',
            hoverText: 'Combines role, goals, data context, and template into final prompt'
        },
        {
            index: 8,
            name: 'Deploy Prompt',
            phase: 'deploy',
            icon: 'utility:upload',
            hoverText: 'Creates DCM and Prompt records in Salesforce and activates'
        },
        {
            index: 9,
            name: 'Execute Test',
            phase: 'deploy',
            icon: 'utility:play',
            hoverText: 'Runs the prompt against your sample record via GPTfy API'
        },
        {
            index: 10,
            name: 'Check Safety',
            phase: 'deploy',
            icon: 'utility:shield',
            hoverText: 'Scans output for errors, injection risks, and broken merge fields'
        },
        {
            index: 11,
            name: 'Score Quality',
            phase: 'deploy',
            icon: 'utility:ribbon',
            hoverText: 'AI rates output on visual design, data accuracy, and business value'
        }
    ];

    /**
     * Show instruction text when no stages have started
     */
    get showInstruction() {
        if (!this.stageStatuses || this.stageStatuses.length === 0) {
            return true;
        }
        return this.stageStatuses.every(status => status === 'pending' || !status);
    }

    // Get row 1 stages (0-5)
    get row1Stages() {
        return this.stageItems.slice(0, 6);
    }

    // Get row 2 stages (6-11)
    get row2Stages() {
        return this.stageItems.slice(6, 12);
    }

    // Check if last stage in its row
    isLastInRow(index) {
        return index === 5 || index === 11;
    }

    /**
     * Get stage items with computed properties for rendering
     */
    @api
    get stageItems() {
        return this.stages.map((stage, index) => {
            const status = this.stageStatuses[index] || 'pending';
            const isCurrent = index === this.currentStage;
            const isClickable = status === 'completed';
            const phaseInfo = this.phases[stage.phase];

            return {
                ...stage,
                key: `stage-${index}`,
                status: status,
                isCurrent: isCurrent,
                isCompleted: status === 'completed',
                isRunning: status === 'running',
                isFailed: status === 'failed',
                isWarning: status === 'warning',
                isSkipped: status === 'skipped',
                isPending: status === 'pending',
                isClickable: isClickable,
                isLastInRow: this.isLastInRow(index),
                phaseLabel: phaseInfo.label,
                phaseColorClass: phaseInfo.colorClass,
                cardClass: this.getCardClass(status, isCurrent, isClickable),
                iconContainerClass: this.getIconContainerClass(stage.phase),
                statusDotClass: this.getStatusDotClass(status)
            };
        });
    }

    /**
     * Get card CSS class
     */
    getCardClass(status, isCurrent, isClickable) {
        let classes = ['stage-card'];

        if (status !== 'pending') {
            classes.push(`status-${status}`);
        }

        if (isCurrent) {
            classes.push('is-current');
        }

        if (isClickable) {
            classes.push('is-clickable');
        }

        return classes.join(' ');
    }

    /**
     * Get icon container class based on phase
     */
    getIconContainerClass(phase) {
        return `icon-container phase-${phase}-icon`;
    }

    /**
     * Get status dot class
     */
    getStatusDotClass(status) {
        return `status-dot status-${status}`;
    }

    /**
     * Calculate completed stages count
     */
    @api
    get completedCount() {
        if (!this.stageStatuses || this.stageStatuses.length === 0) {
            return 0;
        }
        return this.stageStatuses.filter(status => status === 'completed').length;
    }

    /**
     * Calculate overall progress percentage
     */
    @api
    get progressPercentage() {
        return Math.round((this.completedCount / 12) * 100);
    }

    /**
     * Get progress bar style
     */
    @api
    get progressStyle() {
        return `width: ${this.progressPercentage}%;`;
    }

    /**
     * Handle stage click - only fire event for clickable stages
     */
    handleStageClick(event) {
        const stageIndex = parseInt(event.currentTarget.dataset.index, 10);
        const status = this.stageStatuses[stageIndex];

        if (status === 'completed') {
            this.dispatchEvent(
                new CustomEvent('stageclick', {
                    detail: { stageIndex }
                })
            );
        }
    }
}