public without sharing class StudyEventLauncher {
    
    @InvocableMethod(
        label='Publish Study Event'
        description='Receives JSON string and publishes a platform event for studies'
    )
    public static List<String> publishStudyEvent(List<String> jsonInputs) {
        System.debug('StudyEventLauncher.publishStudyEvent - Entry point');
        System.debug('StudyEventLauncher.publishStudyEvent - Input: ' + jsonInputs);
        List<String> results = new List<String>();
        
        try {
            System.debug('StudyEventLauncher.publishStudyEvent - Inside try block');
            if (jsonInputs == null || jsonInputs.isEmpty()) {
                System.debug('StudyEventLauncher.publishStudyEvent - No JSON input provided');
                results.add('Error: No JSON input provided');
                return results;
            }
            
            System.debug('StudyEventLauncher.publishStudyEvent - JSON input: ' + jsonInputs[0]);
            // Create and publish the platform event
            AgentActionEvent__e event = new AgentActionEvent__e(
                Studies_JSON__c = jsonInputs[0]
            );
            System.debug('StudyEventLauncher.publishStudyEvent - Created event: ' + event);
            
            // Publish the event
            System.debug('StudyEventLauncher.publishStudyEvent - Publishing event');
            Database.SaveResult result = EventBus.publish(event);
            System.debug('StudyEventLauncher.publishStudyEvent - Publish result: ' + result);
            
            if (result.isSuccess()) {
                System.debug('StudyEventLauncher.publishStudyEvent - Event published successfully');
                results.add('Recommended trials will be shown shortly on UI');
            } else {
                System.debug('StudyEventLauncher.publishStudyEvent - Failed to publish event: ' + result.getErrors());
                results.add('Error publishing event: ' + result.getErrors()[0].getMessage());
            }
            
        } catch (Exception e) {
            System.debug('StudyEventLauncher.publishStudyEvent - Exception: ' + e.getMessage());
            System.debug('StudyEventLauncher.publishStudyEvent - Stack trace: ' + e.getStackTraceString());
            results.add('Error: ' + e.getMessage());
        }
        
        System.debug('StudyEventLauncher.publishStudyEvent - Returning results: ' + results);
        return results;
    }
}