@IsTest
private class SKY_BirdseyeSyncService_Test {
    @TestSetup static void config() {
        insert new SKY_Legacy_Integration_Config__c(SetupOwnerId = UserInfo.getOrganizationId(),
            Birdseye_Username__c = 'u', Birdseye_Password__c = 'p', Birdseye_Base_URL__c = 'https://x.example', Sync_Enabled__c = true);
    }

    @IsTest static void tokenRequestGoesThroughNamedCredential() {
        SKY_BirdseyeMock api = new SKY_BirdseyeMock();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, api);
        String token = SKY_BirdseyeSyncService.getToken();
        Test.stopTest();

        System.assertEquals('test-token', token);
        System.assertEquals(1, api.requests.size());
        HttpRequest req = api.requests[0];
        System.assertEquals('callout:Birdseye_API/api/v1/token', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        System.assertEquals(null, req.getHeader('X-Api-Key'), 'the API key is added by the Named Credential, never by the class');
        System.assertEquals('username=u&password=p', req.getBody());
    }

    @IsTest static void tokenFailureThrows() {
        SKY_BirdseyeMock api = new SKY_BirdseyeMock();
        api.tokenStatus = 401;
        Boolean thrown = false;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, api);
        try {
            SKY_BirdseyeSyncService.getToken();
        } catch (SKY_BirdseyeSyncService.BirdseyeException e) {
            thrown = e.getMessage().contains('401');
        }
        Test.stopTest();
        System.assert(thrown, 'expected a BirdseyeException naming HTTP 401');
    }

    @IsTest static void syncPostsSelectedAccountsWithBearerToken() {
        Account a = TestDataFactory.insertAccount('Birdseye Sync Co', 'EMEA');
        SKY_BirdseyeMock api = new SKY_BirdseyeMock();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, api);
        Integer synced = SKY_BirdseyeSyncService.syncAccounts(new Set<Id>{ a.Id });
        Test.stopTest();

        System.assertEquals(1, synced);
        System.assertEquals(2, api.requests.size());
        HttpRequest push = api.requests[1];
        System.assertEquals('callout:Birdseye_API/api/v1/accounts', push.getEndpoint());
        System.assertEquals('Bearer test-token', push.getHeader('Authorization'));
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(push.getBody());
        Map<String, Object> row = (Map<String, Object>) ((List<Object>) body.get('accounts'))[0];
        System.assertEquals('salesforce', body.get('source'));
        System.assertEquals(String.valueOf(a.Id), row.get('sf_id'));
        System.assertEquals('EMEA', row.get('region'));
    }

    @IsTest static void nightlyDeltaPicksUpRecentlyChangedAccounts() {
        TestDataFactory.insertAccount('Birdseye Delta One', 'AMER');
        TestDataFactory.insertAccount('Birdseye Delta Two', 'APAC');
        SKY_BirdseyeMock api = new SKY_BirdseyeMock();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, api);
        Integer synced = SKY_BirdseyeSyncService.syncAccounts(new Set<Id>());
        Test.stopTest();
        System.assertEquals(2, synced);
    }

    @IsTest static void syncDisabledMakesNoCallout() {
        SKY_Legacy_Integration_Config__c cfg = SKY_Legacy_Integration_Config__c.getOrgDefaults();
        cfg.Sync_Enabled__c = false;
        update cfg;
        SKY_BirdseyeMock api = new SKY_BirdseyeMock();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, api);
        Integer synced = SKY_BirdseyeSyncService.syncAccounts(null);
        Test.stopTest();
        System.assertEquals(0, synced);
        System.assertEquals(0, api.requests.size());
    }

    @IsTest static void birdseyeErrorReturnsZero() {
        Account a = TestDataFactory.insertAccount('Birdseye Outage Co', 'AMER');
        SKY_BirdseyeMock api = new SKY_BirdseyeMock();
        api.accountsStatus = 503;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, api);
        Integer synced = SKY_BirdseyeSyncService.syncAccounts(new Set<Id>{ a.Id });
        Test.stopTest();
        System.assertEquals(0, synced);
        System.assertEquals(2, api.requests.size());
    }
}
