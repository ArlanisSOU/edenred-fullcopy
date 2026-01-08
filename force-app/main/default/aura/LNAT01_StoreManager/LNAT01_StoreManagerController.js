({
    doInit : function(component, event, helper) {
 
        component.set("v.counters[2]",null);					//set size of the array
        helper.componentSet(component, helper, "v.counters", "...");
        
        var action = component.get("c.GetCounters");			//returns counters of Stores, Acceptors, StoreAuthorizations
        action.setParams({"accId": component.get("v.recordId")});
        action.setCallback(this, function(response){
        	var state = response.getState();  
            
            if (state != 'SUCCESS') {
               helper.componentSet(component, helper, "v.counters", state);
            } else 
            {
                var counterResp = response.getReturnValue();
                helper.componentSet(component, helper, "v.counters", counterResp);
            }

         });  
         $A.enqueueAction(action);
       
},

     cleanStoresAcceptorsStoreAuth: function(component, event, helper){
         helper.deleteStoreAuth(component, event, helper);
         helper.deleteAcceptors(component, event, helper);
         helper.deleteStores(component, event, helper);
               
         $A.get("e.force:closeQuickAction").fire();
         $A.get("e.force:refreshView").fire();
       
    },
    cleanStores: function(component, event, helper){
        helper.deleteStores(component, event, helper);
        
         $A.get("e.force:closeQuickAction").fire();
         $A.get("e.force:refreshView").fire();
    },
    
    cleanAcceptors: function(component, event, helper){
        helper.deleteAcceptors(component, event, helper);
        $A.get("e.force:closeQuickAction").fire();
    },
    
    cleanStoreAuthorizations: function(component, event, helper){
        helper.deleteStoreAuth(component, event, helper);
        $A.get("e.force:closeQuickAction").fire();
    },
    

    //******************closePopUp**************** 
    closePopUp: function(component, event, helper) {
    		$A.get("e.force:closeQuickAction").fire();
	}


})