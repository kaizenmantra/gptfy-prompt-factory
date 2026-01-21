/**
 * @description AI Prompts Table Component
 * @author      Salesforce Development Team
 * @date        2025-11-10
 */
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPromptsByPurpose from '@salesforce/apex/P_PromptsTableController.getPromptsByPurpose';
import getUniquePurposes from '@salesforce/apex/P_PromptsTableController.getUniquePurposes';

export default class P_PromptsTable extends NavigationMixin(LightningElement) {
    
    // Public property to receive the selected card/purpose name
    @api selectedPurpose = '';
    
    @track prompts = [];
    @track filteredPrompts = [];
    @track purposeTabs = [];
    @track activePurpose = '';
    @track isLoading = false;
    @track allSelected = false;
    @track error;
    
    // ================== WIRE SERVICES ==================
    
    /**
     * @description Wire to get unique purposes for tabs
     */
    @wire(getUniquePurposes)
    wiredPurposes({ error, data }) {
        if (data) {
            this.purposeTabs = data.map((purpose, index) => ({
                label: purpose,
                value: purpose,
                tabClass: this.getTabClass(purpose, index)
            }));
            
            // Set first tab as active by default
            if (this.purposeTabs.length > 0 && !this.activePurpose) {
                this.activePurpose = this.purposeTabs[0].value;
            }
            
            // If selectedPurpose is provided, use it
            if (this.selectedPurpose) {
                this.activePurpose = this.selectedPurpose;
            }
            
            this.loadPrompts();
        } else if (error) {
            this.handleError(error);
        }
    }
    
    // ================== LIFECYCLE HOOKS ==================
    
    connectedCallback() {
        if (this.selectedPurpose) {
            this.activePurpose = this.selectedPurpose;
        }
    }
    
    // ================== GETTERS ==================
    
    /**
     * @description Check if prompts exist
     */
    get hasPrompts() {
        return !this.isLoading && this.filteredPrompts && this.filteredPrompts.length > 0;
    }
    
    /**
     * @description Check if empty state should show
     */
    get showEmptyState() {
        return !this.isLoading && (!this.filteredPrompts || this.filteredPrompts.length === 0);
    }
    
    // ================== HELPER METHODS ==================
    
    /**
     * @description Get tab CSS class
     */
    getTabClass(purpose, index) {
        const baseClass = 'purpose-tab';
        let additionalClass = '';
        
        // Assign colors based on index or purpose
        if (index === 0 || purpose === this.activePurpose) {
            additionalClass = 'tab-active tab-green';
        } else if (index === 1) {
            additionalClass = 'tab-blue';
        } else if (index === 2) {
            additionalClass = 'tab-gray';
        } else {
            additionalClass = 'tab-gray';
        }
        
        return `${baseClass} ${additionalClass}`;
    }
    
    /**
     * @description Load prompts based on active purpose
     */
    loadPrompts() {
        this.isLoading = true;
        
        getPromptsByPurpose({ cardName: this.activePurpose })
            .then(data => {
                this.prompts = data.map(prompt => ({
                    ...prompt,
                    ConnectionName: prompt.AI_Connection__r ? prompt.AI_Connection__r.Name : '',
                    statusClass: this.getStatusClass(prompt.Status__c),
                    isSelected: false
                }));
                this.filteredPrompts = [...this.prompts];
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
                this.isLoading = false;
            });
    }
    
    /**
     * @description Get status badge class
     */
    getStatusClass(status) {
        const baseClass = 'status-badge';
        if (status === 'Active') {
            return `${baseClass} status-active`;
        } else if (status === 'Draft') {
            return `${baseClass} status-draft`;
        }
        return baseClass;
    }
    
    // ================== EVENT HANDLERS ==================
    
    /**
     * @description Handle tab click
     */
    handleTabClick(event) {
        const purpose = event.currentTarget.dataset.purpose;
        this.activePurpose = purpose;
        
        // Update tab classes
        this.purposeTabs = this.purposeTabs.map(tab => ({
            ...tab,
            tabClass: tab.value === purpose 
                ? 'purpose-tab tab-active tab-green' 
                : tab.tabClass.replace('tab-active', '').replace('tab-green', '')
        }));
        
        this.loadPrompts();
    }
    
    /**
     * @description Handle select all checkbox
     */
    handleSelectAll(event) {
        this.allSelected = event.target.checked;
        this.filteredPrompts = this.filteredPrompts.map(prompt => ({
            ...prompt,
            isSelected: this.allSelected
        }));
    }
    
    /**
     * @description Handle individual row select
     */
    handleRowSelect(event) {
        const promptId = event.target.dataset.id;
        this.filteredPrompts = this.filteredPrompts.map(prompt => {
            if (prompt.Id === promptId) {
                return { ...prompt, isSelected: event.target.checked };
            }
            return prompt;
        });
        
        // Update select all checkbox
        this.allSelected = this.filteredPrompts.every(prompt => prompt.isSelected);
    }
    
    /**
     * @description Handle prompt name click - navigate to detail
     */
    handlePromptClick(event) {
        event.preventDefault();
        const promptId = event.target.dataset.id;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: promptId,
                objectApiName: 'AI_Prompt__c',
                actionName: 'view'
            }
        });
    }
    
    /**
     * @description Handle edit connection button click
     */
    handleEditConnection(event) {
        event.stopPropagation();
        const promptId = event.currentTarget.dataset.id;
        
        // Navigate to edit page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: promptId,
                objectApiName: 'AI_Prompt__c',
                actionName: 'edit'
            }
        });
    }
    
    // ================== ERROR HANDLING ==================
    
    /**
     * @description Handle errors
     */
    handleError(error) {
        let message = 'An unexpected error occurred';
        
        if (error && error.body) {
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        } else if (typeof error === 'string') {
            message = error;
        }
        
        this.error = message;
        this.showToast('Error', message, 'error');
    }
    
    /**
     * @description Show toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}