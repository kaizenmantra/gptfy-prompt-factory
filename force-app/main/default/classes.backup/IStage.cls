/**
 * @description Interface for pipeline stage execution
 * All stage implementations must implement this interface
 */
public interface IStage {
    /**
     * @description Executes a pipeline stage
     * @param runId ID of the PF_Run__c record
     * @param inputs Map of input data from previous stages
     * @return StageResult containing outputs and execution details
     */
    StageResult execute(Id runId, Map<String, Object> inputs);
}