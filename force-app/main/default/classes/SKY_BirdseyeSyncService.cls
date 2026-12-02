/**
 * SKY_BirdseyeSyncService
 *
 * Pushes Account changes from CRM to Birdseye (customer usage reporting).
 * Written for the Skyward Analytics rollout, 2019.
 *
 * Flow: POST /api/v1/token with the integration user stored in
 * SKY_Legacy_Integration_Config__c, then POST /api/v1/accounts with the
 * Bearer token. Endpoint and API key come from the Birdseye_API Named
 * Credential: its External Credential (Birdseye_Auth) adds the X-Api-Key
 * header from the Birdseye_Service principal, so no key lives in this class.
 * Running users need the Birdseye Named Principal Access permission set.
 * Birdseye depends on this. Talk to the Birdseye team before changing it.
 */
public with sharing class SKY_BirdseyeSyncService {
    @TestVisible private static final String BIRDSEYE_API = 'callout:Birdseye_API';

    public class BirdseyeException extends Exception {}

    public static String getToken() {
        SKY_Legacy_Integration_Config__c cfg = SKY_Legacy_Integration_Config__c.getOrgDefaults();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BIRDSEYE_API + '/api/v1/token');
        req.setMethod('POST');
        req.setBody('username=' + EncodingUtil.urlEncode(cfg.Birdseye_Username__c, 'UTF-8')
            + '&password=' + EncodingUtil.urlEncode(cfg.Birdseye_Password__c, 'UTF-8'));
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new BirdseyeException('Birdseye token request failed: HTTP ' + res.getStatusCode());
        }
        return (String) ((Map<String, Object>) JSON.deserializeUntyped(res.getBody())).get('token');
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
        req.setEndpoint(BIRDSEYE_API + '/api/v1/accounts');
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
