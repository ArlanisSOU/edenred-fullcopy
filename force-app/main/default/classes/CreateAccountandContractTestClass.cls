@isTest
public class CreateAccountandContractTestClass {
  static testMethod void CreateAccountandContract(){
                //Create an Account
        Account a = new Account(Name='Test Account', OwnerId ='0050Y000001IPL8', Inactive_Reason__c = 'Mitbewerber');
        System.debug('Name before inserting new account: ' + a.Name);
                //Insert Account
        insert a;
                //Create an active contract
                ER_Contract__c z = new ER_Contract__c(Account_Name__c=a.Id, Contract_Start_Date__c  = system.TODAY()-10);
                insert z;
                //Create a second inactive contract
                ER_Contract__c y = new ER_Contract__c(Account_Name__c=a.Id, Contract_Start_Date__c   = system.TODAY()-10, Contract_end_date__c = system.today()-9);
                //insert y;
                //Change active contract to inactive
                z.Contract_end_date__c = system.TODAY()-1;
                            update z;
                }
                }