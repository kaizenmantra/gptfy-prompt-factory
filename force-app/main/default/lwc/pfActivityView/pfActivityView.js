import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getStateFileInfo from '@salesforce/apex/PromptFactoryController.getStateFileInfo';

/**
 * Activity View component - displays stage-specific content
 * Shows quality scorecard on completion, errors on failure
 * V2.4: Added state file link and run record link (open in new tabs)
 */
export default class PfActivityView extends NavigationMixin(LightningElement) {
    @api runId = null;
    @api currentStage = 0;
    @api pipelineStatus = 'draft';
    @api qualityScorecard = null;
    @api createdPromptId = null;
    @api createdDcmId = null;
    @api targetPromptName = null;

    // State file info
    stateFileExists = false;
    stateFileId = null;
    stateDocumentId = null;

    /**
     * Wire adapter to fetch state file info when runId changes
     */
    @wire(getStateFileInfo, { runId: '$runId' })
    wiredStateFile({ error, data }) {
        if (data) {
            this.stateFileExists = data.exists;
            this.stateFileId = data.fileId;
            this.stateDocumentId = data.documentId;
        } else if (error) {
            console.warn('Could not load state file info:', error);
            this.stateFileExists = false;
        }
    }

    /**
     * Open run record in new tab
     */
    handleViewRun() {
        if (!this.runId) return;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.runId,
                objectApiName: 'PF_Run__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    /**
     * Open state file in new tab
     */
    handleViewStateFile() {
        if (!this.stateDocumentId) return;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.stateDocumentId,
                objectApiName: 'ContentDocument',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    /**
     * Show state file link when file exists and run is active
     */
    get showStateFileLink() {
        return this.stateFileExists && this.runId && this.pipelineStatus !== 'draft';
    }

    /**
     * Check if prompt was created
     */
    get hasCreatedPrompt() {
        return !!this.createdPromptId;
    }

    /**
     * Check if DCM was created
     */
    get hasCreatedDcm() {
        return !!this.createdDcmId;
    }

    /**
     * Open created prompt in new tab
     */
    handleViewPrompt() {
        if (!this.createdPromptId) return;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.createdPromptId,
                objectApiName: 'ccai__AI_Prompt__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    /**
     * Open created DCM in new tab
     */
    handleViewDcm() {
        if (!this.createdDcmId) return;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.createdDcmId,
                objectApiName: 'ccai__AI_Data_Extraction_Mapping__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    // Stage content definitions
    stageInfo = [
        {
            index: 0,
            name: 'Schema Discovery',
            description: 'Retrieving object schema, fields, relationships, and metadata',
            icon: 'custom:custom19'
        },
        {
            index: 1,
            name: 'Sample Data Retrieval',
            description: 'Fetching sample record data for context and validation',
            icon: 'custom:custom85'
        },
        {
            index: 2,
            name: 'Core Context Generation',
            description: 'Building foundational context about the object and use case',
            icon: 'custom:custom14'
        },
        {
            index: 3,
            name: 'Domain Context Enrichment',
            description: 'Adding industry and business domain-specific context',
            icon: 'custom:custom53'
        },
        {
            index: 4,
            name: 'Operational Context',
            description: 'Incorporating operational workflows and business processes',
            icon: 'custom:custom44'
        },
        {
            index: 5,
            name: 'Guardrails Definition',
            description: 'Establishing safety rules, constraints, and validation criteria',
            icon: 'custom:custom88'
        },
        {
            index: 6,
            name: 'Format Specification',
            description: 'Defining output structure, formatting, and presentation rules',
            icon: 'custom:custom90'
        },
        {
            index: 7,
            name: 'Example Generation',
            description: 'Creating few-shot examples to guide AI behavior',
            icon: 'custom:custom92'
        },
        {
            index: 8,
            name: 'Grounding Data',
            description: 'Adding reference data and knowledge sources for accuracy',
            icon: 'custom:custom95'
        },
        {
            index: 9,
            name: 'Prompt Assembly',
            description: 'Combining all components into final prompt template',
            icon: 'custom:custom97'
        },
        {
            index: 10,
            name: 'Validation',
            description: 'Testing prompt with sample data and checking outputs',
            icon: 'custom:custom99'
        },
        {
            index: 11,
            name: 'Quality Assessment',
            description: 'Evaluating prompt quality across 8 dimensions',
            icon: 'custom:custom101'
        }
    ];

    /**
     * Get current stage information
     */
    @api
    get currentStageInfo() {
        return this.stageInfo[this.currentStage] || this.stageInfo[0];
    }

    /**
     * Show welcome message when in draft state
     */
    @api
    get showWelcome() {
        return this.pipelineStatus === 'draft';
    }

    /**
     * Show stage content when running
     */
    @api
    get showStageContent() {
        const status = this.pipelineStatus;
        const isRunning = status === 'running' || status === 'in progress' || status === 'queued';
        return isRunning && this.runId;
    }

    /**
     * Show quality scorecard when completed
     */
    @api
    get showQualityScorecard() {
        return this.pipelineStatus === 'completed' && this.qualityScorecard;
    }

    /**
     * Show error message when failed
     */
    @api
    get showError() {
        return this.pipelineStatus === 'failed';
    }

    /**
     * Show aborted message
     */
    @api
    get showAborted() {
        return this.pipelineStatus === 'aborted';
    }

    /**
     * Parse quality scorecard for display
     * V2.6: All 11 dimensions - evidenceBinding, diagnosticDepth, visualQuality, uiEffectiveness,
     *       dataAccuracy, personaFit, actionability, businessValue, dateAnalysis, forbiddenPhrases, customerReferences
     */
    @api
    get qualityScores() {
        if (!this.qualityScorecard) {
            return [];
        }

        const scorecard = typeof this.qualityScorecard === 'string'
            ? JSON.parse(this.qualityScorecard)
            : this.qualityScorecard;

        return [
            // Core dimensions
            { dimension: 'Evidence Binding', score: scorecard.evidenceBinding || 0, icon: 'utility:link', weight: '15%' },
            { dimension: 'Date Analysis', score: scorecard.dateAnalysis || 0, icon: 'utility:date_input', weight: '15%' },
            { dimension: 'Diagnostic Depth', score: scorecard.diagnosticDepth || 0, icon: 'utility:search', weight: '10%' },
            { dimension: 'Visual Quality', score: scorecard.visualQuality || 0, icon: 'utility:layout', weight: '10%' },
            { dimension: 'Data Accuracy', score: scorecard.dataAccuracy || 0, icon: 'utility:check', weight: '10%' },
            { dimension: 'Forbidden Phrases', score: scorecard.forbiddenPhrases || 0, icon: 'utility:ban', weight: '10%' },
            { dimension: 'Customer References', score: scorecard.customerReferences || 0, icon: 'utility:people', weight: '10%' },
            { dimension: 'UI Effectiveness', score: scorecard.uiEffectiveness || 0, icon: 'utility:desktop', weight: '5%' },
            { dimension: 'Persona Fit', score: scorecard.personaFit || 0, icon: 'utility:user', weight: '5%' },
            { dimension: 'Actionability', score: scorecard.actionability || 0, icon: 'utility:task', weight: '5%' },
            { dimension: 'Business Value', score: scorecard.businessValue || 0, icon: 'utility:money', weight: '5%' }
        ].map((item, index) => ({
            ...item,
            key: `score-${index}`,
            percentage: `width: ${(item.score || 0) * 10}%`, // Convert 0-10 to 0-100% for progress bar style
            variant: this.getScoreVariant(item.score),
            cssClass: this.getScoreClass(item.score)
        }));
    }

    /**
     * Get overall quality score
     * Uses backend's overallScore if available, otherwise calculates from dimensions
     */
    @api
    get overallScore() {
        if (!this.qualityScorecard) {
            return 0;
        }

        const scorecard = typeof this.qualityScorecard === 'string'
            ? JSON.parse(this.qualityScorecard)
            : this.qualityScorecard;

        // Use backend's overall score if available
        if (scorecard.overallScore !== undefined && scorecard.overallScore !== null) {
            return Number(scorecard.overallScore).toFixed(1);
        }

        // Fallback: calculate from dimension scores
        const scores = this.qualityScores;
        if (scores.length === 0) return 0;
        const total = scores.reduce((sum, item) => sum + (item.score || 0), 0);
        return (total / scores.length).toFixed(1);
    }

    /**
     * Get overall score percentage as CSS style for progress bar
     */
    @api
    get overallScorePercentage() {
        return `width: ${this.overallScore * 10}%`;
    }

    /**
     * Get overall score variant
     */
    @api
    get overallScoreVariant() {
        return this.getScoreVariant(parseFloat(this.overallScore));
    }

    /**
     * Get score variant based on value
     */
    getScoreVariant(score) {
        if (score >= 8) return 'success';
        if (score >= 6) return 'warning';
        return 'error';
    }

    /**
     * Get score CSS class
     */
    getScoreClass(score) {
        if (score >= 8) return 'score-excellent';
        if (score >= 6) return 'score-good';
        return 'score-poor';
    }

    /**
     * Format timestamp
     */
    get currentTimestamp() {
        return new Date().toLocaleString();
    }
}