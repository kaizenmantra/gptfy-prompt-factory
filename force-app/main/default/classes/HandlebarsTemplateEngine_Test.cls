/**
 * @description Test class for HandlebarsTemplateEngine
 */
@IsTest
private class HandlebarsTemplateEngine_Test {

    @IsTest
    static void testRender_SimpleSubstitution() {
        String template = 'Hello {{{Name}}}, welcome to {{{Company}}}!';
        Map<String, Object> data = new Map<String, Object>{
            'Name' => 'John',
            'Company' => 'Salesforce'
        };
        
        Test.startTest();
        String result = HandlebarsTemplateEngine.render(template, data);
        Test.stopTest();
        
        System.assertEquals('Hello John, welcome to Salesforce!', result);
    }

    @IsTest
    static void testRender_ParentLookup() {
        String template = 'Account: {{{Account.Name}}}, Owner: {{{Owner.Name}}}';
        Map<String, Object> data = new Map<String, Object>{
            'Account' => new Map<String, Object>{'Name' => 'Acme'},
            'Owner' => new Map<String, Object>{'Name' => 'Admin'}
        };
        
        Test.startTest();
        String result = HandlebarsTemplateEngine.render(template, data);
        Test.stopTest();
        
        System.assertEquals('Account: Acme, Owner: Admin', result);
    }

    @IsTest
    static void testRender_IterationBlock() {
        String template = 'Contacts: {{#Contacts}}{{{Contacts.FirstName}}} {{{Contacts.LastName}}}, {{/Contacts}}';
        Map<String, Object> data = new Map<String, Object>{
            'Contacts' => new List<Object>{
                new Map<String, Object>{'FirstName' => 'John', 'LastName' => 'Doe'},
                new Map<String, Object>{'FirstName' => 'Jane', 'LastName' => 'Smith'}
            }
        };
        
        Test.startTest();
        String result = HandlebarsTemplateEngine.render(template, data);
        Test.stopTest();
        
        System.assertEquals('Contacts: John Doe, Jane Smith, ', result);
    }

    @IsTest
    static void testRender_NestedIteration() {
        String template = 'Opportunities: {{#Opportunities}}{{{Opportunities.Name}}} ({{#OCR}}{{{OCR.Role}}}, {{/OCR}}), {{/Opportunities}}';
        Map<String, Object> data = new Map<String, Object>{
            'Opportunities' => new List<Object>{
                new Map<String, Object>{
                    'Name' => 'Big Deal',
                    'OCR' => new List<Object>{
                        new Map<String, Object>{'Role' => 'Decision Maker'},
                        new Map<String, Object>{'Role' => 'Influencer'}
                    }
                }
            }
        };
        
        Test.startTest();
        String result = HandlebarsTemplateEngine.render(template, data);
        Test.stopTest();
        
        System.assertEquals('Opportunities: Big Deal (Decision Maker, Influencer, ), ', result);
    }

    @IsTest
    static void testRender_NullHandling() {
        String template = 'Missing: {{{Missing}}}, Null: {{{NullValue}}}';
        Map<String, Object> data = new Map<String, Object>{
            'NullValue' => null
        };
        
        Test.startTest();
        String result = HandlebarsTemplateEngine.render(template, data);
        Test.stopTest();
        
        System.assertEquals('Missing: , Null: ', result);
    }

    @IsTest
    static void testRender_EmptyTemplate() {
        Test.startTest();
        String result = HandlebarsTemplateEngine.render('', new Map<String, Object>());
        Test.stopTest();
        
        System.assertEquals('', result);
    }
}
