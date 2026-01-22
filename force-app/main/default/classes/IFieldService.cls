/**
 * @description Interface for field service implementations
 * Allows Builder Prompts to invoke Apex services at runtime
 */
public interface IFieldService {
    /**
     * @description Execute the field service with provided data
     * @param data Map of input parameters (fieldName, objectName, currentValue, etc.)
     * @return String content to inject into prompt
     */
    String execute(Map<String, Object> data);
}
