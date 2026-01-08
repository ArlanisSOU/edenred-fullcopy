/**
* @author Oussama LASFAR
* @date 28/09/2018 (dd/mm/yyyy)
* @description This class contains unit tests for validating the behavior of VFCER01_Asset_Transactions_Balance
*/

@isTest
private class VFCER01_Asset_Transactions_Balance_Test {
    
    static VFCER01_Asset_Transactions_Balance controller;
    
    @testSetup
    static void testSetup() {
        
        Account newCompany = APER07_UtilityTestMethod.getClient();
        insert newCompany;
        
        ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
        newEmployee.ER_Client__c = newCompany.id;
        insert newEmployee;
        
        Product2 newProduct = APER07_UtilityTestMethod.getProduct('TSC_P');
        insert newProduct;
        
        Asset newAsset = APER07_UtilityTestMethod.getAsset('2801001840','ER_Asset_Record_Type',Label.LAB_SF_ASSET_Type);
        newAsset.ER_Employee__c = newEmployee.id;
        newAsset.AccountId = newCompany.id;
        newAsset.Product2Id = newProduct.id;
        insert newAsset;
        
        Contact newcontact =  APER07_UtilityTestMethod.getContact('ERATRT_StandardContact', 'firstName', 'lastName');
        insert newcontact;
        
        Case newcase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
        insert newcase;
        
    }
    
    static testMethod void getTransactionList() {
        Asset assetinst = [select id, ER_Asset_Type__c, ER_Edenred_Solution__c,ER_Product_Class__c, Name from Asset where name = '2801001840'];
        ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
        controller = new  VFCER01_Asset_Transactions_Balance(sc);
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
        controller.getTransactionList();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
        controller.getTransactionList();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
        controller.getTransactionList();
        Test.StopTest();
    }
    static testMethod void getBalance() {
        Asset assetinst = [select id, ER_Asset_Type__c, ER_Edenred_Solution__c, Name, Status, ER_Product_Class__c from Asset where name = '2801001840'];
        ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
        controller = new  VFCER01_Asset_Transactions_Balance(sc);
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
        controller.getBalance();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
        controller.getBalance();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
        controller.getBalance();
        Test.StopTest();
    }
    static testMethod void getCard() {
        Asset assetinst = [select id, ER_Asset_Type__c, ER_Edenred_Solution__c, Name, Status, ER_Product_Class__c from Asset where name = '2801001840'];
        ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
        controller = new  VFCER01_Asset_Transactions_Balance(sc);
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
        controller.getCard();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
        controller.getCard();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
        controller.getCard();
        Test.StopTest();
    }
    public class CardWSMockImpl implements HttpCalloutMock {
        
        Integer statusCode;
        
        public CardWSMockImpl(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String balanceOK = '{' +
                '"meta": {' +
                '"status": "succeeded",' +
                '"messages": []' +
                '},' +
                '"data": [' +
                '{' +
                '"product_code": "MAIN",' +
                '"remaining_amount": 20000,' +
                '"cleared_amount": 20000,' +
                '"reserved_amount": 0,' +
                '"currency": "EUR",' +
                '"status": "issued"' +
                '}' +
                ']' +
                '}';
            String operationOK = '{' +
                '"meta": {' +
                '"status": "succeeded",' +
                '"messages": []' +
                '},' +
                '"data": [' +
                '{' +
                '"csn": "2801001840",' +
                '"operation_ref": "18052002465131845",' +
                '"type": "fee",' +
                '"amount": "testMaxCover",' +
                '"date": "2018-05-20T01:46:51.000Z",' +
                '"currency": "EUR",' +
                '"outlet_name": null,' +
                '"outlet_ref": null,' +
                '"status": "success",' +
                '"product_code": "TSC_P"' +
                '},' +
                '{' +
                '"csn": "2801001840",' +
                '"operation_ref": "18052002465131845",' +
                '"type": "fee",' +
                '"amount": "",' +
                '"date": "2018-05-22T01:46.",' +
                '"currency": "EUR",' +
                '"outlet_name": null,' +
                '"outlet_ref": null,' +
                '"status": "success",' +
                '"product_code": "TSC_P"' +
                '},' +
                '{' +
                '"csn": "2801001840",' +
                '"operation_ref": "18052002465131845",' +
                '"type": "fee",' +
                '"amount": -455,' +
                '"date": "",' +
                '"currency": "EUR",' +
                '"outlet_name": null,' +
                '"outlet_ref": null,' +
                '"status": "success",' +
                '"product_code": "TSC_P"' +
                '}' +
                ']' +
                '}';
            String cardOK = '{'+
                '"meta": {'+
                '"status": "succeeded",'+
                '"messages": []'+
                '},'+
                '"data": {'+
                '"issue_date": "2018-08-26T00:03:51.61",'+
                '"expiration_date": "2021-08-31T00:00:00",'+
                '"acceptance_profile": "AP_TR",'+
                '"employer_ref": "1362",'+
                '"employer_name": "App Container TR Card",'+
                '"cardholder_name": "THIRIET John",'+
                '"status": "active",'+
                '"order_ref": "9242"'+
                '}'+
                '}';
            String wsKO = '{' +
                '"meta": {' +
                '"status": "failed",' +
                '"messages": [' +
                '{' +
                '"code": "BAD_REQUEST",' +
                '"level": "error",' +
                '"text": "Unable to process your request, please check its validity."' +
                '},' +
                '{' +
                '"code": "AUTHENTICATION_FAILED",' +
                '"level": "error",' +
                '"text": "Incorrect or expired token."' +
                '}' +
                ']' +
                '}' +
                '}';
            String wsMalformedJsonKO = '{' +
                '"meta": {' +
                '"status": "failed",' +
                '"messages": [' +
                '{' +
                '"code": "BAD_REQUEST",' +
                '"level": "error",' +
                '"text": "Unable to process your request, please check its validity."' +
                '},' +
                '{' +
                '"code": "AUTHENTICATION_FAILED",' +
                '"level": "error",' +
                '"text": "Incorrect or expired token."' +
                '}' +
                ']' +
                '}';
            System.debug('####TEST req.getEndpoint() : ' + req.getEndpoint());
            if (statusCode == 200) {
                if (req.getEndpoint().contains('balance')) {
                    res.setBody(balanceOK);
                }else if (req.getEndpoint().contains('operation')) {
                    res.setBody(operationOK);
                }else{
                    res.setBody(cardOK);
                }
            } else if(statusCode == 400) {
                res.setBody(wsMalformedJsonKO);
            } else{
                res.setBody(wsKO);
            }
            
            res.setStatusCode(statusCode);
            
            return res;
        }
    }
}