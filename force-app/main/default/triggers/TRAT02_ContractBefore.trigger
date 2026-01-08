// Business logic:
// 1. Prevent to have more than 1 Active Contracts for Card Product
// 2. Update Contract statuses for all kind of record Types (Affiliate Contract, Client Contract) base on dates (start, end)
// 3. Update Contract statused for Client Contract on dates (reopen date, close date)

trigger TRAT02_ContractBefore on ER_Contract__c (before insert, before update, before delete) {


   
    Set<String> lstContractProducts = new Set<String>();        // for product filter for duplicates check
    Set<Id> lstContractAccounts = new Set<Id>();                // for account filter for duplicates check
    APAT01_ToolkitAT cardToolkit = new APAT01_ToolkitAT();
    List<ER_Contract__c> trgRows;
    
    
    if(Trigger.isDelete)
            trgRows = Trigger.old;
        else
            trgRows = Trigger.new;


    cardToolkit.DebugLog(10, '>>> TRIGGER     ER_Contract__c.TRAT02_ContractBefore  |  Rows: ' + trgRows.size() + ' | isInsert: ' + Trigger.isInsert + ' | isUpdate: ' + Trigger.isUpdate+ ' | IsDelete: ' + Trigger.isDelete);

    Id affiliateRT = APAT01_ToolkitAT.GetRecordTypeId('ER_Contract__C','Affiliate_Contract_RT');           // limit only Affiliate Record Type
    Id clientRT = APAT01_ToolkitAT.GetRecordTypeId('ER_Contract__C','Client_Contract_RT');
    

    if(Trigger.isInsert || Trigger.IsUpdate) {
        
        // update Contract Status
        for(ER_Contract__c trgRow : trgRows) {

            // calculate new Status__c based on dates for all kind of record types (Clients | Merchants) and all products
            // Contract_End_Date__c is not used in ER-AT Process, and all Clients or Retailers will have Contract_Close_Date__c onlt set
            // calculate contract status based on Contract_Reopen_Date__c for Clients record type
            
            if( trgRow.Contract_Reopen_Date__c != null && trgRow.RecordTypeId == clientRT ) {
                
                if(trgRow.Contract_Close_Date__c < trgRow.Contract_Reopen_Date__c && trgRow.Status__c != 'Active') {
                    trgRow.Status__c = 'Active';
                }
            
                if(trgRow.Contract_Close_Date__c >= trgRow.Contract_Reopen_Date__c && trgRow.Status__c != 'Inactive') {
                    trgRow.Status__c = 'Inactive';
                }         
                
            } else {
            
                if( trgRow.Contract_Start_Date__c <= System.today() && ( trgRow.Contract_Close_Date__c == null || trgRow.Contract_Close_Date__c > System.today()) ) {
                    trgRow.Status__c = 'Active';
                } else {
                    trgRow.Status__c = 'Inactive';
                }
            }

            //System.debug('::: for(trgRows) ---  ContractID: ' + trgRow.Id + ' |  Product: '  + trgRow.Product__c   + ' |  Status__c: ' + trgRow.Status__c );

            // add to the Duplicate check-up lists - only if RecordType = Affiliate & Product is APM Card
            if(trgRow.RecordTypeId == affiliateRT &&  trgRow.Status__c == 'Active' && APAT01_ToolkitAT.isCardAPMProduct(trgRow.Product__c) ) {
                lstContractAccounts.add(trgRow.Account_Name__c);
                lstContractProducts.add(trgRow.Product__c);
            }

        } //for trgRows



        // get existing contracts for duplicate check
        List<ER_Contract__c> existingContracts = [SELECT Id, Account_Name__c, Product__c, Status__c FROM ER_Contract__c WHERE Status__c='Active' AND Product__c IN :lstContractProducts AND Account_Name__c = :lstContractAccounts ]; 

        //cardToolkit.DebugLog(11,'--- statistics  | lstContractAccounts.Size: ' + lstContractAccounts.Size() + ' | lstContractProducts.Size: ' + lstContractProducts.Size() + ' |   existingContracts.Size: ' + existingContracts.size());

        //
        // loop through rows again and compare to existing contracts
        // Rule - only 1 active contract per card product is allowed
        //
        for(Integer i = 0 ; i < trgRows.Size(); i++) {
            ER_Contract__c trgRow = trgRows[i];

            // Duplicate Check
            // if Insert: consider only if new status = Active
            // if update: Check if product has changed (and  is Card) and if Status is Changed to Active
            // 
            if ((Trigger.isInsert && trgRow.Status__c == 'Active') 
                || (Trigger.isUpdate && trgRow.Status__c == 'Active' && (trgRow.Status__c != Trigger.old[i].Status__c  || trgRow.Product__c != Trigger.old[i].Product__c)) ) {

                    for(ER_Contract__c existingContract : existingContracts ) {

                        // if contract is now active and status or product has changed within the trigger
                        // and there is another active contract for that product on that account

                        if( existingContract.Status__c == 'Active' &&  trgRow.Account_Name__c == existingContract.Account_Name__c && trgRow.Product__c == existingContract.Product__c) {
                                cardToolkit.DebugLog(5,'This Account (' + trgRow.Account_Name__c + ') has already already active Contract for this product(' +  trgRow.Product__c + ')!');

                                if ( !System.isScheduled() )
                                    trgRow.Product__c.addError('This Account has already another active Contract for this product)!' ); 
                        }

                    } // for existing contracts

            } // if duplicate rules

        } // for loop in trgRows

    } // for Insert || Update


    if(Trigger.isDelete) {
        Set<Id> contractToDeleteIds = new Set<Id>();

        for(ER_Contract__c trgRow : Trigger.old ){
            //if(trgRow.AT_MasterContract__c != NULL) {     //this does  not work, since it's will faill the nested trigger
            //    trgRow.addError('Contract is slave of Master Contract ' +  trgRow.Id__c + ' and can\'t be deleted. Please remove Master Contract instead!' );     // prevent deleting slave contract

            //TODO logic which prevents Slave Contract to be deleted without first deleting master contract
            contractToDeleteIds.add(trgRow.Id);
        }

        //cardToolkit.DebugLog(11,'--- statistics |  contractToDeleteIds.Size: ' + contractToDeleteIds.Size());

        if(contractToDeleteIds.size() > 0) {
            APAT01_ToolkitAT.Contract_BulkDeleteHandler(contractToDeleteIds);                      // delete slave contracts        
        }

    } // if Delete

cardToolkit.DebugLog(10, '<<<  TRIGGER ER_Contract__c.TRAT02_ContractBefore End');

}