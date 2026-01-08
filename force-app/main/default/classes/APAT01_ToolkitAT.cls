// Data Structure Requirements:
// Add ER_Contract__c.AT_MasterContract - lookup to ER_Contract_c
// Add 'None' piclist value to ER_Contract__c.Status__c

// ### Configuration ###
// Lightning Setup -> Company Settings -> My Domain => Set Dedicated URL to Instance  - Needed to deploy/launch Lightning Component
// Lightning Setup -> Email -> Deliverability -> Access Level = All Emails     =>  Allow to send e-mail from the Scheduled Job
// Lightning Setup -> Environments -> Deploy -> Deployment settings => Allow deployments of components when corresponding Apex jobs are pending or in progress  => Allow to deploy Apex when Job is Schedule (Setting to be found)


public class APAT01_ToolkitAT {

    //TODO: replace with staticmethod CardProductList
    //public Map<String, String> mapStatus2SADBehaviour = new Map<String, String> {'Active' => 'ACCEPT', 'Inactive' => 'DECLINE'};
    //public List<String> lstCardAPMProduct = new List<String> {'Ticket Restaurant Card', 'Ticket Service Card'};     
    //public Map<String, Id> mapProduct2Loop = new Map<String, Id>{};


    private Integer m_DebugLevel = 10;

    //private Map<String, String> mapInvertStatus = new Map<String, String>{'Inactive' => 'Active', 'Active' => '#NonExistent#'}; 
    
    public static List<String> CardProductList() {
        return new List<String> {'Ticket Restaurant Card', 'Ticket Service Card'}; 
    }

    //public static Map<String, String> InvertStatusMap() {
    //    return new Map<String, String>{'Inactive' => 'Active', 'Active' => '#NonExistent#'};
    //}

    public static String GetSABehaviourByStatus(String Status){
        Map<String, String> mapStatus2SADBehaviour = new Map<String, String> {'Active' => 'ACCEPT', 'Inactive' => 'DECLINE'};
        return mapStatus2SADBehaviour.get(Status);
    }

    public static boolean IsCardAPMProduct(string product){
        return CardProductList().contains(product);
    }

    /* 
    public APAT01_ToolkitAT() {
            addMapProduct2Loop('Ticket Restaurant Card');
            addMapProduct2Loop('Ticket Service Card');
    }
    */
    

    // DESCRIPTION:
    // Set Account.Status according to Contract for Record Types (Client, Merchant) 
    // 
    // DEPENDENCIES:
    // -  ER_Contract__c.trgContractAfter trigger   
    //
    // STATUS: FINAL rename AccountStatus_Handler
    public static List<String[]> AccountStatus_BatchUpdate(Set<Id> accountIds) {
        System.Debug('>>> CALL   AccountStatus_BatchUpdate()    accountIds.Size()=' + accountIds.Size());

        Integer[] counters = new Integer[]{0, 0};
        List<String[]> result = new List<String[]>();
        String newStatus;
        // limit Records to Client and Merchant
        Set<Id> accRecTypeFilter = new Set<Id>();
        accRecTypeFilter.add(GetRecordTypeId('Account', 'Client_Account_RT'));
        accRecTypeFilter.add(GetRecordTypeId('Account', 'Merchant_Account_RT'));

        // filter input by Record Type
        List<Account> Accounts = [SELECT Id, Name, RecordType.Name, Status__c, Partner_Code__c, (SELECT  Id FROM Contracts__r WHERE Account_Name__c IN :accountIds AND Status__c='Active')  FROM Account  WHERE  RecordTypeID IN :accRecTypeFilter AND Id IN :accountIds ORDER BY Partner_Code__c];     
        //DebugLog(11, 'AccountStatusBatchUpdate: records:' + oAccounts.size());

        
        for (Account Account : Accounts) {

                newStatus = '';     //reset status
                if (  Account.Contracts__r.isEmpty() ) {
                    // account has NO active contract, so has to be inactivated, except it's Prospect.
                    if (Account.Status__c == 'Active' || Account.Status__c == '' /* ||  oAccount.Status__c == 'Prospect' */ )     //
                        newStatus = 'Inactive';
                        counters[0]++;
                } else {
                        // Account has at least 1 active contract, not matter what's previous account status it must be set to Active
                        newStatus = 'Active';
                        counters[1]++;
                }

                // status has changed
                if ( newStatus != '' ) {
                    
                    // add to result to send inside the job notification e-mail, otherwise not needed to use memory
                    //if(System.isScheduled()) //20190207 OK if commented?
                        //result.add('Id: ' + Account.Id + ' | RecordType: ' + Account.RecordType.Name + ' | Name: ' +  Account.Name +  ' | Code: ' + Account.Partner_Code__c + ' | Status: ' + Account.Status__c + ' => ' + newStatus );
                        result.add(new String[]{Account.Id,  Account.RecordType.Name ,  Account.Name ,  Account.Partner_Code__c ,  Account.Status__c + ' => ' + newStatus });
                   
                    Account.Status__c = newStatus;
                } //if status
           
        } // for accounts
        update Accounts;
        System.Debug('<<<   AccountStatus_BatchUpdate(). Processed Accounts: ' + Accounts.size() + ', Updated : ' + result.size() + ' ->  Set to INACTIVE: ' + counters[0] + ' | Set to ACTIVE: ' + counters[1] );

        Return result;
    } //AccountStatusBatchUpdate



    // DESCRIPTION:
    //  Creates, Updates or Deletes Store Authorizations depending  on Contracts
    //
    // DEPENDENCIES:
    //  - ER_Contract__c.trgContractAfter.trigger
    //  - ER_Contract__c.trgContractBefore.trigger
    // STATUS: FINAL
    public static void StoreAuth_ByContractHandler(Set<Id> contractIds, boolean bDelete) {
        DebugLog('>>> CALL   StoreAuth_ByContractHandler()    Contracts.Size()=' + contractIds.Size() + ' bDelete=' + bDelete);

        // process
        // 1. Generate Store Authorizations (add new and update behavior on current)
        // 2. TODO: Change Payment Accepted on Store Level as per contract
        //      Vouchers Only
        //      Vouchers + Cards
        //      Cards Only
        //      None


        // get distinct set of Contract Status and Product, for furthe loop
        List<AggregateResult> distinctProductStatus = [SELECT Product__c, Status__c FROM ER_Contract__c WHERE Id in :contractIds GROUP BY Product__c, Status__c];
   
                // loop through distinct set of  Contract Product and  Status to reduce number of SOQL queries
                // then  another sub-for loop to update Store Authorization  for given Product  according  to  Contract  Status
                for (AggregateResult oFor : distinctProductStatus) {

                        String contractProduct = (string)oFor.get('Product__c');
                        String contractStatus = (string)oFor.get('Status__c');


                        Id critLoopId = GetLoopIdByProductName(contractProduct);
                        String critBehaviour = GetSABehaviourByStatus(contractStatus);
                        DebugLog('StoreAuth_ByContractHandler > loop(distinctProductStatus) Iteration |  ContractProduct: ' + contractProduct + ' |  contractStatus: ' + contractStatus);

                        // Get unique AccountIds to obtain associated  Store Authorizations
                        Set<Id> AccountIds = new Map<Id, AggregateResult>([SELECT Account_Name__c Id, count(Id)  Counter FROM ER_Contract__c WHERE Id IN :contractIds  AND Product__c = :contractProduct AND Status__c = :contractStatus GROUP BY Account_Name__c ]).keySet();
                        
                        // small expcetion -  If contract is not active, then check if there is another Active Contract for this product
                        // In case there is active contract, remove account from the list, to not change Store Authorization to Inactive 
                        if (contractStatus != 'Active') {
                            Set<Id> accountsToSkip= new Map<Id, AggregateResult>([SELECT Account_Name__c Id, count(Id)  Counter FROM ER_Contract__c WHERE Account_Name__c  IN :AccountIds  AND Product__c = :contractProduct AND Status__c = 'Active' GROUP BY Account_Name__c ]).keySet();
                            System.Debug(' !!! Removing  following AccountIDs because they are having another Active Contract for the same product: ' + accountsToSkip);
                            AccountIds.removeAll(accountsToSkip);
                        }
                        
                        DebugLog('StoreAuth_ByContractHandler > for(distinctProductStatus loopID=' +critLoopID  + ') > AccountIds.size: ' + AccountIds.size());
        

                        // Get list of Store Authorization and iterate to populate behavior from contract
                        List<ER_Store__c> oStores = [SELECT Id, Name, AT_Accepts_Payment__c, 
                                                            (SELECT Id, Name, ER_Store__c, ER_Loop__c, ER_Behaviour__c FROM Stores_Authorization__r WHERE ER_Loop__c= :critLoopID),                                      
                                                            (SELECT Id FROM Acceptors__r WHERE ER_MID_Authorization__c != NULL /* AND  AT_Acceptor_Status__c='Active' */)        //TODO: Filter by Acceptor AT_Acceptor_Status__c also?
                                                            FROM ER_Store__c WHERE ER_Merchant__c IN :AccountIds];
                    

                        //
                        // Loop throught the  Stores  belonging to Accounts of which contracts beeing modified
                        // 
                        for (ER_Store__c oStore : oStores) {

                            // UPDATE Store Store Authorization
                            //
                            ER_Store_Authorization__c newSa = new ER_Store_Authorization__c();        //for further use in below

                            if(oStore.Stores_Authorization__r.size() == 0 && bDelete == false) {
                                // add Store Authorization
                                System.debug('>>>> No StoreAuthorization for StoreID: ' + oStore.Id + ' adding one');

                                newSa.ER_Store__c = oStore.Id;
                                newSa.ER_Loop__c = critLoopID;
                                newSa.ER_Behaviour__c = critBehaviour;
                                insert newSa;

                            } else { 
                                for(ER_Store_Authorization__c storeAuth : oStore.Stores_Authorization__r ) {
                                    if (bDelete)  {
                                            // delete Store Authorization
                                            System.debug('>>>> oStoreAuth deleting Store AUthorization Name=' + storeAuth.Name + ' behaviour old : ' + storeAuth.ER_Behaviour__c + ' behaviour new:' + critBehaviour );
                                            delete storeAuth;

                                    } else {
                                        // Update store authorization if behavior  has hanged (otherw)
                                        if (storeAuth.ER_Behaviour__c != critBehaviour)         // has behaviour changed?
                                        {   
                                            System.debug('>>>> oStoreAuth updating behavior for=' + storeAuth.Name + ' from: ' + storeAuth.ER_Behaviour__c + ' to:' + critBehaviour );
                                            storeAuth.ER_Behaviour__c = critBehaviour;
                                            update storeAuth;

                                        } // if behviour changed

                                    } // if bDelete                             


                                } // for  Store Authorizations

                            } // if Store has  no Store_Authorization

                        } // for oStorese

                        update oStores;
                } //for Products
        DebugLog('<<< CALL   StoreAuth_ByContractHandler()');
    } //StoreAuth_ByContractHandler



    // DESCRIPTION:
    // Delete Store Authorizations and Slave contracts when Contract Is Deleted
    //
    // DEPENDENCY / Called from:
    // -  ER_Contract__c.trgBefore.trigger
    //
    // STATUS: FINAL
    public static void Contract_BulkDeleteHandler(Set<id> contractIds) {
        // delete child contracts
        // Inactivate/Delete store authorizations
        System.Debug('>>> CALL   ContractBulkDelete_Handler() Contracts.size()=' + contractIds.size());

        // delete Store Authorizations first
        APAT01_ToolkitAT.StoreAuth_ByContractHandler(contractIds, True); 


        // find  Slave Contracts and  delete  them
        List<ER_Contract__c> oSlaveContracts = [SELECT Id, AT_MasterContract__c FROM ER_Contract__c WHERE AT_MasterContract__c IN :contractIds];
        delete oSlaveContracts;

        System.Debug('<<<   ContractBulkDelete_Handler()');
    } 



    // DESCRIPTION:
    // Get Stores which has no Store Authorization, and have active contract
    // Since multiple contracts can be inactive, it would trigger always to create inactive first
    //
    // DEPENDENCY / Called from:
    // -  ER_Store__c.trgStore trigger
    //
    // STATUS: FINAL
    public static void StoreAuth_ByStoreHandler(Set<Id> storeIds) {
        System.debug('>>> CALL   StoreAuth_ByStoreHandler() storeIds.size()=' + storeIds.size());

        Map<String, Id> mapProductsLoops = APAT01_ToolkitAT.GetProductsLoopsMap();

        for (String contractProduct : mapProductsLoops.keySet() ){
                
            List<ER_Store__c> oStores = [SELECT Id FROM ER_Store__c WHERE  Id IN :storeIds AND ER_Merchant__c IN (SELECT Account_Name__c FROM ER_Contract__c WHERE Status__c='Active' and Product__c =:contractProduct) AND Id NOT IN (SELECT ER_Store__c FROM ER_Store_Authorization__c WHERE ER_Loop__c = :mapProductsLoops.get(contractProduct))];

            System.debug('::: StoreAuth_ByStoreHandler for Contract Product: ' +  contractProduct + ' size of oStores: ' + oStores.Size());

            List<ER_Store_Authorization__c> oStoreAuths  = new List<ER_Store_Authorization__c>();

            for (ER_Store__c oStore : oStores) {
                    System.debug('::: StoreAuth_ByStoreHandler for() stores which dont have SA for product ' + contractProduct + ' StoreID: ' + oStore.Id);
                    ER_Store_Authorization__c sa = new ER_Store_Authorization__c();
                    sa.ER_Store__c = oStore.Id;
                    sa.ER_Loop__c = mapProductsLoops.get(contractProduct);                     
                    sa.ER_Behaviour__c = 'ACCEPT';
                    oStoreAuths.add(sa);
            }
            insert oStoreAuths;
        }

        System.debug('<<<   StoreAuth_ByStoreHandler()');
    }


    // result holder
    class resultClass {
        public List<String[]> dataRows = new List<String[]>();
        public List<String> errors = new List<String>();
        public Boolean wasError = false;
    }

    // DESCRIPTION:
    // Ensures that Account Status is in synch with Contracts
    //
    // DEPENDENCY / Called from:
    // -  Schedule Job -> SchedulerStatusManager
    //
    // STATUS: FINAL
    public static resultClass ContractStatusUpdate_Hanlder() {
        System.debug('*** CALL    ContractStatusUpdate_Hanlder()  isBatch=' + System.isBatch() + ' |  isScheduled=' +  System.isScheduled() );

        resultClass ret = new resultClass();

        List<String[]> result = new List<String[]>();                                           // holds list of changed Contracts
        List<String> errors = new List<String>();                                             // holds errors

        List<ER_Contract__c> ctrList;
        List<string> statuses = new List<String>();                                         // holds statuses
        List<List<ER_Contract__c>> contractsList = new List<List<ER_Contract__c>>();        // records list and target status
        Integer recordsToChange = 0;
        
        //SFR-1759 - Fix contracts list update issue
        List<ER_Contract__c> contractsListToUpdate = new List<ER_Contract__c>();

        // Find contracts which should be set to Inactive
        statuses.add('Inactive');
        ctrList = [SELECT Id, Name, Product__c, Status__c, Contract_Start_Date__c, Contract_Reopen_Date__c,  Contract_Close_Date__c, RecordType.Name, Account_Name__c, Account_Name__r.Name, Account_Name__r.Partner_Code__c   from ER_Contract__c 
                                    WHERE AT_MasterContract__c = NULL  AND Status__c != :statuses[0]
                                    AND (Contract_Close_Date__c  <=  TODAY OR Contract_Start_Date__c  >  TODAY)
                                    ORDER BY Contract_Close_Date__c 
                                    ];

        contractsList.add(ctrList);
        recordsToChange = recordsToChange + ctrList.size();

        // Find contracts whihc should be set to Active
        statuses.add('Active');
        ctrList = [SELECT Id, Name, Product__c, Status__c, Contract_Start_Date__c, Contract_Reopen_Date__c,  Contract_Close_Date__c, RecordType.Name, Account_Name__c, Account_Name__r.Name, Account_Name__r.Partner_Code__c   from ER_Contract__c 
                                    WHERE  AT_MasterContract__c = NULL  AND Status__c != :statuses[1]
                                    AND Contract_Start_Date__c <= TODAY
                                    AND (Contract_Close_Date__c = NULL OR Contract_Close_Date__c  >  TODAY)
                                    ORDER BY Contract_Start_Date__c 
                                    ];
        contractsList.add(ctrList);
        recordsToChange = recordsToChange + ctrList.size();


        
        for (integer i=0 ; i <= statuses.size() -1 ; i++) {

            for (ER_Contract__c ctr : contractsList[i]) {
                //System.debug('--- Updating  Contract (Id=' + ctr.Id + ' AccountId=' +  ctr.Account_Name__c + ')     Status: ' + ctr.Status__c + ' => ' + statuses[i]);
                
                //result.add('Id: ' + ctr.Id + ' Contract: '  + ctr.Name + ' |  Account: ' +  ctr.Account_Name__r.Name + ' | Partner: ' + ctr.Account_Name__r.Partner_Code__c  + ' | Product: ' + ctr.Product__c + ' | Status: ' + ctr.Status__c + ' => ' + statuses[i]);
                
                result.add(new String[]{
                                ctr.Account_Name__r.Partner_Code__c,
                                ctr.Account_Name__r.Id,
                                ctr.Account_Name__r.Name,
                                ctr.Id,
                                ctr.Name, 
                                ctr.Product__c,
                                ctr.Status__c +  ' => ' + statuses[i]
                                });
                ctr.Status__c = statuses[i];
                
                contractsListToUpdate.add(ctr);  //SFR-1759

                /*Database.SaveResult[] srList = Database.update(contractsList[i]);

                for (Database.SaveResult sr : srList) {
                    if (! sr.isSuccess()) {
                        ret.wasError = true;

                        // Operation failed, so get all errors        
                        errors.add('\r\n[ERROR] following errors (' + sr.getErrors().size() + ') has occurred:');  

                        for(Database.Error err : sr.getErrors()) {               
                            errors.add('\r\n' + err.getStatusCode() + ': ' + err.getMessage() + ' FIELDS: ' + err.getFields());
                        } //errors

                    } // if !isSuccess

                } //for sr */
                
            } // for statuses

        } // for statuses
        
        //SFR-1759 - Logic moved outside the for loop
        if(!contractsListToUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update(contractsListToUpdate);

            for (Database.SaveResult sr : srList) {
                if (! sr.isSuccess()) {
                    ret.wasError = true;
                    
                    // Operation failed, so get all errors        
                    errors.add('\r\n[ERROR] following errors (' + sr.getErrors().size() + ') has occurred:');  
                    
                    for(Database.Error err : sr.getErrors()) {               
                        errors.add('\r\n' + err.getStatusCode() + ': ' + err.getMessage() + ' FIELDS: ' + err.getFields());
                    } //errors
                    
                } // if !isSuccess
                
            } //for sr */
        }
        

        System.debug('<<<   ContractStatusUpdate_Hanlder()');

        ret.dataRows = result;
        ret.errors = errors;


        return ret;
    } // Contract_StatusUpdateHanlder
    
 
    // DESCRIPTION:
    // Copy Ticket Restaurant Contract to Ticket Service contract and sets the AT_MasterContract contract as TRC.
    // list of fields created/updated on slave contract is managed dynamically, and it supports correctly case when old contract get new value = NULL which is not passed in Trigger
    //
    // DEPENDENCY / Called from:
    //  - trgContractAfter.trigger - Creates / Updates the TSC contract based on TRC contract
    //
    // STATUS: FINAL

    public static void ReplicateContractTRCtoTSC(Set<Id> contractIds){
        System.Debug('>>> CALL    ReplicateContractTRCtoTSC() size of ContractID: ' +contractIds.size());

            String soql;
            
            soql = APAT01_ToolkitAT.getCreatableFieldsSOQL('ER_Contract__c','Id IN :contractIds ');
            List<ER_Contract__c> oContractSource  = (List<ER_Contract__c>)Database.query(soql);

            soql = APAT01_ToolkitAT.getCreatableFieldsSOQL('ER_Contract__c','AT_MasterContract__c IN :contractIds ');
            List<ER_Contract__c> oSlaveContracts = (List<ER_Contract__c>)Database.query(soql);


            Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('ER_Contract__c').getDescribe().Fields.getMap();
            Set<string> fieldsNullable = new Set<string>();
            Set<string> fieldsUnique = new Set<string>();


            List<ER_Contract__c> slaveContractsToUpsert = new List<ER_contract__C>();       
            List<ER_Contract__c> slaveContractsToInsert = new List<ER_contract__C>();

            if (fMap != null){
                for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if (fd.isUpdateable())
                        fieldsNullable.add(fd.getName());
                    
                    if (fd.isUnique())
                        fieldsUnique.add(fd.getName());                  
                    }
                }

            for(ER_Contract__c o : oContractSource){
                //System.debug('::: Clonning  Contract:  ContractID=' + o.Id + ' AccountId=' +  o.Account_Name__c);
                
                ER_Contract__c oClone = new ER_Contract__c();
                Integer qtySlaveContracts = 0;


                for(ER_Contract__c oSlaveContract : oSlaveContracts) {
                    if(oSlaveContract.AT_MasterContract__c == o.Id) {
                            System.debug('::: Found Existing Slave for Contract Id: ' + o.Id + ' of product ' + oSlaveContract.Product__c + ' contract ID: ' + oSlaveContract.Id);
                            
                            oClone = o.Clone(false, true, false, false);               // get master contract data

                            // target (cloned) object needs to be explicitly nullified, because fields changing values to NULL are not present/copied wiht o.Clone instruction
                            // without this they would maintain  old value and contracts would be inconsistent
                            for(string f : fieldsNullable) {
                                    try{
                                        if(oClone.get(f) == NULL){
                                            oClone.put(f,NULL);
                                        }
                                    } catch (exception e) {}    // don't cath exceptions - they should be related only with fields which can't be set as null
                            }

                            // set unique fields = NULL otherwise cloning would fail
                            for(string f : fieldsUnique) {
                                    try{ oClone.put(f,NULL); }
                                    catch (exception e) {}    // don't catch exceptions
                            }


                            // override values
                            oClone.Contract_ID__c = NULL;                               // It's  set as Unique, so can't be replicated from Master Contract
                            oClone.Id = oSlaveContract.Id;                              // restore oryginal Contract Id
                            oClone.AT_MasterContract__c = o.Id;                         // restore Master Contract Id
                            oClone.Product__c = oSlaveContract.Product__c;              // restore oryginal Product Id
                            
                            

                            //upsert oClone;      // KA190207 causes trigger to fire record by record
                            slaveContractsToUpsert.add(oClone);

                            //System.Debug('::: !!! Replicating: Oryginal Contract: ' + o);
                            //System.Debug('::: !!! Replicating: Slave Contract: +  ' + oClone);

                            qtySlaveContracts++; 
                    } // if is slave contract
                }



                // if no slave contract has been found,  create one
                if (qtySlaveContracts == 0){
                        System.debug('::: Cloning Contract ' + o.Id + ' for product Ticket Service Card for Account:' + o.Account_Name__c);
                        oClone = o.Clone(false, true, false, false);

                        // Clean/Null fields  which needs to be unique, otherwise insert  will fail.
                        for(string f : fieldsUnique) {
                            oClone.put(f,NULL);    
                        }

                        oClone.Product__c = 'Ticket Service Card';
                        oClone.AT_MasterContract__c = o.id;
                        //insert oClone;                        // KA190207 causes trigger to fire record by record
                        slaveContractsToInsert.add(oClone);         
                }

            }

            upsert slaveContractsToUpsert;
            insert slaveContractsToInsert;

        System.Debug('<<< ReplicateContractTRCtoTSC()');
    }

    // DESCRIPTION:
    // Update Contract statuses (depend on the Start & Close dates) and then update Account statuses based on Contract Statuses
    //
    // DEPENDENCY / Called from
    // - SchedulerStatusManager - APEX job
    // STATUS: FINAL

    class emailHtmlClass{

        public String HTML = '';

        public String crlf = '\r\n<br/>';

        public String css = '<style type="text/css" media="screen">' + 
                        'table.blueTable{border:1px solid #1C6EA4;background-color:#EEE;width:100%;text-align:left;border-collapse:collapse}table.blueTable td,table.blueTable th{text-align:left;border:1px solid #AAA;padding:3px 2px}table.blueTable tbody td{font-size:13px}table.blueTable tr:nth-child(even){background:#D0E4F5}table.blueTable thead{background:#1C6EA4;background:-moz-linear-gradient(top,#5592bb 0%,#327cad 66%,#1C6EA4 100%);background:-webkit-linear-gradient(top,#5592bb 0%,#327cad 66%,#1C6EA4 100%);background:linear-gradient(to bottom,#5592bb 0%,#327cad 66%,#1C6EA4 100%);border-bottom:2px solid #444}table.blueTable thead th{font-size:15px;font-weight:700;color:#FFF;border-left:2px solid #D0E4F5}table.blueTable thead th:first-child{border-left:none}table.blueTable tfoot{font-size:14px;font-weight:700;color:#FFF;background:#D0E4F5;background:-moz-linear-gradient(top,#dcebf7 0%,#d4e6f6 66%,#D0E4F5 100%);background:-webkit-linear-gradient(top,#dcebf7 0%,#d4e6f6 66%,#D0E4F5 100%);background:linear-gradient(to bottom,#dcebf7 0%,#d4e6f6 66%,#D0E4F5 100%);border-top:2px solid #444}table.blueTable tfoot td{font-size:14px}table.blueTable tfoot .links{text-align:right}table.blueTable tfoot .links a{display:inline-block;background:#1C6EA4;color:#FFF;padding:2px 8px;border-radius:5px}'
                       + '</style>' ;

        
      

        public String tag(String sTag, Integer i) {
            //String tdSeparator = '</td><td>';

            string Ret;

                switch on (i){
                    WHEN 1 { Ret = '<' + sTag + '>'; }
                    WHEN 2 { Ret = '</' + sTag + '><' + sTag + '>'; }
                    WHEN 3 { Ret = '</' + sTag + '>'; }
                }
                
            return Ret;
            }



        public void addTableHeader(String[] aColumns){
            HTML+=  '<table class="blueTable"><tr><th>' + String.join(aColumns, '</th><th>') + '</th></tr>';
        }

        public void addTableRow(String[] aColumns) {
            HTML+=  tag('tr',1) + tag('td', 1) + String.join(aColumns, tag('td',2)) + tag('td',3) + tag('tr',3);

        }

        public void addTableRow(List<String[]> aColumns) {
            for (String[] row : aColumns){
                addTableRow(row);
            }

        }

        public void addTableClose() {
            HTML+= tag('table',3);
        }

        public void addParagraph(String str){
            HTML+= tag('br',3) +  str;
        }


        public String GetHTML(){
            return css + HTML;
        }

    }



    public static void statusManager(){
        Set<Id> accountIds = new Set<Id>();
        resultClass contractResult = new resultClass();
        List<String[]> accountResult;
        String emailBody;
        String crlf = '\r\n<br/>';
        String tdSeparator = '</td><td>';
        

        emailHtmlClass htmlEmail = new emailHtmlClass();



        String finalStatus;
        

        system.debug('>>> SchedulerStatusManager() START');
        
        // first update Contract Statuses, because Account Statuses depends on Contracts
        // Contract Status can change on a dialy basis because of Contract Start and End date whihch can be set in future
       

        try{

            // Execute and get List of updated Contracts
            contractResult = APAT01_ToolkitAT.ContractStatusUpdate_Hanlder();

            // build list of Accounts which needs to be changed
            // Accounts which Stauts=Active but have no active  Contract
            accountIds.addAll((new Map<Id,Account>([SELECT Id FROM Account WHERE Status__c  = 'Active' AND Id Not IN (SELECT Account_Name__c FROM ER_Contract__c WHERE Status__c='Active')])).keySet());
            
            // Accounts which Stauts is not Active but have Active Contract
            accountIds.addAll((new Map<Id,Account>([SELECT Id FROM Account WHERE Status__c != 'Active' AND Id     IN (SELECT Account_Name__c FROM ER_Contract__c WHERE Status__c='Active')])).keySet());

            // Execute and get list of updated Accounts
            accountResult = APAT01_ToolkitAT.AccountStatus_BatchUpdate(accountIds);
            
            //emailBody = 'Status Management Job has completed. \r\n\r\n';

            htmlEmail.addParagraph('Status Management Job has completed.');
            htmlEmail.addParagraph('Contracts processsed: ' + contractResult.dataRows.size() );
            htmlEmail.addTableHeader(new String[]{'Partner Code','Account Name', 'Contract Name', 'Product', 'Status change'});
                for (String[] row : contractResult.dataRows) {
                    htmlEmail.addTableRow(new String[]{
                                row[0],
                                '<a href=' + URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + row[1] + '/view>' + row[2] + '</a>',
                                '<a href=' + URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + row[3] + '/view>' + row[4] + '</a>',
                                row[5],
                                row[6]
                    });
                }

            //htmlEmail.addTableRow(contractResult.dataRows);
            htmlEmail.addTableClose();
            //emailBody = emailBody + 'Contract processed: ' + contractResult.size() + ' \r\n';
            //emailBody = emailBody + string.join(contractResult, '\r\n');

            //emailBody = emailBody + '\r\n\r\n';
            //emailBody = emailBody + 'Account processed: ' + accountResult.size() + ' \r\n';
            //emailBody = emailBody + string.join(accountResult, '\r\n');
            htmlEmail.addParagraph( 'Account processed: ' + accountResult.size() );
            htmlEmail.addTableHeader(new String[]{'RecordType', 'Account', 'Partner Code',  'Status change'});
                    for (String[] row : accountResult) {
                    htmlEmail.addTableRow(new String[]{
                                row[1],     //record type
                                '<a href=' + URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + row[0] + '/view>' + row[2] + '</a>',
                                row[3], //Partner Code
                                row[4]
                    });
                }

            //htmlEmail.addTableRow(accountResult);
            htmlEmail.addTableClose();



            Map<String, AggregateResult> storeCount = new Map<String,AggregateResult>();
            List<AggregateResult> storeAuthStats;
            
            storeAuthStats = [SELECT ER_Behaviour__c Behavior, ER_Loop__r.ER_Reference__c LoopRef, ER_Loop__r.Name LoopName, ER_Store__r.AT_Status__c StoreStatus,  count(id)  Counter FROM ER_Store_Authorization__C WHERE ER_Store__r.AT_Status__c='Active' AND ER_Behaviour__c='ACCEPT' GROUP BY ER_Loop__r.ER_Reference__c, ER_Loop__r.Name, ER_Behaviour__c, ER_Store__r.AT_Status__c ORDER BY ER_Behaviour__c, ER_Loop__r.ER_Reference__c];

            //SELECT AT_Status__c, count(id) FROM ER_Store__c GROUP BY AT_Status__c


             

            


            //emailBody = emailBody + '\r\n\r\nStatistic - Active Stores:';
            //emailBody = emailBody + '\r\nBehavior   |  Loop Ref.  |  Loop Name  |  Stores  |   MIDs';

            htmlEmail.addParagraph('Statistic - Active Stores:');
            htmlEmail.addTableHeader(new String[]{'Behavior', 'Loop Ref.', 'Loop Name', 'Stores', 'MIDs'});
            for (AggregateResult stat : storeAuthStats) {
               //get unique number of MIDs
               
                //List<AggregateResult> midCount = [SELECT count_distinct(ER_MID_Authorization__c) midCount FROM ER_Acceptor__c WHERE ER_Store__c IN (SELECT ER_Store__c FROM ER_Store_Authorization__c WHERE ER_Loop__r.ER_Reference__c=:stat.get('LoopRef') AND ER_Store__r.AT_Status__c=:stat.get('Behavior'))];
                AggregateResult midCount = [SELECT count_distinct(ER_MID_Authorization__c) midCount FROM ER_Acceptor__c WHERE ER_Store__c IN (SELECT ER_Store__c FROM ER_Store_Authorization__c WHERE ER_Loop__r.ER_Reference__c = :(string)stat.get('LoopRef') AND ER_Behaviour__c = :(string)stat.get('Behavior') AND ER_Store__r.AT_Status__c IN ('Active', 'X-Directory'))];

                //emailBody = emailBody + '\r\n' + stat.get('Behavior') + '  |  ' + stat.get('LoopRef') + '  |  ' + stat.get('LoopName') + '            |  ' + stat.get('Counter') + '  |  ' + midCount.get('midCount');
                htmlEmail.addTableRow(new String[]{ 
                                (string)stat.get('Behavior'), 
                                (string)stat.get('LoopRef'), 
                                (string)stat.get('LoopName'), 
                                String.ValueOf(stat.get('Counter')), 
                                String.ValueOf(midCount.get('midCount')) 
                                });
            }

            htmlEmail.addTableClose();


            storeAuthStats = [SELECT ER_Behaviour__c Behavior, ER_Loop__r.ER_Reference__c LoopRef, ER_Loop__r.Name LoopName, ER_Store__r.AT_Status__c StoreStatus,  count(id)  Counter FROM ER_Store_Authorization__C WHERE ER_Store__r.AT_Status__c !='Active' OR ER_Behaviour__c!='ACCEPT' GROUP BY ER_Loop__r.ER_Reference__c, ER_Loop__r.Name, ER_Behaviour__c, ER_Store__r.AT_Status__c ORDER BY ER_Behaviour__c, ER_Loop__r.ER_Reference__c];

            //emailBody = emailBody + '\r\n\r\nStatistic - NOT active Stores:';
            //emailBody = emailBody + '\r\nBehavior   |  Loop Ref.  |  Loop Name  |  Stores';

            htmlEmail.addParagraph('Statistic - inactive Stores:');
            htmlEmail.addTableHeader(new String[]{'Behavior', 'Loop Ref.', 'Loop Name', 'Stores'});
            for (AggregateResult stat : storeAuthStats) {
               
                //emailBody = emailBody + '\r\n' + stat.get('Behavior') + '  |  ' + stat.get('LoopRef') + '  |  ' + stat.get('LoopName') + '            |  ' + stat.get('Counter') ;
                htmlEmail.addTableRow(new String[]{
                    String.ValueOf(stat.get('Behavior')),
                    String.ValueOf(stat.get('LoopRef')),
                    String.ValueOf(stat.get('LoopName')),
                    String.ValueOf(stat.get('Counter'))
                });
            }
            htmlEmail.addTableClose();


            //System.debug('Debug #1: E-mail body: ' + emailBody);
            //System.debug('Debug #1: E-HTML body: ' + htmlEmail.GetHTML());

           if (contractResult.wasError)
                finalStatus = 'WARNING';
            else 
                finalStatus = 'SUCCESS';

        }
        catch (exception e) {
            finalStatus =  'ERROR';
            htmlEmail.addParagraph('There was error while executing the job:');
            htmlEmail.addParagraph(e.getMessage());
            
            //emailBody = emailBody + e.getMessage();

            
        }

        //System.debug('E-mail body: ' + emailBody);
        APAT01_ToolkitAT.sendNotificationEmail('Salesforce Status Management Job [' +  finalStatus + ']' ,htmlEmail.GetHTML());

        
        System.Debug('<<< SchedulerStatusManager() END');
    }

    // DESCRIPTION:
    // Function to check data consistency, and send report over e-mail
    // covers:
    //  #1 List Accpetors which has the sub-MID capable MID, but the sub-MID is not indicated
    //  #2 List Stores which has store authorization, but has no contract
    //  #3 List Stores which has store authorization decision inconsistent with Active contract (anomalies/exception report) 
    //  #4 List of Merchants which has a Contract but has no corresponding Store Authorization
    //
    // STATUS: DEV
    public static void  consistencyCheck() {
        
        String[] p = new String[5]; // e-mail partials
        String emailBody = '';
        emailHtmlClass htmlEmail = new emailHtmlClass();
        List<Integer> resultRecCount = new List<Integer>();

 
        String finalStatus = 'OK';
        Integer i = 1;
        Integer iRec = 0;
        Id recTypeMerCtr = GetRecordTypeId('ER_Contract__c', 'Affiliate_Contract_RT');
        Map<String, Id> mapProdctsLoops  =  GetProductsLoopsMap();
        Map<String, ER_Loop__c> mapProductLoopFull = ProductLoopFullMap();

        // get accounts which has Affiliate contract for card Products
        Set<Id> accountFilter = new Map<Id, AggregateResult>([SELECT Account_Name__c Id FROM ER_Contract__c WHERE RecordTypeId = :GetRecordTypeId('ER_Contract__c', 'Affiliate_Contract_RT') AND Product__c IN :CardProductList() GROUP BY Account_Name__c ]).keySet();


        
        List<Account> lstAccountAndStores = [SELECT Id, (SELECT Id, Name FROM Stores__r) FROM Account WHERE Id IN :accountFilter];
            Map<Id, List<ER_Store__c>> mapMerchantStores = new Map<Id,List<ER_Store__c>>();
            for (Account a : lstAccountAndStores) {
                mapMerchantStores.put(CompositeKey(a.Id), a.Stores__r);
            }
        
        lstAccountAndStores = NULL;

        // get Stores of merchants with contracts
        

        
        Map<String, List<ER_Store_Authorization__c>> mapMerchantStoreAuth = new Map<String, List<ER_Store_Authorization__c>>();
        List<ER_Store_Authorization__c> storeAuth = [SELECT Id, Name,  ER_Store__c, ER_Loop__c, ER_Loop__r.Name, ER_Behaviour__c, ER_Store__r.Name, ER_Store__r.ER_Merchant__c FROM ER_Store_Authorization__c WHERE  ER_Store__r.ER_Merchant__c IN  :accountFilter AND ER_Loop__c IN :mapProdctsLoops.values() ];


        //list of Accounts and Contracts-Products
        List<AggregateResult> ctrProdStatAggr = [SELECT Account_Name__c, Product__c, Status__c, count(Id) ContractQty FROM ER_Contract__c WHERE  Account_Name__c IN :accountFilter AND  RecordTypeId= :recTypeMerCtr AND Product__c IN :CardProductList()  GROUP BY Account_Name__c, Product__c, Status__c] ;

            Map<String,Integer> mapCtrProdStatAggr = new Map<String, Integer>();

            for (AggregateResult a : ctrProdStatAggr){
                mapCtrProdStatAggr.put( String.valueof(a.get('Account_Name__c')) + '.' + a.get('Product__c') + '.' + a.get('Status__c'), (Integer)a.get('ContractQty'));
            }


        //list of Stores and SA
        List<AggregateResult> lstStoresAuthAggr = [SELECT ER_Store__r.ER_Merchant__c, ER_Store__c, ER_Loop__c, count(id) Counter FROM ER_Store_Authorization__c GROUP BY ER_Store__r.ER_Merchant__c, ER_Store__c, ER_Loop__c];
            Map<String, Integer> mapStoresAuthAggr = new map<String,Integer>();
            
            for (AggregateResult a : lstStoresAuthAggr) {
                mapStoresAuthAggr.put(  String.ValueOf(a.get('ER_Store__c'))  + '.' + String.ValueOf(a.get('ER_loop__c')), (Integer)a.get('Counter'));
            }


        List<ER_Store_Authorization__c> storeAuthWithoutContract = [SELECT id, Name, ER_Behaviour__c,  ER_Loop__r.Name, ER_Store__r.Name, ER_Store__r.ER_Merchant__r.Name, ER_Store__r.ER_Merchant__r.Partner_Code__c FROM ER_Store_Authorization__c WHERE ER_Store__r.ER_Merchant__r.Id NOT IN :accountFilter ORDER BY ER_Store__r.ER_Merchant__r.Partner_Code__c ];


         //System.debug('storeAuthWithoutContract: ' + storeAuthWithoutContract);


        //  #1 List Accpetors which has the sub-MID capable MID, but the sub-MID is not indicated
        List<String> acceptorList = new List<String>();
        Set<String> midsWithSubMIDs = new Map<String, AggregateResult>([SELECT ER_MID_Authorization__c Id, count(Id) FROM ER_Acceptor__c WHERE ER_Sub_MID_Authorization__c !=NULL GROUP BY ER_MID_Authorization__c  ]).keySet();

        //System.debug('midsWithSubMIDs: ' + midsWithSubMIDs);
        List<ER_Acceptor__c> acceptorsWithMissingSubMID = [SELECT Id, Name, ER_MID_Authorization__c, ER_Store__c, ER_Store__r.Name, ER_Store__r.ER_Merchant__c,  ER_Store__r.ER_Merchant__r.Name,  ER_Store__r.ER_Merchant__r.Partner_Code__c
                                                            FROM ER_Acceptor__c  
                                                            WHERE (ER_Sub_MID_Authorization__c =NULL OR ER_Sub_MID_Authorization__c = ' ') 
                                                                AND ER_MID_Authorization__c IN :midsWithSubMIDs
                                                            ORDER BY ER_Store__r.ER_Merchant__r.Partner_Code__c, ER_MID_Authorization__c ];





        resultRecCount.add(acceptorsWithMissingSubMID.size());
        htmlEmail.addParagraph('Report #1 - Provide subMID for following Acceptors (' + acceptorsWithMissingSubMID.size() + '):' );
        htmlEmail.addTableHeader( new String[]{'#', 'Partner Code', 'Account Name', 'Acceptor', 'Auth. MID'});
        
        for (ER_Acceptor__c x : acceptorsWithMissingSubMID) {
            
            iRec++;
            Account acc = x.ER_Store__r.ER_Merchant__r;


            htmlEmail.addTableRow(new String[]{
                String.ValueOF(iRec),
                acc.Partner_Code__c,
                '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + acc.Id + '/view>' + acc.Name + '</a>',
                '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + x.Id + '/view>' + x.Name + '</a>',
                x.ER_MID_Authorization__c


            });
        }
  
        htmlEmail.addTableClose();



        //  #2 List Stores which has store authorization, but has no contract
        // 
        //List<Account> accountFilter = [SELECT Id FROM Account WHERE Id NOT IN (SELECT  FROM ER_Contract__c)];
        //Affiliate_Contract_RT

        i = 2;
        iRec = 0;

        resultRecCount.add(storeAuthWithoutContract.size());
        htmlEmail.addParagraph('Report #2 - List of Store Authorization which has no Merchant Contract (' + storeAuthWithoutContract.size()  + '):' );
        htmlEmail.addTableHeader( new String[]{'#', 'Partner Code', 'Account Name', 'Store', 'Loop', 'Behaviour', 'StoreAuth.'});
        
        iRec=0;
        for (ER_Store_Authorization__c x : storeAuthWithoutContract) {
            iRec++;

            Account acc = x.ER_Store__r.ER_Merchant__r;
                htmlEmail.addTableRow(new String[]{
                    String.ValueOF(iRec),
                    acc.Partner_Code__c, 
                    '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + acc.Id + '/view' + '>' + acc.Name + '</a>',
                    '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + x.ER_Store__c + '/view' + '>' + x.ER_Store__r.Name + '</a>',
                    x.ER_Loop__r.Name, 
                    x.ER_Behaviour__c, 
                    '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + x.Id + '/view' + '>' + x.Name + '</a>'
            });
        }

        htmlEmail.addTableClose();

    //  #3 List Stores which has store authorization decision inconsistent with Active contract (anomalies/exception report) 


        for (ER_Store_Authorization__c x : storeAuth ) {

            List<ER_Store_Authorization__c> tmpSA = mapMerchantStoreAuth.get(String.ValueOf(x.ER_Store__r.ER_Merchant__c) + '.' + x.ER_Loop__c);

            // check if value is already in map, if not add it, if yes, add another entry to the existing list
            if (tmpSA == NULL) 
                tmpSA =  new List<ER_Store_Authorization__c>();
  
            tmpSA.add(x);
            mapMerchantStoreAuth.put(String.ValueOf(x.ER_Store__r.ER_Merchant__c) + '.' +  String.ValueOf(x.ER_Loop__c), tmpSA);
        }

        System.debug('mapMerchantStoreAuth'+ mapMerchantStoreAuth);


        List<ER_Contract__c> cardContracts = [SELECT Id, Name,  Account_Name__c, Product__c, Status__c, Account_name__r.Id, Account_name__r.Name, Account_name__r.Partner_Code__c 
                                                FROM ER_Contract__c 
                                                WHERE  Account_name__c IN  :accountFilter 
                                                        AND Product__c IN :mapProdctsLoops.keySet() 
                                                        AND RecordTypeId = : recTypeMerCtr
                                                ORDER BY Account_name__r.Partner_Code__c ];

            //remove from the list contracts with Status__c='Inactive' which has another Active variant





        List<String[]> lstReport3 = new List<String[]>();
        
        //iterate throught contracts
        for(ER_Contract__c ctr : cardContracts) {

            //get how many Active Contracts is for given Account and Product
            Integer nbActiveContracts = mapCtrProdStatAggr.get(String.valueOf(ctr.Account_Name__c) + '.' +  ctr.Product__c + '.Active');
            if (nbActiveContracts == NULL)
                nbActiveContracts = 0;


            // iterate throught mapMerchantStoreAuth and compare

            //get Merchant's Store Authorization
            List<ER_Store_Authorization__c> merchantSA = mapMerchantStoreAuth.get(String.ValueOf(ctr.Account_Name__c) + '.' +String.ValueOf(mapProdctsLoops.get(ctr.Product__c)));

            if (merchantSA == NULL) {
                merchantSA = new List<ER_Store_Authorization__c>();
                merchantSA.add(new ER_Store_Authorization__c(ER_Behaviour__c='NON EXISTING', ER_Loop__c = mapProdctsLoops.get(ctr.Product__c)));
            }


            for (ER_Store_Authorization__c x : merchantSA) {

                // compare Store Authorizations to given Product and Contract
                if ( x.ER_Loop__c == mapProdctsLoops.get(ctr.Product__c)   &&   x.ER_Behaviour__c !=  GetSABehaviourByStatus(ctr.Status__c) && !( ctr.Status__c !='Active' &&  nbActiveContracts >0  ) ) {
                    
                    iRec++;

                    Account acc = ctr.Account_Name__r;
                    lstReport3.add(new String[]{acc.Partner_Code__c, acc.Id, acc.Name, ctr.Id, ctr.Name, ctr.Product__c, ctr.Status__c, x.ER_Store__c, x.ER_Store__r.Name , x.ER_Loop__r.Name , x.ER_Behaviour__c, x.Id,  x.Name   });

                }
            }
        }


        i = 3;
        iRec = 0;
  
        resultRecCount.add(lstReport3.size());
        htmlEmail.addParagraph('Report #3 - List of Store Authorization inconsistent with Merchant Active Contract (' + lstReport3.size() + '):' );
        htmlEmail.addTableHeader( new String[]{'#', 'Partner Code', 'Account', 'Contract', 'Contract Status', 'Store', 'Loop', 'Behaviour', 'StoreAuth.'});

        for (String[] s : lstReport3) {

                    iRec++;  

     
                    htmlEmail.addTableRow(new String[]{
                            String.ValueOF(iRec),
                            s[0],  
                            '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + s[1] + '/view' + '>' + s[2]+ '</a>',
                            '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + s[3]+ '/view' + '>' + s[4] +'</a>&nbsp; ' + s[5],
                            s[6],
                            s[7] == NULL ? '' : '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + s[7]+ '/view' + '>' + s[8] + '</a>',                           // Store
                            s[9],       //loop  
                            s[10],      // behaviour
                            s[11] == NULL ? '' : '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' +s[11]+ '/view' + '>' + s[12] + '</a>'      //StoreAuth
                    });

                                    
        }

 
        htmlEmail.addTableClose();
        //lstReport3 = NULL;
        

        i = 4;
        iRec = 0;
        List<String[]> lstReport4 = new List<String[]>();
        Integer nStoreAuthQty = 0;
        //iterate throught contracts
        for(ER_Contract__c ctr : cardContracts) {

            if (ctr.Status__c == 'Active'){
                
                // find ALL stores of given merchant, and check, if store has StoreAuth for given Product

                for (ER_Store__c store : mapMerchantStores.get(CompositeKey(ctr.Account_Name__c))) {
                    nStoreAuthQty =  mapStoresAuthAggr.get(String.ValueOf(store.Id) + '.' + String.ValueOf(mapProdctsLoops.get(ctr.Product__c)));

                    if (nStoreAuthQty ==0 || nStoreAuthQty == NULL ) {
                            iRec++;
                            Account acc = ctr.Account_Name__r;
                            lstREport4.add(new String[]{
                                        acc.Partner_Code__c,// 0
                                        acc.Id,             // 1
                                        acc.Name,           // 2
                                        ctr.Id,             // 3
                                        ctr.Name,           // 4
                                        ctr.Product__c,     // 5
                                        ctr.Status__c,      // 6
                                        store.ID,           // 7
                                        store.Name          // 8
                                        });
                                                        
                   }
                    
                }
            }
        }


        resultRecCount.add(lstReport4.size());
        htmlEmail.addParagraph('Report #4 - Missing Store Authorizations(' + lstReport4.size() + '):' );
        htmlEmail.addTableHeader( new String[]{'#', 'Partner Code', 'Account', 'Contract', 'Contract Status', 'Store', 'Missing SA for Loop'});

        iRec=0;
        for(String[] s : lstReport4) {
            iRec++;


            htmlEmail.addTableRow(new String[]{
                    String.ValueOF(iRec),
                    s[0],  
                    '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + s[1] + '/view' + '>' + s[2] + '</a>', 
                    '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + s[3] + '/view' + '>' + s[4]+'</a>&nbsp; ' + s[5],
                    s[6],
                    '<a href=' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/' + s[7] + '/view' + '>' + s[8] + '</a>',
                    mapProductLoopFull.get(s[5]).Name        // loop name of missing SA
            });


        }

        htmlEmail.addTableClose();

        //lstReport4 = NULL;
        

        for(Integer cnt : resultRecCount) {
            if (cnt>0)
                finalStatus = 'WARNING';
        }

        APAT01_ToolkitAT.sendNotificationEmail('Salesforce Consistency Check Job [' +  finalStatus + ']' , htmlEmail.GetHTML());

    }
    // DESCRIPTION:
    // Function to be executed after deployment of the solution to Preprod/PROD
    // This process existing contracts and creates relationship between Ticket Restaurant Card Contract (Master) and Ticket Service Card Contract (Slave)
    //
    // STATUS: TO IMPROVE
    public static void makeMasterSlaveContractRelationship() {
        System.Debug('>>>   CALL makeMasterSlaveContractRelationship()');


        List<ER_Contract__c> contractsToUpdateSlave = new List<ER_Contract__c>();
        List<ER_Contract__c> contractsToUpdateMaster = new List<ER_Contract__c>();
        
        List<ER_Contract__c> contractsTR = [SELECT Id, Name, Account_Name__c, Account_Name__r.Name, Product__c 
                                                    FROM ER_Contract__c 
                                                    WHERE Product__c='Ticket Restaurant Card' 
                                                        AND RecordTypeId =:GetRecordTypeId('ER_Contract__c', 'Affiliate_Contract_RT')
                                                        AND Status__c='Active'
                                                    ];

        List<ER_Contract__c> contractsTS = [SELECT Id, Name, Account_Name__c, Product__c, AT_MasterContract__c 
                                                    FROM ER_Contract__c 
                                                    WHERE  Product__c='Ticket Service Card'
                                                        AND RecordTypeId =:GetRecordTypeId('ER_Contract__c', 'Affiliate_Contract_RT')  
                                                        AND AT_MasterContract__c = NULL 
                                                        AND Status__c='Active'
                                                    ORDER BY Status__c // should will catch first active contract
                                                    ];      

        
        
        for(ER_Contract__c ctr : contractsTR){
            Integer iMasterCounter = 0;
            
            for(ER_Contract__c ctrSlave : contractsTS) {
                Integer iSlaveCounter = 0;
                if (ctrSlave.Account_Name__c == ctr.Account_Name__c && iMasterCounter == 0 &&  iSlaveCounter == 0 ){
                    System.Debug('--- Setting slave contract: Master Account: ' + ctr.Account_Name__r.Name  + ' Contract: '+ ctr.Name + ' | Slave Contract: ' + ctrSlave.Name  + ' - ' + ctrSlave.Product__c);
                    
                    iSlaveCounter++;                          // set counter so only 1 Slave  contract is set

                    ctrSlave.AT_MasterContract__c = ctr.Id;
                    contractsToUpdateSlave.add(ctrSlave);  //save changes to slave contracts   
                    contractsToUpdateMaster.add(ctr);         
                }
            }

            iMasterCounter++;
        }

        update contractsToUpdateSlave;  //write down to DB
        update contractsToUpdateMaster; //force to save master, so all  changes are replicated to Slave contracts. Confirm this works without modifying the data

        //update ctr; //force change on master contract to ensure slave contract is in sync
        System.Debug('<<<   makeMasterSlaveContractRelationship()');
    } //makeMasterSlaveContractRelationship


    /* ############ HELPER FUNCTIONS ############ */
    public static Boolean sendNotificationEmail(string subject, string body){
        boolean bResult;
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        //set senders
        message.toAddresses = new String[] { 'PartnerSupport-AT@edenred.com'};

        
        message.optOutPolicy = 'SEND';
        message.subject = subject;
        //message.plainTextBody = body;
        message.setHtmlBody(body);
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        if (results[0].success) 
        {
            System.debug('--- The email was sent successfully.');
            bResult = true;
        } else 
        {
            System.debug('--- ERROR The email failed to send: ' + results[0].errors[0].message);
            bResult = false;
        }

        return bResult;
    } // sendNotificationEmail



    /* ############ HELPER FUNCTIONS ############ */
    public static Set<Id> getIdsFromSOQL(String someSOQL){
        List<SObject> results = Database.query(someSOQL);
        Set<Id> resultIds = (new Map<Id,SObject>(results)).keySet();

        return resultIds;
    }


    // sample: APAT01_ToolkitAT.GetRecordTypeId('ER_Contract__C','Affiliate_Contract_RT')
    public static Id GetRecordTypeId(String objectName, String recordTypeName){
        //RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType = :objectName AND  Name = ''];
        // Object           Developer/API name          Friendly Name
        // ER_Contract__C   Affiliate_Contract_RT       Affiliate Contract   
        // ER_Contract__C   Client_Contract_RT          Client Contract
        // Account          Merchant_Account_RT         Merchant
        // Account          Client_Account_RT           Client
        // Account          Group                       Group
        // Account          Beneficiary                 Beneficiary
        // Account          Individual                  Individual
     
        //getRecordTypeInfosByName -> firendly name

        Return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();

    }


    public static Id GetLoopIdByLoopReference(String criteria) {
        Id loopId;

        try{
             loopId = [SELECT Id FROM ER_Loop__c WHERE ER_Reference__c=: criteria LIMIT 1].Id;          // get LoopId by Loop Reference e.g. LOOP-0001

        } catch (exception e) {
            system.debug('!!! Exception in GetLoopIdByLoopReference: ' + e);
        }

        Return loopId;

    }


    public static ID GetLoopIdByLoopName(String criteria) {
        Id loopId;

        try{
             loopId = [SELECT Id, Name FROM ER_Loop__c WHERE Name= :criteria LIMIT 1].Id;           // get LoopId by Loop Name E.g. APM_TR

        } catch (exception e) {
            
            system.debug('!!! Exception in GetLoopIdByLoopName: ' + e);
        }
    
        Return loopId;
    }

    // Returns ER_Loop__c for Card Product
    public static Map<String,ER_Loop__c> ProductLoopFullMap() {
        Map<String,ER_Loop__c> mapResult = new Map<String,ER_Loop__c>();

        List<ER_Loop__c> lstLoops = [SELECT Id, Name, ER_Reference__c FROM ER_Loop__c];
        Map<String, String> mapLoopRefProduct = LoopRefProductMap();


        for (ER_Loop__c l : lstLoops) {
            String productMatch = mapLoopRefProduct.get(l.ER_Reference__c);
            if ( productMatch != NULL  ) 
                mapResult.put(productMatch, l );
            //else
            //    mapResult.put(l.ER_Reference__c, l)       //add also unmatched loops with Product = Loop Reference
        }
        Return mapResult;
    }

    // GetLoopIdByProductName
    // Get's Product to Loop mapping with some static mapping for AP_OPEN/Test Card
    //

    public static Map<String, String> LoopRefProductMap(){

        Map<String, String> Result = new Map<String, String>();

        /*
        Result.put('Ticket Restaurant Card', 'LOOP-0001');
        Result.put('Ticket Service Card', 'LOOP-0002');
        Result.put('Test Card', 'LOOP-0003');
        */
        Result.put('LOOP-0001','Ticket Restaurant Card');
        Result.put('LOOP-0002','Ticket Service Card');
        Result.put('LOOP-0003','Test Card');

        return Result;
    }

    public static Id GetLoopIdByProductName(string ProductName) {

        system.debug('::: GetLoopIdByProductName: ' +ProductName );
        List<ER_Loop__c> apmLoops;
        Id Ret;


        switch on (ProductName)  {
            WHEN 'Ticket Restaurant Card'   { apmLoops =  [SELECT Id FROM ER_Loop__c WHERE ER_Reference__c='LOOP-0001' LIMIT 1];  }        
            WHEN 'Ticket Service Card'      { apmLoops =  [SELECT Id FROM ER_Loop__c WHERE ER_Reference__c='LOOP-0002' LIMIT 1];  }        
            WHEN 'APM_OPEN', 'Test Card'     { apmLoops =  [SELECT Id FROM ER_Loop__c WHERE ER_Reference__c='LOOP-0003' LIMIT 1];  }       
        }

        try{
            if (apmLoops.Size() == 1){
                    Ret = apmLoops[0].Id;
                } else {
                system.debug('::: GetLoopIdByProductName: Could not find LoopId for product: ' + ProductName + ' apmLoops.Size(): ' + apmLoops.Size() );
                }
        } catch (exception e) {
            System.Debug('Exception in GetLoopIdByProductName: ' + e.getMessage() );
        }
 
        
        
        return Ret;
    }


    public static Map<String, Id> GetProductsLoopsMap() {
        Map<String, Id> mapProductsLoops = new Map<String, Id>{};
        mapProductsLoops.put('Ticket Restaurant Card', GetLoopIdByLoopReference('LOOP-0001'));
        mapProductsLoops.put('Ticket Service Card', GetLoopIdByLoopReference('LOOP-0002'));

        // AP_TR    =>  a090Q0000009jr4QAA
        // AP_TS    =>  a090Q0000009jyeQAA
        // AP_OPEN  =>  a090Q0000009jyjQAA

        return mapProductsLoops;
    }


    /*
    public void addMapProduct2Loop(String contractProduct){
        mapProduct2Loop.put(contractProduct, GetLoopIdByProductName(contractProduct));
    }

    public void removeMapProduct2Loop(String contractProduct){
        try{
            mapProduct2Loop.remove(contractProduct);
        } catch (exception e) {
            DebugLog(e);
        }
    }
    */

    //custom  System.Debug function
    public static void DebugLog(String message){
        System.Debug('::: ' + message);
        
    }

    public void DebugLog(Integer level, String message){
        if (level <= m_DebugLevel)
            System.Debug('::: ' + message);
    }

    public static void DebugLog(exception e) {
        System.Debug('[E] Exception: ' + e.getMessage() );
    }
    
    
    //http://sfdc.arrowpointe.com/2011/03/28/cloning-records-in-apex/
    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
         
        String selects = '';
         
        if (whereClause == null || whereClause == ''){ return null; }
         
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
         
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }
         
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
             
        }
         
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
         
    } // getCreatableFieldsSOQL

    // more helpers - lib

    /*
    private static string IfNull(String str, String strIfNull){
        if (str == NULL) 
            return strIfNull;
        else
            return str;
    }
    */

    private static String CompositeKey(Id Id1) {
        return String.ValueOf(Id1);
    }

    private static String CompositeKey(String key1, String key2) {
        return key1 + '.' + key2;
    }
    private static String CompositKey(Id Id1, Id Id2) {
        return CompositeKey(String.ValueOf(Id1), String.ValueOf(Id2));
    }




    

}