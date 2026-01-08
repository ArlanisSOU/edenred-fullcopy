trigger TRAT06_Lead on Lead (before insert, after insert) {
	 if (trigger.isAfter && trigger.isInsert) { 
        LeadTriggerHandler.setEmailHeader(trigger.new);
    } 
}