@isTest(SeeAllData=true)
private class AxyValidatorAccountTriggerTest{
	@isTest
	static void testInsert(){
		try{
			axyvalidator.ValidatorTriggerHandler.isTest = true;
			Test.startTest();
			insert new Account();
			Test.stopTest();
		}catch(Exception e){}
	}
	@isTest
	static void testUpdate(){
		Account record = [SELECT Id FROM Account ORDER BY LastModifiedDate DESC LIMIT 1]; 
		axyvalidator.ValidatorTriggerHandler.isTest = true;
		Test.startTest();
		try{
			update record;
		}catch(Exception e){}
		Test.stopTest();
	}
}