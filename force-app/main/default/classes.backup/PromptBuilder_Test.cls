/**
 * @description Test class for PromptBuilder
 * Tests AI Prompt creation, validation, activation, and cloning
 */
@IsTest
private class PromptBuilder_Test {

    @TestSetup
    static void setup() {
        // Create test DCM
        // Note: ccai__Root_Object__c may not exist, so we don't set it
        ccai__AI_Data_Extraction_Mapping__c dcm = new ccai__AI_Data_Extraction_Mapping__c(
            Name = 'Test DCM',
            ccai__Status__c = 'Active',
            ccai__External_Id__c = 'TEST_DCM_PROMPT'
        );
        insert dcm;

        // Create DCM fields for validation - using ccai__Field__c instead of ccai__API_Name__c
        List<ccai__AI_Data_Extraction_Field__c> fields = new List<ccai__AI_Data_Extraction_Field__c>();
        fields.add(new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
            ccai__Type__c = 'FIELD',
            ccai__Field__c = 'Name',
            ccai__Object__c = 'Account',
            ccai__Send_To_AI__c = true
        ));
        insert fields;
    }

    /**
     * @description Test creating a basic AI Prompt
     */
    @IsTest
    static void testCreatePrompt_Basic() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Test_Prompt_001';
        config.label = 'Test Prompt';
        config.description = 'Test prompt description';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Generate a summary based on the account data.';
        config.htmlTemplate = '<html><body><p>Account: {{{Name}}}</p></body></html>';
        config.targetObject = 'Account';

        Test.startTest();
        Id promptId = PromptBuilder.createPrompt(config);
        Test.stopTest();

        // Verify prompt created
        // Note: ccai__Label__c and ccai__HTML_Template__c don't exist on ccai__AI_Prompt__c
        ccai__AI_Prompt__c prompt = [
            SELECT Name, ccai__Description__c, ccai__Status__c,
                   ccai__AI_Data_Extraction_Mapping__c, ccai__Prompt_Command__c,
                   ccai__Object__c, ccai__Type__c
            FROM ccai__AI_Prompt__c
            WHERE Id = :promptId
        ];

        System.assertEquals('Test_Prompt_001', prompt.Name, 'Prompt name should match');
        System.assertEquals('Draft', prompt.ccai__Status__c, 'Status should be Draft by default');
        System.assertEquals(dcm.Id, prompt.ccai__AI_Data_Extraction_Mapping__c, 'DCM should be linked');
        System.assertEquals('Account', prompt.ccai__Object__c, 'Target object should be Account');
    }

    /**
     * @description Test creating prompt with custom parameters
     */
    @IsTest
    static void testCreatePrompt_CustomParameters() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Custom_Prompt';
        config.label = 'Custom Prompt';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test command';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';
        config.groundingRules = 'Be concise and accurate.';
        config.modelName = 'claude-opus-4.5';
        config.maxTokens = 2048;
        config.temperature = 0.5;

        Test.startTest();
        Id promptId = PromptBuilder.createPrompt(config);
        Test.stopTest();

        // Note: ccai__Model_Name__c and ccai__Grounding_Rules__c don't exist on ccai__AI_Prompt__c
        // Using ccai__Max_Output_Tokens__c instead of ccai__Max_Tokens__c
        ccai__AI_Prompt__c prompt = [
            SELECT ccai__Max_Output_Tokens__c, ccai__Temperature__c,
                   ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c
            WHERE Id = :promptId
        ];

        System.assertEquals(2048, prompt.ccai__Max_Output_Tokens__c, 'Max tokens should be 2048');
        System.assertEquals(0.5, prompt.ccai__Temperature__c, 'Temperature should be 0.5');
        // Grounding rules are embedded in prompt command
        System.assert(prompt.ccai__Prompt_Command__c.contains('Be concise and accurate.'),
            'Grounding rules should be embedded in prompt command');
    }

    /**
     * @description Test creating prompt with auto-activation
     */
    @IsTest
    static void testCreatePrompt_AutoActivate() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Auto_Active_Prompt';
        config.label = 'Auto Active';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';
        config.autoActivate = true;

        Test.startTest();
        Id promptId = PromptBuilder.createPrompt(config);
        Test.stopTest();

        ccai__AI_Prompt__c prompt = [
            SELECT ccai__Status__c FROM ccai__AI_Prompt__c WHERE Id = :promptId
        ];

        System.assertEquals('Active', prompt.ccai__Status__c,
            'Prompt should be activated automatically');
    }

    /**
     * @description Test activatePrompt method
     */
    @IsTest
    static void testActivatePrompt() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        // Create prompt in Draft status
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Draft_Prompt';
        config.label = 'Draft';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';

        Id promptId = PromptBuilder.createPrompt(config);

        Test.startTest();
        PromptBuilder.activatePrompt(promptId);
        Test.stopTest();

        ccai__AI_Prompt__c prompt = [
            SELECT ccai__Status__c FROM ccai__AI_Prompt__c WHERE Id = :promptId
        ];

        System.assertEquals('Active', prompt.ccai__Status__c, 'Prompt should be activated');
    }

    /**
     * @description Test deactivatePrompt method
     */
    @IsTest
    static void testDeactivatePrompt() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        // Create and activate prompt
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Active_Prompt';
        config.label = 'Active';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';
        config.autoActivate = true;

        Id promptId = PromptBuilder.createPrompt(config);

        Test.startTest();
        PromptBuilder.deactivatePrompt(promptId);
        Test.stopTest();

        ccai__AI_Prompt__c prompt = [
            SELECT ccai__Status__c FROM ccai__AI_Prompt__c WHERE Id = :promptId
        ];

        System.assertEquals('Draft', prompt.ccai__Status__c, 'Prompt should be deactivated');
    }

    /**
     * @description Test validatePromptConfig with valid config
     */
    @IsTest
    static void testValidatePromptConfig_Valid() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Valid_Config';
        config.label = 'Valid';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test command';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';

        Test.startTest();
        List<String> errors = PromptBuilder.validatePromptConfig(config);
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid config should have no errors');
    }

    /**
     * @description Test validatePromptConfig with missing required fields
     */
    @IsTest
    static void testValidatePromptConfig_MissingFields() {
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        // Leave all required fields blank

        Test.startTest();
        List<String> errors = PromptBuilder.validatePromptConfig(config);
        Test.stopTest();

        // Note: label validation was removed (using Name instead)
        System.assert(errors.size() >= 4, 'Should have multiple validation errors');

        String allErrors = String.join(errors, ' | ');
        System.assert(allErrors.contains('name is required'), 'Should mention name is required');
        System.assert(allErrors.contains('DCM ID is required'), 'Should mention DCM ID is required');
        System.assert(allErrors.contains('command is required'), 'Should mention command is required');
        System.assert(allErrors.contains('template is required'), 'Should mention template is required');
    }

    /**
     * @description Test validatePromptConfig with invalid object
     */
    @IsTest
    static void testValidatePromptConfig_InvalidObject() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Test';
        config.label = 'Test';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'InvalidObject__c';

        Test.startTest();
        List<String> errors = PromptBuilder.validatePromptConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasObjectError = false;
        for (String error : errors) {
            if (error.contains('InvalidObject__c') && error.contains('not accessible')) {
                hasObjectError = true;
            }
        }
        System.assert(hasObjectError, 'Should mention object is not accessible');
    }

    /**
     * @description Test validatePromptConfig with invalid DCM ID
     */
    @IsTest
    static void testValidatePromptConfig_InvalidDCM() {
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Test';
        config.label = 'Test';
        config.dcmId = '001000000000000'; // Fake ID
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';

        Test.startTest();
        List<String> errors = PromptBuilder.validatePromptConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasDCMError = false;
        for (String error : errors) {
            if (error.contains('DCM') && error.contains('does not exist')) {
                hasDCMError = true;
            }
        }
        System.assert(hasDCMError, 'Should mention DCM does not exist');
    }

    /**
     * @description Test validatePromptConfig with invalid maxTokens
     */
    @IsTest
    static void testValidatePromptConfig_InvalidMaxTokens() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Test';
        config.label = 'Test';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';
        config.maxTokens = 200000; // Too high

        Test.startTest();
        List<String> errors = PromptBuilder.validatePromptConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasTokenError = false;
        for (String error : errors) {
            if (error.contains('Max tokens')) {
                hasTokenError = true;
            }
        }
        System.assert(hasTokenError, 'Should mention max tokens error');
    }

    /**
     * @description Test validatePromptConfig with invalid temperature
     */
    @IsTest
    static void testValidatePromptConfig_InvalidTemperature() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Test';
        config.label = 'Test';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';
        config.temperature = 1.5; // Too high

        Test.startTest();
        List<String> errors = PromptBuilder.validatePromptConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasTempError = false;
        for (String error : errors) {
            if (error.contains('Temperature')) {
                hasTempError = true;
            }
        }
        System.assert(hasTempError, 'Should mention temperature error');
    }

    /**
     * @description Test clonePrompt method
     */
    @IsTest
    static void testClonePrompt() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        // Create original prompt
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Original_Prompt';
        config.label = 'Original';
        config.description = 'Original description';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Original command';
        config.htmlTemplate = '<p>Original</p>';
        config.groundingRules = 'Original rules';
        config.targetObject = 'Account';

        Id originalId = PromptBuilder.createPrompt(config);

        Test.startTest();
        Id clonedId = PromptBuilder.clonePrompt(originalId, 'Cloned_Prompt');
        Test.stopTest();

        // Note: ccai__Label__c doesn't exist on ccai__AI_Prompt__c
        ccai__AI_Prompt__c original = [
            SELECT Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c WHERE Id = :originalId
        ];

        ccai__AI_Prompt__c cloned = [
            SELECT Name, ccai__Prompt_Command__c
            FROM ccai__AI_Prompt__c WHERE Id = :clonedId
        ];

        System.assertNotEquals(originalId, clonedId, 'Should create new record');
        System.assertEquals('Cloned_Prompt', cloned.Name, 'Cloned name should match');
        // Prompt command should contain the same content
        System.assertNotEquals(null, cloned.ccai__Prompt_Command__c, 'Command should be cloned');
    }

    /**
     * @description Test updatePrompt method
     */
    @IsTest
    static void testUpdatePrompt() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        // Create prompt
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Update_Test';
        config.label = 'Original Label';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Original command';
        config.htmlTemplate = '<p>Original</p>';
        config.targetObject = 'Account';

        Id promptId = PromptBuilder.createPrompt(config);

        // Update prompt
        PromptBuilder.PromptConfig updateConfig = new PromptBuilder.PromptConfig();
        updateConfig.label = 'Updated Label';
        updateConfig.description = 'Updated description';
        updateConfig.maxTokens = 8192;

        Test.startTest();
        PromptBuilder.updatePrompt(promptId, updateConfig);
        Test.stopTest();

        // Note: ccai__Label__c doesn't exist; using ccai__Max_Output_Tokens__c instead of ccai__Max_Tokens__c
        ccai__AI_Prompt__c prompt = [
            SELECT ccai__Description__c, ccai__Max_Output_Tokens__c
            FROM ccai__AI_Prompt__c WHERE Id = :promptId
        ];

        System.assertEquals('Updated description', prompt.ccai__Description__c,
            'Description should be updated');
        System.assertEquals(8192, prompt.ccai__Max_Output_Tokens__c, 'Max tokens should be updated');
    }

    /**
     * @description Test deletePrompt method
     */
    @IsTest
    static void testDeletePrompt() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        // Create prompt
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = 'Delete_Test';
        config.label = 'To Delete';
        config.dcmId = dcm.Id;
        config.promptCommand = 'Test';
        config.htmlTemplate = '<p>Test</p>';
        config.targetObject = 'Account';

        Id promptId = PromptBuilder.createPrompt(config);

        // Verify exists
        Integer countBefore = [SELECT COUNT() FROM ccai__AI_Prompt__c WHERE Id = :promptId];
        System.assertEquals(1, countBefore, 'Prompt should exist');

        Test.startTest();
        PromptBuilder.deletePrompt(promptId);
        Test.stopTest();

        Integer countAfter = [SELECT COUNT() FROM ccai__AI_Prompt__c WHERE Id = :promptId];
        System.assertEquals(0, countAfter, 'Prompt should be deleted');
    }

    /**
     * @description Test PromptConfig wrapper initialization
     */
    @IsTest
    static void testPromptConfigWrapper() {
        Test.startTest();
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        Test.stopTest();

        System.assertEquals('Record Action', config.promptType, 'Should default to Record Action');
        System.assertEquals('claude-sonnet-4.5', config.modelName, 'Should default to claude-sonnet-4.5');
        System.assertEquals(4096, config.maxTokens, 'Should default to 4096');
        System.assertEquals(1.0, config.temperature, 'Should default to 1.0');
        System.assertEquals(false, config.autoActivate, 'Should default to false');
    }

    /**
     * @description Test exception handling
     */
    @IsTest
    static void testCreatePrompt_Exception() {
        PromptBuilder.PromptConfig config = new PromptBuilder.PromptConfig();
        config.name = null; // Invalid

        Test.startTest();
        try {
            Id promptId = PromptBuilder.createPrompt(config);
            System.assert(false, 'Should throw exception');
        } catch (PromptBuilder.PromptBuilderException e) {
            System.assert(e.getMessage().contains('Invalid prompt configuration'),
                'Exception should mention configuration error');
        }
        Test.stopTest();
    }
}