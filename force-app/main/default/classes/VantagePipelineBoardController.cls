/**
 * Open pipeline grouped by stage for the vantagePipelineBoard tab.
 * Owner: Vantage Sales Systems
 */
public with sharing class VantagePipelineBoardController {
    @TestVisible private static final Integer MAX_CARDS = 500;

    @AuraEnabled(cacheable=true)
    public static List<StageColumn> getBoard() {
        List<StageColumn> columns = new List<StageColumn>();
        Map<String, StageColumn> byStage = new Map<String, StageColumn>();
        for (OpportunityStage s : [SELECT ApiName, MasterLabel FROM OpportunityStage
                                   WHERE IsActive = true AND IsClosed = false
                                   WITH USER_MODE ORDER BY SortOrder]) {
            StageColumn col = new StageColumn(s.ApiName, s.MasterLabel);
            columns.add(col);
            byStage.put(s.ApiName, col);
        }

        for (Opportunity o : [SELECT Id, Name, Amount, CloseDate, StageName, Account.Name, Owner.Name
                              FROM Opportunity WHERE IsClosed = false
                              WITH USER_MODE
                              ORDER BY Amount DESC NULLS LAST LIMIT :MAX_CARDS]) {
            StageColumn col = byStage.get(o.StageName);
            if (col != null) col.add(new Card(o));
        }
        return columns;
    }

    public class StageColumn {
        @AuraEnabled public String stage;
        @AuraEnabled public String label;
        @AuraEnabled public Integer count = 0;
        @AuraEnabled public Decimal total = 0;
        @AuraEnabled public List<Card> cards = new List<Card>();

        public StageColumn(String stage, String label) {
            this.stage = stage;
            this.label = label;
        }

        public void add(Card c) {
            cards.add(c);
            count++;
            total += c.amount == null ? 0 : c.amount;
        }
    }

    public class Card {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String accountName;
        @AuraEnabled public String ownerName;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date closeDate;

        public Card(Opportunity o) {
            id = o.Id;
            name = o.Name;
            accountName = o.Account == null ? null : o.Account.Name;
            ownerName = o.Owner == null ? null : o.Owner.Name;
            amount = o.Amount;
            closeDate = o.CloseDate;
        }
    }
}
