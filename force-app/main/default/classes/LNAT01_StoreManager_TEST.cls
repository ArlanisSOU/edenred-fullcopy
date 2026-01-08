// StoreAuthorization depends on APAT01_ToolkitAT class and triggers, which needs to be in place for the tests to succeed.
// Removing assertion on StoreAuthorization is possible
//
@IsTest
public class LNAT01_StoreManager_TEST {
    
    

    @TestSetup
    static void makeData(){
    System.Debug('>>>    #START - LNAT01_StoreManager_TEST.MakeData \r\n');

    List<ER_Loop__c> apmLoops = new List<ER_Loop__c>();
    apmLoops.add(new ER_Loop__c(Name='APM_TR', ER_Reference__c='LOOP-0001'));
    apmLoops.add(new ER_Loop__c(Name='APM_TS', ER_Reference__c='LOOP-0002'));
    insert apmLoops;


    List<Account> accs = new List<Account>();
    accs.add(new Account(Name='UnitTest Merchant CT00', Partner_Code__c='MER-CT00', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));              //Vouchers + Cards - standard client
    accs.add(new Account(Name='UnitTest Merchant CT01', Partner_Code__c='MER-CT01', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));      //have 2 active contracts
  
    insert accs;

    System.debug('TEST.DATAPREP: INSERTED Account: ' + accs.size());

        ER_Contract__c c = new ER_Contract__c();

        c.Account_Name__c  = accs[1].Id;
        c.Product__c = 'Ticket Restaurant Card';
        c.RecordTypeId = Schema.getGlobalDescribe().get('ER_Contract__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Affiliate_Contract_RT').getRecordTypeId();
        c.Advisor__c = 'Claudia Eisl';
        c.Commission_Value__c = 5.55;
        c.Contract_Start_Date__c = date.today()-10;         
        c.Invoice_Type__c = 'Electronic';
        insert c;



    //Stores

    List<ER_Store__c> stores = new List<ER_Store__c>();
    
    stores.add (new ER_Store__c(Name='Test Store MER-CT01 - Voucher only',   AT_Accepts_Payment__c='Voucher only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[1].id) );
    stores.add (new ER_Store__c(Name='Test Store MER-CT01 - Vouher+Card',    AT_Accepts_Payment__c='Voucher+Card', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[1].id) );
    stores.add (new ER_Store__c(Name='Test Store MER-CT01 - Card only',      AT_Accepts_Payment__c='Card only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[1].id) );
    stores.add (new ER_Store__c(Name='Test Store MER-CT01 - None',           AT_Accepts_Payment__c='Card only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[1].id) );
    
    insert stores;
    //Acceptors

    List<ER_Acceptor__c> acceptors = new List<ER_Acceptor__c>();
    for (ER_Store__c store : stores) {
        acceptors.add (new ER_Acceptor__c(Name='Test Acceptor MER-CT01', ER_Store__c=store.Id, ER_MID_Authorization__c = String.valueof(store.Id)) );
    }

    insert acceptors;
    
    // obtain gobal Test Account Id
    

    System.Debug('');
    System.Debug('<<<    #FINISHED - APAT01_ToolkitAT_Test.MakeData \r\n');
    System.Debug('');
    }

    @IsTest 
    public static void GetCounters() {
        
        Id accId  = [SELECT Id FROM Account WHERE Partner_code__c='MER-CT01' LIMIT 1][0].Id;

        List<Integer> recCounters = LNAT01_StoreManager.GetCounters(accId); // result contains: Store, Acceptor, StoreAuth
        system.assertEquals(4, recCounters[0], 'Check Store count');
        system.assertEquals(4, recCounters[1], 'Check Acceptor count');
        system.assertEquals(8, recCounters[2], 'Check StoreAuth count');

        try {
            recCounters = LNAT01_StoreManager.GetCounters('0010Q00000zzzzzzzz');
        } catch (exception e) {
            system.assert(e.getMessage().contains('Unable to execut query'),'Confirm exception');
        }

    }
    @IsTest 
    public static void deleteUnderlyingAcceptorsAndStores(){
        Id accId  = [SELECT Id FROM Account WHERE Partner_code__c='MER-CT01' LIMIT 1][0].Id;

        LNAT01_StoreManager.deleteUnderlyingAcceptorsAndStores(accId);

        List<Integer> recCounters = LNAT01_StoreManager.GetCounters(accId); // result contains: Store, Acceptor, StoreAuth
        system.assertEquals(0, recCounters[0], 'Check Store count');
        system.assertEquals(0, recCounters[1], 'Check Acceptor count');
        system.assertEquals(0, recCounters[2], 'Check StoreAuth count');

        try{
            LNAT01_StoreManager.deleteUnderlyingAcceptorsAndStores('0010Q00000zzzzzzzz'); //exception
        } catch (exception e) {
            system.assert(e.getMessage().contains('Unable to delete'),'Confirm exception');
        }
        
        
    }

    @IsTest 
    public static void deleteUnderlyingStores(){

        Id accId  = [SELECT Id FROM Account WHERE Partner_code__c='MER-CT01' LIMIT 1][0].Id;

        LNAT01_StoreManager.deleteUnderlyingStores(accId);

        List<Integer> recCounters = LNAT01_StoreManager.GetCounters(accId); // result contains: Store, Acceptor, StoreAuth
        system.assertEquals(0, recCounters[0], 'Check Store count');
        system.assertEquals(0, recCounters[1], 'Check Acceptor count');
        system.assertEquals(0, recCounters[2], 'Check StoreAuth count');

        try{
            LNAT01_StoreManager.deleteUnderlyingStores('0010Q00000zzzzzzzz'); //exception
        } catch (exception e) {
            system.assert(e.getMessage().contains('Unable to delete'),'Confirm exception');
        }
    }

    @IsTest 
    public static void deleteUnderlyingAcceptors(){

        Id accId  = [SELECT Id FROM Account WHERE Partner_code__c='MER-CT01' LIMIT 1][0].Id;

        LNAT01_StoreManager.deleteUnderlyingAcceptors(accId);

        List<Integer> recCounters = LNAT01_StoreManager.GetCounters(accId); // result contains: Store, Acceptor, StoreAuth
        system.assertEquals(4, recCounters[0], 'Check Store count');
        
		/* Comment by AAB, error :  System.AssertException: Assertion Failed: Check Acceptor count: Expected: 0, Actual: 4 */
        /* Comment by Kamil adamiec: no idea why this was problematic - TBC after next run */
        
		system.assertEquals(0, recCounters[1], 'Check Acceptor count');
        system.assertEquals(8, recCounters[2], 'Check StoreAuth count');


        try{
            LNAT01_StoreManager.deleteUnderlyingAcceptors('0010Q00000zzzzzzzz'); //exception
        } catch (exception e) {
            system.assert(e.getMessage().contains('Unable to delete'),'Confirm exception');
        }
    }

    @IsTest 
    public static void deleteUnderlyingStoreAuth(){

        Id accId  = [SELECT Id FROM Account WHERE Partner_code__c='MER-CT01' LIMIT 1][0].Id;

        LNAT01_StoreManager.deleteUnderlyingStoreAuth(accId);

        List<Integer> recCounters = LNAT01_StoreManager.GetCounters(accId); // result contains: Store, Acceptor, StoreAuth
        system.assertEquals(4, recCounters[0], 'Check Store count');
        system.assertEquals(4, recCounters[1], 'Check Acceptor count');
        system.assertEquals(0, recCounters[2], 'Check StoreAuth count');

        try{
            LNAT01_StoreManager.deleteUnderlyingStoreAuth('0010Q00000zzzzzzzz'); //exception
        } catch (exception e) {
            system.assert(e.getMessage().contains('Unable to delete'),'Confirm exception');
        }
    }
	
	
	@IsTest 
    public static void additionalTest(){
		LNAT01_StoreManager.additionalTest();

    }
}