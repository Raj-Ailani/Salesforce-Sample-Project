public with sharing class DocuSignController {
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion>  getAllDocuments(String agreementId){
    List<ContentVersion> documents = [SELECT Id, Title, VersionData, FileExtension FROM ContentVersion WHERE FirstPublishLocationId = :agreementId];
    return documents;
  }

  @AuraEnabled(cacheable=true)
  public static String  createEnvelope(String recipient1,String recipient2 ,String documentId){
    HttpRequest req = new HttpRequest();
    ContentVersion file = [SELECT Id, Title, VersionData, FileExtension FROM ContentVersion WHERE Id = :documentId LIMIT 1];

    String base64FileBody = EncodingUtil.base64Encode(file.VersionData);

    Map<String, Object> envelope = new Map<String, Object>();
    envelope.put('emailSubject', 'Please sign the document');
    envelope.put('status', 'created'); // Sends envelope immediately
    List<Map<String, Object>> documents = new List<Map<String, Object>>();

    //Add Document
    Map<String, Object> document = new Map<String, Object>();
    document.put('documentBase64', base64FileBody);
    document.put('documentId', '1');
    document.put('name', 'Sample Agreement');
    documents.add(document);
    envelope.put('documents', documents);
    //Create recipients :- 
    Map<String, Object> recipients = new Map<String, Object>();
    List<Map<String, Object>> signers = new List<Map<String, Object>>();
    Map<String, Object> signer1 = new Map<String, Object>();
        signer1.put('name', 'Raj Name 1');
        signer1.put('recipientId', '1');
        signer1.put('routingOrder', 1);
        signer1.put('email', recipient1);
        signers.add(signer1);
    Map<String, Object> signer2 = new Map<String, Object>();
        signer2.put('name', 'Raj Name 2');
        signer2.put('recipientId', '2');
        signer2.put('routingOrder', 2);
        signer2.put('email', recipient2);
        signers.add(signer2);
      recipients.put('signers', signers);
      envelope.put('recipients', recipients);


      String requestBody =  JSON.serialize(envelope);
      req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/31776368/envelopes');
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json');
      req.setBody(requestBody);

      Http http = new Http();
      HttpResponse res = http.send(req);
      if (res.getStatusCode() == 201) {
        System.debug('Envelope Created: ' + res.getBody());
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String envelopeId = (String) responseMap.get('envelopeId');
        return envelopeId;
    } else {
      return 'Error Creating Envelope: ' + res.getBody();
    
    }       
  
  }
}