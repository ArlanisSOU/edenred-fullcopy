@IsTest 
private class APAT01_ToolkitAT_TEST {
    
   
    @TestSetup
    static void makeData(){
    System.Debug('>>>    #START - APAT01_ToolkitAT_Test.MakeData \r\n');
    List<ER_Loop__c> apmLoops = new List<ER_Loop__c>();
    apmLoops.add(new ER_Loop__c(Name='APM_TR', ER_Reference__c='LOOP-0001'));
    apmLoops.add(new ER_Loop__c(Name='APM_TS', ER_Reference__c='LOOP-0002'));
    insert apmLoops;

    Integer i;
    System.debug('TEST.DATAPREP: INSERTED ER_Loop__c: ' + apmLoops.Size());




    System.debug('---------- MakeData >>> ACCOUNTS ----------');

       
    List<Account> accs = new List<Account>();
    
    accs.add(new Account(Name='UnitTest Merchant',                                  Partner_Code__c='MER-CT00', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));              //Vouchers + Cards - standard client
    accs.add(new Account(Name='UnitTest Merchant CT01 - TRI1 Stores and Contracts', Partner_Code__c='MER-CT01', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));      //have 2 active contracts
    accs.add(new Account(Name='UnitTest Merchant CT02 - Clean Merchant',            Partner_Code__c='MER-CT02', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant CT03 - Card Only Merchant with Existing Contract ', Partner_Code__c='MER-CT03', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant CT04 - Inactive Contracts',                                  Partner_Code__c='MER-CT04', Status__c='Inactive', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant',                                  Partner_Code__c='MER-CT05', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant',                                  Partner_Code__c='MER-CT06', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant',                                  Partner_Code__c='MER-CT07', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant',                                  Partner_Code__c='MER-CT08', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant',                                  Partner_Code__c='MER-CT09', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));
    accs.add(new Account(Name='UnitTest Merchant CT10',                             Partner_Code__c='MER-CT10', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Merchant_Account_RT')));      // card test playground
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT01', Status__c='Active', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));               // have multiple contracts
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT02', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));   
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT03', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT04', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT05', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT06', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT07', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT08', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT09', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));
    accs.add(new Account(Name='UnitTest Client', Partner_Code__c='CLI-CT10', RecordTypeId=APAT01_ToolkitAT.GetRecordTypeId('Account','Client_Account_RT')));           // card test playground
    //CT10 - Clean Account without any related objects


    insert accs;

    System.debug('---------- MakeData <<<  ACCOUNTS: ' +  accs.size() + ' ----------');



    System.debug('---------- MakeData >>> CONTRACTS ----------');

        List<ER_Contract__c> merCtrs  = new List<ER_Contract__c>();
        List<ER_Contract__c> merCtrsClosed  = new List<ER_Contract__c>();

        //MER-CT01 contracts
        i = 1;
        merCtrs.add ( prepareStandardMerchantContract('Ticket Restaurant',accs[i].id));
        merCtrs.add ( prepareStandardMerchantContract('Ticket Service',accs[i].id));
        merCtrs.add ( prepareStandardMerchantContract('Ticket Restaurant Card',accs[i].id));

        //MER-CT03
        i=3;
        merCtrs.add ( prepareStandardMerchantContract('Ticket Restaurant Card',accs[i].id));         // contract to be cloned to Ticket Service


        //MER-CT04 - inactive contracts
        i = 4;
        merCtrsClosed.add ( prepareStandardMerchantContract('Ticket Restaurant',accs[i].id));             // voucher contracts
        merCtrsClosed.add ( prepareStandardMerchantContract('Ticket Service',accs[i].id));             // voucher contracts
        merCtrsClosed.add ( prepareStandardMerchantContract('Ticket Restaurant Card',accs[i].id));


        // close contracts
        for (ER_Contract__c c :merCtrsClosed ) {
                c.Contract_Close_Date__c = date.today();
        }

        insert merCtrs;
        insert merCtrsClosed;

    System.debug('---------- MakeData <<<  CONTRACTS: ' +  merCtrs.size() + ' ----------');



    //Stores
    System.debug('---------- MakeData >>> STORES ----------');

        // Ensure you have correct encoding UTF-8, otherwise following statemetns will fail due to usage of german-specyfic characters

        List<ER_Store__c> stores = new List<ER_Store__c>();
        // MER-CT01
        i=1;
        stores.add (new ER_Store__c(Name='Test Store MER-CT01 - Voucher only',   AT_Accepts_Payment__c='Voucher only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[i].id) );
        stores.add (new ER_Store__c(Name='Test Store MER-CT01 - Voucher only',   AT_Accepts_Payment__c='Voucher only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Restaurants', ER_Merchant__c = accs[i].id) );

        // MER-CT03
        i = 3;
        stores.add (new ER_Store__c(Name='Test Store MER-CT03 - Voucher only',   AT_Accepts_Payment__c='Voucher only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[i].id) );
        stores.add (new ER_Store__c(Name='Test Store MER-CT03 - Vouher+Card',    AT_Accepts_Payment__c='Voucher+Card', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[i].id) );
        stores.add (new ER_Store__c(Name='Test Store MER-CT03 - Card only',      AT_Accepts_Payment__c='Card only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Restaurants', ER_Merchant__c = accs[i].id) );
        stores.add (new ER_Store__c(Name='Test Store MER-CT03 - None',           AT_Accepts_Payment__c='Card only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Restaurants', ER_Merchant__c = accs[i].id) );
        

        //MER-CT04
        i = 4;
        stores.add (new ER_Store__c(Name='Test Store MER-CT04 - Voucher only',   AT_Accepts_Payment__c='Voucher only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Supermarkt', ER_Merchant__c = accs[i].id) );
        stores.add (new ER_Store__c(Name='Test Store MER-CT04 - Voucher only',   AT_Accepts_Payment__c='Voucher only', AT_Category__c = 'Essen & Ernährung', AT_Sub_Category__c = 'Restaurants', ER_Merchant__c = accs[i].id) );

        insert stores;

    System.debug('---------- MakeData <<<  STORES: ' +  stores.size() + ' ----------');


    //Acceptors
     System.debug('---------- MakeData >>> ACCEPTORS ----------');

        List<ER_Acceptor__c> acceptors = new List<ER_Acceptor__c>();
        for (ER_Store__c store : stores) {
            acceptors.add (new ER_Acceptor__c(Name='Test Acceptor', ER_Store__c=store.Id, ER_MID_Authorization__c = String.valueof(store.Id)) );
        }

        insert acceptors;
     System.debug('---------- MakeData <<<  ACCEPTORS: ' +  acceptors.size() + ' ----------');

    System.Debug('');
    System.Debug('<<<    #FINISHED - APAT01_ToolkitAT_Test.MakeData \r\n');
    System.Debug('');

    }
    



    //
    // prepares contract for Merchant with standard fields
    public static ER_Contract__c prepareStandardClientContract(string productName, Id AccountId){
        
        ER_Contract__c c = new ER_Contract__c();

        c.Account_Name__c  = Accountid;
        c.RecordTypeId = APAT01_ToolkitAT.GetRecordTypeId('ER_Contract__c', 'Client_Contract_RT');
        c.Advisor__c = 'Philip Pree';
        c.Product__c = productName;
        

        c.Contract_Start_Date__c = date.today()-10;             //not mandatory, but status depends on that
        return c;
    }

    // prepares contract for Merchant with standard fields
    public static ER_Contract__c prepareStandardMerchantContract(string productName, Id AccountId){
        
        ER_Contract__c c = new ER_Contract__c();

        c.Account_Name__c  = Accountid;
        c.RecordTypeId = APAT01_ToolkitAT.GetRecordTypeId('ER_Contract__c', 'Affiliate_Contract_RT');
        c.Advisor__c = 'Claudia Eisl';
        c.Commission_Value__c = 5.55;
        c.Product__c = productName;
        c.Contract_Start_Date__c = date.today()-10;         
        c.Invoice_Type__c = 'Electronic';
        c.AT_Comments__c = 'Comments';
        
        //c.Payment_Delay__c='7';           // changed in PROD to different picklist values?

        return c;
    }

    public static ER_Store__c prepareStore(string stoerName, Id AccountId){
        ER_Store__c x = new ER_Store__c();

        x.name='Test Store';
        x.AT_Accepts_Payment__c = 'None';
        x.AT_Category__c = 'Essen & Ernährung';
        x.AT_Sub_Category__c = 'Supermarkt';
        x.ER_Merchant__c = AccountId;
    
        return x;
    }


    // ############# TESTS #############

    @IsTest
    static void TestReferentials(){
        APAT01_ToolkitAT.GetLoopIdByLoopReference('LOOP-0001');     // exists
        APAT01_ToolkitAT.GetLoopIdByLoopName('APM_TR');             // succes
        APAT01_ToolkitAT.GetLoopIdByLoopReference('NotexistingLoopRef');

    }

    @IsTest
    static void TestContract_MasterSlaveRelationship(){

        
        List<Account> accs = [SELECT Id, Name, RecordTypeId, Partner_Code__c FROM Account  WHERE Partner_Code__c='CLI-CT02'];
        insert prepareStandardMerchantContract('Ticket Restaurant Card', accs[0].Id);

        List<ER_Contract__c> ctrs = [SELECT Id, Name, AT_MasterContract__c FROM ER_Contract__c WHERE Account_Name__c in :accs AND Product__c = 'Ticket Service Card' AND AT_MasterContract__c != NULL];

        system.assertEquals(1,ctrs.Size(), 'Confirm relationship is in place');

        ctrs[0].AT_MasterContract__c = NULL;        //remove relationship
        update ctrs;

        system.assertEquals(1,[SELECT Id, Name, AT_MasterContract__c FROM ER_Contract__c WHERE Account_Name__c IN :accs AND Product__c='Ticket Service Card' AND AT_MasterContract__c = NULL].Size(), 'Confirm relationship has been removed');

            test.startTest();
            APAT01_ToolkitAT.makeMasterSlaveContractRelationship();
            test.stopTest();

        system.assertEquals(1,[SELECT Id, Name, AT_MasterContract__c FROM ER_Contract__c WHERE Account_Name__c IN :accs AND Product__c='Ticket Service Card' AND AT_MasterContract__c != NULL].Size(), 'Confirm relationship is back in place');


    }
    @IsTest
    static void ClientContractTest(){
        List<Account> accs = [SELECT Id, Name, RecordTypeId, Partner_Code__c FROM Account  WHERE Partner_Code__c='CLI-CT02'];

        List<ER_Contract__c> contracts = new List<ER_Contract__c>();

        // THIS DOES NOT WORK DUE TO Duplicate  Rule -> Contract Product Duplicates ->  One Active Contract Per Product 
        // The duplicate rule is actually wrong, becasuse
        // Prevent's to Add Merchant Contracts on the Merchant with the same name
        // Prevent's to have more than  1 inactive contract (does not filter status='Active')
        /*
        contracts.add(prepareStandardClientContract('Ticket Restaurant', accs[0].id));
        contracts.add(prepareStandardClientContract('Ticket Restaurant Card', accs[0].id));
        System.debug('TEST #ClientTests: contracts dump' +contracts );
        insert contracts;
        */

        insert prepareStandardClientContract('Ticket Junior', accs[0].id);
        insert prepareStandardClientContract('Ticket Restaurant', accs[0].id);
        insert prepareStandardClientContract('Ticket Restaurant Card', accs[0].id);

        // no actions should be taken for Client Contracts
        system.assertEquals(3, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Status__c='Active'] .Size(), 'Confirm there are 2 client contracts');

    }

    @IsTest
    // Force to setClient and Contract statuses, which are corrected then by the triggers and job
    static void TestStatuses_OverrideContractAndAccountStatus() {
        
        
    //Created contracts CLI-CT01
    
    List<ER_Contract__c> cliCtrs = new List<ER_Contract__c>();
        System.debug('---------- MakeData >>> Client Contracts ----------');
        Id accountId = [SELECT ID from Account WHERE Partner_Code__c='CLI-CT01'][0].Id;

            cliCtrs.add(prepareStandardClientContract('Ticket Service', AccountId));
            cliCtrs.add(prepareStandardClientContract('Ticket Restaurant', AccountId));
            cliCtrs.add(prepareStandardClientContract('Ticket Service Card', AccountId));
            cliCtrs.add(prepareStandardClientContract('Ticket Restaurant Card', AccountId));

        insert cliCtrs;
        System.debug('---------- MakeData <<< Client Contracts ----------');
        
       

        system.assertEquals(4, [SELECT Id  FROM ER_Contract__c  WHERE Account_Name__r.Partner_Code__c='CLI-CT01' and Status__c='Active'] .Size(), 'Confirm 4 active contracts');
        system.assertEquals(1, [SELECT Id  FROM Account         WHERE                 Partner_Code__c='CLI-CT01' and Status__c='Active'] .Size(), 'Confirm 1 active account');


        List<ER_Contract__c> ctrs = [SELECT Id, Name, RecordTypeId, Status__c FROM ER_Contract__c WHERE Account_Name__c = :accountId];

        for(ER_Contract__c  c: ctrs) {
            c.Status__c = 'Inactive';
        }

        update ctrs;
        system.assertEquals(4, [SELECT Id  FROM ER_Contract__c  WHERE Account_Name__r.Partner_Code__c='CLI-CT01' and Status__c='Active'] .Size(), 'Confirm 3 active contracts, since trigger is working');

        List<Account> accs = [SELECT Id, Name, RecordTypeId, Partner_Code__c, Status__c FROM Account WHERE Id = :accountId];

        for(Account  a: accs) {
            a.Status__c = 'Inactive';
        }


        update accs;

        system.assertEquals(0, [SELECT Id  FROM Account         WHERE                 Partner_Code__c='CLI-CT01' and Status__c='Active'] .Size(), 'Confirm that acount has been actually inactivated. To be fixed with the job run');


        // call the job to override Account statuses
        testStatusManagerJob();



        system.assertEquals(1, [SELECT Id  FROM Account         WHERE                 Partner_Code__c='CLI-CT01' and Status__c='Active'] .Size(), 'Confirm that acount has been activated again by the job');

    }

    @IsTest
    // Tests, if exception is thrown when trying to create more than  1 active Merchant Contract contract per product
    static void TestContracts_MultipleActiveContracts() {
        // add contract to merchant which has already active contracts

        List<Account> accs = [SELECT Id, Name, RecordTypeId, Partner_Code__c FROM Account  WHERE Partner_Code__c='MER-CT01'];

        system.assertEquals(4, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Status__c='Active'].Size(), '2 contracts has been created on account');
        

        List<ER_Contract__c> ctrs = new List<ER_contract__c>();
        
        ER_Contract__C c;
        c = prepareStandardMerchantContract('Ticket Restaurant Card',accs[0].id);
        c.Contract_Start_Date__c = date.today();
        ctrs.add(c);
       


        try {
            insert ctrs;
        } catch (DmlException e) {
            //System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, This Account has already another active Contract for this product)!: [Product__c]
            system.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),'Confirm that exception is FIELD_CUSTOM_VALIDATION_EXCEPTION');
            system.assert(e.getMessage().contains('This Account has already another active Contract for this product'),'Confirm it\'s because of business rule');
        }
       

        system.assertEquals(4, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Status__c='Active'].Size(), 'Confirm 2 contracts has been created on account');
        system.assertEquals(0, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Status__c!='Active'].Size(), 'Confirm there is no other contracts than active');



    }

    // Can user close the contract and open another one the same day?
   
    @IsTest
    static void TestContracts_AddAnotherTRContract() {
        

        List<Account> accs = [SELECT Id, Name, RecordTypeId, Partner_Code__c FROM Account  WHERE Partner_Code__c='MER-CT01'];
        List<ER_Contract__c> contracts = [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs and Status__c='Active' and Product__c='Ticket Restaurant Card'];
        
        system.assertEquals(4, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs and Status__c='Active'].Size(), 'Confirm all contracts Cards and Vouchers  are active');

         //  Close currently active contract with current date
        contracts[0].Contract_Close_Date__c = date.today();
        upsert contracts;

        // Confirm no active contract
        system.assertEquals(2, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs and Status__c='Active'].Size(), 'Confirm now only 2 contracts (vouchers) are active');
        
        // Create another contract starting from today
        ER_Contract__c c = prepareStandardMerchantContract('Ticket Restaurant Card',accs[0].id);
        c.Contract_Start_Date__c = date.today();

            Test.startTest();
            insert c;
            Test.stopTest();

        // confirm values
        system.assertEquals(4, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs and Status__c='Active'].Size(),  'Confirm 4 contracts are active now (2 vouchers and 2 cards)');
        system.assertEquals(2, [SELECT Id, Name, Product__c, Account_Name__c  FROM ER_Contract__c  WHERE Account_Name__c in :accs and Status__c!='Active'].Size(), 'Confirm 2 contracts are also inactive (2 cards)');
    }    



    @IsTest
    static void TestContract_NullifiedFieldReplication() {
        List<Account> accs = [SELECT Id, Name, RecordTypeId, Partner_Code__c FROM Account  WHERE Partner_Code__c='MER-CT03'];
        List<ER_Contract__c> contracts;     //holds contracts

        Integer i=0;
        //ER_Contract__c c = prepareStandardMerchantContract('Ticket Restaurant Card',accs[0].id);

        //c.AT_Comments__c = 'NullifiedTest';
        //insert c;

        contracts = [SELECT Id, Name, Product__c, Account_Name__c, AT_Comments__c FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Product__c IN :APAT01_ToolkitAT.CardProductList()];

        system.assertEquals(2, contracts.size(), '2 contracts has been created on account');

        for (ER_Contract__c testC : contracts) {
            if (testC.AT_Comments__c != NULL)
                i++;
        }

        system.assertEquals(2, i, 'Both contracts has AT comment filed non empty');
        i=0;

        ER_Contract__c c = [SELECT Id, Name, Product__c, Account_Name__c, AT_Comments__c FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Product__c ='Ticket Restaurant Card' AND Status__c='Active'][0];
        c.AT_Comments__c = NULL;
        update c;

        // refresh contract
        contracts = [SELECT Id, Name, Product__c, Account_Name__c, AT_Comments__c FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Product__c IN :APAT01_ToolkitAT.CardProductList()];

        for (ER_Contract__c testC : contracts) {
            if (testC.AT_Comments__c == NULL)
                i++;
        }

        system.assertEquals(2, i, 'Both contracts has AT comment filed = NULL');
        
    }

    static void ExistingContractDelete(){

        System.debug('########## TEST Case:  ##########');
            List<Account> accs = [SELECT Id, Name, RecordTypeId FROM Account  WHERE Partner_Code__c='MER-CT10'];
            system.assertEquals(1, accs.size(), 'Number of Accounts');


            List<ER_Contract__c> contracts = [SELECT Id FROM ER_Contract__c  WHERE Account_Name__c in :accs];
            delete contracts;

            system.assertEquals(0, contracts.size(), 'Confirming there is no contracts');



    }

    @IsTest
    static void CreateContractAndStores() {

    System.debug('TEST.START: CreateContractAndStores');

        //User U =  [SELECT id FROM User WHERE alias='kadam'];
        //System.runAs(u) {

        System.debug('########## TEST Case #1 - referentials - Loops ##########');
        
        List<ER_loop__c> loops = [SELECT Id, Name, ER_Reference__c FROM ER_Loop__c];
        System.assertEquals(2, loops.Size(), 'Checking number of loops');

        String productName = 'Ticket Restaurant Card';

        System.assertEquals(true, APAT01_ToolkitAT.isCardAPMProduct(productName), 'Checkin if product is card product');
        //System.assertEquals('a090Q0000009jr4QAA', APAT01_ToolkitAT.GetLoopIdByProductName(productName), 'Check the LOOP-ID');

        Account a = new Account(); 
        

        //delete accounts

    System.debug('########## TEST Case #2 - referentials - Accounts ##########');
        List<Account> accs = [SELECT Id, Name, RecordTypeId FROM Account  WHERE Partner_Code__c='MER-CT10'];
        system.assertEquals(1, accs.size(), 'Number of Accounts');


        a = accs[0];
        system.debug('--- Account:' + a);


    System.debug('########## TEST Case #3 - Creating TR Card Contract ##########');
        Test.startTest();       // measure only the Contract creation, sinte it's most resource-consuming

            List<ER_Contract__c> contracts = new List<ER_Contract__c>();
            ER_Contract__c contract = new ER_Contract__c();

                contract.Account_Name__c = accs[0].Id;
                contract.RecordTypeId = APAT01_ToolkitAT.GetRecordTypeId('ER_Contract__c', 'Affiliate_Contract_RT');
                contract.Advisor__c = 'Claudia Eisl';
                contract.Commission_Value__c = 1.23;
                contract.Product__c = productName;
                contract.Contract_Start_Date__c = date.today();
                
            upsert contract;
    
            system.debug('--- Contract: ' + contract);

        Test.stopTest();

        //refresh because 2nd should be added via trigger
        contracts = [SELECT Id, Name, Product__c, Account_Name__c FROM ER_Contract__c  WHERE Account_Name__c in :accs];

        system.assertEquals(2, contracts.size(), 'Test if 2 contracts has been created (TR replicated to TS)');


    System.debug('########## TEST Case #4 - Creating New Store ##########');
        
            //create store
        ER_Store__c store = new ER_Store__c();
            store.Name='UnitTest Store 1';
            store.AT_Sub_Category__c = 'Supermarkt';
            store.AT_Accepts_Payment__c = 'Card only';
            store.AT_Status__c = 'Active';
            store.ER_Merchant__c = a.Id;
        insert store;

        
        //check if 2 Store Authorizations has been created
        List<ER_Store_Authorization__c> storeAuth = [SELECT Id FROM ER_Store_Authorization__c WHERE ER_Store__c = :store.Id ];
        system.assertEquals(2, storeAuth.size(), 'Test - 2 SA creation after Store is created');

        // TODO check which are active and which not


        // add new store
        // implies creating new store authorizations

        store.Name='UnitTest Store 2';
        store.Id = null;
        insert store;

        storeAuth = [SELECT Id FROM ER_Store_Authorization__c WHERE ER_Store__r.ER_Merchant__c = :a.Id AND ER_Behaviour__c='ACCEPT'];
        system.assertEquals(4, storeAuth.size(), 'Test - 4 SA creation after Store is created');
        delete store;

        storeAuth = [SELECT Id FROM ER_Store_Authorization__c WHERE ER_Store__r.ER_Merchant__c = :a.Id AND ER_Behaviour__c='ACCEPT'];
        system.assertEquals(2, storeAuth.size(), 'Test - 4 SA creation after Store is created');

        
        delete contract;           //delete contract
 
        storeAuth = [SELECT Id FROM ER_Store_Authorization__c WHERE ER_Store__r.ER_Merchant__c = :a.Id];
        system.assertEquals(0, storeAuth.size(), 'Test - if all SA has been deleted');

        //}
    }

    @IsTest
    static void TestMerchantContractClose() {
        
        List<Account> accs = [SELECT Id, Name, RecordTypeId FROM Account  WHERE Partner_Code__c='MER-CT03'];     // Account has 2 stores, and 2 contracts TR + TS


        system.assertEquals(1, accs.size(), 'Number of Accounts');

        List<ER_Contract__c> contracts = [SELECT Id, Name, Account_Name__c, Status__c, Product__c, Contract_Close_Date__c FROM ER_Contract__C WHERE Account_Name__c IN :accs AND Product__c IN :APAT01_ToolkitAT.CardProductList() AND Status__c='Active'];
        system.assertEquals(2, contracts.size(), 'Number of Card  Contracts');

        system.assertEquals(4, [SELECT Id FROM ER_Store__c WHERE ER_Merchant__c IN :accs].size(), 'Number of Stores');

        List<ER_Store_Authorization__c> storeAuth = [SELECT Id FROM ER_Store_Authorization__c WHERE ER_Store__c IN (SELECT Id FROM ER_Store__c WHERE ER_Merchant__c IN :accs) AND ER_Behaviour__c='ACCEPT'];
        system.assertEquals(8, storeAuth.size(), 'Test - if stores are ACCEPT in all contracts');
        
        System.debug('########## TEST Case #1 - Close Open Card Contract Today ##########');

            // Close TR contract today.
            // Implies to close TS contract as well and change the store authorizations
            // Implies to Set Account as Inactive


            ER_Contract__c contract = [SELECT Id, Name, Account_Name__c, Status__c, Product__c, Contract_Close_Date__c FROM ER_Contract__C WHERE Account_Name__c IN :accs AND Product__c ='Ticket Restaurant Card'][0];

            contract.Contract_Close_Date__c = date.today();
            upsert contract;

            
            storeAuth = [SELECT Id FROM ER_Store_Authorization__c WHERE ER_Store__c IN (SELECT Id FROM ER_Store__c WHERE ER_Merchant__c IN :accs) AND ER_Behaviour__c='DECLINE'];
            system.assertEquals(8, storeAuth.size(), 'Test - if  stores are now DECLINED');


            contracts = [SELECT Id, Name, Product__c, Account_Name__c FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Status__c='Inactive'];
            system.assertEquals(2, contracts.size(), 'Test - if contracts has been inactivated');


            contracts = [SELECT Id, Name, Product__c, Account_Name__c FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Status__c='Active'];
            system.assertEquals(0, contracts.size(), 'Test - if no active contract ramains on account');

            system.assertEquals(1, [SELECT Id, Name, RecordTypeId FROM Account  WHERE Id IN :accs and Status__c='Inactive'].size(), 'Test - if account is now inactive');       


    } 

@IsTest

static void TestMerchantContractReopen() {

    Contract_Reopen('MER-CT04');
}

static void Contract_Reopen(String partnerCode) {
        
        List<Account> accs = [SELECT Id, Name, RecordTypeId FROM Account  WHERE Partner_Code__c=:partnerCode];     // Account has 2 stores, and 2 contracts TR + TS


        List<ER_Contract__c> contracts;
        List<ER_Store_Authorization__c> storeAuth;
        System.debug('########## TEST Case #1 - Reopen Card Contract  ##########');


            system.assertEquals(1, [SELECT Id, Name, RecordTypeId FROM Account  WHERE Id IN :accs and Status__c='Inactive'].size(), 'Test - if account is now inactive');       

            ER_Contract__c contract = [SELECT Id, Name, Account_Name__c, Status__c, Product__c, Contract_Close_Date__c FROM ER_Contract__C WHERE Account_Name__c IN :accs AND Product__c ='Ticket Restaurant Card'][0];
            //enable TR Contract (&TS) Voucher Contracts remain closed
            contract.Contract_Close_Date__c = null;
            update contract;

            
            contracts = [SELECT Id, Name, Product__c, Account_Name__c FROM ER_Contract__c  WHERE Account_Name__c in :accs AND Status__c='Active'];
            system.assertEquals(2, contracts.size(), 'Test - if both contracts has been Activated again');

            storeAuth = [SELECT Id FROM ER_Store_Authorization__c WHERE ER_Store__c IN (SELECT Id FROM ER_Store__c WHERE ER_Merchant__c IN :accs) AND ER_Behaviour__c='ACCEPT'];
            system.assertEquals(4, storeAuth.size(), 'Test - if  stores are now ACCEPT again');
        
            system.assertEquals(1, [SELECT Id, Name, RecordTypeId FROM Account  WHERE Id IN :accs AND Status__c='Active'].size(), 'Test - if account is now inactive');   

    } 


    @IsTest
    static void TestAcceptorTrigger_StoreAcceptPayment(){

        List<ER_Store__c> stores = [SELECT Id, Name, AT_Accepts_Payment__c FROM ER_Store__c WHERE Name='Test Store MER-CT03 - Vouher+Card'];

        Id StoreId = stores[0].id;
        // add 2nd Acceptor

        insert  new ER_Acceptor__c(Name='Test Acceptor MER-CT03 - Bulk Test', ER_Store__c = StoreId, ER_MID_Authorization__c ='RandomMID'); 

        // delete in batch both Acceptors

        system.assertEquals('Voucher+Card', [SELECT AT_Accepts_Payment__c FROM ER_Store__c WHERE Id=:StoreId][0].AT_Accepts_Payment__c, 'Check AT_Accept_payment__c before delete');
        

        delete [SELECT Id FROM ER_Acceptor__c WHERE ER_Store__c=:StoreId];

        system.assertEquals('Voucher only', [SELECT AT_Accepts_Payment__c FROM ER_Store__c WHERE Id=:StoreId][0].AT_Accepts_Payment__c, 'Check AT_Accept_payment__c before delete');
    }


    @IsTest
    static void PB002_test(){
        System.Debug('>>>>>>>>>>>>>>>>>>> PB002_test START ######################');
        
            Account acc = [SELECT Id FROM Account WHERE Partner_Code__c='MER-CT05'][0];
            //List<ER_Contract__c> merCtrs  = new List<ER_Contract__c>();

        Test.startTest();   //start counter

            insert prepareStandardMerchantContract('Ticket Restaurant Card', acc.Id);

        Test.stopTest();
          System.Debug('<<<<<<<<<<<<<<< PB002_test START ######################');

    }

    static testmethod void testStatusManagerJob(){
        String schedule='0 22 16 * * ?';
        Test.startTest();
        String jobId=System.Schedule('StatusManagerJob',schedule, new BAAT01_SchedulerStatusManager());
        Test.stopTest();
    } 


    
    static testmethod void testConsistencyCheckJob(){
        String schedule='0 22 16 * * ?';
        Test.startTest();
        String jobId=System.Schedule('ConsistencyCheckJob',schedule, new BAAT02_ConsistencyCheck());
        Test.stopTest();
    } 
}