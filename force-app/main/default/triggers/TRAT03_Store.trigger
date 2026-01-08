// Business logic:
// 1. Create Store Authorization for newly created store

trigger TRAT03_Store on ER_Store__c (after insert) {
    System.Debug('>>>   TRIGGER    ER_Store__c.TRAT03Store Start');

    Set<Id> stores = Trigger.newMap.keySet();   
    if (stores.size() > 0) {
        APAT01_ToolkitAT.StoreAuth_ByStoreHandler(stores);
    }

     System.Debug('<<<   TRIGGER   ER_Store__c.TRAT03Store End');
     
}