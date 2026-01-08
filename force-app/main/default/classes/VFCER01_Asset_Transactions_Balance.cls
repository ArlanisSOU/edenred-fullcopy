/*
~ Author            : Oussama LASFAR (Oussam.lasfar@edenred.com)
~ Created Date      : 06/10/2018 (dd/mm/yyyy)
~ Description       : Controller of the VFER01_Asset_Transactions_Balance
                      This class allows users to perform several WS calls:
                        * getTransactionList
                        * getBalance
                        * getCard

VERSION HISTORY
~ Modified By       :  (@.com)
~ Modified Date     : // (dd/mm/yyyy)
~ Description       :
*/

public class VFCER01_Asset_Transactions_Balance {

    public Asset currentAsset {get; set;}
    public Asset updateAsset;
    public List<TransactionWrapper> transactionlist {get; set;}
    public Boolean showError {get; set;}
    public BalanceWrapper balanceInst {get; set;}
    public WSER01_BalanceDetails.CardBalanceResponse cardBalanceResponse {get; set;}
    public WSER02_OperationDetails.CardOperationResponse cardOperationResponse {get; set;}
    public WSER05_GetCardDetails.CardDetailResponse cardDetailResponse;
    public List<String> assetFields;
    public String errorMessages;
    public String status_details;
    public Map<String, String> errorLabels;
    public Date startDate {get; set;}
    public Date endDate {get; set;}
    public String daterFilters {get; set;}
    public String daterFiltersToCompare;
    public Integer indexFilter;
    public Boolean checkMoreButton {get; set;}
    public Boolean checkTransactionButton {get; set;}
    public String transactionsParameters;
    public String transactionsCallType;


    public VFCER01_Asset_Transactions_Balance(ApexPages.StandardController controller) {

        assetFields = new List<String>();
        balanceInst = new BalanceWrapper();

        assetFields.add('ER_Edenred_Solution__c');
        assetFields.add('Accountid');
        assetFields.add('Status');
        assetFields.add('Name');
        assetFields.add('ER_Asset_Type__c');
        assetFields.add('ER_Asset_Status_Last_Modified_Date__c');
        assetFields.add('ER_Product_Class__c');
        assetFields.add('recordtype.Developername');

        daterFilters = '';
        daterFiltersToCompare = '';
        indexFilter = 0;
        checkMoreButton = true;
        checkTransactionButton = false;
        transactionsParameters = '';

        if (!Test.isRunningTest()) controller.addFields(assetFields);

        currentAsset = (Asset)controller.getRecord();
        updateAsset = currentAsset;
        if (String.isNotBlank(currentAsset.ER_Asset_Type__c) && (currentAsset.ER_Asset_Type__c == Label.LAB_SF_ASSET_Type) && String.isNotBlank(currentAsset.ER_Product_Class__c)) {
            currentAsset.ER_Edenred_Solution__c = currentAsset.ER_Product_Class__c;
        }
        showError = false;
    }
    /**
    * @author Oussama LASFAR
    * @date 26/09/2018 (dd/mm/yyyy)
    * @description This method is created to call the WS <<operations>> and display the operation list.
    */
    public void getTransactionList() {

        try {
            System.debug('### daterFilters :: ' + daterFilters);
            System.debug('### transactionsCallType :: ' + transactionsCallType);
            if (transactionsCallType == 'init') {
                indexFilter = 0;
            } else {
                transactionsCallType = 'init';
            }

            if (String.isBlank(daterFilters)) {

                transactionsParameters = '?status=allAffectingBalance&page_index=' + indexFilter + '&page_size=50';
            } else {

                Date dateFrom = Date.valueOf(daterFilters.split(' - ')[0]);
                Date dateTo = Date.valueOf(daterFilters.split(' - ')[1]);
                DateTime dateTimeFrom = DateTime.newInstance(dateFrom.year(), dateFrom.month(), dateFrom.day(), 0, 0, 0);
                DateTime dateTimeTo = DateTime.newInstance(dateTo.year(), dateTo.month(), dateTo.day(), 23, 59, 59);
                transactionsParameters = '?status=allAffectingBalance&page_index=' + indexFilter + '&page_size=50&date-from=' + dateTimeFrom.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '&date-to=' + dateTimeTo.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
            System.debug('indexFilter :: ' + indexFilter);
            errorMessages = '';
            showError = false;
            if (indexFilter == 0)
                transactionlist = new List<TransactionWrapper> {};

            cardOperationResponse = WSER02_OperationDetails.getCardOperations(currentAsset.ER_Edenred_Solution__c, currentAsset.Name, transactionsParameters);
            System.debug('#### cardOperationResponse : ' + cardOperationResponse);
            if (cardOperationResponse != null && cardOperationResponse.meta != null && cardOperationResponse.meta.status != null && cardOperationResponse.meta.status.equalsIgnoreCase('succeeded')) {
                for (WSER02_OperationDetails.CardOperation CardOp : cardOperationResponse.data) {
                    status_details = '';
                    if (currentAsset.ER_Edenred_Solution__c.equalsIgnoreCase(CardOp.product_code) && currentAsset.Name == CardOp.csn) {

                        if (String.isNotBlank(CardOp.status_details)) {
                            //status_details = errorLabels.get(CardOp.status_details);
                        }
                        transactionlist.add(new TransactionWrapper(Changeformat(CardOp.opDate), CardOp.type, CardOp.status, CardOp.outlet_name, ConvertAmount(CardOp.amount)));

                        if (math.mod(transactionlist.size(), 50) == 0 ) {
                            checkMoreButton = false;
                            //checkTransactionButton = true;
                            indexFilter++;
                        } else {
                            checkMoreButton = true;
                        }
                    }
                }
            } else {
                Integer index = 0;
                String messageText;
                List<WSER02_OperationDetails.Message> cardOpeationMessages = (cardOperationResponse.meta.messages != null ? cardOperationResponse.meta.messages : cardOperationResponse.meta.message);
                for (WSER02_OperationDetails.Message message : cardOpeationMessages) {
                    if (String.isNotBlank(message.text) || String.isNotBlank(message.message)) {
                        messageText = String.isNotBlank(message.text) ? message.text : (String.isNotBlank(message.message) ? message.message : '');
                        if (index > 0)
                            errorMessages += '<br/>';
                        errorMessages += '<b>' + message.code + '</b> : ' + messageText;
                        index++;
                    }
                }
                if (String.isBlank(errorMessages)) {
                    errorMessages = Label.LABS_SF_WS_Unavailable;
                }
                throw new VisualforceException(errorMessages);
            }
        } catch (Exception e) {
            transactionlist = new List<TransactionWrapper> {};
            Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
            System.debug('### Exception get transaction: ' + e.getMessage());
            showError = true;

        }

    }
    /**
    * @author Oussama LASFAR
    * @date 26/09/2018 (dd/mm/yyyy)
    * @description This method is created to call the WS <<operations>> and display the operation list.
        */
    public void geMoretTransactionList() {
        transactionsCallType = 'more';
        getTransactionList();
    }
    /**
    * @author Oussama LASFAR
    * @date 26/09/2018 (dd/mm/yyyy)
    * @description This method is created to call the WS <<balances>> display the balance values and update the field Status and ER_Asset_Status_Last_Modified_Date__c.
    */
    public void getBalance() {

        errorMessages = '';
        showError = false;
        balanceInst = new BalanceWrapper();
        try {
            cardBalanceResponse = WSER01_BalanceDetails.getCardBalances(currentAsset.ER_Edenred_Solution__c, currentAsset.Name);
            System.debug('#### cardBalanceResponse : ' + cardBalanceResponse);
            if (cardBalanceResponse != null && cardBalanceResponse.meta != null && cardBalanceResponse.meta.status != null && cardBalanceResponse.meta.status.equalsIgnoreCase('succeeded')) {
                for (WSER01_BalanceDetails.CardBalance cardBal  : cardBalanceResponse.data) {
                    if (String.isNotBlank(cardBal.product_code) && cardBal.product_code.equalsIgnoreCase('Main')) {
                        balanceInst = new BalanceWrapper(
                            ConvertAmount(cardBal.cleared_amount),
                            ConvertAmount(cardBal.reserved_amount),
                            ConvertAmount(cardBal.remaining_amount),
                            cardBal.status);

                        if (String.isNotBlank(cardBal.status)) {
                            if (String.isBlank(currentAsset.Status) || (String.isNotBlank(currentAsset.Status) && !currentAsset.Status.equalsIgnoreCase(cardBal.status)) ) {
                                updateAsset(cardBal.status, '');
                            }
                        }
                    }
                }

                System.debug('#### balanceInst : ' + balanceInst);
            } else {
                Integer index = 0;
                String messageText;
                List<WSER01_BalanceDetails.Message> cardBalanceMessages = (cardBalanceResponse.meta.messages != null ? cardBalanceResponse.meta.messages : cardBalanceResponse.meta.message);
                for (WSER01_BalanceDetails.Message message : cardBalanceMessages) {
                    if (String.isNotBlank(message.text) || String.isNotBlank(message.message)) {
                        messageText = String.isNotBlank(message.text) ? message.text : (String.isNotBlank(message.message) ? message.message : '');
                        if (index > 0)
                            errorMessages += '<br/>';
                        errorMessages += '<b>' + message.code + '</b> : ' + messageText;
                        index++;
                    }
                }
                if (String.isBlank(errorMessages)) {
                    errorMessages = Label.LABS_SF_WS_Unavailable;
                }
                throw new VisualforceException(errorMessages);
            }
        } catch (Exception e) {
            balanceInst = new BalanceWrapper();
            Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
            System.debug('### Exception get balance: ' + e.getMessage());
            showError = true;
        }
    }
    /**
    * @author Oussama LASFAR
    * @date 26/09/2018 (dd/mm/yyyy)
    * @description This method is created to call the WS <<cards>> and update the fields status and ER_Asset_Status_Last_Modified_Date__c.
    */
    public void getCard() {

        errorMessages = '';
        showError = false;

        try {
            cardDetailResponse = WSER05_GetCardDetails.getCardDetail(currentAsset.ER_Edenred_Solution__c, currentAsset.Name);
            System.debug('#### cardDetailResponse : ' + cardDetailResponse);
            if (cardDetailResponse != null && cardDetailResponse.meta != null && cardDetailResponse.meta.status != null && cardDetailResponse.meta.status.equalsIgnoreCase('succeeded')) {
                if (cardDetailResponse.data != null) {
                    if (String.isNotBlank(cardDetailResponse.data.status)) {
                        updateAsset(cardDetailResponse.data.status, cardDetailResponse.data.employer_ref);
                    }
                }
            } else {
                Integer index = 0;
                String messageText;
                List<WSER05_GetCardDetails.Message> cardDetailMessages = (cardDetailResponse.meta.messages != null ? cardDetailResponse.meta.messages : cardDetailResponse.meta.message);
                for (WSER05_GetCardDetails.Message message : cardDetailMessages) {
                    if (String.isNotBlank(message.text) || String.isNotBlank(message.message)) {
                        messageText = String.isNotBlank(message.text) ? message.text : (String.isNotBlank(message.message) ? message.message : '');
                        if (index > 0)
                            errorMessages += '<br/>';
                        errorMessages += '<b>' + message.code + '</b> : ' + messageText;
                        index++;
                    }
                }
                if (String.isBlank(errorMessages)) {
                    errorMessages = Label.LABS_SF_WS_Unavailable;
                }
                throw new VisualforceException(errorMessages);
            }
        } catch (Exception e) {

            Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.INFO, e.getMessage()));
            System.debug('### Exception get Card: ' + e.getMessage());
            showError = true;
        }
    }

    public void updateAsset(String Status, String employer_ref) {

        if (String.isBlank(currentAsset.Status) || (String.isNotBlank(Status) && !Status.equalsIgnoreCase(currentAsset.Status))) {
            currentAsset.Status = Status;
            updateAsset.Status = Status;
            updateAsset.ER_Asset_Status_Last_Modified_Date__c = Datetime.now();
            if (String.isBlank(updateAsset.AccountId) && String.isNotBlank(employer_ref)) {
                try {
                    Account accountReference = new Account(ER_Card_Operational_System_ID__c = employer_ref);
                    updateAsset.Account = accountReference;
                    System.debug('### VFCER01_Asset_Transactions_Balance updateAssetWithAccount: ' + updateAsset);
                    update updateAsset;
                    return;
                } catch (Exception e) {
                    System.debug('### VFCER01_Asset_Transactions_Balance updateAsset Exception : ' + e.getMessage());
                }
            }
            updateAsset.Account = null;
            System.debug('### VFCER01_Asset_Transactions_Balance updateAsset : ' + updateAsset);
            update updateAsset;
        }
    }

    public String Changeformat(string thedate) {

        if (String.isNotBlank(thedate)) {
            try {
                thedate = thedate.replace('T', ' ').replace('.000Z', '');
                Datetime dd = Datetime.valueof(thedate);
                return dd.format('yyyy-MM-dd HH:mm:ss');
            } catch (Exception e) {
                try {
                    Datetime dd = (datetime)json.deserialize('"' + thedate + '"', datetime.class);
                    return dd.format('yyyy-MM-dd HH:mm:ss');
                } catch (Exception ex) {
                    return thedate;
                }
            }
        } else {
            return '-';
        }
    }
    public Map<String, String> geterrorLabels() {

        Map<String, String> errorLabels = new Map<String, String>();
        List<CMER03_EDG_Error_Label__mdt> errorLabelList = [select id, DeveloperName, MasterLabel from CMER03_EDG_Error_Label__mdt];
        for (CMER03_EDG_Error_Label__mdt errorLabel : errorLabelList) {
            errorLabels.put(errorLabel.DeveloperName, errorLabel.MasterLabel);
        }

        return errorLabels;
    }
    public String ConvertAmount(string amount) {

        if (String.isNotBlank(amount)) {
            try {
                return String.valueOf((Decimal.valueOf(amount) / 100).setScale(2));
            } catch (Exception e) {
                System.debug('Exception ConvertAmount :' + e);
                return amount;
            }
        }
        return amount;
    }

    class BalanceWrapper {

        public String balance {get; set;}
        public String pendingDebit {get; set;}
        public String balanceAvailable {get; set;}
        public String status {get; set;}

        public BalanceWrapper() {

            balance = '-';
            pendingDebit = '-';
            balanceAvailable = '-';
            status = '-';
        }

        public BalanceWrapper(String balance, String pendingDebit, String balanceAvailable, String status) {

            this.balance = balance;
            this.pendingDebit = pendingDebit;
            this.balanceAvailable = balanceAvailable;
            this.status = status;
        }
    }

    class TransactionWrapper {

        public String trDate {get; set;}
        public String type {get; set;}
        public String status {get; set;}
        public String status_details {get; set;}
        public String acceptorName {get; set;}
        public String amount {get; set;}

        public TransactionWrapper(String trDate, String type, String status, String acceptorName, String amount) {

            this.trDate = trDate;
            this.type = type;
            this.status = status;
            this.status_details = status_details;
            this.acceptorName = acceptorName;
            this.amount = amount;
        }
    }

    public class VisualforceException extends Exception {}
}