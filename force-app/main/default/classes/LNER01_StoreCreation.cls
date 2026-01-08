//MagicStoreController
public with sharing class LNER01_StoreCreation {

    @AuraEnabled
    public static Account getAccountWS(Id accId) {
        return [SELECT Name, BillingStreet, BillingPostalCode, BillingCity FROM Account WHERE Id = :accId];
    }
    
    @AuraEnabled
    //ER_Store__c
    public static ER_Store__c saveStoreWS(ER_Store__c erStore, Id accId) {
        
        erStore.ER_Merchant__c = accId;
        upsert erStore;
        //return erStore.Id;
        return erStore;
    }
}