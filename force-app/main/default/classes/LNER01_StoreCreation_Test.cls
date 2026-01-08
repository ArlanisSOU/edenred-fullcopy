@isTest
public class LNER01_StoreCreation_Test {

        @isTest static void testMagicStoreController() {
        
        //getAccount    
        Account testAccount = new Account();
 		testAccount.Name='Test Account' ;
 		insert testAccount;
            
        Account newAccount = LNER01_StoreCreation.getAccountWS(testAccount.Id);
        System.assertEquals('Test Account', newAccount.Name);
            
        //saveStoreFromAccount    
        ER_Store__c testErStore = new ER_Store__c();
        testErStore.ER_Merchant__c = newAccount.Id; 
        testErStore.Name = 'Test Store';
            
        ER_Store__c newErStore = LNER01_StoreCreation.saveStoreWS(testErStore, newAccount.Id);
        System.assertEquals('Test Store',newErStore.Name);
    }
}