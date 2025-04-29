/**
 * @description       : 
 * @author            : Coder
 * @group             : 
 * @last modified on  : 04-24-2025
 * @last modified by  : Coder
**/
public without sharing class AgentTrialEnrollmentController {
    
    /**
     * Input parameters for the invocable method
     */
    public class EnrollmentRequest {
        @InvocableVariable(required=true)
        public String accountId;
        
        @InvocableVariable(required=true)
        public String trialName;
    }
    
    /**
     * Creates an Association record between a Patient and a Clinical Trial
     * This method can be invoked by agents through Flow or Process Builder
     * @param requests List of enrollment requests containing accountId and trialName
     * @return List<String> with result messages or errors
     */
    @InvocableMethod(label='Enroll Patient in Trial' description='Enrolls a patient in a clinical trial')
    public static List<String> enrollPatientInTrial(List<EnrollmentRequest> requests) {
        List<String> results = new List<String>();
        
        for(EnrollmentRequest request : requests) {
            try {
                // Validate Account exists
                List<Account> accounts = [SELECT Id FROM Account WHERE Id = :request.accountId LIMIT 1];
                if(accounts.isEmpty()) {
                    results.add('Error: Account not found.');
                    continue;
                }
                
                // Find the Clinical Trial based on the name
                String key = '%' + request.trialName + '%';
                List<Clinical_Trial__c> trials = [SELECT Id FROM Clinical_Trial__c WHERE Clinical_Trial_Name__c LIKE :key LIMIT 1];
                
                if(trials.isEmpty()) {
                    results.add('Error: Clinical Trial "' + request.trialName + '" not found.');
                    continue;
                }
                
                Id trialId = trials[0].Id;
                
                // Check if an association already exists
                List<Association__c> existingAssociations = [
                    SELECT Id 
                    FROM Association__c 
                    WHERE Patient__c = :request.accountId 
                    AND Clinical_Trial__c = :trialId 
                    LIMIT 1
                ];
                
                if(!existingAssociations.isEmpty()) {
                    results.add('Patient is already enrolled in this study.');
                    continue;
                }
                
                // Create the Association record
                Association__c newAssociation = new Association__c(
                    Patient__c = request.accountId,
                    Clinical_Trial__c = trialId
                );
                
                insert newAssociation;
                
                results.add('Success: Patient has been enrolled in the ' + request.trialName + ' study.');
                
            } catch(Exception e) {
                // Log the error
                System.debug('Error enrolling patient in trial: ' + e.getMessage());
                results.add('Error: ' + e.getMessage());
            }
        }
        
        return results;
    }
}