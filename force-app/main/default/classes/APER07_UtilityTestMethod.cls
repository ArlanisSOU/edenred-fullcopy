/*
----------------------------------------------------------------------
-- - Name          : APER07_UtilityTestMethod
-- - Author        : OLA
-- - Description   : utility class to insert data
--
-- Date         Name                Version     Remarks
-- -----------  -----------         --------    ---------------------------------------
--  JAN-2019       OLA                 1.0         Initial version
---------------------------------------------------------------------------------------
*/
public class APER07_UtilityTestMethod {

  /*************************************
  *               Asset
  **************************************/

  //provide a single Asset
  public static Asset getAsset(String name, String recordTypeDeveloperName, String assetType) {
    return new Asset(
             Name = name,
             Status = Label.LAB_SF_ASSET_Status_Active,
             recordtypeid = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId(),
             ER_Asset_Type__c = assetType
           );
  }

  /*************************************
  *               Case
  **************************************/

  //provide a single Case
  public static Case getCase(String recordTypeDeveloperName) {
    return new Case(
             recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId()
           );
  }


  /*************************************
  *           ER_Employee__c
  **************************************/

  //provide a single Employee
  public static ER_Employee__c getEmployee() {
    return new ER_Employee__c(
             name = 'testEmployee',
             ER_Professional_Email__c = 'test@test.com'
           );
  }

  /*************************************
  *               Account
  **************************************/

  //provide a single Company
  public static Account getClient() {
    return new Account(
             recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client_Account_RT').getRecordTypeId(),
             Name = 'test DE name'
           );
  }

  /*************************************
  *               Contact
  **************************************/

  public static Contact getContact(String recordType, String firstName, String lastName) {
    return new Contact(
             FirstName = firstName ,
             LastName = lastName ,
             recordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId()
           );
  }
    
  /*************************************
  *               Product
  **************************************/

  //provide a single Client
  public static Product2 getProduct(String codeEDG) {
    return new Product2(
             Name = 'testProduct',
             ER_EDG_Product_Ref__c = codeEDG
           );
  }
}