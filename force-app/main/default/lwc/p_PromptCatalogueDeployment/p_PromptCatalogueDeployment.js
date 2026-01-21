/**
 * @description Prompt Catalogue Deployment Component
 * @author      Salesforce Development Team
 * @date        2025-11-12
 */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import updatePromptData from '@salesforce/apex/CatalogController.updatePromptData';
import getPurposeOptions from '@salesforce/apex/CatalogController.getPurposeOptions';
import PMT_OBJECT from '@salesforce/schema/AI_Prompt__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import AiPromptWhereClauseFormulaComponent from 'c/aiPromptWhereClauseFormulaComponent';

export default class P_PromptCatalogueDeployment extends NavigationMixin(LightningElement) {
    
    // ================== PUBLIC PROPERTIES ==================
    
    @api selectedPurpose = '';
    @api selectedPrompts = [];
    
    // ================== STATE MANAGEMENT ==================
    
    @track showSpinner = false;
    @track profileOptions = [];
    @track recTypeOptions = {};
    @track selectedMappings = [];
    @track helpText_VisibilityCondition;
    
    // ================== WIRE SERVICES ==================
    
    /**
     * @description Wire to get AI_Prompt__c object info for help text
     */
    @wire(getObjectInfo, { objectApiName: PMT_OBJECT })
    wiredRecord({ error, data }) {
        if (error) {
            this.handleError(error);
        } else if (data) {
            if (data.fields && data.fields['Visibility_Condition__c'] && data.fields['Visibility_Condition__c'].inlineHelpText) {
                this.helpText_VisibilityCondition = data.fields['Visibility_Condition__c'].inlineHelpText;
            }
        }
    }
    
    // ================== LIFECYCLE HOOKS ==================
    
    connectedCallback() {
        this.loadOptionsAndInitialize();
    }
    
    // ================== DATA LOADING METHODS ==================
    
    /**
     * @description Load profile options and record type options
     */
    async loadOptionsAndInitialize() {
        this.showSpinner = true;
        
        try {
            const result = await getPurposeOptions();
            
            if (result && result.profileOptions && result.profileOptions.length > 0) {
                this.profileOptions = JSON.parse(JSON.stringify(result.profileOptions));
            }
            
            if (result && result.recTypeOptions) {
                this.recTypeOptions = JSON.parse(JSON.stringify(result.recTypeOptions));
            }
            
            // Initialize selected mappings from selected prompts
            this.initializeSelectedMappings();
            
        } catch (error) {
            this.handleError(error);
        } finally {
            this.showSpinner = false;
        }
    }
    
    /**
     * @description Initialize selected mappings with record type options
     */
    initializeSelectedMappings() {
        if (this.selectedPrompts && this.selectedPrompts.length > 0) {
            this.selectedMappings = JSON.parse(JSON.stringify(this.selectedPrompts));
            console.log('selectedMappings', JSON.parse(JSON.stringify(this.selectedPrompts)));
            // Add record type options for each mapping based on object
            for (let rec of this.selectedMappings) {
                const oName = rec['primaryObject'] || rec['objectName'];
                if (this.recTypeOptions && this.recTypeOptions.hasOwnProperty(oName)) {
                    rec['recordTypeOptions'] = this.recTypeOptions[oName];
                }
                
                // Initialize arrays if not present
                if (!rec['profileNames']) {
                    rec['profileNames'] = [];
                }
                if (!rec['recordTypes']) {
                    rec['recordTypes'] = [];
                }
                if (!rec['visibilityCondition']) {
                    rec['visibilityCondition'] = '';
                }
            }
        }
    }
    
    // ================== EVENT HANDLERS ==================
    
    /**
     * @description Handle profile selection change
     * @param {Event} event - Change event from dual listbox
     */
    handleProfileChange(event) {
        const index = event.target.dataset.id;
        this.selectedMappings[index].profileNames = event.target.value;
    }
    
    /**
     * @description Handle record type selection change
     * @param {Event} event - Change event from dual listbox
     */
    handleRecordTypeChange(event) {
        const index = event.target.dataset.id;
        this.selectedMappings[index].recordTypes = event.target.value;
    }
    
    /**
     * @description Handle visibility condition text change
     * @param {Event} event - Change event from textarea
     */
    handleVisibilityConditionChange(event) {
        const index = event.target.dataset.index;
        this.selectedMappings[index].visibilityCondition = event.target.value;
    }
    
    /**
     * @description Open visibility condition modal for formula builder
     * @param {Event} event - Click event from button
     */
    handleOpenVisibilityCondition = async (event) => {
        const index = event.target.dataset.index;
        const objectName = event.target.dataset.objectname;
        
        try {
            const result = await AiPromptWhereClauseFormulaComponent.open({
                size: 'medium',
                description: 'Visibility Condition',
                objectApiName: objectName
            });
            
            if (result) {
                this.selectedMappings[index].visibilityCondition = result;
            }
        } catch (error) {
            console.error('Error opening visibility condition modal:', error);
        }
    }
    
    /**
     * @description Public method to save deployment configuration (called by parent)
     */
    @api
    saveDeploymentConfiguration() {
        // Validate that at least one profile is selected for each prompt
        const missingProfiles = this.selectedMappings.filter(map => 
            !map.profileNames || map.profileNames.length === 0
        );
        
        if (missingProfiles.length > 0) {
            this.showToast('error', 'Validation Error', 'Please select at least one profile for each prompt.');
            return;
        }
        
        this.showSpinner = true;
        
        return updatePromptData({ data: this.selectedMappings })
            .then(result => {
                this.showSpinner = false;
                return { success: true };
            })
            .catch(error => {
                this.showSpinner = false;
                throw error;
            });
    }
    
    // ================== HELPER METHODS ==================
    
    /**
     * @description Show toast notification
     * @param {String} variant - Toast variant (success, error, warning, info)
     * @param {String} title - Toast title
     * @param {String} message - Toast message
     */
    showToast(variant, title, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message
        });
        this.dispatchEvent(event);
    }
    
    /**
     * @description Handle errors
     * @param {Object} error - Error object
     */
    handleError(error) {
        this.showSpinner = false;
        console.error('Error:', JSON.stringify(error));
        
        let errorMessage = 'An unexpected error occurred';
        
        if (error && error.body && error.body.message) {
            errorMessage = error.body.message;
        } else if (typeof error === 'string') {
            errorMessage = error;
        } else if (error && error.message) {
            errorMessage = error.message;
        }
        
        this.showToast('error', 'Error', errorMessage);
    }
}