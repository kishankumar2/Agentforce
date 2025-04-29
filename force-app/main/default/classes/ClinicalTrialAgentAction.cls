public with sharing class ClinicalTrialAgentAction {
    public class ClinicalTrialException extends Exception {}

    public class Input {
        @InvocableVariable(required=true)
        public Id AssociationId;
    }

    public class Output {
        @InvocableVariable
        public String summaryMessage;
    }

    @InvocableMethod(label='Handle Association Record')
    public static List<Output> handle(List<Input> inputs) {
        List<Output> results = new List<Output>();

        if (inputs == null || inputs.isEmpty()) {
            Output o = new Output();
            o.summaryMessage = ' No input received.';
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

        // Query Associations safely
        Map<Id, Association__c> assocMap = new Map<Id, Association__c>(
            [SELECT Id, Name,
                    Patient__r.Id,
                    Patient__r.Name,
                    Patient__r.Owner.Email,
                    Clinical_Trial__r.Name
             FROM Association__c
             WHERE Id IN :assocIds]
        );

        for (Id assocId : assocIds) {
            Output o = new Output();

            if (!assocMap.containsKey(assocId)) {
                o.summaryMessage = 'Association not found for ID: ' + assocId;
                results.add(o);
                continue;
            }

            Association__c assoc = assocMap.get(assocId);

            try {
                // Create Task
                Task t = new Task(
                    WhatId = assoc.Patient__r.Id,
                    Subject = 'Follow-up for Clinical Trial: ' + assoc.Clinical_Trial__r.Name,
                    Status = 'Not Started',
                    Priority = 'Normal',
                    OwnerId = getQueueIdByName('Clinical_Trials_Queue')
                );
                insert t;
 			String slackMsg = '📌 Association processed for patient: *' + assoc.Patient__r.Name + '* | Trial: *' + assoc.Clinical_Trial__r.Name + '*';
                SlackIntegration.sendMessage(slackMsg);
       if (assoc.Patient__r.OwnerId != null) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setTargetObjectId(assoc.Patient__r.OwnerId); // internal User
    mail.setWhatId(assoc.Patient__r.Id);              // related to Account
    mail.setSubject('Clinical Trial Task Assigned');
    mail.setPlainTextBody('A task has been created for the patient: ' + assoc.Patient__r.Name);
    mail.setSaveAsActivity(false); // 
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
}

                // Summary Output
                o.summaryMessage = 'Task created for ' + assoc.Patient__r.Name +
                                   ' | Trial: ' + assoc.Clinical_Trial__r.Name +
                                   ' | Email sent.';
            } catch (Exception e) {
                o.summaryMessage = 'Failed to process ' + assoc.Name + ': ' + e.getMessage();
            }

            results.add(o);
        }

        return results;
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
throw new ClinicalTrialException('Queue "' + queueName + '" not found.');
    }
}

}