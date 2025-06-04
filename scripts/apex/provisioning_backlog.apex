// Closed Won opportunities that never got a Provisioning Request (e.g. won before the flow existed,
// or the flow failed). Dry run prints the list; set DRY_RUN = false to provision them.
Boolean DRY_RUN = true;
Integer DAYS_BACK = 90;

Date since = Date.today().addDays(-DAYS_BACK);
List<Opportunity> backlog = [
    SELECT Id, Name, Account.Name, CloseDate, Amount
    FROM Opportunity
    WHERE StageName = 'Closed Won' AND CloseDate >= :since AND Provisioning_Request__c = null
    ORDER BY CloseDate
    LIMIT 200
];
System.debug(backlog.size() + ' Closed Won opportunities without a provisioning request since ' + since);
List<Id> ids = new List<Id>();
for (Opportunity o : backlog) {
    System.debug(o.CloseDate + '  ' + o.Name + '  (' + o.Account.Name + ')');
    ids.add(o.Id);
}
if (!DRY_RUN && !ids.isEmpty()) {
    VantageProvisioningService.onClosedWon(ids);
    System.debug('Provisioned ' + [SELECT COUNT() FROM Provisioning_Request__c WHERE Opportunity__c IN :ids] + ' requests');
}
