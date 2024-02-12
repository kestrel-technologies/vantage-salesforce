@IsTest
private class VantageLeadRoutingService_Test {
    private static VantageLeadRoutingService.RoutingRequest req(String region, String segment) {
        VantageLeadRoutingService.RoutingRequest r = new VantageLeadRoutingService.RoutingRequest();
        r.region = region;
        r.segment = segment;
        return r;
    }

    @IsTest static void resolvesQueueIdsFromRegionAndSegment() {
        Map<String, Id> queues = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE 'SDR_%']) {
            queues.put(g.DeveloperName, g.Id);
        }

        List<Id> result = VantageLeadRoutingService.resolveQueue(new List<VantageLeadRoutingService.RoutingRequest>{
            req('AMER', 'Enterprise'), req('AMER', 'Mid-Market'), req('EMEA', 'Enterprise'), req('APAC', 'Mid-Market')
        });

        System.assertEquals(4, result.size());
        System.assertEquals(queues.get('SDR_AMER_Enterprise'), result[0]);
        System.assertEquals(queues.get('SDR_AMER_MidMarket'), result[1]);
        System.assertEquals(queues.get('SDR_EMEA'), result[2]);
        System.assertEquals(queues.get('SDR_APAC'), result[3]);
        System.assertNotEquals(null, result[0], 'queue SDR_AMER_Enterprise must exist');
    }

    @IsTest static void unknownRegionFallsBackToApac() {
        System.assertEquals('SDR_APAC', VantageLeadRoutingService.queueName('MARS', null));
        List<Id> result = VantageLeadRoutingService.resolveQueue(new List<VantageLeadRoutingService.RoutingRequest>{ req('MARS', null) });
        System.assertEquals(TestDataFactory.queueId('SDR_APAC'), result[0]);
    }

    @IsTest static void flowRoutesNewLeadToRegionQueue() {
        Lead l = new Lead(LastName = 'Routing', Company = 'Routing Test Co', LeadSource = 'Web',
            Region__c = 'EMEA', Segment__c = 'Enterprise', Status = 'New');
        Test.startTest();
        insert l;
        Test.stopTest();
        System.assertEquals(TestDataFactory.queueId('SDR_EMEA'), [SELECT OwnerId FROM Lead WHERE Id = :l.Id].OwnerId);
    }

    @IsTest static void flowRespectsManualLeadOwnedByUser() {
        Lead l = new Lead(LastName = 'Manual', Company = 'Manual Test Co', LeadSource = 'Manual',
            Region__c = 'APAC', Segment__c = 'Enterprise', Status = 'New', OwnerId = UserInfo.getUserId());
        insert l;
        System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM Lead WHERE Id = :l.Id].OwnerId);
    }

    @IsTest static void flowReroutesQueuedLeadWhenRegionChanges() {
        Lead l = new Lead(LastName = 'Mover', Company = 'Mover Test Co', LeadSource = 'Event',
            Region__c = 'AMER', Segment__c = 'Mid-Market', Status = 'New');
        insert l;
        System.assertEquals(TestDataFactory.queueId('SDR_AMER_MidMarket'), [SELECT OwnerId FROM Lead WHERE Id = :l.Id].OwnerId);
        Test.startTest();
        update new Lead(Id = l.Id, Region__c = 'APAC');
        Test.stopTest();
        System.assertEquals(TestDataFactory.queueId('SDR_APAC'), [SELECT OwnerId FROM Lead WHERE Id = :l.Id].OwnerId);
    }
}
