/**
 * Quote repricing rules (company handbook, quoting section).
 *  - Platform discount: 8% on VDC-* lines when the quote carries >= 10 blocks of VDC-CU-1K.
 *  - Services attach: 5% on VES-* lines when the quote has a VDC-ENT or VDC-ENTP line.
 *  - Discount approval: Requested when the quote's total discount exceeds 20%.
 * Called by the Vantage_Quoting_Pricing flow when a line's price or quantity changes.
 * Owner: Vantage Sales Systems
 */
public with sharing class VantageQuotePricingService {
    @TestVisible private static final Decimal PLATFORM_DISCOUNT_PCT = 8;
    @TestVisible private static final Decimal SERVICES_ATTACH_PCT = 5;
    @TestVisible private static final Decimal CU_BLOCKS_FOR_PLATFORM_DISCOUNT = 10;
    // same threshold as Quote.Total_Discount_Pct__c > 0.20 in Quote_Discount_Requires_Approval, in percent points
    @TestVisible private static final Decimal APPROVAL_THRESHOLD_PCT = 20;

    // recursion guard: a quote is repriced at most once per transaction
    private static Set<Id> repriced = new Set<Id>();

    @InvocableMethod(label='Reprice quote' description='Applies platform and services-attach discounts and flags quotes that need discount approval.')
    public static void reprice(List<Id> quoteIds) {
        Set<Id> todo = new Set<Id>();
        for (Id qid : quoteIds) {
            if (qid != null && !repriced.contains(qid)) todo.add(qid);
        }
        if (todo.isEmpty()) return;
        repriced.addAll(todo);

        Map<Id, List<QuoteLineItem>> linesByQuote = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem li : [SELECT Id, QuoteId, Quantity, UnitPrice, Discount, Product2.ProductCode
                                 FROM QuoteLineItem WHERE QuoteId IN :todo WITH USER_MODE]) {
            if (!linesByQuote.containsKey(li.QuoteId)) linesByQuote.put(li.QuoteId, new List<QuoteLineItem>());
            linesByQuote.get(li.QuoteId).add(li);
        }

        List<QuoteLineItem> lineUpdates = new List<QuoteLineItem>();
        Map<Id, Quote> quoteUpdates = new Map<Id, Quote>();
        Map<Id, Decimal> totalDiscountPct = new Map<Id, Decimal>();
        for (Id qid : todo) {
            List<QuoteLineItem> lines = linesByQuote.containsKey(qid) ? linesByQuote.get(qid) : new List<QuoteLineItem>();
            Decimal cuBlocks = 0;
            Boolean hasEnterprisePlatform = false;
            for (QuoteLineItem li : lines) {
                String code = productCode(li);
                if (code == 'VDC-CU-1K') cuBlocks += li.Quantity == null ? 0 : li.Quantity;
                if (code == 'VDC-ENT' || code == 'VDC-ENTP') hasEnterprisePlatform = true;
            }
            Boolean platform = cuBlocks >= CU_BLOCKS_FOR_PLATFORM_DISCOUNT;
            Boolean services = hasEnterprisePlatform;
            Decimal subtotal = 0;
            Decimal discounted = 0;
            for (QuoteLineItem li : lines) {
                String code = productCode(li);
                Decimal target = null;
                if (platform && code.startsWith('VDC-')) target = PLATFORM_DISCOUNT_PCT;
                if (services && code.startsWith('VES-')) target = SERVICES_ATTACH_PCT;
                // never lower a larger discount a rep already entered
                Decimal discount = li.Discount == null ? 0 : li.Discount;
                if (target != null && discount < target) {
                    discount = target;
                    lineUpdates.add(new QuoteLineItem(Id = li.Id, Discount = target));
                }
                Decimal lineSubtotal = (li.UnitPrice == null ? 0 : li.UnitPrice) * (li.Quantity == null ? 0 : li.Quantity);
                subtotal += lineSubtotal;
                discounted += lineSubtotal * discount / 100;
            }
            quoteUpdates.put(qid, new Quote(Id = qid, Platform_Discount_Applied__c = platform,
                Services_Attach_Discount_Applied__c = services));
            // computed from the lines: the quote's own totals are not rolled up yet while this runs
            totalDiscountPct.put(qid, subtotal > 0 ? discounted / subtotal * 100 : 0);
        }

        if (!lineUpdates.isEmpty()) {
            update Security.stripInaccessible(AccessType.UPDATABLE, lineUpdates).getRecords();
        }

        for (Quote q : [SELECT Id, Discount_Approval__c FROM Quote WHERE Id IN :todo WITH USER_MODE]) {
            Boolean notRequired = q.Discount_Approval__c == null || q.Discount_Approval__c == 'Not Required';
            if (totalDiscountPct.get(q.Id) > APPROVAL_THRESHOLD_PCT && notRequired) {
                quoteUpdates.get(q.Id).Discount_Approval__c = 'Requested';
            }
        }
        update Security.stripInaccessible(AccessType.UPDATABLE, quoteUpdates.values()).getRecords();
    }

    private static String productCode(QuoteLineItem li) {
        return li.Product2 == null || li.Product2.ProductCode == null ? '' : li.Product2.ProductCode;
    }
}
