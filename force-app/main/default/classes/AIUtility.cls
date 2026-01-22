public with sharing class AIUtility {
    
	
    @AuraEnabled
    public static Map<String, Object> getCustomSettings(){
        Map<String, Object> returnMap = new Map<String, Object>();
        // Hardcoded defaults since GPTfy_Settings__c is missing
        returnMap.put('typeEffect', false); 
        returnMap.put('fileProcessing', false);
        returnMap.put('prefixSuffix', false);
        returnMap.put('enableExceptionLog', true); // Enable logging to debug input issues
        returnMap.put('enablePromptVersion', false);
        returnMap.put('fileType', null);
        returnMap.put('maxFileSize', null);
        returnMap.put('maxFileCount', null);
        returnMap.put('reportingPeriod', null);
        returnMap.put('hourlyCost', null);
        returnMap.put('additionalInstructions', null);
        return returnMap;
    } 
    
    @AuraEnabled
    public static void updateCustomSettings(String fieldName, Boolean value){
        System.debug(LoggingLevel.INFO, 'Mock updateCustomSettings: ' + fieldName + ' = ' + value);
    }
    
    @AuraEnabled
    public static void updateGPTfySettings(String fieldName, Object value){
        System.debug(LoggingLevel.INFO, 'Mock updateGPTfySettings: ' + fieldName + ' = ' + value);
    }
    
    /*
     * This method is use for handle where clause condition.
     * @params: 
     * whereClause : use for user input whereclause on record.
     * defaultOrderBy : set default order by field on whereClause.
     * defaultLimit : set default limit on whereClause.
     * isValidating : use for where clause validating with limit 0.
     * @return : The correct where clause condition.
     */
    public static String getFormattedWhereClause(String whereClause, String defaultOrderBy, Integer defaultLimit, Boolean isValidating){
        String formattedWhereClause = ' WHERE Id != NULL ';
        if(String.isBlank(whereClause)){
            formattedWhereClause = '';
        }
        
        if(String.isNotBlank(whereClause)){
            whereClause = whereClause.trim();
            if(whereClause.startsWithIgnoreCase('ORDER BY ') || whereClause.startsWithIgnoreCase('LIMIT ')){
            	formattedWhereClause += whereClause;
            }else{
                formattedWhereClause += ' AND '+whereClause;
            }
        }

        if(formattedWhereClause.indexOf('ORDER BY') != -1){
            //do-nothing
        }else{
            if(String.isNotBlank(defaultOrderBy)){
                if(formattedWhereClause.indexOfIgnoreCase('LIMIT ') != -1){
                    Integer index = formattedWhereClause.indexOfIgnoreCase('LIMIT ');
                    if(index > -1){
                        String temp1 = formattedWhereClause.substring(0, index);
                        String temp2 = formattedWhereClause.substring(index);
                        formattedWhereClause = temp1+defaultOrderBy+temp2;
                    }
                }else{
                    formattedWhereClause += defaultOrderBy;
                }
            }
        }
        
        if(formattedWhereClause.indexOfIgnoreCase('LIMIT ') != -1){
            //do-nothing
        }else{
            if(defaultLimit != null){
            	formattedWhereClause += ' LIMIT '+defaultLimit;
            }
        }
        
        if(isValidating){
            if(formattedWhereClause.indexOfIgnoreCase('LIMIT ') != -1){
                Integer index = formattedWhereClause.lastIndexOfIgnoreCase('LIMIT ');
                if(index > -1){
                    formattedWhereClause = formattedWhereClause.substring(0, index);
                }
            }
            formattedWhereClause += ' LIMIT 0 ';
        }  
        if(!String.isBlank(formattedWhereClause)){
            formattedWhereClause = formattedWhereClause.replace('\\\'', '\'');                                                         
            Pattern regex = Pattern.compile('\\b\\w*\'\\w*\\b'); 
            Matcher matcher = regex.matcher(formattedWhereClause);
            while (matcher.find()) {
                formattedWhereClause = formattedWhereClause.replace(matcher.group(0), matcher.group(0).replace('\'', '\\\''));
            }
        }
        return formattedWhereClause;
    }
    
}