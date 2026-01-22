public without sharing class BuilderDiagnostic {
    public class DiagnosticResult {
        public Integer totalBuilders;
        public Integer qualityRules;
        public Integer patterns;
        public Integer uiComponents;
        public Integer contextTemplates;
        public List<String> builderNames;
        public String error;
    }

    public static DiagnosticResult runTest() {
        DiagnosticResult res = new DiagnosticResult();
        res.builderNames = new List<String>();
        try {
            List<ccai__AI_Prompt__c> allBuilders = [
                SELECT Id, Name, Category__c, RecordType.DeveloperName 
                FROM ccai__AI_Prompt__c 
                WHERE RecordType.DeveloperName = 'Builder'
                AND ccai__Status__c = 'Active'
            ];
            
            res.totalBuilders = allBuilders.size();
            res.qualityRules = 0;
            res.patterns = 0;
            res.uiComponents = 0;
            res.contextTemplates = 0;
            
            for (ccai__AI_Prompt__c p : allBuilders) {
                res.builderNames.add(p.Name + ' [' + p.Category__c + ']');
                if (p.Category__c == 'Quality Rule') res.qualityRules++;
                else if (p.Category__c == 'Pattern') res.patterns++;
                else if (p.Category__c == 'UI Component') res.uiComponents++;
                else if (p.Category__c == 'Context Template') res.contextTemplates++;
            }
        } catch (Exception e) {
            res.error = e.getMessage() + ' | ' + e.getStackTraceString();
        }
        return res;
    }
}
