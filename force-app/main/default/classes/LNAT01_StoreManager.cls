public class LNAT01_StoreManager {
        
@AuraEnabled
    public static String deleteUnderlyingAcceptorsAndStores(Id accId) {
        try {

            deleteUnderlyingStores(accId);
            deleteUnderlyingAcceptors(accId);
            
            return 'SUCCESS';
            
        } catch (Exception e) {
            throw new AuraHandledException('Unable to delete : ' + e.getMessage());
        }
    }
    
 @AuraEnabled 
     public static String deleteUnderlyingStores(Id accId) {
        try {
            List<ER_Store__c> data = [SELECT Id FROM ER_Store__c WHERE ER_Merchant__c = :accId];
            delete data;
            return 'SUCCESS';
            
        } catch (Exception e) {
            throw new AuraHandledException('Unable to delete : ' + e.getMessage());
        }
    }
    
@AuraEnabled 
    public static String deleteUnderlyingAcceptors(Id accId) {
        try {
            List<ER_Acceptor__c> data = [SELECT Id  FROM ER_Acceptor__c WHERE ER_Store__c IN (SELECT Id FROM ER_Store__c WHERE ER_Merchant__c = :accId)];
            
			/* Comment by AAB, error : CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY*/
            /* Comment by Kamil Adamiec: Let's find the reason why it's not working in PreProd */
			delete data;
            return 'SUCCESS';
            
        } catch (Exception e) {
			AuraHandledException en = new AuraHandledException('Unable to delete : ' + e.getMessage());
			en.setMessage('Unable to delete : ' + e.getMessage());
			System.debug(e.getMessage());
			throw en;
            //throw new AuraHandledException('Unable to delete : ' + e.getMessage());
        }
    }
    
@AuraEnabled 
    public static String deleteUnderlyingStoreAuth(Id accId) {
        try {
            List<ER_Store_Authorization__c> data = [SELECT Id  FROM ER_Store_Authorization__c WHERE ER_Store__c IN (SELECT Id FROM ER_Store__c WHERE ER_Merchant__c = :accId)];
            delete data;
            return 'SUCCESS';
            
        } catch (Exception e) {
            throw new AuraHandledException('Unable to delete : ' + e.getMessage());
        }
    }
	
	


    
@AuraEnabled      
     //Counters
     public static List<Integer> GetCounters(Id accId) {       
        try {
            Integer[] Ret = new Integer[]{
                			database.countQuery('SELECT count() FROM ER_Store__c               WHERE  ER_Merchant__c=:accId'),
                			database.countQuery('SELECT count() FROM ER_Acceptor__c            WHERE ER_Store__c IN (SELECT Id FROM  ER_Store__c  WHERE ER_Merchant__c = :accId)'),
                            database.countQuery('SELECT count() FROM ER_Store_Authorization__c WHERE ER_Store__c IN (SELECT Id FROM  ER_Store__c  WHERE ER_Merchant__c = :accId)')
                			};
            return Ret;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to execute query: ' + e.getMessage());
        }
    }
    
	
@AuraEnabled 
    public static void additionalTest() {
		Account myAccount = new Account();
		
		myAccount.Name = 'my name';
		myAccount.BillingStreet = 'my street';
		myAccount.BillingCity = 'city';
		myAccount.BillingCountry = 'country';
		myAccount.BillingPostalCode = 'my postal Code';
		
		myAccount.ShippingStreet = 'my street';
		myAccount.ShippingCity = 'city';
		myAccount.ShippingCountry = 'country';
		myAccount.ShippingPostalCode = 'my postal Code';
		
    }
}