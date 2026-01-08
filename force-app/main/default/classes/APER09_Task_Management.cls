public class APER09_Task_Management {
    
    Public Static Task CreateTask(String Subject, String Status, String WhatId){
        
        Task newTask = new Task();
        newTask.WhatId = WhatId;
        newTask.Subject = Subject;
        newTask.Status = Status;
        insert newTask;
        return newTask;
    }
}