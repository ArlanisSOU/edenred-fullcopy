// Business logic:
// 1. Update Account Status as per statuses of contracts (Active, Inactive) - all Record Types
// 2. Create/Update/Delete underlying StoreAuthorization according to Contract Status

trigger TRAT01_ContractAfter on ER_Contract__c (after insert, after update, after delete) {
  System.debug('>>> TRIGGER    ER_Contract__c.TRAT01_ContractAfter');
  List<ER_Contract__c> oList;
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isUnDelete))
      oList = Trigger.new;

    
    if(Trigger.isAfter && Trigger.isDelete)
      oList =  Trigger.old;


    //System.debug('TRAT01_ContractAfter - Number of records: ' + oList.size() + '   |  Trigger.OLD.Size():' + Trigger.Old.size() +  '    |   Trigger.NEW.Size():' + Trigger.New.size());

    Id affiliateRT = APAT01_ToolkitAT.GetRecordTypeId('ER_Contract__C','Affiliate_Contract_RT');


    Set<Id> accountIds = new Set<Id>();
    Set<Id> ContractIdTRToClone = new Set<Id>{};
    Set<Id> contractIdsStatusChange = new Set<Id>();
    Set<String> lstContractProducts = new Set<String>();



    //get ContractId (Affiliate Contract only) involved in the  trigger for which status has change
    
    for (Integer i = 0 ; i < oList.size(); i++) {
      System.Debug('::: TRAT01_ContractAfter -  Row #: ' + (i +1)  );

      ER_Contract__c trgRow = oList[i];

      //limit to Affiliate Contract Record Type - TODO: Add the Client Support as well.!!!
      //    Affiliate_Contract_RT
      //
      if(!Trigger.isInsert)
      {
        if(Trigger.Old[i].Status__c  !=  trgRow.Status__c)
        {
          accountIds.add(trgRow.Account_Name__c);
        }
      }
        if(APAT01_ToolkitAT.IsCardAPMProduct(trgRow.Product__c)) { 

           // for updating the Account Status (Client or Merchant) - force to recalculate Fix bug CC-5257

        if (trgRow.RecordTypeId == affiliateRT) {
            
            // check if status has changed or contract has been created or deleted
            if ( Trigger.isInsert || Trigger.isDelete ||  (Trigger.isUpdate && Trigger.Old[i].Status__c  !=  trgRow.Status__c)   ) {
                  lstContractProducts.add(trgRow.Product__c);
                  contractIdsStatusChange.add(trgRow.Id);
            }

            // check if contract should be clonned TR=>TS            
            if ((Trigger.isInsert || Trigger.isUpdate) &&  trgRow.Product__c=='Ticket Restaurant Card') {
                  ContractIdTRToClone.add(trgRow.Id);
            }

        } // if recordtype= Affiliate
      } // if card  product
    } // for each record in trigger
    
   

    /*
    System.Debug('--- TRAT01_ContractAfter statistics: lstContractProducts.size() = ' + lstContractProducts.size());
    System.Debug('--- TRAT01_ContractAfter statistics: accountIds.size() = ' + accountIds.size());
    System.Debug('--- TRAT01_ContractAfter statistics: contractIdsStatusChange.size() = ' + contractIdsStatusChange.size());
    */

    //
    //actions on gathered sets/contracts
    //

    if(accountIds.Size() > 0) {
      APAT01_ToolkitAT.AccountStatus_BatchUpdate(accountIds);
    }

    If(contractIdsStatusChange.Size() > 0) {
        APAT01_ToolkitAT.StoreAuth_ByContractHandler(contractIdsStatusChange,Trigger.isDelete);
    }


    if (ContractIdTRToClone.Size()>0) {
      APAT01_ToolkitAT.ReplicateContractTRCtoTSC(ContractIdTRToClone);
    }
    

System.debug('<<< TRIGGER    ER_Contract__c.TRAT01_ContractAfter');

} //trigger