@IsTest
public class SKY_BirdseyeMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if (req.getEndpoint().endsWith('/api/v1/token')) {
            res.setBody('{"token":"test-token","expires_in":3600}');
        } else {
            res.setBody('{"synced":0}');
        }
        return res;
    }
}
