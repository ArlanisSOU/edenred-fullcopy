@IsTest(SeeAllData=True)
//seealldata=true is needed to see referential data like loops etc.
public class BAAT01_SchedulerStatusManager_TEST{


    static testmethod void testAccStatus(){
        String schedule='0 22 16 * * ?';
        Test.startTest();
        String jobId=System.Schedule('ConsistencyCheckJob',schedule, new BAAT01_SchedulerStatusManager());
        Test.stopTest();
    } 


}