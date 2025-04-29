public with sharing class NotifyDownstreamSystemAction {
    
    public class Input {
        @InvocableVariable(required=true)
        public String patientName;
        
        @InvocableVariable(required=true)
        public String clinicalTrialName;
    }

    public class Output {
        @InvocableVariable
        public String summaryMessage;
    }

    @InvocableMethod(label='Notify Downstream System' description='Send Patient and Clinical Trial details to Target Org')
    public static List<Output> notifyDownstream(List<Input> inputs) {
        List<Output> results = new List<Output>();

        if (inputs == null || inputs.isEmpty()) {
            Output o = new Output();
            o.summaryMessage = 'No input received.';
            results.add(o);
            return results;
        }

        for (Input input : inputs) {
            Output o = new Output();

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:ConnectTargetOrg/services/apexrest/patienttrial');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');

                Map<String, String> payload = new Map<String, String>{
                    'patientName' => input.patientName,
                    'clinicalTrialName' => input.clinicalTrialName
                };

                req.setBody(JSON.serialize(payload));

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    o.summaryMessage = '✅ Successfully notified downstream for patient: ' + input.patientName +
                                       ' | Trial: ' + input.clinicalTrialName;
                } else {
                    o.summaryMessage = '⚠️ Failed to notify downstream for patient: ' + input.patientName +
                                       '. Status: ' + res.getStatusCode() +
                                       '. Response: ' + res.getBody();
                }

            } catch (Exception ex) {
                o.summaryMessage = '❌ Exception notifying downstream for patient: ' + input.patientName +
                                   '. Error: ' + ex.getMessage();
            }

            results.add(o);
        }

        return results;
    }
}