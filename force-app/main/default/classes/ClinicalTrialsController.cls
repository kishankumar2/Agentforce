public without sharing class ClinicalTrialsController {
    
    public class ClinicalTrialsInput {
        @InvocableVariable(
            label='Account ID' 
            required=true
            description='The Salesforce ID of the Account record containing patient information'
        )
        public String accountId;
        
        @InvocableVariable(
            label='Current User ID' 
            required=true
            description='The Salesforce ID of the currently logged-in user who is requesting the clinical trials'
        )
        public String currentUserId;
    }
    
    @InvocableMethod(
        label='Get Clinical Trials'
        description='Retrieves clinical trials for given account and current user ID'
    )
    public static List<String> getClinicalTrialsResponse(List<ClinicalTrialsInput> inputs) {
        List<String> results = new List<String>();
        
        try {
            if (inputs == null || inputs.isEmpty() || inputs[0].accountId == null || inputs[0].currentUserId == null) {
                results.add('Error: Account ID and Current User ID are required');
                return results;
            }
            
            // Query Account record
            Account acc = [SELECT Id, Patient_Age__c, Gender__c,Patient_City__c, Medical_Conditions__c, Medicines__c 
                          FROM Account 
                          WHERE Id = :inputs[0].accountId LIMIT 1];
            
            // Build the query string with the specified format
            String queryString = 'Find relevant Clinical Trails for this Patient (Patient_Age__c = ' + acc.Patient_Age__c + 
                ' ,Gender__c = \'' + acc.Gender__c + '\'' +               
                ' ,Patient_City__c = \'' + acc.Patient_City__c + '\'' +
                               ' ,Medical_Conditions__c = \'' + acc.Medical_Conditions__c + '\'' +
                               ' ,Medicines__c = \'' + (acc.Medicines__c != null ? acc.Medicines__c : '') + '\')' +
                               ' the Current_User_ID__c = \'' + inputs[0].currentUserId + '\'';

            // Build input map for the template
            Map<String, ConnectApi.WrappedValue> valueMap = new Map<String, ConnectApi.WrappedValue>();
            
            // Create wrapped value for Query with proper input parameter name
            ConnectApi.WrappedValue queryWrappedValue = new ConnectApi.WrappedValue();
            queryWrappedValue.value = queryString;
            valueMap.put('Input:Query', queryWrappedValue);
            System.debug('queryString'+queryString);
            // Create wrapped value for RetrieverId with exact parameter name
            ConnectApi.WrappedValue retrieverIdWrappedValue = new ConnectApi.WrappedValue();
            retrieverIdWrappedValue.value = '1CxgK0000000Ma1SAE';
            valueMap.put('Input:retrieverIdOrName', retrieverIdWrappedValue);

            // Configure invocation parameters
            ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
            executeTemplateInput.isPreview = false;
            executeTemplateInput.inputParams = valueMap;

            System.debug('ClinicalTrialsController.getClinicalTrialsResponse - Calling Einstein LLM with template: Clinical_Trials');
            System.debug('ClinicalTrialsController.getClinicalTrialsResponse - Input parameters: Template name = Clinical_Trials');
            
            // Call the service
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Clinical_Trials', executeTemplateInput);
            
            System.debug('ClinicalTrialsController.getClinicalTrialsResponse - Received response from Einstein LLM');
            
            // Return the response
            String responseText = generationsOutput.generations[0].text;
            AgentActionEvent__e event = new AgentActionEvent__e(
                Studies_JSON__c = responseText
            );
            System.debug('ClinicalTrialsController.getClinicalTrialsResponse - Created event: ' + event);
            
            // Publish the event
            System.debug('ClinicalTrialsController.getClinicalTrialsResponse - Publishing event');
            Database.SaveResult result = EventBus.publish(event);
            
            if (result.isSuccess()) {
                results.add('Recommended trials will be shown shortly on UI');
            } else {
                results.add('Error publishing event: ' + result.getErrors()[0].getMessage());
            }
           
        } catch (Exception e) {
            System.debug('ClinicalTrialsController.getClinicalTrialsResponse - Error occurred: ' + e.getMessage());
            System.debug('ClinicalTrialsController.getClinicalTrialsResponse - Stack trace: ' + e.getStackTraceString());
            results.add('Error: ' + e.getMessage());
        }
        
        return results;
    }
}