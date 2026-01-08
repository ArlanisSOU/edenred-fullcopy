@isTest
public class TRTA05_Account_After_Update_TEST {
@isTest static void UpdateAccountOwner() 
	{
    	Profile adminp = [select id from profile where Name = 'System Administrator' limit 1];    
		List<User> lstUser = new list<User>();
        User adminu = new User(alias = 'test123', email='test1234@noemail.com', lastname='Testing', emailencodingkey='ISO-8859-1',localesidkey='fr_FR_EURO', languagelocalekey='fr', profileid = adminp.Id, timezonesidkey='Europe/Paris', username='test1235334'+String.valueOf(date.today())+ '@noemail.com', street='mystree', city='mycity', postalcode='1234', country='France');
		lstUser.add(adminu);
        User adminu2 = new User(alias = 'test1234', email='test12345@noemail.com', lastname='Testing2', emailencodingkey='ISO-8859-1',localesidkey='fr_FR_EURO', languagelocalekey='fr', profileid = adminp.Id, timezonesidkey='Europe/Paris', username='test12353345'+String.valueOf(date.today())+ '@noemail.com', street='mystreee', city='mycity2', postalcode='12345', country='France');
        lstUser.add(adminu2);
        insert lstUser; 
        Account acc = new Account(ownerid=adminu.id,recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Merchant_Account_RT').getRecordTypeId(), Name = 'AccTestTRAT',Partner_Code__c='TST-XX99');
		insert acc;
        Contact ContactAcc = new Contact(ownerid=adminu.id,FirstName = 'FirstName' , LastName = 'LastName',Email ='testemail@teeeeeeest.com', Accountid = acc.id );
		insert ContactAcc;
        ER_Contract__c contracttest = new ER_Contract__c(ownerid=adminu.id,Account_Name__c  = acc.id,recordtypeid = Schema.SObjectType.ER_Contract__c.getRecordTypeInfosByDeveloperName().get('Affiliate_Contract_RT').getRecordTypeId(),Advisor__c = 'Claudia Eisl',Commission_Value__c = 5.55,Product__c = 'Ticket Restaurant',Contract_Start_Date__c = date.today()-10,Invoice_Type__c = 'Electronic',AT_Comments__c = 'Comments'); 
		insert contracttest;
        ER_Order__c Ordertest = new ER_Order__c(ownerid=adminu.id,Account_Name__c= acc.id , recordtypeid = Schema.SObjectType.ER_Order__c.getRecordTypeInfosByDeveloperName().get('Affiliate_Order_RT').getRecordTypeId());  
		insert Ordertest;
        acc.ownerid = adminu2.id;
        update acc;    
	}
}