// Business logic:
// 1. Update ER_Store__c.AT_Accept_Payment__c

trigger TRAT04_AcceptorAfter on ER_Acceptor__c (after insert, after update, before delete) {
    System.Debug('>>>   TRIGGER    ER_Acceptor__c.TRAT04_AcceptorAfter Start');

    List<ER_Acceptor__c> trgRows;
    Map<Id,Integer> acceptorsCount = new Map<Id,Integer>();

    if(Trigger.isDelete) {
            trgRows = Trigger.old;
    }
    else
        trgRows = Trigger.new;

    // count Active acceptors per StoreId
    // relevant to set correct status after deletion
    for (ER_Acceptor__c  row : trgRows) {
        if (row.AT_Acceptor_Status__c == 'Active') {
            if (acceptorsCount.get(row.ER_Store__c) == NULL) {
                acceptorsCount.put(row.ER_Store__c, 1);
            } else {
                acceptorsCount.put(row.ER_Store__c, acceptorsCount.get(row.ER_Store__c)  + 1);
            }
        } // if Acceptor is active
    } // for stores


    List<ER_Store__c> lstStores = [SELECT Id, AT_Accepts_Payment__c, (SELECT Id, AT_Acceptor_Status__c FROM Acceptors__r WHERE AT_Acceptor_Status__c='Active') FROM ER_Store__c WHERE ID IN (SELECT ER_Store__c FROM ER_Acceptor__c WHERE ID in :trgRows)];
   

    for(ER_Store__C store : lstStores) {
        System.debug(' --- Processing Store: ' + store + '  |  Related Acceptor: ' + store.Acceptors__r);

        // TODO: Add support for Active and Inactive ER_Acceptor__c.AT_Acceptor_Status__c
        string newStatus;

        // Set stauts = Voucher+Card if store is 'Voucher only' and has at least 1 acceptor (with or without MID)
        if(store.AT_Accepts_Payment__c == 'Voucher only' &&  store.Acceptors__r.Size() > 0 ){
            newStatus= 'Voucher+Card';
        } 

        // set status = 'Voucher only' if it's now 'Voucher+Card' there is  no Acceptors or the last acceptor is just now deleted.
        if(store.AT_Accepts_Payment__c == 'Voucher+Card' &&  (store.Acceptors__r.Size() == 0 || ( store.Acceptors__r.Size() == acceptorsCount.get(store.Id) && Trigger.isDelete == True ) ) ){
            newStatus = 'Voucher only';
        } 

        // in case AT_Acceptos_Payment is not mandatory, set it as Card only
        if( (store.AT_Accepts_Payment__c == '' ||  store.AT_Accepts_Payment__c == 'None') &&  store.Acceptors__r.Size() > 0){
            newStatus= 'Card only';
        } 
        
        if( store.AT_Accepts_Payment__c == 'Card only'  &&  (store.Acceptors__r.Size() == 0 || ( store.Acceptors__r.Size() == acceptorsCount.get(store.Id)  && Trigger.isDelete == True ) )){
            newStatus= 'None';  
            //newStatus= NULL;
        } 
        

        if (newStatus != NULL) {
            System.Debug(' --- Store AT_Accepts_Payment__c changed: ' +  store.AT_Accepts_Payment__c + ' => ' + newStatus);
            store.AT_Accepts_Payment__c = newStatus;
       // } else {
       //     System.Debug(' --- no status change - keeping oryginal value  to: ' + store.AT_Accepts_Payment__c);
        }
        

    }
    update lstStores;

    System.Debug('<<<   TRIGGER   ER_Acceptor__cs.TRAT04_AcceptorAfter End');
     
}