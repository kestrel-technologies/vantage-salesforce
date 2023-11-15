@IsTest
private class VantageQuotePricingService_Test {
    private static Map<String, PricebookEntry> entries;
    private static Quote quote;

    private static void setup() {
        entries = TestDataFactory.insertProducts(new Map<String, Decimal>{
            'VDC-ENT' => 360000, 'VDC-CU-1K' => 18000, 'VES-MIG-M' => 240000, 'VIN-USER' => 600
        });
        Account a = TestDataFactory.insertAccount('Pricing Test Co', 'AMER');
        Opportunity opp = TestDataFactory.newOpportunity(a.Id, 'Pricing Test Opp', 'Discovery');
        opp.Pricebook2Id = Test.getStandardPricebookId();
        insert opp;
        quote = TestDataFactory.insertQuote(opp.Id, Test.getStandardPricebookId());
    }

    private static Map<String, QuoteLineItem> linesByCode() {
        Map<String, QuoteLineItem> out = new Map<String, QuoteLineItem>();
        for (QuoteLineItem li : [SELECT Discount, Product2.ProductCode FROM QuoteLineItem WHERE QuoteId = :quote.Id]) {
            out.put(li.Product2.ProductCode, li);
        }
        return out;
    }

    @IsTest static void appliesPlatformAndServicesAttachDiscounts() {
        setup();
        Test.startTest();
        insert new List<QuoteLineItem>{
            TestDataFactory.newQuoteLine(quote.Id, entries.get('VDC-ENT'), 1),
            TestDataFactory.newQuoteLine(quote.Id, entries.get('VDC-CU-1K'), 12),
            TestDataFactory.newQuoteLine(quote.Id, entries.get('VES-MIG-M'), 1),
            TestDataFactory.newQuoteLine(quote.Id, entries.get('VIN-USER'), 50)
        };
        Test.stopTest();

        Map<String, QuoteLineItem> lines = linesByCode();
        System.assertEquals(8, lines.get('VDC-ENT').Discount);
        System.assertEquals(8, lines.get('VDC-CU-1K').Discount);
        System.assertEquals(5, lines.get('VES-MIG-M').Discount);
        System.assertEquals(null, lines.get('VIN-USER').Discount);

        Quote q = [SELECT Platform_Discount_Applied__c, Services_Attach_Discount_Applied__c, Discount_Approval__c FROM Quote WHERE Id = :quote.Id];
        System.assert(q.Platform_Discount_Applied__c);
        System.assert(q.Services_Attach_Discount_Applied__c);
        System.assertEquals('Not Required', q.Discount_Approval__c, 'below the 20% threshold');
    }

    @IsTest static void noDiscountBelowCuThreshold() {
        setup();
        insert new List<QuoteLineItem>{
            TestDataFactory.newQuoteLine(quote.Id, entries.get('VDC-CU-1K'), 9),
            TestDataFactory.newQuoteLine(quote.Id, entries.get('VES-MIG-M'), 1)
        };
        Map<String, QuoteLineItem> lines = linesByCode();
        System.assertEquals(null, lines.get('VDC-CU-1K').Discount);
        System.assertEquals(null, lines.get('VES-MIG-M').Discount);
        Quote q = [SELECT Platform_Discount_Applied__c, Services_Attach_Discount_Applied__c FROM Quote WHERE Id = :quote.Id];
        System.assert(!q.Platform_Discount_Applied__c);
        System.assert(!q.Services_Attach_Discount_Applied__c);
    }

    @IsTest static void largeDiscountRequestsApproval() {
        setup();
        QuoteLineItem li = TestDataFactory.newQuoteLine(quote.Id, entries.get('VIN-USER'), 100);
        li.Discount = 30;
        Test.startTest();
        insert li;
        Test.stopTest();
        Quote q = [SELECT Discount_Approval__c FROM Quote WHERE Id = :quote.Id];
        System.assertEquals('Requested', q.Discount_Approval__c);
        System.assertEquals(30, [SELECT Discount FROM QuoteLineItem WHERE Id = :li.Id].Discount, 'rep discount kept');
    }

    @IsTest static void presentedQuoteOverThresholdIsBlockedWithoutApproval() {
        setup();
        QuoteLineItem li = TestDataFactory.newQuoteLine(quote.Id, entries.get('VIN-USER'), 100);
        li.Discount = 30;
        insert li;
        try {
            update new Quote(Id = quote.Id, Status = 'Presented');
