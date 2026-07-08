// Recomputes routing and SLA due dates for open cases (use after a Priority mapping change).
Boolean DRY_RUN = true;
Integer DAYS_BACK = 14;

Datetime since = Datetime.now().addDays(-DAYS_BACK);
List<Case> open = [
    SELECT Id, CaseNumber, Priority, Status, SLA_Response_Due__c, SLA_Resolution_Due__c
    FROM Case
    WHERE IsClosed = false AND CreatedDate >= :since
    ORDER BY CreatedDate
    LIMIT 500
];
System.debug(open.size() + ' open cases since ' + since);
if (!DRY_RUN && !open.isEmpty()) {
    List<Id> ids = new List<Id>();
    for (Case c : open) {
        ids.add(c.Id);
    }
    VantageCaseRoutingService.routeCases(ids);
    System.debug('Recalculated ' + ids.size() + ' cases');
}
