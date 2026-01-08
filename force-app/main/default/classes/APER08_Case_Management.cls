public class APER08_Case_Management {
    
    
    Public Static List<SelectOption> GetEmployeeCaseOptions(String Employee){ 
        System.debug('GetEmployeeCaseOptions Employee : '+Employee);
        List<SelectOption> caseOptions = new List<SelectOption>();
        caseOptions.add(new SelectOption('','--'+Label.LAB_SF_None+'--'));
        
        if(String.isNotBlank(Employee)){
            List<Case> cases = GetEmployeeCases(Employee);
            System.debug('GetEmployeeCaseOptions cases : '+cases);
            if(!cases.isEmpty()){
                for(Case c:cases){
                    caseOptions.add(new SelectOption(c.Id+'',c.CaseNumber+ (String.isBlank(c.Reason)? '' : ' - '+c.Reason) )); 
                }
            }
        }
        
        return caseOptions;
    }
    
    Public Static List<Case> GetEmployeeCases(String Employee){  
        System.debug('GetEmployeeCases Employee : '+Employee);
        if(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT') != null){
            
            String RecordtypeId= Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId();
            string query ='SELECT Id,CaseNumber,toLabel(Reason) '
                + ' FROM Case'
                + ' WHERE ER_Employee__c = \'' + Employee +'\''
                + ' AND isclosed= false and recordtypeid = \''+RecordtypeId+'\' order by CaseNumber desc';
            
            return (List<Case>)Database.query(query);
        }
        
        return new List<Case>();
    }
    
    Public Static Case CreateCase(String reason, String detailedReason, String assetID){
        
        Case newCase = new Case();
        newCase.AssetId = assetID;
        newCase.RecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId();
        newCase.Reason = reason;
        newCase.ER_CaseReason2__c = detailedReason;
        insert newCase;
        
        return newCase;
    }
}