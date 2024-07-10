/**
 * SLA due dates by priority, measured from case creation.
 * Called by the Case_Routing flow on create, on escalation and on priority change.
 * Owner: Vantage Sales Systems
 */
public with sharing class VantageCaseSlaService {
    /** priority => [response hours, resolution hours] */
    @TestVisible private static final Map<String, List<Integer>> SLA_HOURS = new Map<String, List<Integer>>{
        'P1' => new List<Integer>{ 1, 8 },
        'P2' => new List<Integer>{ 4, 24 },
        'P3' => new List<Integer>{ 8, 72 },
        'P4' => new List<Integer>{ 24, 120 }
    };
    @TestVisible private static final String DEFAULT_PRIORITY = 'P3';

    @InvocableMethod(label='Set case SLA due dates' description='Returns response and resolution due dates for a case priority.')
    public static List<SlaResult> setDueDates(List<SlaRequest> requests) {
        List<SlaResult> results = new List<SlaResult>();
        for (SlaRequest r : requests) {
            List<Integer> hours = SLA_HOURS.containsKey(r.priority) ? SLA_HOURS.get(r.priority) : SLA_HOURS.get(DEFAULT_PRIORITY);
            Datetime start = r.createdDate != null ? r.createdDate : Datetime.now();
            SlaResult res = new SlaResult();
            res.responseDue = start.addHours(hours[0]);
            res.resolutionDue = start.addHours(hours[1]);
            results.add(res);
        }
        return results;
    }

    public class SlaRequest {
        @InvocableVariable(label='Priority' description='P1-P4; anything else is treated as P3') public String priority;
        @InvocableVariable(label='Created Date') public Datetime createdDate;
    }

    public class SlaResult {
        @InvocableVariable(label='Response Due') public Datetime responseDue;
        @InvocableVariable(label='Resolution Due') public Datetime resolutionDue;
    }
}
