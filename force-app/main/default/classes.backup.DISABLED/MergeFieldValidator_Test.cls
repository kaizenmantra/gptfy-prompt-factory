/**
 * @description Test class for MergeFieldValidator
 * Tests merge field extraction, validation, and DCM integration
 */
@IsTest
private class MergeFieldValidator_Test {

    @TestSetup
    static void setup() {
        // Create test DCM
        // Note: ccai__Root_Object__c may not exist, so we don't set it
        ccai__AI_Data_Extraction_Mapping__c dcm = new ccai__AI_Data_Extraction_Mapping__c(
            Name = 'Test DCM',
            ccai__Status__c = 'Active',
            ccai__External_Id__c = 'TEST_DCM_001'
        );
        insert dcm;

        // Create DCM fields - using ccai__Field__c and ccai__Object__c instead of ccai__API_Name__c
        List<ccai__AI_Data_Extraction_Field__c> fields = new List<ccai__AI_Data_Extraction_Field__c>();

        // Root object (for OBJECT type, use ccai__Object__c to store the object name)
        fields.add(new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
            ccai__Type__c = 'OBJECT',
            ccai__Object__c = 'Account',
            ccai__Send_To_AI__c = true
        ));

        // Root object fields (use ccai__Field__c for field API name)
        fields.add(new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
            ccai__Type__c = 'FIELD',
            ccai__Field__c = 'Name',
            ccai__Object__c = 'Account',
            ccai__Send_To_AI__c = true
        ));

        fields.add(new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
            ccai__Type__c = 'FIELD',
            ccai__Field__c = 'Industry',
            ccai__Object__c = 'Account',
            ccai__Send_To_AI__c = true
        ));

        // Child object
        fields.add(new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
            ccai__Type__c = 'OBJECT',
            ccai__Object__c = 'Contact',
            ccai__Send_To_AI__c = true
        ));

        // Child object fields
        fields.add(new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
            ccai__Type__c = 'FIELD',
            ccai__Field__c = 'FirstName',
            ccai__Object__c = 'Contact',
            ccai__Send_To_AI__c = true
        ));

        fields.add(new ccai__AI_Data_Extraction_Field__c(
            ccai__AI_Data_Extraction_Mapping__c = dcm.Id,
            ccai__Type__c = 'FIELD',
            ccai__Field__c = 'LastName',
            ccai__Object__c = 'Contact',
            ccai__Send_To_AI__c = true
        ));

        insert fields;
    }

    /**
     * @description Test extracting merge fields from simple template
     */
    @IsTest
    static void testExtractMergeFields_Simple() {
        String template = 'Account Name: {{{Name}}}, Industry: {{{Industry}}}';

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.extractMergeFields(template);
        Test.stopTest();

        System.assertEquals(2, fields.size(), 'Should extract 2 merge fields');
        System.assertEquals('Name', fields[0].fieldName, 'First field should be Name');
        System.assertEquals('Industry', fields[1].fieldName, 'Second field should be Industry');
        System.assertEquals(null, fields[0].objectName, 'First field should have no object name');
    }

    /**
     * @description Test extracting merge fields with object prefix
     */
    @IsTest
    static void testExtractMergeFields_WithObjectPrefix() {
        String template = 'Contact: {{{Contact.FirstName}}} {{{Contact.LastName}}}';

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.extractMergeFields(template);
        Test.stopTest();

        System.assertEquals(2, fields.size(), 'Should extract 2 merge fields');
        System.assertEquals('Contact', fields[0].objectName, 'Object should be Contact');
        System.assertEquals('FirstName', fields[0].fieldName, 'Field should be FirstName');
        System.assertEquals('Contact', fields[1].objectName, 'Object should be Contact');
        System.assertEquals('LastName', fields[1].fieldName, 'Field should be LastName');
    }

    /**
     * @description Test extracting merge fields from complex HTML template
     */
    @IsTest
    static void testExtractMergeFields_ComplexHTML() {
        String template = '<html><body>' +
            '<h1>Account: {{{Name}}}</h1>' +
            '<p>Industry: {{{Industry}}}</p>' +
            '<div>Contact: {{{Contact.FirstName}}} {{{Contact.LastName}}}</div>' +
            '</body></html>';

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.extractMergeFields(template);
        Test.stopTest();

        System.assertEquals(4, fields.size(), 'Should extract 4 merge fields from HTML');
    }

    /**
     * @description Test extracting merge fields from empty or null template
     */
    @IsTest
    static void testExtractMergeFields_EmptyOrNull() {
        Test.startTest();
        List<MergeFieldValidator.MergeField> nullFields =
            MergeFieldValidator.extractMergeFields(null);
        List<MergeFieldValidator.MergeField> emptyFields =
            MergeFieldValidator.extractMergeFields('');
        List<MergeFieldValidator.MergeField> noFieldsTemplate =
            MergeFieldValidator.extractMergeFields('No merge fields here');
        Test.stopTest();

        System.assertEquals(0, nullFields.size(), 'Null template should return empty list');
        System.assertEquals(0, emptyFields.size(), 'Empty template should return empty list');
        System.assertEquals(0, noFieldsTemplate.size(), 'Template without fields should return empty list');
    }

    /**
     * @description Test validating merge fields against DCM - all valid
     */
    @IsTest
    static void testValidateAgainstDCM_AllValid() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        String template = '{{{Name}}} - {{{Industry}}} - {{{Contact.FirstName}}}';

        // Build DCM config
        Map<String, Object> dcmConfig = new Map<String, Object>{
            'rootObject' => 'Account',
            'childObjects' => new List<String>{ 'Contact' },
            'fieldsByObject' => new Map<String, List<String>>{
                'Account' => new List<String>{ 'Name', 'Industry' },
                'Contact' => new List<String>{ 'FirstName', 'LastName' }
            }
        };

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.validateAgainstDCM(template, dcmConfig);
        Test.stopTest();

        System.assertEquals(3, fields.size(), 'Should validate 3 fields');
        for (MergeFieldValidator.MergeField field : fields) {
            System.assert(field.isValid, 'All fields should be valid: ' + field.fieldName);
            System.assertEquals(null, field.errorMessage, 'No error message for valid fields');
        }
    }

    /**
     * @description Test validating merge fields with invalid root field
     */
    @IsTest
    static void testValidateAgainstDCM_InvalidRootField() {
        String template = '{{{Name}}} - {{{InvalidField__c}}}';

        Map<String, Object> dcmConfig = new Map<String, Object>{
            'rootObject' => 'Account',
            'childObjects' => new List<String>(),
            'fieldsByObject' => new Map<String, List<String>>{
                'Account' => new List<String>{ 'Name', 'Industry' }
            }
        };

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.validateAgainstDCM(template, dcmConfig);
        Test.stopTest();

        System.assertEquals(2, fields.size(), 'Should validate 2 fields');
        System.assert(fields[0].isValid, 'Name should be valid');
        System.assert(!fields[1].isValid, 'InvalidField__c should be invalid');
        System.assertNotEquals(null, fields[1].errorMessage, 'Should have error message');
    }

    /**
     * @description Test validating merge fields with invalid child object
     */
    @IsTest
    static void testValidateAgainstDCM_InvalidChildObject() {
        String template = '{{{InvalidObject.FieldName}}}';

        Map<String, Object> dcmConfig = new Map<String, Object>{
            'rootObject' => 'Account',
            'childObjects' => new List<String>{ 'Contact' },
            'fieldsByObject' => new Map<String, List<String>>{
                'Account' => new List<String>{ 'Name' },
                'Contact' => new List<String>{ 'FirstName' }
            }
        };

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.validateAgainstDCM(template, dcmConfig);
        Test.stopTest();

        System.assertEquals(1, fields.size(), 'Should validate 1 field');
        System.assert(!fields[0].isValid, 'Field should be invalid');
        System.assert(fields[0].errorMessage.contains('InvalidObject'),
            'Error should mention invalid object');
    }

    /**
     * @description Test validating merge fields with invalid child field
     */
    @IsTest
    static void testValidateAgainstDCM_InvalidChildField() {
        String template = '{{{Contact.InvalidField__c}}}';

        Map<String, Object> dcmConfig = new Map<String, Object>{
            'rootObject' => 'Account',
            'childObjects' => new List<String>{ 'Contact' },
            'fieldsByObject' => new Map<String, List<String>>{
                'Account' => new List<String>{ 'Name' },
                'Contact' => new List<String>{ 'FirstName', 'LastName' }
            }
        };

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.validateAgainstDCM(template, dcmConfig);
        Test.stopTest();

        System.assertEquals(1, fields.size(), 'Should validate 1 field');
        System.assert(!fields[0].isValid, 'Field should be invalid');
        System.assert(fields[0].errorMessage.contains('InvalidField__c'),
            'Error should mention invalid field');
    }

    /**
     * @description Test finding unsubstituted fields in output
     */
    @IsTest
    static void testFindUnsubstitutedFields() {
        String outputHtml = '<html><body>' +
            '<p>Name: John Doe</p>' +
            '<p>Missing: {{{MissingField}}}</p>' +
            '<p>Another: {{{Another.Missing}}}</p>' +
            '</body></html>';

        Test.startTest();
        List<String> unsubstituted = MergeFieldValidator.findUnsubstitutedFields(outputHtml);
        Test.stopTest();

        System.assertEquals(2, unsubstituted.size(), 'Should find 2 unsubstituted fields');
        System.assert(unsubstituted.contains('{{{MissingField}}}'),
            'Should find MissingField');
        System.assert(unsubstituted.contains('{{{Another.Missing}}}'),
            'Should find Another.Missing');
    }

    /**
     * @description Test finding unsubstituted fields when all are substituted
     */
    @IsTest
    static void testFindUnsubstitutedFields_AllSubstituted() {
        String outputHtml = '<html><body><p>Name: John Doe</p><p>Industry: Technology</p></body></html>';

        Test.startTest();
        List<String> unsubstituted = MergeFieldValidator.findUnsubstitutedFields(outputHtml);
        Test.stopTest();

        System.assertEquals(0, unsubstituted.size(), 'Should find no unsubstituted fields');
    }

    /**
     * @description Test allFieldsSubstituted method
     */
    @IsTest
    static void testAllFieldsSubstituted() {
        String fullySubstituted = '<p>Name: John Doe</p>';
        String partiallySubstituted = '<p>Name: {{{Name}}}</p>';

        Test.startTest();
        Boolean allSubbed = MergeFieldValidator.allFieldsSubstituted(fullySubstituted);
        Boolean notAllSubbed = MergeFieldValidator.allFieldsSubstituted(partiallySubstituted);
        Test.stopTest();

        System.assert(allSubbed, 'Should return true when all fields substituted');
        System.assert(!notAllSubbed, 'Should return false when fields remain');
    }

    /**
     * @description Test building DCM config from actual records
     */
    @IsTest
    static void testBuildDCMConfigFromRecords() {
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 1
        ];

        Test.startTest();
        Map<String, Object> config = MergeFieldValidator.buildDCMConfigFromRecords(dcm.Id);
        Test.stopTest();

        System.assertNotEquals(null, config, 'Should return config map');
        System.assertEquals('Account', config.get('rootObject'), 'Root object should be Account');

        List<String> childObjects = (List<String>) config.get('childObjects');
        System.assert(childObjects.contains('Contact'), 'Should include Contact child object');

        Map<String, List<String>> fieldsByObject =
            (Map<String, List<String>>) config.get('fieldsByObject');
        System.assert(fieldsByObject.containsKey('Account'), 'Should have Account fields');
        System.assert(fieldsByObject.get('Account').contains('Name'),
            'Account fields should include Name');
        System.assert(fieldsByObject.get('Contact').contains('FirstName'),
            'Contact fields should include FirstName');
    }

    /**
     * @description Test building DCM config with invalid ID
     */
    @IsTest
    static void testBuildDCMConfigFromRecords_InvalidId() {
        Id fakeId = '001000000000000';

        Test.startTest();
        Map<String, Object> config = MergeFieldValidator.buildDCMConfigFromRecords(fakeId);
        Test.stopTest();

        System.assertEquals(null, config, 'Should return null for invalid DCM ID');
    }

    /**
     * @description Test validation summary
     */
    @IsTest
    static void testGetValidationSummary() {
        List<MergeFieldValidator.MergeField> fields = new List<MergeFieldValidator.MergeField>();

        // Create some valid fields
        MergeFieldValidator.MergeField field1 = new MergeFieldValidator.MergeField(
            '{{{Name}}}', null, 'Name'
        );
        field1.isValid = true;
        fields.add(field1);

        MergeFieldValidator.MergeField field2 = new MergeFieldValidator.MergeField(
            '{{{Industry}}}', null, 'Industry'
        );
        field2.isValid = true;
        fields.add(field2);

        // Create an invalid field
        MergeFieldValidator.MergeField field3 = new MergeFieldValidator.MergeField(
            '{{{Invalid}}}', null, 'Invalid'
        );
        field3.isValid = false;
        field3.errorMessage = 'Field not found';
        fields.add(field3);

        Test.startTest();
        Map<String, Integer> summary = MergeFieldValidator.getValidationSummary(fields);
        Test.stopTest();

        System.assertEquals(3, summary.get('total'), 'Total should be 3');
        System.assertEquals(2, summary.get('valid'), 'Valid should be 2');
        System.assertEquals(1, summary.get('invalid'), 'Invalid should be 1');
    }

    /**
     * @description Test MergeField wrapper class
     */
    @IsTest
    static void testMergeFieldWrapper() {
        Test.startTest();
        MergeFieldValidator.MergeField field = new MergeFieldValidator.MergeField(
            '{{{Contact.FirstName}}}', 'Contact', 'FirstName'
        );
        Test.stopTest();

        System.assertEquals('{{{Contact.FirstName}}}', field.originalText,
            'Original text should be set');
        System.assertEquals('Contact', field.objectName, 'Object name should be set');
        System.assertEquals('FirstName', field.fieldName, 'Field name should be set');
        System.assert(field.isValid, 'Should default to valid');
        System.assertEquals(null, field.errorMessage, 'Error message should be null by default');
    }

    /**
     * @description Test extracting merge fields with whitespace
     */
    @IsTest
    static void testExtractMergeFields_WithWhitespace() {
        String template = '{{{ Name }}} - {{{ Contact.FirstName }}}';

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.extractMergeFields(template);
        Test.stopTest();

        System.assertEquals(2, fields.size(), 'Should extract 2 fields');
        System.assertEquals('Name', fields[0].fieldName, 'Should trim whitespace from Name');
        System.assertEquals('Contact', fields[1].objectName, 'Should trim object name');
        System.assertEquals('FirstName', fields[1].fieldName, 'Should trim field name');
    }

    /**
     * @description Test bulk merge field extraction
     */
    @IsTest
    static void testExtractMergeFields_Bulk() {
        // Create template with 50+ merge fields
        String template = '';
        for (Integer i = 0; i < 60; i++) {
            template += '{{{Field' + i + '}}} ';
        }

        Test.startTest();
        List<MergeFieldValidator.MergeField> fields =
            MergeFieldValidator.extractMergeFields(template);
        Test.stopTest();

        System.assertEquals(60, fields.size(), 'Should extract all 60 fields');
    }
}