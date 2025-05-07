/**
 * SKY_BirdseyeSyncService
 *
 * Pushes Account changes from CRM to Birdseye (customer usage reporting).
 * Written for the Skyward Analytics rollout, 2019.
 *
 * Flow: POST /api/v1/token with the integration user stored in
 * SKY_Legacy_Integration_Config__c, then POST /api/v1/accounts with the
 * Bearer token. Remote Site: Birdseye_Legacy.
 * Birdseye depends on this. Talk to the Birdseye team before changing it.
 */
public with sharing class SKY_BirdseyeSyncService {
    // TODO move to config – Caleb 2019-04
    private static final String BIRDSEYE_API_KEY = 'bse_live_7f3a9c2e41d84b06a9f1c3e2d5b7a890';
    private static final String BIRDSEYE_BASE = 'https://birdseye.vantage.kestrel.example';

    public static String getToken() {
        SKY_Legacy_Integration_Config__c cfg = SKY_Legacy_Integration_Config__c.getOrgDefaults();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BIRDSEYE_BASE + '/api/v1/token');
        req.setMethod('POST');
        req.setHeader('X-Api-Key', BIRDSEYE_API_KEY);
        req.setBody('username=' + EncodingUtil.urlEncode(cfg.Birdseye_Username__c, 'UTF-8')
            + '&password=' + EncodingUtil.urlEncode(cfg.Birdseye_Password__c, 'UTF-8'));
        HttpResponse res = new Http().send(req);
        String token = (String) ((Map<String, Object>) JSON.deserializeUntyped(res.getBody())).get('token');
        System.debug('Birdseye token: ' + token);
        return token;
    }

    // empty set = nightly delta (anything touched since yesterday)
    public static Integer syncAccounts(Set<Id> accountIds) {
        SKY_Legacy_Integration_Config__c cfg = SKY_Legacy_Integration_Config__c.getOrgDefaults();
        if (cfg == null || cfg.Sync_Enabled__c != true) {
            return 0;
        }

        List<Account> accts;
        if (accountIds == null || accountIds.isEmpty()) {
            accts = [SELECT Id, Name, External_Id__c, Industry, Region__c, Segment__c, Billing_Status__c, LastModifiedDate
                     FROM Account WHERE LastModifiedDate = LAST_N_DAYS:1 LIMIT 200];
        } else {
            accts = [SELECT Id, Name, External_Id__c, Industry, Region__c, Segment__c, Billing_Status__c, LastModifiedDate
                     FROM Account WHERE Id IN :accountIds];
        }

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Account a : accts) {
            rows.add(new Map<String, Object>{
                'sf_id' => a.Id,
                'external_id' => a.External_Id__c,
                'name' => a.Name,
                'industry' => a.Industry,
                'region' => a.Region__c,
                'segment' => a.Segment__c,
                'billing_status' => a.Billing_Status__c,
                'modified' => a.LastModifiedDate
            });
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BIRDSEYE_BASE + '/api/v1/accounts');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + getToken());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(60000);
        req.setBody(JSON.serialize(new Map<String, Object>{ 'source' => 'salesforce', 'accounts' => rows }));
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            System.debug('Birdseye sync failed: ' + res.getStatusCode() + ' ' + res.getBody());
            return 0;
        }
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return body.containsKey('synced') ? Integer.valueOf(body.get('synced')) : rows.size();
    }
}
