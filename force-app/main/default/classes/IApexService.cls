public interface IApexService {
    /**
     * Executes the service logic.
     * @param inputs A map of inputs provided by the Prompt Factory pipeline (e.g., fieldMetadata, selectedFields).
     * @return A string result to be injected into the prompt context.
     */
    String execute(Map<String, Object> inputs);
}
