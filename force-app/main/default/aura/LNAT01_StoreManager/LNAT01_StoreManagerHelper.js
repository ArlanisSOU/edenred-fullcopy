({
	deleteStores: function(component, event, helper){
        var action = component.get("c.deleteUnderlyingStores");
        action.setParams({"accId": component.get("v.recordId")});

        action.setCallback(this, function(response){});    
        
        $A.enqueueAction(action);
        helper.actionWaitForFinish(action, helper, "Stores deleted"); 
    },
    
    deleteAcceptors: function(component, event, helper){
        var action = component.get("c.deleteUnderlyingAcceptors");
        action.setParams({"accId": component.get("v.recordId")});
        
        action.setCallback(this, function(response){});   
        
        $A.enqueueAction(action);
        helper.actionWaitForFinish(action, helper, "Acceptors deleted"); 
    },
    
    deleteStoreAuth: function(component, event, helper){
        var action = component.get("c.deleteUnderlyingStoreAuth");
        var state;
        action.setParams({"accId": component.get("v.recordId")});
        
        action.setCallback(this, function(response){});   
        
        $A.enqueueAction(action);
        helper.actionWaitForFinish(action, helper, "Store Authorizations deleted"); 
    },
    

    
    toastThis  : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type,
            "key": "sticky"
        });
        toastEvent.fire();
    },
    
    //
    // This guarantees that toaster is shown. 
    // Wait for result
    actionWaitForFinish : function(action, helper, message) {
        
            var intervalId;
            var checkTheAction = function(){
                if (action.getState() === "SUCCESS" || action.getState() === "ERROR" || action.getState() === "ABORTED"){
                    helper.toastThis(action.getReturnValue(), message);  
                    window.clearInterval(intervalId);
                    
                }
            };
			
        	//console.log("actionWaitForFinish waiting...")
    		intervalId = window.setInterval(checkTheAction,1000);
        
    },
    
    //
    // Replaces component.set
    // Works with Arrays (assign array to array), or loops through array
    //
    componentSet : function(component, helper, variable, value) {
        
        var compVar;
        compVar = component.get(variable);
        
        if (compVar instanceof Array) {
            if (value instanceof Array) {
                //Array2Array
                component.set(variable,value);
                
            } else {
                //set the same value for all ArrayElements
                for (var i = 0; i < compVar.length; i++) {
                      component.set(variable + "[" + i + "]", value);
                }
            }
 
        } else {
            //not an array
            component.set(variable, value);
        }   
    }
})