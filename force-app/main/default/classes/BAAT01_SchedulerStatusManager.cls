global class BAAT01_SchedulerStatusManager implements Schedulable {
    global void execute(SchedulableContext ctx) {
        
        APAT01_ToolkitAT.statusManager();
    }
    
}