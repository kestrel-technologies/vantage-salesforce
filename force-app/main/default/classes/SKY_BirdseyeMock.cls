@IsTest
public class SKY_BirdseyeMock implements HttpCalloutMock {
    public List<HttpRequest> requests = new List<HttpRequest>();
    public Integer tokenStatus = 200;
    public Integer accountsStatus = 200;

    public HttpResponse respond(HttpRequest req) {
        requests.add(req);
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if (req.getEndpoint().endsWith('/api/v1/token')) {
            res.setStatusCode(tokenStatus);
            res.setBody(tokenStatus == 200 ? '{"token":"test-token","expires_in":3600}' : '{"error":"invalid_grant"}');
        } else {
            res.setStatusCode(accountsStatus);
            res.setBody(accountsStatus == 200 ? '{"synced":' + syncedCount(req) + '}' : '{"error":"unavailable"}');
        }
        return res;
    }

    private static Integer syncedCount(HttpRequest req) {
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
        return ((List<Object>) body.get('accounts')).size();
    }
}
