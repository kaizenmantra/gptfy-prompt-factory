/**
* @description       : 
* @author            : Rishabh Goel
* @group             : Plumcloud Labs
* @last modified on  : 03-28-2023
* @last modified by  : Rishabh Goel
**/
public with sharing class CatalogController {
	
    /**
     * Retrieves a list of available catalog options for further processing or display purposes.
     * 
     * @return List<Object> A list containing various catalog options, which can be used for generating a catalog or providing options to the user.
     */
    @AuraEnabled
    public static List<Object> getCatalogOptions(){
        
        String namespace = AIExtractionFieldMappingController.NAMESPACE;
        List<AIExtractionFieldMappingController.PicklistAttributeWrapper> allOptions = AIExtractionFieldMappingController.getPickListValues(namespace+'ccai__AI_Connection__c', namespace+'AI_Technology__c');
        
        Set<String> setOfStaticResources = new Set<String>();
        for(AIExtractionFieldMappingController.PicklistAttributeWrapper opt : allOptions){
            setOfStaticResources.add(opt.value);
        }
        
        List<StaticResource> lstOfResources = [SELECT Id, Description, Name FROM StaticResource WHERE Name IN :setOfStaticResources];
        Map<String, StaticResource> mapOfNameToSR = new Map<String, StaticResource>();
        for(StaticResource sr : lstOfResources){
            mapOfNameToSR.put(sr.Name, sr);
        }
        
        Map<String, String> mapOfResNameToConnectionId = new Map<String, String>();
        List<ccai__AI_Connection__c> lstOfConnections = [SELECT Id, Name, AI_Technology__c FROM ccai__AI_Connection__c WHERE AI_Technology__c != NULL];
        for(ccai__AI_Connection__c conn : lstOfConnections){
            mapOfResNameToConnectionId.put(conn.AI_Technology__c, conn.Id);
        }

        List<Object> cardOptions = new List<Object>();
        for(AIExtractionFieldMappingController.PicklistAttributeWrapper opt : allOptions){
            String resName = opt.value;
            String resUrl = '';
            String resDesc = '';
            if(!mapOfNameToSR.isEmpty() && mapOfNameToSR.containsKey(resName)){
                resUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/resource/'+namespace+resName;
                resDesc = mapOfNameToSR.get(resName).Description;
            }
            
            String conId = '';
            if(!mapOfResNameToConnectionId.isEmpty() && mapOfResNameToConnectionId.containsKey(resName)){
                conId = mapOfResNameToConnectionId.get(resName);
            }
            
            cardOptions.add(new Map<String, String>{
                'aiLabel' => opt.label, 'aiName' => resName, 'iconUrl' => resUrl, 'aiDesc' => resDesc, 'conId' => conId
            });
        }
        return cardOptions;
    }
    
    /**
     * Retrieves a list of available catalog options for further processing or display purposes.
     * 
     * @return List<Object> A list containing various catalog options, which can be used for generating a catalog or providing options to the user.
     */
    @AuraEnabled
    public static Map<String, Object> getPurposeOptions(){
        Map<String, Object> data = new Map<String, Object>();
        
        String namespace = AIExtractionFieldMappingController.NAMESPACE;
        
        //List<AIExtractionFieldMappingController.PicklistAttributeWrapper> allOptions = AIExtractionFieldMappingController.getPickListValues(namespace+'AI_Prompt__c', namespace+'Purpose__c');
        //data.put('purposeOptions', AddCardController.getCardConfiguration('CTLOG'));
        
        Map<String, List<Object>> promptData = new Map<String, List<Object>>();
        Set<String> setOfObjNames = new Set<String>();
        List<Object> connectionOptions = new List<Object>();
        List<AI_Prompt__c> lstOfPrompts = [SELECT Id, Name, ccai__AI_Connection__c, AI_Connection__r.Name, AI_Data_Extraction_Mapping__c, 
                                           AI_Data_Extraction_Mapping__r.Name, Description__c, Object__c, Profiles__c,
                              				Purpose__c, Record_Type__c, Status__c, Visibility_Condition__c FROM AI_Prompt__c WHERE Purpose__c != NULL];
        if(lstOfPrompts != null && lstOfPrompts.size()>0){
            Set<String> activeAIModal = new Set<String>();
            for(ccai__AI_Card_Configuration__c mdt : [SELECT Id, Name FROM ccai__AI_Card_Configuration__c where Enabled__c = true LIMIT 50000]){
                activeAIModal.add(mdt.Name.toLowercase());
            }
            for(ccai__AI_Connection__c p : [SELECT Id, Name FROM ccai__AI_Connection__c  WHERE Name IN:activeAIModal ORDER BY Name LIMIT 50000]){
                Map<String, String> obj = new Map<String, String>();
               obj.put('label', p.Name);
               obj.put('value', p.Id);
               connectionOptions.add(obj);
            }
        }
        for(AI_Prompt__c pmt : lstOfPrompts){
            List<String> listOfPurposes = pmt.Purpose__c.split(';');
            
            Map<String, Object> obj = new Map<String, Object>();
            obj.put('pmtId', pmt.Id);
            obj.put('name', pmt.Name);
            obj.put('pmtUrl', '/lightning/r/'+namespace+'AI_Prompt__c/'+pmt.Id+'/view');
            obj.put('aiConnection', pmt.ccai__AI_Connection__c);
            obj.put('aiConnectionName', pmt.AI_Connection__r.Name);
            obj.put('mappingId', pmt.AI_Data_Extraction_Mapping__c);
            obj.put('mappingName', pmt.AI_Data_Extraction_Mapping__r.Name);
            obj.put('mappingUrl', '/lightning/r/'+namespace+'AI_Data_Extraction_Mapping__c/'+pmt.AI_Data_Extraction_Mapping__c+'/view');
            obj.put('description', pmt.Description__c);
            obj.put('objectName', pmt.Object__c);
            obj.put('profileNames', (pmt.Profiles__c != null ? pmt.Profiles__c.split(';') : new List<String>()));
            obj.put('recordTypes', (pmt.Record_Type__c != null ? pmt.Record_Type__c.split(';') : new List<String>()));
            obj.put('status', pmt.Status__c);
            obj.put('pickListOptions', connectionOptions);
            obj.put('visibilityCondition', pmt.Visibility_Condition__c);
            
            for(String purp : listOfPurposes){
                if(!promptData.containsKey(purp)){
                    promptData.put(purp, new List<Object>());
                }
                promptData.get(purp).add(obj);
            }
            setOfObjNames.add(pmt.Object__c);
            
        }
        data.put('promptData', promptData);
        
        Map<String, List<Object>> recTypeOptions = new Map<String, List<Object>>();
        Map<String, List<Object>> extractOptions = new Map<String, List<Object>>();
        if(!setOfObjNames.isEmpty()){
            for(RecordType p : [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SObjectType IN :setOfObjNames AND isActive = True ORDER BY Name]){
                if(!recTypeOptions.containsKey(p.SObjectType)){
                    recTypeOptions.put(p.SObjectType, new List<Object>());
                }
                recTypeOptions.get(p.SObjectType).add(new Map<String, Object>{
                    'label' => p.Name, 'value' => p.DeveloperName
                });
            }
    
            for(AI_Data_Extraction_Mapping__c p : [SELECT Id, Name, Object_Name__c FROM AI_Data_Extraction_Mapping__c WHERE Object_Name__c IN :setOfObjNames ORDER BY Name]){
                if(!extractOptions.containsKey(p.Object_Name__c)){
                    extractOptions.put(p.Object_Name__c, new List<Object>());
                }
                extractOptions.get(p.Object_Name__c).add(new Map<String, Object>{
                    'label' => p.Name, 'value' => p.Id
                });
            }

        }
        data.put('extractOptions', extractOptions);
        data.put('recTypeOptions', recTypeOptions);
        data.put('profileOptions', AIPromptController.getProfileOptions());
        
        
        return data;
    }
    
     /**
     * Updates the prompt data based on the provided list of PromptWrapper objects, allowing for the modification or addition of prompt-related information.
     * 
     * @param data A list of PromptWrapper objects containing the data to be updated for the prompt.
     */
    @AuraEnabled
    public static void updatePrompts(String jsonData){
        try{
            List<AI_Prompt__c> promptsToUpdate = new List<AI_Prompt__c>();
            List<Object> promptRecords = (List<Object>)JSON.deserializeUntyped(jsonData);
            for(Object promptData : promptRecords){
                Map<String, Object> mapData = (Map<String,Object>)promptData;
                AI_Prompt__c pmt = new AI_Prompt__c();
                pmt.Id = String.valueOf(mapData.get('pmtId'));
                pmt.Name = String.valueOf(mapData.get('name'));
                pmt.ccai__AI_Connection__c = String.valueOf(mapData.get('aiConnection'));
                pmt.Description__c = String.valueOf(mapData.get('description'));
                promptsToUpdate.add(pmt);
            }
            if(promptsToUpdate.size()>0){
                FLSCheck.getInstance().updateDML(promptsToUpdate);
            }
        }catch(DMLException dmlex){
           throw new AuraHandledException(dmlex.getDMLMessage(0));
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Updates the prompt data based on the provided list of PromptWrapper objects, allowing for the modification or addition of prompt-related information.
     * 
     * @param data A list of PromptWrapper objects containing the data to be updated for the prompt.
     */
    @AuraEnabled
    public static void updatePromptData(List<PromptWrapper> data){
        List<AI_Prompt__c> lstToUpdate = new List<AI_Prompt__c>();
        for(PromptWrapper wrap : data){
            AI_Prompt__c pmt = new AI_Prompt__c();
            pmt.Id = wrap.pmtId;
            pmt.Record_Type__c = wrap.recordTypes != null && !wrap.recordTypes.isEmpty() ? String.join(wrap.recordTypes, ';') : '';
            pmt.Profiles__c = wrap.profileNames != null && !wrap.profileNames.isEmpty() ? String.join(wrap.profileNames, ';') : '';
            pmt.Visibility_Condition__c = wrap.visibilityCondition;
            //pmt.Status__c = 'Active';
            lstToUpdate.add(pmt);
        }
        List<SObject> records = FLSCheck.getInstance().updateDML(lstToUpdate);
    }
    
    @AuraEnabled
    public static List<FieldSetWrappper> getFields(){
        String namespace = AIExtractionFieldMappingController.NAMESPACE;
        List<FieldSetWrappper> fieldData = new List<FieldSetWrappper>();
        for(Schema.FieldSetMember field : SobjectType.ccai__AI_Connection__c.FieldSets.AI_Model_Creation_Fields.getFields()){ 
            fieldData.add(new FieldSetWrappper(field, namespace));
        }
        return fieldData; 
    }
    
    public class PromptWrapper{
        @AuraEnabled public String pmtId{get;set;}
        @AuraEnabled public String visibilityCondition{get;set;}
        @AuraEnabled public List<String> profileNames{get;set;}
        @AuraEnabled public List<String> recordTypes{get;set;}
    }
    
}