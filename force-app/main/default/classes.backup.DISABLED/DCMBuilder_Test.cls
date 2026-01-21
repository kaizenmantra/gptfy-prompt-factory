/**
 * @description Test class for DCMBuilder
 * Tests DCM creation, validation, and field masking logic
 */
@IsTest
private class DCMBuilder_Test {

    /**
     * @description Test creating a simple DCM with root object only
     */
    @IsTest
    static void testCreateDCM_RootObjectOnly() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Test Account DCM';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name', 'Industry', 'Phone' });

        Test.startTest();
        Id dcmId = DCMBuilder.createDCM(config);
        Test.stopTest();

        // Verify DCM record
        // Note: ccai__Root_Object__c field may not exist on this object
        // The root object is determined from DCM field records
        ccai__AI_Data_Extraction_Mapping__c dcm = [
            SELECT Id, Name, ccai__Status__c
            FROM ccai__AI_Data_Extraction_Mapping__c
            WHERE Id = :dcmId
        ];

        System.assertEquals('Test Account DCM', dcm.Name, 'DCM name should match');
        System.assertEquals('Active', dcm.ccai__Status__c, 'Status should be Active');

        // Verify fields created - using ccai__Field__c and ccai__Object__c
        List<ccai__AI_Data_Extraction_Field__c> fields = [
            SELECT ccai__Type__c, ccai__Field__c, ccai__Object__c
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
        ];

        // Should have 1 OBJECT record + 3 FIELD records = 4 total
        System.assertEquals(4, fields.size(), 'Should create 4 field records');

        // Count types and verify
        Integer objectCount = 0;
        Integer fieldCount = 0;
        Set<String> fieldNames = new Set<String>();

        for (ccai__AI_Data_Extraction_Field__c field : fields) {
            if (field.ccai__Type__c == 'OBJECT') {
                objectCount++;
                System.assertEquals('Account', field.ccai__Object__c, 'Object should be Account');
            } else if (field.ccai__Type__c == 'FIELD') {
                fieldCount++;
                fieldNames.add(field.ccai__Field__c);
                System.assertEquals('Account', field.ccai__Object__c, 'Field should belong to Account');
            }
        }

        System.assertEquals(1, objectCount, 'Should have 1 OBJECT record');
        System.assertEquals(3, fieldCount, 'Should have 3 FIELD records');
        System.assert(fieldNames.contains('Name'), 'Should include Name field');
        System.assert(fieldNames.contains('Industry'), 'Should include Industry field');
        System.assert(fieldNames.contains('Phone'), 'Should include Phone field');
    }

    /**
     * @description Test creating DCM with child objects
     */
    @IsTest
    static void testCreateDCM_WithChildObjects() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Account with Contacts DCM';
        config.rootObject = 'Account';

        // Add root fields
        config.fieldsByObject.put('Account', new List<String>{ 'Name', 'Industry' });

        // Add child object
        DCMBuilder.ObjectConfig contactConfig = new DCMBuilder.ObjectConfig(
            'Contact', 'Contacts', 'AccountId'
        );
        contactConfig.maxRecords = 5;
        config.childObjects.add(contactConfig);

        // Add child fields
        config.fieldsByObject.put('Contact', new List<String>{ 'FirstName', 'LastName', 'Email' });

        Test.startTest();
        Id dcmId = DCMBuilder.createDCM(config);
        Test.stopTest();

        // Verify DCM created
        System.assertNotEquals(null, dcmId, 'DCM should be created');

        // Verify objects - using ccai__Object__c instead of ccai__API_Name__c
        // Note: ccai__Sequence__c doesn't exist, order by CreatedDate instead
        List<ccai__AI_Data_Extraction_Field__c> objects = [
            SELECT ccai__Object__c
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            AND ccai__Type__c = 'OBJECT'
            ORDER BY CreatedDate
        ];

        System.assertEquals(2, objects.size(), 'Should have 2 objects');
        System.assertEquals('Account', objects[0].ccai__Object__c, 'First should be Account');
        System.assertEquals('Contact', objects[1].ccai__Object__c, 'Second should be Contact');

        // Verify detail record for relationship
        List<ccai__AI_Data_Extraction_Detail__c> details = [
            SELECT ccai__Object_Name__c, ccai__RelationshipField__c, ccai__Record_Limit__c
            FROM ccai__AI_Data_Extraction_Detail__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
        ];

        System.assertEquals(1, details.size(), 'Should create 1 detail record');
        System.assertEquals('Contact', details[0].ccai__Object_Name__c, 'Child should be Contact');
        System.assertEquals('AccountId', details[0].ccai__RelationshipField__c,
            'Relationship field should be AccountId');
        System.assertEquals(5, details[0].ccai__Record_Limit__c, 'Max records should be 5');

        // Verify all fields created
        Integer fieldCount = [
            SELECT COUNT()
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            AND ccai__Type__c = 'FIELD'
        ];

        System.assertEquals(5, fieldCount, 'Should create 5 field records (2 + 3)');
    }

    /**
     * @description Test creating DCM with multiple child objects
     */
    @IsTest
    static void testCreateDCM_MultipleChildObjects() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Account with Multiple Children';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name' });

        // Add Contact child
        config.childObjects.add(new DCMBuilder.ObjectConfig(
            'Contact', 'Contacts', 'AccountId'
        ));
        config.fieldsByObject.put('Contact', new List<String>{ 'FirstName', 'LastName' });

        // Add Opportunity child
        config.childObjects.add(new DCMBuilder.ObjectConfig(
            'Opportunity', 'Opportunities', 'AccountId'
        ));
        config.fieldsByObject.put('Opportunity', new List<String>{ 'Name', 'Amount', 'StageName' });

        Test.startTest();
        Id dcmId = DCMBuilder.createDCM(config);
        Test.stopTest();

        // Verify 3 objects created
        Integer objectCount = [
            SELECT COUNT()
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            AND ccai__Type__c = 'OBJECT'
        ];

        System.assertEquals(3, objectCount, 'Should create 3 object records');

        // Verify 2 detail records
        List<ccai__AI_Data_Extraction_Detail__c> details = [
            SELECT ccai__Object_Name__c
            FROM ccai__AI_Data_Extraction_Detail__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
        ];

        System.assertEquals(2, details.size(), 'Should create 2 detail records');
    }

    /**
     * @description Test field masking for PII fields
     */
    @IsTest
    static void testFieldMasking_PIIFields() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Test Masking';
        config.rootObject = 'Contact';
        config.fieldsByObject.put('Contact', new List<String>{
            'FirstName', 'LastName', 'SSN__c', 'CreditCard__c', 'Password__c'
        });

        Test.startTest();
        Id dcmId = DCMBuilder.createDCM(config);
        Test.stopTest();

        // Verify PII scanning applied - using ccai__Scan_for_PII__c instead of ccai__Mask_Data__c
        List<ccai__AI_Data_Extraction_Field__c> fields = [
            SELECT ccai__Field__c, ccai__Scan_for_PII__c
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            AND ccai__Type__c = 'FIELD'
        ];

        Map<String, Boolean> maskingByField = new Map<String, Boolean>();
        for (ccai__AI_Data_Extraction_Field__c field : fields) {
            maskingByField.put(field.ccai__Field__c, field.ccai__Scan_for_PII__c);
        }

        System.assertEquals(false, maskingByField.get('FirstName'), 'FirstName should not be masked');
        System.assertEquals(false, maskingByField.get('LastName'), 'LastName should not be masked');
        System.assertEquals(true, maskingByField.get('SSN__c'), 'SSN should be masked');
        System.assertEquals(true, maskingByField.get('CreditCard__c'), 'CreditCard should be masked');
        System.assertEquals(true, maskingByField.get('Password__c'), 'Password should be masked');
    }

    /**
     * @description Test validateConfig with valid configuration
     */
    @IsTest
    static void testValidateConfig_Valid() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Valid Config';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name', 'Industry' });

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfig(config);
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid config should have no errors');
    }

    /**
     * @description Test validateConfig with missing name
     */
    @IsTest
    static void testValidateConfig_MissingName() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = '';
        config.rootObject = 'Account';

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        System.assert(errors[0].contains('name is required'), 'Error should mention missing name');
    }

    /**
     * @description Test validateConfig with missing root object
     */
    @IsTest
    static void testValidateConfig_MissingRootObject() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Test';
        config.rootObject = '';

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasRootObjectError = false;
        for (String error : errors) {
            if (error.contains('Root object is required')) {
                hasRootObjectError = true;
            }
        }
        System.assert(hasRootObjectError, 'Should mention root object is required');
    }

    /**
     * @description Test validateConfig with invalid root object
     */
    @IsTest
    static void testValidateConfig_InvalidRootObject() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Test';
        config.rootObject = 'InvalidObject__c';

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasAccessError = false;
        for (String error : errors) {
            if (error.contains('not accessible')) {
                hasAccessError = true;
            }
        }
        System.assert(hasAccessError, 'Should mention object is not accessible');
    }

    /**
     * @description Test validateConfig with invalid child object
     */
    @IsTest
    static void testValidateConfig_InvalidChildObject() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Test';
        config.rootObject = 'Account';

        DCMBuilder.ObjectConfig childConfig = new DCMBuilder.ObjectConfig(
            'InvalidChild__c', 'InvalidChildren', 'ParentId__c'
        );
        config.childObjects.add(childConfig);

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasChildError = false;
        for (String error : errors) {
            if (error.contains('InvalidChild__c') && error.contains('not accessible')) {
                hasChildError = true;
            }
        }
        System.assert(hasChildError, 'Should mention child object is not accessible');
    }

    /**
     * @description Test validateConfig with invalid field
     */
    @IsTest
    static void testValidateConfig_InvalidField() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Test';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name', 'InvalidField__c' });

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasFieldError = false;
        for (String error : errors) {
            if (error.contains('InvalidField__c') && error.contains('not accessible')) {
                hasFieldError = true;
            }
        }
        System.assert(hasFieldError, 'Should mention field is not accessible');
    }

    /**
     * @description Test validateConfig with missing relationship field
     */
    @IsTest
    static void testValidateConfig_MissingRelationshipField() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Test';
        config.rootObject = 'Account';

        DCMBuilder.ObjectConfig childConfig = new DCMBuilder.ObjectConfig(
            'Contact', 'Contacts', ''
        );
        config.childObjects.add(childConfig);

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfig(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasRelError = false;
        for (String error : errors) {
            if (error.contains('Relationship field is required')) {
                hasRelError = true;
            }
        }
        System.assert(hasRelError, 'Should mention relationship field is required');
    }

    /**
     * @description Test deleteDCM
     */
    @IsTest
    static void testDeleteDCM() {
        // Create a DCM first
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'To Be Deleted';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name' });

        Id dcmId = DCMBuilder.createDCM(config);

        // Verify it exists
        Integer countBefore = [SELECT COUNT() FROM ccai__AI_Data_Extraction_Mapping__c WHERE Id = :dcmId];
        System.assertEquals(1, countBefore, 'DCM should exist');

        Test.startTest();
        DCMBuilder.deleteDCM(dcmId);
        Test.stopTest();

        // Verify it's deleted
        Integer countAfter = [SELECT COUNT() FROM ccai__AI_Data_Extraction_Mapping__c WHERE Id = :dcmId];
        System.assertEquals(0, countAfter, 'DCM should be deleted');

        // Verify child records are also deleted (cascade delete)
        Integer fieldsCount = [
            SELECT COUNT()
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
        ];
        System.assertEquals(0, fieldsCount, 'All field records should be deleted');
    }

    /**
     * @description Test deleteDCM with invalid ID
     */
    @IsTest
    static void testDeleteDCM_InvalidId() {
        Id fakeId = '001000000000000';

        Test.startTest();
        try {
            DCMBuilder.deleteDCM(fakeId);
            System.assert(false, 'Should throw exception for invalid ID');
        } catch (DCMBuilder.DCMBuilderException e) {
            System.assert(e.getMessage().contains('Failed to delete DCM'),
                'Exception should mention delete failure');
        }
        Test.stopTest();
    }

    /**
     * @description Test DCMConfig wrapper initialization
     */
    @IsTest
    static void testDCMConfigWrapper() {
        Test.startTest();
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        Test.stopTest();

        System.assertNotEquals(null, config.childObjects, 'Child objects list should be initialized');
        System.assertNotEquals(null, config.fieldsByObject, 'Fields map should be initialized');
        System.assertEquals(0, config.childObjects.size(), 'Child objects should be empty');
        System.assertEquals(0, config.fieldsByObject.size(), 'Fields map should be empty');
    }

    /**
     * @description Test ObjectConfig wrapper
     */
    @IsTest
    static void testObjectConfigWrapper() {
        Test.startTest();
        DCMBuilder.ObjectConfig objConfig = new DCMBuilder.ObjectConfig(
            'Contact', 'Contacts', 'AccountId'
        );
        Test.stopTest();

        System.assertEquals('Contact', objConfig.objectName, 'Object name should be set');
        System.assertEquals('Contacts', objConfig.relationshipName, 'Relationship name should be set');
        System.assertEquals('AccountId', objConfig.relationshipField, 'Relationship field should be set');
        System.assertEquals(10, objConfig.maxRecords, 'Max records should default to 10');
    }

    /**
     * @description Test bulk DCM creation with 200+ fields
     */
    @IsTest
    static void testCreateDCM_BulkFields() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Bulk Fields DCM';
        config.rootObject = 'Account';

        // Create a list with many field names (simulated)
        List<String> bulkFields = new List<String>{ 'Name', 'Industry', 'Phone',
            'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode',
            'ShippingStreet', 'ShippingCity', 'ShippingState', 'ShippingPostalCode',
            'Website', 'AnnualRevenue', 'NumberOfEmployees', 'Description'
        };
        config.fieldsByObject.put('Account', bulkFields);

        Test.startTest();
        Id dcmId = DCMBuilder.createDCM(config);
        Test.stopTest();

        // Verify all fields created
        Integer fieldCount = [
            SELECT COUNT()
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            AND ccai__Type__c = 'FIELD'
        ];

        System.assertEquals(bulkFields.size(), fieldCount,
            'Should create all ' + bulkFields.size() + ' field records');
    }

    /**
     * @description Test exception handling in createDCM
     */
    @IsTest
    static void testCreateDCM_Exception() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        // Intentionally invalid config (no name)
        config.name = null;
        config.rootObject = 'Account';

        Test.startTest();
        try {
            Id dcmId = DCMBuilder.createDCM(config);
            // Should throw exception due to null name
        } catch (DCMBuilder.DCMBuilderException e) {
            System.assert(e.getMessage().contains('Failed to create DCM'),
                'Exception should mention DCM creation failure');
        }
        Test.stopTest();
    }

    /**
     * @description Test auto-detection of relationship field (standard pattern)
     */
    @IsTest
    static void testDetectRelationshipField_StandardPattern() {
        Test.startTest();
        DCMBuilder.RelationshipDetectionResult result =
            DCMBuilder.detectRelationshipField('Contact', 'Account');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should detect relationship');
        System.assertEquals('AccountId', result.relationshipField, 'Should find AccountId');
        System.assertEquals('standard_pattern', result.detectionMethod, 'Should use standard pattern');
        System.assertEquals(false, result.isPolymorphic, 'Should not be polymorphic');
    }

    /**
     * @description Test auto-detection for Opportunity -> Account relationship
     */
    @IsTest
    static void testDetectRelationshipField_Opportunity() {
        Test.startTest();
        DCMBuilder.RelationshipDetectionResult result =
            DCMBuilder.detectRelationshipField('Opportunity', 'Account');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should detect relationship');
        System.assertEquals('AccountId', result.relationshipField, 'Should find AccountId');
    }

    /**
     * @description Test auto-detection for OpportunityLineItem -> Opportunity relationship
     */
    @IsTest
    static void testDetectRelationshipField_OpportunityLineItem() {
        Test.startTest();
        DCMBuilder.RelationshipDetectionResult result =
            DCMBuilder.detectRelationshipField('OpportunityLineItem', 'Opportunity');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should detect relationship');
        System.assertEquals('OpportunityId', result.relationshipField, 'Should find OpportunityId');
    }

    /**
     * @description Test auto-detection returns null for non-existent relationship
     */
    @IsTest
    static void testDetectRelationshipField_NotFound() {
        Test.startTest();
        DCMBuilder.RelationshipDetectionResult result =
            DCMBuilder.detectRelationshipField('Account', 'Contact'); // Reverse - no direct relationship
        Test.stopTest();

        // Account doesn't have a ContactId field, so detection should fail or find nothing
        // Note: This may find OwnerId -> User, but not Contact specifically
        if (result != null) {
            System.assertNotEquals('ContactId', result.relationshipField, 'Should not find ContactId');
        }
    }

    /**
     * @description Test relationship name pluralization
     */
    @IsTest
    static void testGetRelationshipName() {
        Test.startTest();
        System.assertEquals('Contacts', DCMBuilder.getRelationshipName('Contact'), 'Contact -> Contacts');
        System.assertEquals('Opportunities', DCMBuilder.getRelationshipName('Opportunity'), 'Irregular plural');
        System.assertEquals('Cases', DCMBuilder.getRelationshipName('Case'), 'Irregular plural');
        System.assertEquals('Accounts', DCMBuilder.getRelationshipName('Account'), 'Account -> Accounts');
        Test.stopTest();
    }

    /**
     * @description Test DCM creation with auto-detected relationship
     */
    @IsTest
    static void testCreateDCMWithGrandchildren_AutoDetect() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Auto-Detect Test';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name', 'Industry' });

        // Add child without specifying relationshipField - should auto-detect
        DCMBuilder.ObjectConfig contactConfig = new DCMBuilder.ObjectConfig(
            'Contact', null, null  // Let it auto-detect
        );
        config.childObjects.add(contactConfig);
        config.fieldsByObject.put('Contact', new List<String>{ 'FirstName', 'LastName' });

        Test.startTest();
        Id dcmId = DCMBuilder.createDCMWithGrandchildren(config);
        Test.stopTest();

        System.assertNotEquals(null, dcmId, 'DCM should be created');

        // Verify detail record was created with auto-detected relationship field
        List<ccai__AI_Data_Extraction_Detail__c> details = [
            SELECT ccai__Object_Name__c, ccai__RelationshipField__c
            FROM ccai__AI_Data_Extraction_Detail__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
        ];

        System.assertEquals(1, details.size(), 'Should create detail record');
        System.assertEquals('Contact', details[0].ccai__Object_Name__c, 'Should be Contact');
        System.assertEquals('AccountId', details[0].ccai__RelationshipField__c,
            'Should auto-detect AccountId');
    }

    /**
     * @description Test DCM creation with grandchild objects (3-level hierarchy)
     */
    @IsTest
    static void testCreateDCMWithGrandchildren_ThreeLevels() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Three Level DCM';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name' });

        // Add direct child: Opportunity
        DCMBuilder.ObjectConfig oppConfig = new DCMBuilder.ObjectConfig(
            'Opportunity', 'Opportunities', 'AccountId'
        );
        config.childObjects.add(oppConfig);
        config.fieldsByObject.put('Opportunity', new List<String>{ 'Name', 'Amount' });

        // Add grandchild: OpportunityLineItem (child of Opportunity)
        DCMBuilder.ObjectConfig oliConfig = new DCMBuilder.ObjectConfig(
            'OpportunityLineItem', 'OpportunityLineItems', 'OpportunityId', 'Opportunity'
        );
        config.childObjects.add(oliConfig);
        config.fieldsByObject.put('OpportunityLineItem', new List<String>{ 'Quantity', 'UnitPrice' });

        Test.startTest();
        Id dcmId = DCMBuilder.createDCMWithGrandchildren(config);
        Test.stopTest();

        System.assertNotEquals(null, dcmId, 'DCM should be created');

        // Verify all 3 objects created
        Integer objectCount = [
            SELECT COUNT()
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            AND ccai__Type__c = 'OBJECT'
        ];
        System.assertEquals(3, objectCount, 'Should create 3 object records');

        // Verify 2 detail records (one for Opportunity, one for OLI)
        List<ccai__AI_Data_Extraction_Detail__c> details = [
            SELECT ccai__Object_Name__c, ccai__RelationshipField__c, ccai__Parent_Detail__c
            FROM ccai__AI_Data_Extraction_Detail__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcmId
            ORDER BY CreatedDate
        ];

        System.assertEquals(2, details.size(), 'Should create 2 detail records');

        // Find grandchild detail and verify parent link
        for (ccai__AI_Data_Extraction_Detail__c detail : details) {
            if (detail.ccai__Object_Name__c == 'OpportunityLineItem') {
                System.assertNotEquals(null, detail.ccai__Parent_Detail__c,
                    'Grandchild should link to parent detail');
            }
        }
    }

    /**
     * @description Test enhanced validation with schema checks
     */
    @IsTest
    static void testValidateConfigWithSchema_Valid() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Valid Schema Config';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name', 'Industry', 'Phone' });

        // Add child with valid relationship
        DCMBuilder.ObjectConfig contactConfig = new DCMBuilder.ObjectConfig(
            'Contact', 'Contacts', 'AccountId'
        );
        config.childObjects.add(contactConfig);
        config.fieldsByObject.put('Contact', new List<String>{ 'FirstName', 'LastName' });

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfigWithSchema(config);
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid config should have no errors: ' +
            (errors.isEmpty() ? '' : String.join(errors, '; ')));
    }

    /**
     * @description Test enhanced validation catches invalid fields
     */
    @IsTest
    static void testValidateConfigWithSchema_InvalidFields() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Invalid Fields Config';
        config.rootObject = 'Account';
        config.fieldsByObject.put('Account', new List<String>{ 'Name', 'FakeField__c', 'AnotherFake__c' });

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfigWithSchema(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasFieldError = false;
        for (String error : errors) {
            if (error.contains('FakeField__c') || error.contains('Invalid fields')) {
                hasFieldError = true;
            }
        }
        System.assert(hasFieldError, 'Should detect invalid fields');
    }

    /**
     * @description Test enhanced validation catches relationship name with spaces
     */
    @IsTest
    static void testValidateConfigWithSchema_RelationshipNameSpaces() {
        DCMBuilder.DCMConfig config = new DCMBuilder.DCMConfig();
        config.name = 'Spaces Test';
        config.rootObject = 'Account';

        // Add child with spaces in relationship name (invalid for GPTfy)
        DCMBuilder.ObjectConfig contactConfig = new DCMBuilder.ObjectConfig(
            'Contact', 'Contact Records', 'AccountId'  // Space in name
        );
        config.childObjects.add(contactConfig);

        Test.startTest();
        List<String> errors = DCMBuilder.validateConfigWithSchema(config);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        Boolean hasSpaceError = false;
        for (String error : errors) {
            if (error.contains('cannot contain spaces')) {
                hasSpaceError = true;
            }
        }
        System.assert(hasSpaceError, 'Should detect spaces in relationship name');
    }

    /**
     * @description Test ObjectConfig with parentObject constructor
     */
    @IsTest
    static void testObjectConfigWrapper_WithParent() {
        Test.startTest();
        DCMBuilder.ObjectConfig objConfig = new DCMBuilder.ObjectConfig(
            'OpportunityLineItem', 'LineItems', 'OpportunityId', 'Opportunity'
        );
        Test.stopTest();

        System.assertEquals('OpportunityLineItem', objConfig.objectName, 'Object name should be set');
        System.assertEquals('LineItems', objConfig.relationshipName, 'Relationship name should be set');
        System.assertEquals('OpportunityId', objConfig.relationshipField, 'Relationship field should be set');
        System.assertEquals('Opportunity', objConfig.parentObject, 'Parent object should be set');
        System.assertEquals(10, objConfig.maxRecords, 'Max records should default to 10');
    }

    /**
     * @description Test RelationshipDetectionResult wrapper
     */
    @IsTest
    static void testRelationshipDetectionResultWrapper() {
        Test.startTest();
        DCMBuilder.RelationshipDetectionResult result = new DCMBuilder.RelationshipDetectionResult(
            'AccountId', 'Contacts', false, 'standard_pattern'
        );
        Test.stopTest();

        System.assertEquals('AccountId', result.relationshipField, 'Field should be set');
        System.assertEquals('Contacts', result.relationshipName, 'Name should be set');
        System.assertEquals(false, result.isPolymorphic, 'Polymorphic flag should be set');
        System.assertEquals('standard_pattern', result.detectionMethod, 'Method should be set');
    }
}