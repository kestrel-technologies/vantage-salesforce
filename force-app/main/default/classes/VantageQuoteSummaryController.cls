/**
 * Opportunity + quote amounts for the vantageQuoteSummary card on the Opportunity page.
 * Owner: Vantage Sales Systems
 */
public with sharing class VantageQuoteSummaryController {
    @AuraEnabled(cacheable=true)
    public static QuoteSummary getSummary(Id opportunityId) {
        Opportunity opp = [SELECT Id, Name, Amount, StageName, Contract_Term_Months__c,
                                  (SELECT Id, Name, TotalPrice, Total_Discount_Pct__c, Status FROM Quotes)
                           FROM Opportunity WHERE Id = :opportunityId];
        return new QuoteSummary(opp);
    }

    public class QuoteSummary {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String stage;
        @AuraEnabled public Decimal termMonths;
        @AuraEnabled public Integer quoteCount;
        @AuraEnabled public Decimal maxDiscountPct;
        @AuraEnabled public List<QuoteLine> quotes;

        public QuoteSummary(Opportunity opp) {
            opportunityId = opp.Id;
            opportunityName = opp.Name;
            amount = opp.Amount;
            stage = opp.StageName;
            termMonths = opp.Contract_Term_Months__c;
            quotes = new List<QuoteLine>();
            maxDiscountPct = 0;
            for (Quote q : opp.Quotes) {
                quotes.add(new QuoteLine(q));
                if (q.Total_Discount_Pct__c != null && q.Total_Discount_Pct__c > maxDiscountPct) {
                    maxDiscountPct = q.Total_Discount_Pct__c;
                }
            }
            quoteCount = quotes.size();
        }
    }

    public class QuoteLine {
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public Decimal discountPct;
        @AuraEnabled public String status;

        public QuoteLine(Quote q) {
            quoteId = q.Id;
            name = q.Name;
            totalPrice = q.TotalPrice;
            discountPct = q.Total_Discount_Pct__c;
            status = q.Status;
        }
    }
}
