@isTest(SeeAllData=true)
private class AxyValidatorERBankAccountTriggerTest{
	@isTest
	static void testInsert(){
		try{
			axyvalidator.ValidatorTriggerHandler.isTest = true;
			Test.startTest();
			insert new ER_Bank_Account__c();
			Test.stopTest();
		}catch(Exception e){}
	}
	@isTest
	static void testUpdate(){
		ER_Bank_Account__c record = [SELECT Id FROM ER_Bank_Account__c ORDER BY LastModifiedDate DESC LIMIT 1]; 
		axyvalidator.ValidatorTriggerHandler.isTest = true;
		Test.startTest();
		try{
			update record;
		}catch(Exception e){}
		Test.stopTest();
	}
}