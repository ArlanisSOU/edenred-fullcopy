@isTest
public class LeadTriggerHandlerTest {
    @isTest
    public static void setEmailHeaderTest() {
        List<Lead> newLeads = new List<Lead>();
        for(Integer i = 0; i < 10; i++) {
            Lead l = new Lead(LeadSource = 'Pay per lead',
                              FirstName = 'Test',
                              LastName = 'Lead',
                              Email = 'test.email@edenred.com',
                              Company = 'Test company'
                             );
            newLeads.add(l);
        }
        insert newLeads;
    }
}