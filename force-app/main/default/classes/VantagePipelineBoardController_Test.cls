@IsTest
private class VantagePipelineBoardController_Test {
    @IsTest static void groupsOpenOpportunitiesByStage() {
        Account a = TestDataFactory.insertAccount('Board Test Co', 'AMER');
        List<Opportunity> opps = new List<Opportunity>{
            TestDataFactory.newOpportunity(a.Id, 'Board Discovery 1', 'Discovery'),
            TestDataFactory.newOpportunity(a.Id, 'Board Discovery 2', 'Discovery'),
            TestDataFactory.newOpportunity(a.Id, 'Board Negotiation', 'Negotiation'),
            TestDataFactory.newOpportunity(a.Id, 'Board Lost', 'Closed Lost')
        };
        opps[0].Amount = 100000;
        opps[1].Amount = 50000;
        opps[2].Amount = 250000;
        insert opps;

        Test.startTest();
        List<VantagePipelineBoardController.StageColumn> board = VantagePipelineBoardController.getBoard();
        Test.stopTest();

        Map<String, VantagePipelineBoardController.StageColumn> byStage = new Map<String, VantagePipelineBoardController.StageColumn>();
        for (VantagePipelineBoardController.StageColumn c : board) byStage.put(c.stage, c);

        System.assertEquals('Discovery', board[0].stage, 'columns follow the stage sort order');
        System.assert(!byStage.containsKey('Closed Lost'), 'closed stages are not columns');
        System.assertEquals(2, byStage.get('Discovery').count);
        System.assertEquals(150000, byStage.get('Discovery').total);
        System.assertEquals('Board Discovery 1', byStage.get('Discovery').cards[0].name, 'largest deal first');
        System.assertEquals('Board Test Co', byStage.get('Discovery').cards[0].accountName);
        System.assertEquals(1, byStage.get('Negotiation').count);
        System.assertEquals(0, byStage.get('Solution Design').count);
    }
}
