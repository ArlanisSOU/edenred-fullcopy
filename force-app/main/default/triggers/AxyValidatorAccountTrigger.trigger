trigger AxyValidatorAccountTrigger on Account (before insert, before update){
	try{
		axyvalidator.ValidatorTriggerHandler.run(Trigger.new);
	}catch(Exception e){}
}