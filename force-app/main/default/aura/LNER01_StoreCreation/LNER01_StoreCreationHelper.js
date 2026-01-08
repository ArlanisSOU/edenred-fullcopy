({
    validateStoreForm: function(component) {
        var validStore = true;
  
        var acc = component.get("v.acc");
        
        if($A.util.isEmpty(acc)) 
        {
            validStore = false;
            console.log("Quick action context doesn't have a valid Account.");
        }
        return(validStore);
    }
})