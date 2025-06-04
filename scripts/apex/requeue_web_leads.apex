// Open Web / Pulsar Nurture leads that ended up owned by a user instead of an SDR queue
// (typically leads created while the integration user's routing was failing).
Boolean DRY_RUN = true;

List<Lead> stuck = [
    SELECT Id, Name, Company, LeadSource, Region__c, Segment__c, OwnerId, Owner.Name
    FROM Lead
    WHERE IsConverted = false AND Status IN ('New', 'Working')
      AND LeadSource IN ('Web', 'Pulsar Nurture') AND Owner.Type = 'User'
    ORDER BY CreatedDate
    LIMIT 200
];
List<VantageLeadRoutingService.RoutingRequest> reqs = new List<VantageLeadRoutingService.RoutingRequest>();
for (Lead l : stuck) {
    VantageLeadRoutingService.RoutingRequest r = new VantageLeadRoutingService.RoutingRequest();
    r.leadId = l.Id;
    reqs.add(r);
}
List<VantageLeadRoutingService.RoutingResult> results = VantageLeadRoutingService.resolveQueue(reqs);
List<Lead> updates = new List<Lead>();
for (Integer i = 0; i < stuck.size(); i++) {
    System.debug(stuck[i].Company + ' (' + stuck[i].Region__c + '/' + stuck[i].Segment__c + '): '
        + stuck[i].Owner.Name + ' -> ' + results[i].queueName);
    if (results[i].queueId != null) {
        updates.add(new Lead(Id = stuck[i].Id, OwnerId = results[i].queueId));
    }
}
System.debug(updates.size() + ' of ' + stuck.size() + ' leads would move to a queue');
if (!DRY_RUN) {
    update updates;
}
