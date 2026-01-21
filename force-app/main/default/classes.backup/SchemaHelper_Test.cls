/**
 * @description Test class for SchemaHelper
 * Tests schema introspection, caching, and validation methods
 */
@IsTest
private class SchemaHelper_Test {

    @TestSetup
    static void setup() {
        // No custom objects to create, will use standard Salesforce objects for testing
    }

    /**
     * @description Test getObjectDescribe with valid object
     */
    @IsTest
    static void testGetObjectDescribe_ValidObject() {
        Test.startTest();
        Schema.DescribeSObjectResult result = SchemaHelper.getObjectDescribe('Account');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return describe result for Account');
        System.assertEquals('Account', result.getName(), 'Object name should be Account');
        System.assert(result.isAccessible(), 'Account should be accessible');
    }

    /**
     * @description Test getObjectDescribe with invalid object
     */
    @IsTest
    static void testGetObjectDescribe_InvalidObject() {
        Test.startTest();
        Schema.DescribeSObjectResult result = SchemaHelper.getObjectDescribe('NonExistentObject__c');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for invalid object');
    }

    /**
     * @description Test that describe cache works correctly
     */
    @IsTest
    static void testDescribeCache() {
        // Clear cache first
        SchemaHelper.clearCache();

        Test.startTest();
        // First call - should hit Salesforce API
        Schema.DescribeSObjectResult result1 = SchemaHelper.getObjectDescribe('Account');
        // Second call - should hit cache
        Schema.DescribeSObjectResult result2 = SchemaHelper.getObjectDescribe('Account');
        Test.stopTest();

        System.assertNotEquals(null, result1, 'First call should return result');
        System.assertNotEquals(null, result2, 'Second call should return cached result');
        System.assertEquals(result1, result2, 'Both results should be identical');
    }

    /**
     * @description Test getChildRelationships for Account object
     */
    @IsTest
    static void testGetChildRelationships_Account() {
        Test.startTest();
        List<SchemaHelper.ChildRelationship> relationships =
            SchemaHelper.getChildRelationships('Account');
        Test.stopTest();

        System.assertNotEquals(null, relationships, 'Should return list of relationships');
        System.assert(relationships.size() > 0, 'Account should have child relationships');

        // Verify structure of first relationship
        if (relationships.size() > 0) {
            SchemaHelper.ChildRelationship rel = relationships[0];
            System.assertNotEquals(null, rel.childObject, 'Child object should be populated');
            System.assertNotEquals(null, rel.field, 'Relationship field should be populated');
        }
    }

    /**
     * @description Test that system objects are filtered out from child relationships
     */
    @IsTest
    static void testGetChildRelationships_FiltersSystemObjects() {
        Test.startTest();
        List<SchemaHelper.ChildRelationship> relationships =
            SchemaHelper.getChildRelationships('Account');
        Test.stopTest();

        // Verify no Feed, History, or Share objects
        for (SchemaHelper.ChildRelationship rel : relationships) {
            System.assert(!rel.childObject.endsWith('Feed'),
                'Should not include Feed objects: ' + rel.childObject);
            System.assert(!rel.childObject.endsWith('History'),
                'Should not include History objects: ' + rel.childObject);
            System.assert(!rel.childObject.endsWith('Share'),
                'Should not include Share objects: ' + rel.childObject);
        }
    }

    /**
     * @description Test getChildRelationships with invalid object
     */
    @IsTest
    static void testGetChildRelationships_InvalidObject() {
        Test.startTest();
        List<SchemaHelper.ChildRelationship> relationships =
            SchemaHelper.getChildRelationships('InvalidObject__c');
        Test.stopTest();

        System.assertNotEquals(null, relationships, 'Should return empty list, not null');
        System.assertEquals(0, relationships.size(), 'Should return empty list for invalid object');
    }

    /**
     * @description Test getFields for Account object
     */
    @IsTest
    static void testGetFields_Account() {
        Test.startTest();
        List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields('Account');
        Test.stopTest();

        System.assertNotEquals(null, fields, 'Should return list of fields');
        System.assert(fields.size() > 0, 'Account should have fields');

        // Find the Name field
        SchemaHelper.FieldMetadata nameField = null;
        for (SchemaHelper.FieldMetadata field : fields) {
            if (field.name == 'Name') {
                nameField = field;
                break;
            }
        }

        System.assertNotEquals(null, nameField, 'Should include Name field');
        System.assertEquals('Name', nameField.name, 'Field name should be Name');
        System.assertEquals('STRING', nameField.type, 'Name should be STRING type');
        System.assert(nameField.isAccessible, 'Name should be accessible');
    }

    /**
     * @description Test that system fields are filtered correctly
     */
    @IsTest
    static void testGetFields_FiltersSystemFields() {
        Test.startTest();
        List<SchemaHelper.FieldMetadata> fields = SchemaHelper.getFields('Account');
        Test.stopTest();

        // Verify no unwanted system fields
        Set<String> unwantedFields = new Set<String>{
            'CreatedById', 'LastModifiedById', 'SystemModstamp',
            'IsDeleted', 'LastActivityDate'
        };

        for (SchemaHelper.FieldMetadata field : fields) {
            System.assert(!unwantedFields.contains(field.name),
                'Should not include system field: ' + field.name);
        }

        // Verify useful system fields are included
        Boolean hasId = false;
        Boolean hasName = false;
        Boolean hasCreatedDate = false;

        for (SchemaHelper.FieldMetadata field : fields) {
            if (field.name == 'Id') hasId = true;
            if (field.name == 'Name') hasName = true;
            if (field.name == 'CreatedDate') hasCreatedDate = true;
        }

        System.assert(hasId, 'Should include Id field');
        System.assert(hasName, 'Should include Name field');
        System.assert(hasCreatedDate, 'Should include CreatedDate field');
    }

    /**
     * @description Test getFields with invalid object
     */
    @IsTest
    static void testGetFields_InvalidObject() {
        Test.startTest();
        List<SchemaHelper.FieldMetadata> fields =
            SchemaHelper.getFields('InvalidObject__c');
        Test.stopTest();

        System.assertNotEquals(null, fields, 'Should return empty list, not null');
        System.assertEquals(0, fields.size(), 'Should return empty list for invalid object');
    }

    /**
     * @description Test isObjectAccessible with valid object
     */
    @IsTest
    static void testIsObjectAccessible_ValidObject() {
        Test.startTest();
        Boolean isAccessible = SchemaHelper.isObjectAccessible('Account');
        Test.stopTest();

        System.assert(isAccessible, 'Account should be accessible');
    }

    /**
     * @description Test isObjectAccessible with invalid object
     */
    @IsTest
    static void testIsObjectAccessible_InvalidObject() {
        Test.startTest();
        Boolean isAccessible = SchemaHelper.isObjectAccessible('InvalidObject__c');
        Test.stopTest();

        System.assert(!isAccessible, 'Invalid object should not be accessible');
    }

    /**
     * @description Test isFieldAccessible with valid field
     */
    @IsTest
    static void testIsFieldAccessible_ValidField() {
        Test.startTest();
        Boolean isAccessible = SchemaHelper.isFieldAccessible('Account', 'Name');
        Test.stopTest();

        System.assert(isAccessible, 'Account.Name should be accessible');
    }

    /**
     * @description Test isFieldAccessible with invalid field
     */
    @IsTest
    static void testIsFieldAccessible_InvalidField() {
        Test.startTest();
        Boolean isAccessible = SchemaHelper.isFieldAccessible('Account', 'InvalidField__c');
        Test.stopTest();

        System.assert(!isAccessible, 'Invalid field should not be accessible');
    }

    /**
     * @description Test isFieldAccessible with invalid object
     */
    @IsTest
    static void testIsFieldAccessible_InvalidObject() {
        Test.startTest();
        Boolean isAccessible = SchemaHelper.isFieldAccessible('InvalidObject__c', 'Name');
        Test.stopTest();

        System.assert(!isAccessible, 'Field on invalid object should not be accessible');
    }

    /**
     * @description Test ChildRelationship wrapper class
     */
    @IsTest
    static void testChildRelationshipWrapper() {
        Test.startTest();
        SchemaHelper.ChildRelationship rel = new SchemaHelper.ChildRelationship(
            'Contact', 'Contacts', 'AccountId'
        );
        Test.stopTest();

        System.assertEquals('Contact', rel.childObject, 'Child object should be set');
        System.assertEquals('Contacts', rel.relationshipName, 'Relationship name should be set');
        System.assertEquals('AccountId', rel.field, 'Field should be set');
    }

    /**
     * @description Test FieldMetadata wrapper class
     */
    @IsTest
    static void testFieldMetadataWrapper() {
        Test.startTest();
        SchemaHelper.FieldMetadata field = new SchemaHelper.FieldMetadata(
            'Name', 'Account Name', 'STRING', true, true, false
        );
        Test.stopTest();

        System.assertEquals('Name', field.name, 'Field name should be set');
        System.assertEquals('Account Name', field.label, 'Field label should be set');
        System.assertEquals('STRING', field.type, 'Field type should be set');
        System.assertEquals(true, field.isAccessible, 'Is accessible should be set');
        System.assertEquals(true, field.isUpdateable, 'Is updateable should be set');
        System.assertEquals(false, field.isCustom, 'Is custom should be set');
    }

    /**
     * @description Test clearCache method
     */
    @IsTest
    static void testClearCache() {
        // Populate cache
        SchemaHelper.getObjectDescribe('Account');

        Test.startTest();
        SchemaHelper.clearCache();
        // After clear, should still work
        Schema.DescribeSObjectResult result = SchemaHelper.getObjectDescribe('Account');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should still return result after cache clear');
    }

    /**
     * @description Test bulk operations - get fields for multiple objects
     */
    @IsTest
    static void testBulkOperations() {
        Test.startTest();
        List<SchemaHelper.FieldMetadata> accountFields = SchemaHelper.getFields('Account');
        List<SchemaHelper.FieldMetadata> contactFields = SchemaHelper.getFields('Contact');
        List<SchemaHelper.FieldMetadata> oppFields = SchemaHelper.getFields('Opportunity');
        Test.stopTest();

        System.assert(accountFields.size() > 0, 'Should return Account fields');
        System.assert(contactFields.size() > 0, 'Should return Contact fields');
        System.assert(oppFields.size() > 0, 'Should return Opportunity fields');
    }
}