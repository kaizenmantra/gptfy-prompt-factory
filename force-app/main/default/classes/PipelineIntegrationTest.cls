/**
 * @description Integration test for Prompt Factory pipeline (Stages 1-9)
 * Tests that pipeline creates valid DCM and Prompt with merge fields
 * Does NOT test GPTfy execution (Stage 10-12) - use Python script for that
 *
 * Golden Test Account: 001QH000024mdDnYAI (TESTDATA_Pinnacle Wealth Partners)
 * Baseline established: 2026-01-24 (see temp/task-5.10-complete.md)
 *
 * Strategy:
 * - Start pipeline, let it run as far as it can
 * - Check if DCM and Prompt were created
 * - Validate their structure and quality
 * - Don't care if Stage 10+ fails (that's tested separately)
 */
@isTest
public class PipelineIntegrationTest {

    // Golden test account created via external data generation
    private static final Id GOLDEN_ACCOUNT_ID = '001QH000024mdDnYAI';
    private static final String GOLDEN_ACCOUNT_NAME = 'TESTDATA_Pinnacle Wealth Partners';

    /**
     * @description Main integration test: Run pipeline and validate DCM + Prompt creation
     * Uses SeeAllData=true to access golden test accounts created externally
     */
    @isTest(SeeAllData=true)
    static void testPipeline_CreatesDCMAndPrompt() {
        // GIVEN: Golden test account exists
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id = :GOLDEN_ACCOUNT_ID LIMIT 1];
        if (accounts.isEmpty()) {
            System.assert(false, 'Golden test account ' + GOLDEN_ACCOUNT_ID + ' does not exist. Create it first.');
            return;
        }

        // WHEN: Pipeline runs
        Id runId;
        try {
            runId = PromptFactoryController.startPipelineRun(
                'Integration Test - Account 360',
                'Account',
                GOLDEN_ACCOUNT_ID,
                'Analyze this wealth management firm for account health, opportunity pipeline, support issues, and engagement.',
                'Narrative',
                'a01gD000003okzEQAQ', // GPTfy OpenAI connection
                'https://pinnaclewealth.example.com'
            );
        } catch (Exception e) {
            System.assert(false, 'Failed to start pipeline: ' + e.getMessage());
            return;
        }

        System.assertNotEquals(null, runId, 'Pipeline run should be created');

        // Let pipeline run as far as it can (may hit recursion limit, that's OK)
        Test.startTest();
        Test.stopTest();

        // THEN: Validate outputs were created
        PF_Run__c run = [
            SELECT Id, Name, Status__c, Current_Stage__c, Error_Message__c
            FROM PF_Run__c
            WHERE Id = :runId
        ];

        System.debug('Pipeline reached stage: ' + run.Current_Stage__c + ', Status: ' + run.Status__c);

        // Try to find created DCM and Prompt
        List<ccai__AI_Data_Extraction_Mapping__c> dcms = [
            SELECT Id, Name, ccai__Object_Name__c
            FROM ccai__AI_Data_Extraction_Mapping__c
            WHERE Name LIKE '%Integration Test%'
            AND CreatedDate = TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        List<ccai__AI_Prompt__c> prompts = [
            SELECT Id, Name, ccai__Prompt_Command__c, ccai__Description__c, ccai__How_it_works__c
            FROM ccai__AI_Prompt__c
            WHERE Name LIKE '%Integration Test%'
            AND CreatedDate = TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        // If we got DCM and Prompt, validate them
        // If not, fail with helpful diagnostic
        if (dcms.isEmpty() || prompts.isEmpty()) {
            String diagnostic = 'Pipeline did not create DCM and/or Prompt.\n';
            diagnostic += 'Current Stage: ' + run.Current_Stage__c + '\n';
            diagnostic += 'Status: ' + run.Status__c + '\n';
            diagnostic += 'Error: ' + run.Error_Message__c + '\n';
            diagnostic += 'DCM Created: ' + !dcms.isEmpty() + '\n';
            diagnostic += 'Prompt Created: ' + !prompts.isEmpty() + '\n';
            diagnostic += '\nExpected: Stage 9 completion with DCM and Prompt created.';
            System.assert(false, diagnostic);
            return;
        }

        // SUCCESS - Both DCM and Prompt created, now validate quality
        validateDCMStructure(dcms[0]);
        validatePromptTemplate(prompts[0]);
    }

    /**
     * @description Validate DCM structure matches baseline expectations
     */
    private static void validateDCMStructure(ccai__AI_Data_Extraction_Mapping__c dcm) {
        System.assertEquals('Account', dcm.ccai__Object_Name__c,
            'Root object should be Account');

        // Validate Detail records (child/grandchild objects)
        List<ccai__AI_Data_Extraction_Detail__c> details = [
            SELECT Id, ccai__Object_Name__c, ccai__RelationshipName__c, ccai__Type__c
            FROM ccai__AI_Data_Extraction_Detail__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcm.Id
        ];

        System.assert(details.size() >= 5,
            'Should have at least 5 child objects. Found: ' + details.size());
        System.assert(details.size() <= 10,
            'Should have at most 10 child objects. Found: ' + details.size());

        // Verify at least one grandchild object exists (OpportunityContactRole expected)
        Integer grandchildCount = 0;
        Set<String> childObjects = new Set<String>();

        for (ccai__AI_Data_Extraction_Detail__c detail : details) {
            if (detail.ccai__Type__c == 'CHILD') {
                childObjects.add(detail.ccai__Object_Name__c);
            } else if (detail.ccai__Type__c == 'GRANDCHILD') {
                grandchildCount++;
            }
        }

        System.assert(grandchildCount >= 1,
            'Should have at least 1 grandchild object (e.g., OpportunityContactRole, CaseComment)');

        // Verify expected child objects are present
        System.assert(childObjects.contains('Opportunity') || childObjects.contains('Opportunities'),
            'Should include Opportunity child object');

        // Validate Field records
        Integer fieldCount = [
            SELECT COUNT()
            FROM ccai__AI_Data_Extraction_Field__c
            WHERE ccai__AI_Data_Extraction_Mapping__c = :dcm.Id
        ];

        System.assert(fieldCount >= 40,
            'Should have at least 40 fields selected. Found: ' + fieldCount);
        System.assert(fieldCount <= 150,
            'Should have at most 150 fields selected. Found: ' + fieldCount);

        System.debug('✅ DCM Validation Passed: ' + details.size() + ' details, ' + fieldCount + ' fields');
    }

    /**
     * @description Validate Prompt template quality (merge fields, no hardcoded values)
     */
    private static void validatePromptTemplate(ccai__AI_Prompt__c prompt) {
        String template = prompt.ccai__Prompt_Command__c;
        System.assertNotEquals(null, template, 'Prompt template should not be null');
        System.assert(template.length() > 1000,
            'Prompt template should be substantial (>1000 chars). Found: ' + template.length());

        // Validate merge field syntax
        System.assert(template.contains('{{{') && template.contains('}}}'),
            'Template should contain merge field syntax {{{ }}}');

        // Validate iteration blocks
        System.assert(template.contains('{{#') && template.contains('{{/'),
            'Template should contain iteration blocks {{# }} and {{/ }}');

        // Validate NO hardcoded values from sample data
        List<String> hardcodedValues = new List<String>{
            'Pinnacle Wealth',
            'TESTDATA_',
            'Sarah Chen',
            'Michael Rodriguez',
            'Jennifer Park'
        };

        for (String hardcoded : hardcodedValues) {
            System.assert(!template.contains(hardcoded),
                'Template should NOT contain hardcoded value: ' + hardcoded);
        }

        // Validate parent lookup fields are present (best practice for relationships)
        Boolean hasParentLookup =
            template.contains('Contact.Name') ||
            template.contains('Owner.Name') ||
            template.contains('.Name') ||
            template.contains('.Email');

        System.assert(hasParentLookup,
            'Template should include parent lookup fields (e.g., Contact.Name, Owner.Name)');

        // Count merge fields and iteration blocks
        Integer mergeFieldCount = template.countMatches('{{{');
        Integer iterationCount = template.countMatches('{{#');

        System.assert(mergeFieldCount >= 50,
            'Template should have at least 50 merge fields. Found: ' + mergeFieldCount);
        System.assert(iterationCount >= 3,
            'Template should have at least 3 iteration blocks. Found: ' + iterationCount);

        System.debug('✅ Prompt Validation Passed: ' + template.length() + ' chars, ' +
                     mergeFieldCount + ' merge fields, ' + iterationCount + ' iteration blocks');
    }

    /**
     * @description Test that pipeline handles missing required fields gracefully
     */
    @isTest
    static void testPipeline_ValidatesRequiredFields() {
        // GIVEN: Invalid inputs
        String missingRootObject = null;
        String missingContext = null;

        // WHEN: Try to start pipeline without required fields
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        try {
            PromptFactoryController.startPipelineRun(
                'Test',
                missingRootObject, // NULL
                '001000000000000',
                missingContext, // NULL
                'Narrative',
                'a01gD000003okzEQAQ',
                'https://test.com'
            );
        } catch (Exception e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }

        // THEN: Should throw validation error
        System.assert(exceptionThrown, 'Should throw exception for missing required fields');
        System.assert(exceptionMessage.toLowerCase().contains('required'),
            'Error message should mention required field: ' + exceptionMessage);
    }

    /**
     * @description Test that controller successfully creates run record
     */
    @isTest(SeeAllData=true)
    static void testPipeline_CreatesRunRecord() {
        // Skip if golden account doesn't exist
        List<Account> accounts = [SELECT Id FROM Account WHERE Id = :GOLDEN_ACCOUNT_ID LIMIT 1];
        if (accounts.isEmpty()) {
            return; // Skip test
        }

        // GIVEN: Valid inputs
        Test.startTest();

        Id runId = PromptFactoryController.startPipelineRun(
            'Minimal Test',
            'Account',
            GOLDEN_ACCOUNT_ID,
            'Basic analysis',
            'Narrative',
            null, // No AI model (will use default)
            null  // No company URL
        );

        Test.stopTest();

        // THEN: Run record should be created
        System.assertNotEquals(null, runId, 'Pipeline should create run record');

        PF_Run__c run = [
            SELECT Id, Root_Object__c, Business_Context__c, Status__c
            FROM PF_Run__c
            WHERE Id = :runId
        ];

        System.assertEquals('Account', run.Root_Object__c);
        System.assertEquals('Basic analysis', run.Business_Context__c);
        System.assertNotEquals(null, run.Status__c, 'Status should be set');
    }
}
