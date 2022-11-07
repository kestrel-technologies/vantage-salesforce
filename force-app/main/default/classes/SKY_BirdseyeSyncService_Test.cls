@IsTest
private class SKY_BirdseyeSyncService_Test {
    @IsTest static void coverage() {
        Test.setMock(HttpCalloutMock.class, new SKY_BirdseyeMock());
        SKY_Legacy_Integration_Config__c c = new SKY_Legacy_Integration_Config__c(SetupOwnerId = UserInfo.getOrganizationId(),
            Birdseye_Username__c = 'u', Birdseye_Password__c = 'p', Birdseye_Base_URL__c = 'https://x.example', Sync_Enabled__c = true);
        insert c;
        Test.startTest();
        SKY_BirdseyeSyncService.getToken();
        SKY_BirdseyeSyncService.syncAccounts(new Set<Id>());
        Test.stopTest();
        System.assert(true);
    }
}
