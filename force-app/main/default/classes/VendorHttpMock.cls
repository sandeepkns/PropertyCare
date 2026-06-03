@isTest
public class VendorHttpMock implements HttpCalloutMock {
    private Integer statusCode;
    private String body;
    public VendorHttpMock(Integer statusCode, String body) {
        this.statusCode = statusCode; this.body = body;
    }
    public HTTPResponse respond(HTTPRequest req) {
        // Assert the callout used the Named Credential, not a raw URL
        System.assert(req.getEndpoint().startsWith('callout:PropertyCare_Vendor'),
            'Callout must go through the Named Credential');
        System.assertEquals('POST', req.getMethod());
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(body == null ? '{}' : body);
        res.setHeader('Content-Type','application/json');
        return res;
    }
}