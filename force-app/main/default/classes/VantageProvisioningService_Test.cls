@IsTest
private class VantageProvisioningService_Test {
    private static Opportunity oppWithLines(Account a, Map<String, PricebookEntry> entries, Map<String, Decimal> qtyByCode) {
        Opportunity opp = TestDataFactory.newOpportunity(a.Id, 'Provisioning Test Opp', 'Negotiation');
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Contract_Term_Months__c = 24;
        insert opp;
        List<OpportunityLineItem> lines = new List<OpportunityLineItem>();
        for (String code : qtyByCode.keySet()) {
            lines.add(new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = entries.get(code).Id,
                Quantity = qtyByCode.get(code), UnitPrice = entries.get(code).UnitPrice));
        }
        insert lines;
        return opp;
    }

    @IsTest static void createsRequestContractAndTaskOnce() {
        Map<String, PricebookEntry> entries = TestDataFactory.insertProducts(new Map<String, Decimal>{ 'VDC-ENT' => 360000, 'VDC-CU-1K' => 18000 });
        Account a = TestDataFactory.insertAccount('Provisioning Test Co', 'AMER');
        Opportunity opp = oppWithLines(a, entries, new Map<String, Decimal>{ 'VDC-ENT' => 1, 'VDC-CU-1K' => 12 });

        Test.startTest();
        VantageProvisioningService.onClosedWon(new List<Id>{ opp.Id });
        VantageProvisioningService.onClosedWon(new List<Id>{ opp.Id, null });   // re-run is a no-op
        Test.stopTest();

        List<Provisioning_Request__c> prs = [SELECT Id, Edition__c, CU_Commit__c, Status__c, Account__c FROM Provisioning_Request__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, prs.size());
        System.assertEquals('Enterprise', prs[0].Edition__c);
        System.assertEquals(12000, prs[0].CU_Commit__c);
        System.assertEquals('Requested', prs[0].Status__c);
        System.assertEquals(a.Id, prs[0].Account__c);

        List<Contract> contracts = [SELECT StartDate, ContractTerm, Status FROM Contract WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, contracts.size());
        System.assertEquals(24, contracts[0].ContractTerm);
        System.assertEquals('Draft', contracts[0].Status);

        List<Task> tasks = [SELECT Subject, OwnerId, ActivityDate FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size());
        System.assertEquals('CSM kickoff: Provisioning Test Opp', tasks[0].Subject);
        System.assertEquals(UserInfo.getUserId(), tasks[0].OwnerId);
        System.assertEquals(Date.today().addDays(5), tasks[0].ActivityDate);

        System.assertEquals(prs[0].Id, [SELECT Provisioning_Request__c FROM Opportunity WHERE Id = :opp.Id].Provisioning_Request__c);
        System.assertEquals(opp.CloseDate, [SELECT Customer_Since__c FROM Account WHERE Id = :a.Id].Customer_Since__c);
    }

    @IsTest static void closedWonFlowFansOutServicesOnlyDeal() {
        Id pbId = TestDataFactory.activeStandardPricebookId();
        Account a = TestDataFactory.insertAccount('Flow Fan-out Co', 'EMEA');
        Opportunity opp = TestDataFactory.newOpportunity(a.Id, 'Services Deal', 'Negotiation');
        opp.SE_Owner__c = UserInfo.getUserId();
        opp.Pricebook2Id = pbId;
        insert opp;
        Quote q = TestDataFactory.insertQuote(opp.Id, pbId);
        update new Opportunity(Id = opp.Id, SyncedQuoteId = q.Id);

        Test.startTest();
        update new Opportunity(Id = opp.Id, StageName = 'Closed Won');
        Test.stopTest();

        List<Provisioning_Request__c> prs = [SELECT Edition__c FROM Provisioning_Request__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, prs.size());
        System.assertEquals('Services Only', prs[0].Edition__c);
        System.assertEquals(1, [SELECT COUNT() FROM Contract WHERE Opportunity__c = :opp.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :opp.Id]);
    }
        } catch (DmlException e) {
