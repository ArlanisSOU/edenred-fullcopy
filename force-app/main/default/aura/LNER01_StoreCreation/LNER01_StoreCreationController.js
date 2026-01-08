({
    doInit : function(component, event, helper) {
        var getAccountAction = component.get("c.getAccountWS");
        getAccountAction.setParams({"accId": component.get("v.recordId")});
 
        // Configure response handler
        getAccountAction.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if(state === "SUCCESS") 
            {
                component.set("v.acc", response.getReturnValue());
                
                //Suggest Store Info from Parent Account
                var strName = component.get("v.acc.Name");
                
                component.set("v.newStore.Name", strName + ' (Store)');
                component.set("v.newStore.ER_Street__c", component.get("v.acc.BillingStreet"));
                component.set("v.newStore.ER_Zip_Code__c", component.get("v.acc.BillingPostalCode"));
                component.set("v.newStore.ER_City__c", component.get("v.acc.BillingCity"));
            } 
            else 
            {
                console.log('Problem getting Account, response state: ' + state);
            }
        });
        $A.enqueueAction(getAccountAction);
    },

    //******************saveStore****************
    saveStore: function(component, event, helper) {
        	if(helper.validateStoreForm(component)) {
            var saveStoreAction = component.get("c.saveStoreWS");
                
            saveStoreAction.setParams({
                "erStore": component.get("v.newStore"),
                "accId": component.get("v.recordId")
            });

            // Configure the response handler for the action
            saveStoreAction.setCallback(this, function(response) {
                var state = response.getState();
                if(state === "SUCCESS") {
                    
                var jsonNewStore = response.getReturnValue();
                // Prepare a toast UI message
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    mode: 'sticky',
                    message: 'New Store created',
                    messageTemplate: 'New Store *' + jsonNewStore.Name + '* created! See it {1}!',
                    messageTemplateData: ['Salesforce', {
                        url: '/lightning/r/ER_Store__c/' + jsonNewStore.Id + '/view',
                        label: 'here',
                        }
                    ]
                });
                $A.get("e.force:closeQuickAction").fire();    
                toastEvent.fire();
                }
                else if (state === "ERROR") {
                    console.log('Problem saving Store, response state: ' + state);
                }
                else {
                    console.log('Unknown problem, response state: ' + state);
                }
            });

    
            $A.enqueueAction(saveStoreAction);
        }
        
    },

    //******************closePopUp**************** 
	closePopUp: function(component, event, helper) {
	    $A.get("e.force:closeQuickAction").fire();
    }
})