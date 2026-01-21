/**
 * @description Factory class for creating stage instances
 * Uses Factory pattern to instantiate the appropriate stage implementation based on stage number
 */
public with sharing class StageFactory {

    /**
     * @description Gets an instance of the stage implementation for the given stage number
     * @param stageNumber Stage number (1-12)
     * @return IStage implementation for that stage
     * @throws StageFactoryException if stage number is invalid
     */
    public static IStage getStage(Integer stageNumber) {
        if (stageNumber == null) {
            throw new StageFactoryException('Stage number cannot be null');
        }

        switch on stageNumber {
            when 1 {
                return new Stage01_IntelligenceRetrieval();
            }
            when 2 {
                return new Stage02_StrategicProfiling();
            }
            when 3 {
                return new Stage03_SchemaDiscovery();
            }
            when 4 {
                return new Stage04_DataProfiling();
            }
            when 5 {
                return new Stage05_FieldSelection();
            }
            when 6 {
                return new Stage06_ConfigurationValidation();
            }
            when 7 {
                return new Stage07_TemplateDesign();
            }
            when 8 {
                return new Stage08_PromptAssembly();
            }
            when 9 {
                return new Stage09_CreateAndDeploy();
            }
            when 10 {
                return new Stage10_TestExecution();
            }
            when 11 {
                return new Stage11_SafetyValidation();
            }
            when 12 {
                return new Stage12_QualityAudit();
            }
            when else {
                throw new StageFactoryException('Invalid stage number: ' + stageNumber +
                    '. Must be between 1 and 12.');
            }
        }
    }

    /**
     * @description Gets stage metadata including name and description
     * @param stageNumber Stage number (1-12)
     * @return StageMetadata with details about the stage
     */
    public static StageMetadata getStageMetadata(Integer stageNumber) {
        switch on stageNumber {
            when 1 {
                return new StageMetadata(1, 'Requirement Understanding',
                    'Parse user input and extract structured requirements');
            }
            when 2 {
                return new StageMetadata(2, 'Schema Discovery',
                    'Identify relevant Salesforce objects and relationships');
            }
            when 3 {
                return new StageMetadata(3, 'Field Selection',
                    'Select optimal fields for DCM mapping');
            }
            when 4 {
                return new StageMetadata(4, 'DCM Blueprint Generation',
                    'Create Data Context Mapping configuration');
            }
            when 5 {
                return new StageMetadata(5, 'DCM Creation',
                    'Build DCM records in Salesforce');
            }
            when 6 {
                return new StageMetadata(6, 'Prompt Command Generation',
                    'Generate AI prompt command with instructions');
            }
            when 7 {
                return new StageMetadata(7, 'HTML Template Generation',
                    'Create output template with merge fields');
            }
            when 8 {
                return new StageMetadata(8, 'Grounding Rules Generation',
                    'Generate grounding rules for AI behavior');
            }
            when 9 {
                return new StageMetadata(9, 'AI Prompt Creation',
                    'Create ccai__AI_Prompt__c record');
            }
            when 10 {
                return new StageMetadata(10, 'Validation & Testing',
                    'Validate prompt configuration and test execution');
            }
            when 11 {
                return new StageMetadata(11, 'Quality Scoring',
                    'Score prompt quality across dimensions');
            }
            when 12 {
                return new StageMetadata(12, 'Activation & Finalization',
                    'Activate prompt and finalize deployment');
            }
            when else {
                return null;
            }
        }
    }

    /**
     * @description Gets all stage metadata for the pipeline
     * @return List of StageMetadata for all 12 stages
     */
    public static List<StageMetadata> getAllStageMetadata() {
        List<StageMetadata> allStages = new List<StageMetadata>();
        for (Integer i = 1; i <= 12; i++) {
            allStages.add(getStageMetadata(i));
        }
        return allStages;
    }

    /**
     * @description Checks if a stage number is valid
     * @param stageNumber Stage number to check
     * @return true if stage number is between 1 and 12
     */
    public static Boolean isValidStageNumber(Integer stageNumber) {
        return stageNumber != null && stageNumber >= 1 && stageNumber <= 12;
    }

    /**
     * @description Gets the next stage number in the pipeline
     * @param currentStageNumber Current stage number
     * @return Next stage number, or null if at the end
     */
    public static Integer getNextStageNumber(Integer currentStageNumber) {
        if (currentStageNumber == null || currentStageNumber >= 12) {
            return null;
        }
        return currentStageNumber + 1;
    }

    /**
     * @description Gets the previous stage number in the pipeline
     * @param currentStageNumber Current stage number
     * @return Previous stage number, or null if at the beginning
     */
    public static Integer getPreviousStageNumber(Integer currentStageNumber) {
        if (currentStageNumber == null || currentStageNumber <= 1) {
            return null;
        }
        return currentStageNumber - 1;
    }

    /**
     * @description Inner class representing stage metadata
     */
    public class StageMetadata {
        @AuraEnabled public Integer stageNumber { get; set; }
        @AuraEnabled public String stageName { get; set; }
        @AuraEnabled public String description { get; set; }

        public StageMetadata(Integer stageNumber, String stageName, String description) {
            this.stageNumber = stageNumber;
            this.stageName = stageName;
            this.description = description;
        }
    }

    /**
     * @description Custom exception for stage factory errors
     */
    public class StageFactoryException extends Exception {}
}