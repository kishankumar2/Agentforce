public with sharing class AgentUtil {
    @AuraEnabled( cacheable=true )
    public static String fetchSessionId() {
        
        return UserInfo.getSessionId();
        
    }
}