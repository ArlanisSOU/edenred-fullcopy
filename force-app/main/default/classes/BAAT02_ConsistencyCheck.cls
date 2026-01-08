global class BAAT02_ConsistencyCheck implements Schedulable {
    global void execute(SchedulableContext ctx) {
        
        APAT01_ToolkitAT.consistencyCheck();
    }
    
}