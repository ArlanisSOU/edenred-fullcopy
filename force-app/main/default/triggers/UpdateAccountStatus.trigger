trigger UpdateAccountStatus on ER_Contract__c (after insert, after update) {
 
  for(ER_Contract__c rowCtr : Trigger.new ) {
        
   String rowAccId = rowCtr.Account_Name__c; 
        
    if(rowCtr.Contract_Close_Date__c >= System.today())
     {         
     Account accountRow = [SELECT Id, Name, Status__c FROM Account WHERE Id = :rowAccId limit 1]; 
      accountRow.Status__c = 'Active'; 
      update accountRow;     
      }  
        
    }//End for
 }