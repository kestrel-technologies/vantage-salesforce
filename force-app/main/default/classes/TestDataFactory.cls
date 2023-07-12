/**
 * Shared builders for Vantage unit tests. Nothing here is inserted unless the
 * method name says so.
 */
@IsTest
public class TestDataFactory {
    public static Account insertAccount(String name, String region) {
        Account a = new Account(Name = name, Region__c = region, Segment__c = 'Enterprise');
        insert a;
        return a;
    }

    public static Id activeStandardPricebookId() {
        Id pbId = Test.getStandardPricebookId();
        update new Pricebook2(Id = pbId, IsActive = true);
        return pbId;
    }

    /** Inserts one active product + standard price book entry per code; returns entries keyed by code. */
    public static Map<String, PricebookEntry> insertProducts(Map<String, Decimal> priceByCode) {
        Id pbId = activeStandardPricebookId();
        Map<String, Product2> products = new Map<String, Product2>();
        for (String code : priceByCode.keySet()) {
            products.put(code, new Product2(Name = 'Test ' + code, ProductCode = code, IsActive = true,
                External_Id__c = 'PROD-TEST-' + code));
        }
        insert products.values();
        Map<String, PricebookEntry> entries = new Map<String, PricebookEntry>();
        for (String code : priceByCode.keySet()) {
            entries.put(code, new PricebookEntry(Pricebook2Id = pbId, Product2Id = products.get(code).Id,
                UnitPrice = priceByCode.get(code), IsActive = true));
        }
        insert entries.values();
        return entries;
    }

    public static Opportunity newOpportunity(Id accountId, String name, String stage) {
        return new Opportunity(AccountId = accountId, Name = name, StageName = stage,
            CloseDate = Date.today().addDays(30), Contract_Term_Months__c = 36);
    }

    public static Quote insertQuote(Id opportunityId, Id pricebookId) {
        Quote q = new Quote(OpportunityId = opportunityId, Name = 'Test Quote', Pricebook2Id = pricebookId, Status = 'Draft');
        insert q;
        return q;
    }

    public static QuoteLineItem newQuoteLine(Id quoteId, PricebookEntry pbe, Decimal quantity) {
        return new QuoteLineItem(QuoteId = quoteId, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id,
            Quantity = quantity, UnitPrice = pbe.UnitPrice);
    }

    public static Id queueId(String developerName) {
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :developerName LIMIT 1].Id;
    }
}
