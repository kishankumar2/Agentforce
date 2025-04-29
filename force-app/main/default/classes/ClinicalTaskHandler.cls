/**
 * @description       : 
 * @author            : Coder
 * @group             : 
 * @last modified on  : 04-23-2025
 * @last modified by  : Coder
**/
public with sharing class ClinicalTaskHandler {
    public class ClinicalTaskException extends Exception {}
    
    public class Input {
        @InvocableVariable(required=true)
        public Id AssociationId;
        
        @InvocableVariable(required=true)
        public String TaskSubject;
        
        @InvocableVariable(required=true)
        public Date DueDate;
    }
    
    public class Output {
        @InvocableVariable
        public String summaryMessage;
        
        @InvocableVariable
        public Id taskId;
    }
    
    @InvocableMethod(label='Create Clinical Trial Task')
    public static List<Output> createTask(List<Input> inputs) {
        List<Output> results = new List<Output>();
        
        if (inputs == null || inputs.isEmpty()) {
            Output o = new Output();
            o.summaryMessage = 'No input received.';
            results.add(o);
            return results;
        }
        
        Set<Id> assocIds = new Set<Id>();
        for (Input input : inputs) {
            if (input.AssociationId != null) {
                assocIds.add(input.AssociationId);
            }
        }
        
        if (assocIds.isEmpty()) {
            Output o = new Output();
            o.summaryMessage = 'No valid Association IDs provided.';
            results.add(o);
            return results;
        }
        
        // Query Associations to get Patient and Trial details
        Map<Id, Association__c> assocMap = new Map<Id, Association__c>([
            SELECT Id, Name,
                   Patient__r.Id,
                   Patient__r.Name,
                   Clinical_Trial__r.Name
            FROM Association__c
            WHERE Id IN :assocIds
        ]);
        
        for (Input input : inputs) {
            Output o = new Output();
            try {
                if (!assocMap.containsKey(input.AssociationId)) {
                    o.summaryMessage = 'Association not found for ID: ' + input.AssociationId;
                    results.add(o);
                    continue;
                }
                
                Association__c assoc = assocMap.get(input.AssociationId);
                Task t = createClinicalTrialTask(
                    assoc.Patient__r.Id,
                    input.TaskSubject,
                    input.DueDate,
                    assoc.Clinical_Trial__r.Name
                );
                
                o.taskId = t.Id;
                o.summaryMessage = 'Task created successfully for Patient: ' + assoc.Patient__r.Name + 
                                 ' | Trial: ' + assoc.Clinical_Trial__r.Name;
            } catch (Exception e) {
                o.summaryMessage = 'Failed to create task: ' + e.getMessage();
            }
            results.add(o);
        }
        
        return results;
    }
    
    private static Task createClinicalTrialTask(Id patientId, String subject, Date dueDate, String clinicalTrialName) {
        try {
            Task t = new Task(
                WhatId = patientId,
                Subject = subject,
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = dueDate,
                OwnerId = getQueueIdByName('Clinical_Trials_Queue')
            );
            insert t;
            return t;
        } catch (Exception e) {
            throw new ClinicalTaskException('Failed to create task: ' + e.getMessage());
        }
    }
    
    private static Id getQueueIdByName(String queueName) {
        try {
            Group q = [
                SELECT Id FROM Group
                WHERE DeveloperName = :queueName AND Type = 'Queue'
                LIMIT 1
            ];
            return q.Id;
        } catch (Exception e) {
            throw new ClinicalTaskException('Queue "' + queueName + '" not found.');
        }
    }
}