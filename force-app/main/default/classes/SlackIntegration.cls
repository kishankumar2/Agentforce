public class SlackIntegration {
    
    // Replace this with your actual Slack Webhook URL
    private static final String SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/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';

    @future(callout=true)
    public static void sendMessage(String message) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(SLACK_WEBHOOK_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');

        // Prepare message payload
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('text', message);

        // Serialize payload and send
        String jsonPayload = JSON.serialize(payload);
        request.setBody(jsonPayload);

        Http http = new Http();
        HttpResponse response = http.send(request);

        // Log response if error
        if (response.getStatusCode() != 200) {
            System.debug(' Error sending message to Slack: ' + response.getBody());
        } else {
            System.debug('✅ Slack message sent: ' + message);
        }
    }
}