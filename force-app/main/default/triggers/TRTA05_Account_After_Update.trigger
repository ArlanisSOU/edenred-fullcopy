trigger TRTA05_Account_After_Update on Account (after update) {
    
//  Contact    AccountId 
List<Contact> contacts = [select Id, OwnerId, Account.OwnerId  from Contact where AccountId in : Trigger.New ];
List<Contact> contactsToUpdate = new List<Contact>();
    for(Contact o:contacts)
    {
		if(o.ownerid != o.Account.OwnerId)
       		{
            	o.ownerid = o.Account.OwnerId;
            	contactsToUpdate.add(o);
        	}
    }
if(!contactsToUpdate.isEmpty())
    {
        update contactsToUpdate;
    }    
    
//  ER_Contract__c Account_Name__c
List<ER_Contract__c> contracts = [select id, ownerId,Account_Name__r.OwnerId from ER_Contract__c where Account_Name__c in : Trigger.New ];
List<ER_Contract__c> contractsToUpdate = new List<ER_Contract__c>();
    for(ER_Contract__c ctr :contracts)
    {
	if(ctr.ownerid != ctr.Account_Name__r.OwnerId)
        {
            ctr.ownerid = ctr.Account_Name__r.OwnerId;
            contractsToUpdate.add(ctr);
        }
    }

if(!contractsToUpdate.isEmpty())
    {
        update contractsToUpdate;
    }
    
//  ER_Order__c    Account_Name__c
List<ER_Order__c> orders = [select id, ownerId,Account_Name__r.OwnerId from ER_Order__c where Account_Name__c in : Trigger.New ];
List<ER_Order__c> OrdersToUpdate = new List<ER_Order__c>();
    for(ER_Order__c o:orders)
    {
		if(o.ownerid != o.Account_Name__r.OwnerId)
       		{
            	o.ownerid = o.Account_Name__r.OwnerId;
            	OrdersToUpdate.add(o);
        	}
    }
if(!OrdersToUpdate.isEmpty())
    {
        update OrdersToUpdate;
    }
    
}