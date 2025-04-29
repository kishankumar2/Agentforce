/**
 * @description       : 
 * @author            : Coder
 * @group             : 
 * @last modified on  : 04-23-2025
 * @last modified by  : Coder
**/
public with sharing class ClinicalSlackHandler {
    public class ClinicalSlackException extends Exception {}
    
    public class Input {
        @InvocableVariable(required=true)
        public Id AssociationId;
        
        @InvocableVariable(required=true)
        public String Message;
    }
    
    public class Output {
        @InvocableVariable
        public String summaryMessage;
    }
    
    @InvocableMethod(label='Send Clinical Trial Slack Message')
    public static List<Output> sendSlackMessage(List<Input> inputs) {
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
        
        // Query Associations to get Trial details
        Map<Id, Association__c> assocMap = new Map<Id, Association__c>([
            SELECT Id, Name,
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
                String slackMsg = input.Message + ' For Clinical Trial: *' + assoc.Clinical_Trial__r.Name + '*';
                SlackIntegration.sendMessage(slackMsg);
                o.summaryMessage = 'Slack message sent successfully for Clinical Trial: ' + assoc.Clinical_Trial__r.Name;
            } catch (Exception e) {
                o.summaryMessage = 'Failed to send Slack message: ' + e.getMessage();
            }
            results.add(o);
        }
        
        return results;
    }
}