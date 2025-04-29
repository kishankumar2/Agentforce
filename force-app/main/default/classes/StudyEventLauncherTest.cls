@IsTest
private class StudyEventLauncherTest {
    
    @IsTest
    static void testPublishStudyEventSuccess() {
        // Test data
        String testJson = '{"studies": [{"id": "123", "title": "Test Study"}]}';
        List<String> jsonInputs = new List<String>{testJson};
        
        // Start test execution context
        Test.startTest();
        List<String> results = StudyEventLauncher.publishStudyEvent(jsonInputs);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Recommended trials will be shown shortly on UI', results[0], 'Should return success message');
    }
    
    @IsTest
    static void testPublishStudyEventEmptyInput() {
        // Test with empty input
        List<String> jsonInputs = new List<String>();
        
        // Start test execution context
        Test.startTest();
        List<String> results = StudyEventLauncher.publishStudyEvent(jsonInputs);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Error: No JSON input provided', results[0], 'Should return error message for empty input');
    }
    
    @IsTest
    static void testPublishStudyEventNullInput() {
        // Test with null input
        List<String> jsonInputs = null;
        
        // Start test execution context
        Test.startTest();
        List<String> results = StudyEventLauncher.publishStudyEvent(jsonInputs);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Error: No JSON input provided', results[0], 'Should return error message for null input');
    }
} 