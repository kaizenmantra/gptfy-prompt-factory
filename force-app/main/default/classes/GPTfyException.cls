public with sharing class GPTfyException extends Exception {

    public static void Log(Exception excp , String applicationName , String moduleName , String className , String methodName,String supportData){
        
        String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
        String dmlLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
        String dmlStat = '3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();
        String cpuUsage = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
        
        List<String> lstSalesforceLimit = new List<String>();
        lstSalesforceLimit.add(queryLimit);
        lstSalesforceLimit.add(dmlLimit);
        lstSalesforceLimit.add(dmlStat);
        lstSalesforceLimit.add(cpuUsage);
        
        
        // Fallback to debug logging since Exception_Log__c is missing or managed
        System.debug(LoggingLevel.ERROR, 'GPTfyException: ' + applicationName + ' - ' + className + '.' + methodName);
        if (excp != null) {
            System.debug(LoggingLevel.ERROR, 'Message: ' + excp.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + excp.getStackTraceString());
        }
        System.debug(LoggingLevel.ERROR, 'Limits: ' + String.format('{0}\n{1}\n{2}\n{3}', lstSalesforceLimit));
        System.debug(LoggingLevel.ERROR, 'Support Data: ' + supportData);
    }
}