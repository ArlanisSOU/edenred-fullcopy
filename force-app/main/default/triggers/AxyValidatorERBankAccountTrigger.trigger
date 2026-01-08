trigger AxyValidatorERBankAccountTrigger on ER_Bank_Account__c (before insert, before update){
	try{
		axyvalidator.ValidatorTriggerHandler.run(Trigger.new);
	}catch(Exception e){}
}