/**
 * Resolves the SDR queue for a lead from its region and segment.
 * Called by the Lead_Routing flow so the flow carries no hard-coded queue Ids.
 * Owner: Vantage Sales Systems
 */
public with sharing class VantageLeadRoutingService {
    @InvocableMethod(label='Resolve SDR queue')
    public static List<Id> resolveQueue(List<RoutingRequest> reqs) {
        Set<String> names = new Set<String>();
        for (RoutingRequest r : reqs) names.add(queueName(r.region, r.segment));
        Map<String, Id> byName = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :names WITH USER_MODE]) {
            byName.put(g.DeveloperName, g.Id);
        }
        List<Id> out = new List<Id>();
        for (RoutingRequest r : reqs) out.add(byName.get(queueName(r.region, r.segment)));
        return out;
    }
    @TestVisible private static String queueName(String region, String segment) {
        if (region == 'AMER') return segment == 'Enterprise' ? 'SDR_AMER_Enterprise' : 'SDR_AMER_MidMarket';
        return region == 'EMEA' ? 'SDR_EMEA' : 'SDR_APAC';
    }
    public class RoutingRequest { @InvocableVariable public String region; @InvocableVariable public String segment; }
}
