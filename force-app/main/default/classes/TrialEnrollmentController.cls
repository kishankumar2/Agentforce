public without sharing class TrialEnrollmentController {
    
    /**
     * Creates an Association record between a Patient and a Clinical Trial
     * @param trialName The name of the clinical trial
     * @param userId The ID of the user to enroll
     * @return String with result message or error
     */
    @AuraEnabled
    public static String enrollPatientInTrial(String trialName, String userId) {
        try {
            // Get the user's Contact.AccountId (Patient ID) using the provided userId
            User currentUser = [SELECT Id, ContactId FROM User WHERE Id = :userId LIMIT 1];
            
            if (currentUser.ContactId == null) {
                return 'Error: User does not have an associated Contact record.';
            }
            
            Contact userContact = [SELECT Id, AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
            
            if (userContact.AccountId == null) {
                return 'Error: Contact does not have an associated Account (Patient) record.';
            }
            
            Id patientId = userContact.AccountId;
            String key = '%'+trialName+'%';
            System.debug('key'+key);
            // Find the Clinical Trial ID based on the name
            //List<Clinical_Trial__c> trials = [SELECT Id FROM Clinical_Trial__c WHERE Name LIKE :key LIMIT 1];
            List<Clinical_Trial__c> trials = [SELECT Id FROM Clinical_Trial__c WHERE Clinical_Trial_Name__c LIKE :key LIMIT 1];
            if (trials.isEmpty()) {
                return 'Error: Clinical Trial "' + trialName + '" not found.';
            }
            
            Id trialId = trials[0].Id;
            
            // Check if an association already exists
            List<Association__c> existingAssociations = [
                SELECT Id 
                FROM Association__c 
                WHERE Patient__c = :patientId 
                AND Clinical_Trial__c = :trialId 
                LIMIT 1
            ];
            
            if (!existingAssociations.isEmpty()) {
                return 'You are already enrolled in this study.';
            }
            
            // Create the Association record
            Association__c newAssociation = new Association__c(
                Patient__c = patientId,
                Clinical_Trial__c = trialId
              
            );
            
            insert newAssociation;
            
            return 'Success: You have been enrolled in the ' + trialName + ' study.';
        } catch (Exception e) {
            // Log the error
            System.debug('Error enrolling patient in trial: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
}