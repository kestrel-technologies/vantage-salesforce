@IsTest
private class VantageCaseSlaService_Test {
    private static VantageCaseSlaService.SlaResult sla(String priority, Datetime created) {
        VantageCaseSlaService.SlaRequest r = new VantageCaseSlaService.SlaRequest();
        r.priority = priority;
        r.createdDate = created;
        return VantageCaseSlaService.setDueDates(new List<VantageCaseSlaService.SlaRequest>{ r })[0];
    }

    @IsTest static void dueDatesFollowPriorityTable() {
        Datetime t0 = Datetime.newInstanceGmt(2026, 10, 1, 9, 0, 0);
        System.assertEquals(t0.addHours(1), sla('P1', t0).responseDue);
        System.assertEquals(t0.addHours(8), sla('P1', t0).resolutionDue);
        System.assertEquals(t0.addHours(4), sla('P2', t0).responseDue);
        System.assertEquals(t0.addHours(24), sla('P2', t0).resolutionDue);
        System.assertEquals(t0.addHours(8), sla('P3', t0).responseDue);
        System.assertEquals(t0.addHours(72), sla('P3', t0).resolutionDue);
        System.assertEquals(t0.addHours(24), sla('P4', t0).responseDue);
        System.assertEquals(t0.addHours(120), sla('P4', t0).resolutionDue);
    }

    @IsTest static void unknownPriorityUsesP3AndMissingDateUsesNow() {
        Datetime t0 = Datetime.newInstanceGmt(2026, 10, 1, 9, 0, 0);
        System.assertEquals(t0.addHours(72), sla(null, t0).resolutionDue);
        Datetime before = Datetime.now();
        System.assert(sla('P1', null).responseDue >= before.addHours(1));
    }

    @IsTest static void routingFlowAssignsQueueAndSla() {
        Account emea = TestDataFactory.insertAccount('Routing EMEA Co', 'EMEA');
        Case c = new Case(Subject = 'Pipeline stuck', AccountId = emea.Id, Origin = 'Email',
            Priority = 'P2', Product_Area__c = 'Data Cloud', Status = 'New');
        Test.startTest();
        insert c;
        Test.stopTest();

        Case saved = [SELECT OwnerId, CreatedDate, SLA_Response_Due__c, SLA_Resolution_Due__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(TestDataFactory.queueId('L1_Platform_INTL'), saved.OwnerId);
        System.assertEquals(saved.CreatedDate.addHours(4), saved.SLA_Response_Due__c);
        System.assertEquals(saved.CreatedDate.addHours(24), saved.SLA_Resolution_Due__c);
    }

    @IsTest static void routingFlowDefaultsToAmerAndServices() {
        Case apps = new Case(Subject = 'Connector auth', Origin = 'Phone', Priority = 'P3', Product_Area__c = 'Connect', Status = 'New');
        Case services = new Case(Subject = 'Invoice question', Origin = 'Phone', Priority = 'P4', Product_Area__c = 'Portal & Account', Status = 'New');
        insert new List<Case>{ apps, services };
        Map<Id, Case> saved = new Map<Id, Case>([SELECT OwnerId FROM Case WHERE Id IN :new List<Id>{ apps.Id, services.Id }]);
        System.assertEquals(TestDataFactory.queueId('L1_Apps_AMER'), saved.get(apps.Id).OwnerId);
        System.assertEquals(TestDataFactory.queueId('L1_Services'), saved.get(services.Id).OwnerId);
    }

    @IsTest static void escalationMovesCaseToL2AndPriorityChangeResetsSla() {
