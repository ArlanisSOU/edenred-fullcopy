@isTest
public class UpdateAccountStatusTEST {
    
    static testMethod void CreateAccountandContract()
    {
        //Create an Account
        Account rowAcc = new Account(Name='Test Account', OwnerId ='0050Y000001IPL8', Inactive_Reason__c = 'Mitbewerber');  
        System.debug('**1** New Account : ' + rowAcc.Name);
        //Insert Account
        insert rowAcc;
                
        //Create an active contract
         ER_Contract__c rowCtrActive = new ER_Contract__c(Account_Name__c = rowAcc.Id, Contract_Start_Date__c = system.TODAY()-10);
        insert rowCtrActive;
        
        //Create a second inactive contract
        ER_Contract__c rowCtrInactive = new ER_Contract__c(Account_Name__c = rowAcc.Id, Contract_Start_Date__c = system.TODAY()-10, Contract_end_date__c = system.today()-9);
        //insert rowCtrInactive;
        
        //END DATE !!!
       rowCtrActive.Contract_end_date__c = system.TODAY() - 1;
        update rowCtrActive;
        
        
        //CLOSE DATE !!!
        rowCtrActive.Contract_Close_Date__c = system.TODAY() + 10;
       update rowCtrActive;
        
        System.debug('**2** Ctr Close Date : ' + rowCtrActive.Contract_Close_Date__c);
        
        if(rowCtrActive.Contract_Close_Date__c >= system.TODAY()) {

        System.debug('**3** Account ID in CTR: ' + rowCtrActive.Account_Name__c);
            
       Account accountRow = [SELECT Id, Name, Status__c FROM Account WHERE Id = :rowCtrActive.Account_Name__c limit 1]; 
       accountRow.Status__c = 'Active'; 
        update accountRow;
        }//if date
     }   
}