/**
 * Verification Test: V2.5 Pipeline (Stage 8 -> Stage 9)
 */
@IsTest
private class Stage09_V25_Verification_Test {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'VusionGroup Test');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Big Deal 2.5',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Amount = 100000
        );
        insert opp;
        
        // Add Line Items (requires Pricebook)
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name = 'Smart Label', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1000,
            TotalPrice = 100000
        );
        insert oli;

        // Add Meta-Prompt Builder record for Stage 8 dependency
        Id builderRtId = Schema.SObjectType.ccai__AI_Prompt__c.getRecordTypeInfosByDeveloperName().get('Builder').getRecordTypeId();
        ccai__AI_Prompt__c metaPromptBuilder = new ccai__AI_Prompt__c(
            Name = 'GPTfy Prompt Generation Framework v2.5',
            ccai__Type__c = 'Context Template',
            ccai__Status__c = 'Active',
            ccai__Prompt_Command__c = 'Test Meta Prompt Builder',
            RecordTypeId = builderRtId
        );
        insert metaPromptBuilder;
    }

    @IsTest
    static void verifyV25MergeGate() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        
        PF_Run__c run = new PF_Run__c(
            Root_Object__c = 'Opportunity',
            Sample_Record_Id__c = opp.Id,
            Status__c = 'Queued',
            Current_Stage__c = 1
        );
        System.debug('--- PF_Run__c before insert: ' + JSON.serialize(run));
        insert run;

        // Mock AI Service
        AIServiceClient.setMockMode(true);
        // Note: Field prefixes are mandatory in V2.5 as per PROMPT_GENERATION_RULES.md
        AIServiceClient.setMockResponse('{"template": "Account: {{{Account.Name}}}, Amount: {{{Amount}}}, Items: {{#OpportunityLineItems}}{{{OpportunityLineItems.Product2.Name}}} - {{{OpportunityLineItems.TotalPrice}}}, {{/OpportunityLineItems}}"}');

        Map<String, Object> inputs = new Map<String, Object>{
            'rootObject' => 'Opportunity',
            'sampleRecordId' => opp.Id,
            'htmlTemplate' => '<div>{{{Name}}}</div>',
            'businessContext' => 'Sales summary',
            'selectedFields' => new Map<String, Object>{
                'Opportunity' => new List<String>{'Name', 'Amount', 'StageName', 'Account.Name'},
                'OpportunityLineItem' => new List<String>{'Product2.Name', 'Quantity', 'TotalPrice'}
            }
        };

        Test.startTest();
        // 1. Run Stage 8
        Stage08_PromptAssembly stage8 = new Stage08_PromptAssembly();
        StageResult result8 = stage8.execute(run.Id, inputs);
        System.assertEquals('Completed', result8.status, 'Stage 8 failed: ' + result8.errorMessage + ' | Logs: ' + JSON.serialize(result8.logs));

        // 2. Prepare Stage 9
        inputs.putAll(result8.outputs);
        Stage09_CreateAndDeploy stage9 = new Stage09_CreateAndDeploy();
        StageResult result9 = stage9.execute(run.Id, inputs);
        Test.stopTest();

        // 3. Verify Result
        Map<String, Object> finalPromptConfig = (Map<String, Object>) inputs.get('promptConfig');
        String finalPrompt = (String) finalPromptConfig.get('promptCommand');
        
        System.debug('Final Prompt: ' + finalPrompt);
        
        System.assert(finalPrompt.contains('Account: VusionGroup Test'), 'Should contain account name: ' + finalPrompt);
        System.assert(finalPrompt.contains('Amount: 100000'), 'Should contain amount: ' + finalPrompt);
        System.assert(finalPrompt.contains('Items: Smart Label - 100000.00'), 'Should contain line item: ' + finalPrompt);
        System.assert(!finalPrompt.contains('{{{'), 'Should not contain raw merge fields: ' + finalPrompt);
    }
}
