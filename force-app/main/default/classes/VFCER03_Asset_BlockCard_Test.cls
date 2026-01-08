/**
* @author Oussama LASFAR
* @date 05/11/2018 (dd/mm/yyyy)
* @description This class contains unit tests for validating the behavior of VFCER03_Asset_BlockCard
*/

@isTest
public class VFCER03_Asset_BlockCard_Test {
    
    static VFCER03_Asset_BlockCard controller;
    
    @testSetup
    static void testSetup() {
        
        Account newClient = APER07_UtilityTestMethod.getClient();
        insert newClient;
        
        ER_Employee__c newEmployee = APER07_UtilityTestMethod.getEmployee();
        newEmployee.ER_Client__c = newClient.id;
        insert newEmployee;
        
        Product2 newProduct = APER07_UtilityTestMethod.getProduct('TSC_P');
        insert newProduct;
        
        Asset newAsset = APER07_UtilityTestMethod.getAsset('2801001840','ER_Asset_Record_Type','ER_Mono-Wallet');
        newAsset.ER_Employee__c = newEmployee.id;
        newAsset.AccountId = newClient.id;
        newAsset.Product2Id = newProduct.id;
        insert newAsset;
        
        Case newCase = APER07_UtilityTestMethod.getCase('ER_User_Case_RT');
        newCase.AssetId = newAsset.id;
        insert newCase;
    }
    
    static testMethod void getrequetesOptions() {
        
        Asset assetinst = [select id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name from Asset where name = '2801001840'];
        ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
        controller = new  VFCER03_Asset_BlockCard(sc);
        
        Test.StartTest();
        controller.getrequetesOptions();
        Test.StopTest();
    }
    
    static testMethod void blockCard() {
        
        Asset assetinst = [select id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name from Asset where name = '2801001840'];
        assetinst.ER_Block_Card_Reason__c = 'Lost';
        ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
        controller = new  VFCER03_Asset_BlockCard(sc);
        
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(401));
        controller.blockCard();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(200));
        controller.blockCard();
        Test.setMock(HttpCalloutMock.class, new CardWSMockImpl(400));
        controller.blockCard();
        Test.StopTest();
    }
        
    static testMethod void linkCase() {
        
        Asset assetinst = [select id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name from Asset where name = '2801001840'];
        ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
        controller = new  VFCER03_Asset_BlockCard(sc);
        
        Case caseinst = [select id from Case limit 1];
        
        Test.StartTest();
        controller.linkCase();//Test Exception
        controller.selectedCase = caseinst.id;
        controller.wsCalledAtLeastOnce = true;
        controller.wsSuccess = true;
        controller.linkCase();
        Test.StopTest();
    }
    
    static testMethod void createNewCase() {
        
        Asset assetinst = [select id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name from Asset where name = '2801001840'];
        ApexPages.StandardController sc = new ApexPages.StandardController(assetInst);
        controller = new  VFCER03_Asset_BlockCard(sc);
        
        Test.StartTest();
        controller.createNewCase();//Test Exception
        controller.wsCalledAtLeastOnce = true;
        controller.createNewCase();
        Test.StopTest();
    }
    
    static testMethod void updateAsset() {
        
        Asset assetinst = [select id, ER_Block_Card_Reason__c, ER_Employee__c, ER_Product_Class__c, ER_Asset_Type__c, ER_Edenred_Solution__c, Name from Asset where name = '2801001840'];
        Test.StartTest();
        VFCER03_Asset_BlockCard.updateAsset(assetinst.Id,'Other');
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
            
            String blockCardOK = '{'+
                                    '"meta": {'+
                                        '"status": "succeeded",'+
                                        '"messages": []'+
                                    '},'+
                                    '"data": ['+
                                    ']'+
                                '}';
            
            String wsKO = '{'+
                    '"meta": {'+
                        '"status": "failed",'+
                        '"messages": ['+
                            '{'+
                                '"code": "BAD_REQUEST",'+
                                '"level": "error",'+
                                '"text": "Unable to process your request, please check its validity."'+
                            '},'+
                            '{'+
                                '"code": "AUTHENTICATION_FAILED",'+
                                '"level": "error",'+
                                '"text": "Incorrect or expired token."'+
                            '}'+
                        ']'+
                    '}'+
                '}';
            
            String wsMalformedJsonKO = '{'+
                                            '"meta": {'+
                                            '"status": "failed",'+
                                            '"messages": ['+
                                                '{'+
                                                    '"code": "BAD_REQUEST",'+
                                                    '"level": "error",'+
                                                    '"text": "Unable to process your request, please check its validity."'+
                                                '},'+
                                                '{'+
                                                    '"code": "AUTHENTICATION_FAILED",'+
                                                    '"level": "error",'+
                                                    '"text": "Incorrect or expired token."'+
                                                '}'+
                                            ']'+
                                        '}';
            
            System.debug('####TEST req.getEndpoint() : ' + req.getEndpoint());
            
            if (statusCode == 200) {
                res.setBody(blockCardOK);
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