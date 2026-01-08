/**
* @author Oussama LASFAR
* @date 26/09/2018 (dd/mm/yyyy)
* @description test class to cover the case trigger before update
*/
@isTest
public class APER08_Case_Management_Test {
    @testSetup
    static void testSetup() {
        
        Case testCase = new Case();
        testCase.Status= Label.LAB_SF_Case_inProgress;
        testCase.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ER_User_Case_RT').getRecordTypeId();
        insert testCase;        
    }
    static testMethod void completeMilestone() {
        List<Case> caseinst = [select id from Case limit 1];
        if(!caseinst.isEmpty()){
            caseinst[0].Status=Label.LAB_SF_Case_resolved;
            update caseinst[0];
            caseinst[0].Status=Label.LAB_SF_Case_feedbackSent;
            update caseinst[0];
        }
    }
    static testMethod void updateCaseRT() {
        List<Case> caseinst = [select id from Case limit 1];
        List<Group> QueueList = [select Id from Group where developerName = 'ERAT_FrontOffice' and Type = 'Queue'];
        if(!caseinst.isEmpty() && !QueueList.isEmpty()){
            caseinst[0].ownerId=QueueList[0].id;
            update caseinst[0];
        }
    }
}