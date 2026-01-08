public class LeadTriggerHandler {
    public static void setEmailHeader(List<Lead> newLeads) {
        List<Lead> newlyInsertedLeads = [SELECT Id From Lead WHERE Id IN :newLeads]; 
        Database.DMLOptions autoResponseOptions = new Database.DMLOptions();
         autoResponseOptions.EmailHeader.triggerUserEmail = true; 
        for (Lead l : newlyInsertedLeads ) { 
            Database.update(l, autoResponseOptions); 
        } 
    }
}