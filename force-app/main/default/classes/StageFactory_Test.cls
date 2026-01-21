/**
 * @description Test class for StageFactory
 * Tests factory pattern, stage instantiation, and metadata retrieval
 */
@IsTest
private class StageFactory_Test {

    /**
     * @description Test getting stage instance for all valid stage numbers
     */
    @IsTest
    static void testGetStage_AllValidStages() {
        Test.startTest();

        // Test all 12 stages
        for (Integer i = 1; i <= 12; i++) {
            IStage stage = StageFactory.getStage(i);
            System.assertNotEquals(null, stage, 'Stage ' + i + ' should be instantiated');

            // Verify the stage has a non-null class name
            System.assertNotEquals(null, String.valueOf(stage).substringBefore(':'), 'Stage ' + i + ' should have a class name');
        }

        Test.stopTest();
    }

    /**
     * @description Test getting stage 1 - Intelligence Retrieval
     */
    @IsTest
    static void testGetStage_Stage01() {
        Test.startTest();
        IStage stage = StageFactory.getStage(1);
        Test.stopTest();

        System.assertNotEquals(null, stage, 'Stage 1 should be instantiated');
        System.assert(stage instanceof Stage01_IntelligenceRetrieval,
            'Should return Stage01_IntelligenceRetrieval instance');
    }

    /**
     * @description Test getting stage 2 - Strategic Profiling
     */
    @IsTest
    static void testGetStage_Stage02() {
        Test.startTest();
        IStage stage = StageFactory.getStage(2);
        Test.stopTest();

        System.assertNotEquals(null, stage, 'Stage 2 should be instantiated');
        System.assert(stage instanceof Stage02_StrategicProfiling,
            'Should return Stage02_StrategicProfiling instance');
    }

    /**
     * @description Test getting stage with null stage number throws exception
     */
    @IsTest
    static void testGetStage_NullStageNumber() {
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            IStage stage = StageFactory.getStage(null);
        } catch (StageFactory.StageFactoryException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw exception for null stage number');
        System.assert(exceptionMessage.contains('cannot be null'),
            'Exception message should mention null');
    }

    /**
     * @description Test getting stage with invalid stage number (too low)
     */
    @IsTest
    static void testGetStage_InvalidStageNumber_TooLow() {
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            IStage stage = StageFactory.getStage(0);
        } catch (StageFactory.StageFactoryException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw exception for stage number 0');
        System.assert(exceptionMessage.contains('Invalid stage number'),
            'Exception message should mention invalid stage number');
    }

    /**
     * @description Test getting stage with invalid stage number (too high)
     */
    @IsTest
    static void testGetStage_InvalidStageNumber_TooHigh() {
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            IStage stage = StageFactory.getStage(13);
        } catch (StageFactory.StageFactoryException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw exception for stage number 13');
        System.assert(exceptionMessage.contains('Invalid stage number'),
            'Exception message should mention invalid stage number');
    }

    /**
     * @description Test getting stage metadata for all stages
     */
    @IsTest
    static void testGetStageMetadata_AllStages() {
        Test.startTest();

        for (Integer i = 1; i <= 12; i++) {
            StageFactory.StageMetadata metadata = StageFactory.getStageMetadata(i);

            System.assertNotEquals(null, metadata, 'Metadata for stage ' + i + ' should not be null');
            System.assertEquals(i, metadata.stageNumber, 'Stage number should match');
            System.assertNotEquals(null, metadata.stageName, 'Stage name should not be null');
            System.assertNotEquals(null, metadata.description, 'Description should not be null');
            System.assert(metadata.stageName.length() > 0, 'Stage name should not be empty');
            System.assert(metadata.description.length() > 0, 'Description should not be empty');
        }

        Test.stopTest();
    }

    /**
     * @description Test getting stage metadata for stage 1
     */
    @IsTest
    static void testGetStageMetadata_Stage1() {
        Test.startTest();
        StageFactory.StageMetadata metadata = StageFactory.getStageMetadata(1);
        Test.stopTest();

        System.assertEquals(1, metadata.stageNumber, 'Stage number should be 1');
        System.assertEquals('Requirement Understanding', metadata.stageName,
            'Stage name should match');
        System.assert(metadata.description.contains('requirements'),
            'Description should mention requirements');
    }

    /**
     * @description Test getting stage metadata for invalid stage number
     */
    @IsTest
    static void testGetStageMetadata_InvalidStageNumber() {
        Test.startTest();
        StageFactory.StageMetadata metadata = StageFactory.getStageMetadata(0);
        Test.stopTest();

        System.assertEquals(null, metadata, 'Should return null for invalid stage number');
    }

    /**
     * @description Test getting all stage metadata
     */
    @IsTest
    static void testGetAllStageMetadata() {
        Test.startTest();
        List<StageFactory.StageMetadata> allMetadata = StageFactory.getAllStageMetadata();
        Test.stopTest();

        System.assertEquals(12, allMetadata.size(), 'Should return metadata for all 12 stages');

        // Verify all stage numbers are present and sequential
        for (Integer i = 0; i < 12; i++) {
            System.assertEquals(i + 1, allMetadata[i].stageNumber,
                'Stage numbers should be sequential');
        }
    }

    /**
     * @description Test is valid stage number - valid cases
     */
    @IsTest
    static void testIsValidStageNumber_Valid() {
        Test.startTest();

        for (Integer i = 1; i <= 12; i++) {
            Boolean isValid = StageFactory.isValidStageNumber(i);
            System.assertEquals(true, isValid, 'Stage ' + i + ' should be valid');
        }

        Test.stopTest();
    }

    /**
     * @description Test is valid stage number - invalid cases
     */
    @IsTest
    static void testIsValidStageNumber_Invalid() {
        Test.startTest();

        System.assertEquals(false, StageFactory.isValidStageNumber(null),
            'Null should be invalid');
        System.assertEquals(false, StageFactory.isValidStageNumber(0),
            '0 should be invalid');
        System.assertEquals(false, StageFactory.isValidStageNumber(-1),
            '-1 should be invalid');
        System.assertEquals(false, StageFactory.isValidStageNumber(13),
            '13 should be invalid');
        System.assertEquals(false, StageFactory.isValidStageNumber(100),
            '100 should be invalid');

        Test.stopTest();
    }

    /**
     * @description Test get next stage number - middle stages
     */
    @IsTest
    static void testGetNextStageNumber_MiddleStages() {
        Test.startTest();

        for (Integer i = 1; i < 12; i++) {
            Integer nextStage = StageFactory.getNextStageNumber(i);
            System.assertEquals(i + 1, nextStage,
                'Next stage after ' + i + ' should be ' + (i + 1));
        }

        Test.stopTest();
    }

    /**
     * @description Test get next stage number - last stage
     */
    @IsTest
    static void testGetNextStageNumber_LastStage() {
        Test.startTest();
        Integer nextStage = StageFactory.getNextStageNumber(12);
        Test.stopTest();

        System.assertEquals(null, nextStage, 'Next stage after 12 should be null');
    }

    /**
     * @description Test get next stage number - null input
     */
    @IsTest
    static void testGetNextStageNumber_NullInput() {
        Test.startTest();
        Integer nextStage = StageFactory.getNextStageNumber(null);
        Test.stopTest();

        System.assertEquals(null, nextStage, 'Next stage for null should be null');
    }

    /**
     * @description Test get previous stage number - middle stages
     */
    @IsTest
    static void testGetPreviousStageNumber_MiddleStages() {
        Test.startTest();

        for (Integer i = 2; i <= 12; i++) {
            Integer prevStage = StageFactory.getPreviousStageNumber(i);
            System.assertEquals(i - 1, prevStage,
                'Previous stage before ' + i + ' should be ' + (i - 1));
        }

        Test.stopTest();
    }

    /**
     * @description Test get previous stage number - first stage
     */
    @IsTest
    static void testGetPreviousStageNumber_FirstStage() {
        Test.startTest();
        Integer prevStage = StageFactory.getPreviousStageNumber(1);
        Test.stopTest();

        System.assertEquals(null, prevStage, 'Previous stage before 1 should be null');
    }

    /**
     * @description Test get previous stage number - null input
     */
    @IsTest
    static void testGetPreviousStageNumber_NullInput() {
        Test.startTest();
        Integer prevStage = StageFactory.getPreviousStageNumber(null);
        Test.stopTest();

        System.assertEquals(null, prevStage, 'Previous stage for null should be null');
    }

    /**
     * @description Test StageMetadata constructor
     */
    @IsTest
    static void testStageMetadata_Constructor() {
        Test.startTest();
        StageFactory.StageMetadata metadata = new StageFactory.StageMetadata(
            1, 'Test Stage', 'Test Description'
        );
        Test.stopTest();

        System.assertEquals(1, metadata.stageNumber, 'Stage number should be set');
        System.assertEquals('Test Stage', metadata.stageName, 'Stage name should be set');
        System.assertEquals('Test Description', metadata.description, 'Description should be set');
    }

    /**
     * @description Test StageMetadata is AuraEnabled
     */
    @IsTest
    static void testStageMetadata_AuraEnabled() {
        Test.startTest();
        StageFactory.StageMetadata metadata = StageFactory.getStageMetadata(1);
        String jsonString = JSON.serialize(metadata);
        Test.stopTest();

        System.assertNotEquals(null, jsonString, 'Should be serializable to JSON');
        System.assert(jsonString.contains('stageNumber'), 'JSON should contain stageNumber');
        System.assert(jsonString.contains('stageName'), 'JSON should contain stageName');
        System.assert(jsonString.contains('description'), 'JSON should contain description');
    }

    /**
     * @description Test stage instantiation for bulk operations
     */
    @IsTest
    static void testGetStage_BulkOperations() {
        Test.startTest();

        // Test creating multiple stage instances
        List<IStage> stages = new List<IStage>();
        for (Integer i = 1; i <= 12; i++) {
            for (Integer j = 0; j < 20; j++) {
                stages.add(StageFactory.getStage(i));
            }
        }

        Test.stopTest();

        System.assertEquals(240, stages.size(), 'Should create 240 stage instances (12 x 20)');
    }

    /**
     * @description Test exception type is correct
     */
    @IsTest
    static void testStageFactoryException_Type() {
        Boolean correctExceptionType = false;

        Test.startTest();
        try {
            throw new StageFactory.StageFactoryException('Test exception');
        } catch (StageFactory.StageFactoryException e) {
            correctExceptionType = true;
            System.assertEquals('Test exception', e.getMessage(),
                'Exception message should be preserved');
        } catch (Exception e) {
            correctExceptionType = false;
        }
        Test.stopTest();

        System.assert(correctExceptionType, 'Should throw StageFactoryException type');
    }

    /**
     * @description Test negative stage numbers
     */
    @IsTest
    static void testGetStage_NegativeStageNumbers() {
        List<Integer> negativeNumbers = new List<Integer>{-1, -5, -100};

        Test.startTest();
        for (Integer stageNum : negativeNumbers) {
            Boolean exceptionThrown = false;
            try {
                IStage stage = StageFactory.getStage(stageNum);
            } catch (StageFactory.StageFactoryException e) {
                exceptionThrown = true;
            }
            System.assert(exceptionThrown,
                'Should throw exception for negative stage number: ' + stageNum);
        }
        Test.stopTest();
    }
}