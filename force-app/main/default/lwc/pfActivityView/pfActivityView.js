import { LightningElement, api } from 'lwc';

/**
 * Activity View component - displays stage-specific content
 * Shows quality scorecard on completion, errors on failure
 */
export default class PfActivityView extends LightningElement {
    @api runId = null;
    @api currentStage = 0;
    @api pipelineStatus = 'draft';
    @api qualityScorecard = null;

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
        return this.pipelineStatus === 'running' && this.runId;
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
     * Uses backend fields: visualQuality, dataAccuracy, personaFit, actionability, businessValue
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
            { dimension: 'Visual Quality', score: scorecard.visualQuality || 0, icon: 'utility:layout' },
            { dimension: 'Data Accuracy', score: scorecard.dataAccuracy || 0, icon: 'utility:check' },
            { dimension: 'Persona Fit', score: scorecard.personaFit || 0, icon: 'utility:user' },
            { dimension: 'Actionability', score: scorecard.actionability || 0, icon: 'utility:dynamic_record_choice' },
            { dimension: 'Business Value', score: scorecard.businessValue || 0, icon: 'utility:money' }
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