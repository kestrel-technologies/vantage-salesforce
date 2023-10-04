@IsTest
private class VantageQuoteSummaryController_Test {
    @IsTest static void summarisesOpportunityAndQuotes() {
        Map<String, PricebookEntry> entries = TestDataFactory.insertProducts(new Map<String, Decimal>{ 'VIN-CREATOR' => 2400 });
        Id pbId = Test.getStandardPricebookId();
        Account a = TestDataFactory.insertAccount('Summary Test Co', 'AMER');
        Opportunity opp = TestDataFactory.newOpportunity(a.Id, 'Summary Test Opp', 'Discovery');
        opp.Pricebook2Id = pbId;
        opp.Contract_Term_Months__c = 12;
        insert opp;
        Quote q1 = TestDataFactory.insertQuote(opp.Id, pbId);
        Quote q2 = TestDataFactory.insertQuote(opp.Id, pbId);
        QuoteLineItem li = TestDataFactory.newQuoteLine(q2.Id, entries.get('VIN-CREATOR'), 10);
        li.Discount = 10;
        insert li;

        Test.startTest();
        VantageQuoteSummaryController.QuoteSummary s = VantageQuoteSummaryController.getSummary(opp.Id);
        Test.stopTest();

        System.assertEquals(opp.Id, s.opportunityId);
        System.assertEquals('Summary Test Opp', s.opportunityName);
        System.assertEquals('Discovery', s.stage);
        System.assertEquals(12, s.termMonths);
        System.assertEquals(2, s.quoteCount);
        Decimal q2Total = null;
        for (VantageQuoteSummaryController.QuoteLine ql : s.quotes) {
            if (ql.quoteId == q2.Id) q2Total = ql.totalPrice;
        }
        System.assertEquals(21600, q2Total, '10 x 2,400 less 10%');
        System.assert(s.maxDiscountPct > 0, 'discount from the second quote is surfaced');
    }
}
