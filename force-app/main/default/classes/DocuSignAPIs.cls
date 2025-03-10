public class DocuSignAPIs {
    public static void testAPI(){
          HttpRequest req = new HttpRequest();
          req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/31776368/envelopes');
		  req.setMethod('POST');
          req.setHeader('Content-Type', 'application/json');
            req.setBody('{}');
        Http http = new Http();
		HttpResponse res = http.send(req);
    	System.debug(res.getBody()); 

    }
     public static void createEnvelope(String contentVersionId,String changeSummaryDoc){
        HttpRequest req = new HttpRequest();
        ContentVersion file = [SELECT Id, Title, VersionData, FileExtension FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
        ContentVersion changeSummary = [SELECT Id, Title, VersionData, FileExtension FROM ContentVersion WHERE Id = :changeSummaryDoc LIMIT 1];
 		 
         String base64FileBody = EncodingUtil.base64Encode(file.VersionData);
         String base64FileBodySummary = EncodingUtil.base64Encode(changeSummary.VersionData);
         
         //Basic Envelope 
         Map<String, Object> envelope = new Map<String, Object>();
         envelope.put('emailSubject', 'Please sign the document');
         envelope.put('status', 'created'); // Sends envelope immediately
         
         // Composite Template 
         List<Map<String, Object>> compositeTemplates = new List<Map<String, Object>>();
		
         //First Document in first composite template
         Map<String, Object> template1 = new Map<String, Object>();
         template1.put('document', new Map<String, Object>{
    		'documentBase64' => base64FileBody,
    		'documentId' => '1',
   			 'name' => 'Sample Agreement',
   			 'fileExtension' => 'docx'
			});
        // Add server template
		template1.put('serverTemplates', new List<Map<String, Object>>{
   		 new Map<String, Object>{
        'sequence' => '1',
        'templateId' => '4c5cce3e-fd9f-4414-ad0d-3cd3304a4df7'
   			 }
		});
         // Add inlineTemplate with recipients
template1.put('inlineTemplates', new List<Map<String, Object>>{
    new Map<String, Object>{
        'sequence' => '2',
        'recipients' => new Map<String, Object>{
            'signers' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'email' => 'pahalchhapiya@gmail.com',
                    'name' => 'Vishal',
                    'roleName' => 'Customer',
                    'routingOrder' => '1',
                    'recipientId' => '1'
                },
                new Map<String, Object>{
                    'email' => 'ailaniraj1@gmail.com',
                    'name' => 'Raj Ailani',
                    'roleName' => 'DLR',
                    'routingOrder' => '2',
                    'recipientId' => '2'
                }
            }
        }
    }
});
         
compositeTemplates.add(template1);
// Second Document (Change Summary)
Map<String, Object> template2 = new Map<String, Object>();
template2.put('document', new Map<String, Object>{
    'documentBase64' => base64FileBodySummary,
    'documentId' => '2',
    'name' => 'Change Summary',
    'fileExtension' => 'docx'
});

// Add inlineTemplate with recipients for second document
template2.put('inlineTemplates', new List<Map<String, Object>>{
    new Map<String, Object>{
        'sequence' => '2',
        'recipients' => new Map<String, Object>{
            'signers' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'email' => 'pahalchhapiya@gmail.com',
                    'name' => 'Vishal Parikh',
                    'roleName' => 'Customer',
                    'routingOrder' => '1',
                    'recipientId' => '1'
                },
                new Map<String, Object>{
                    'email' => 'ailaniraj1@gmail.com',
                    'name' => 'Raj Ailani',
                    'roleName' => 'DLR',
                    'routingOrder' => '2',
                    'recipientId' => '2'
                }
            }
        }
    }
});
    
compositeTemplates.add(template2);    
envelope.put('compositeTemplates', compositeTemplates);
         
String requestBody = JSON.serialize(envelope);
System.debug('Final Envelope JSON: ' + requestBody);        
         
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
    updateDocumentVisibility(envelopeId);
    sendEnvelope(envelopeId);
} else {
    System.debug('Error Creating Envelope: ' + res.getBody());
}      
}
    
    public static void updateDocumentVisibility(String envelopeId) {
        HttpRequest req = new HttpRequest();
         Map<String, Object> documentVisibility = new Map<String, Object>();
        documentVisibility.put('documentVisibility', new List<Map<String, Object>>{
            new Map<String, Object>{
                'documentId' => '2',
                'recipientId' => '1',
                'visible' => 'false'
            }
        });
           String requestBody = JSON.serialize(documentVisibility);
        System.debug('Document Visibility JSON: ' + requestBody);
          String endpoint = 'callout:DocuSign/restapi/v2.1/accounts/31776368/envelopes/' + envelopeId + '/recipients/1/document_visibility';
        req.setEndpoint(endpoint);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestBody);
         Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Document Visibility Updated');
        } else {
            System.debug('Error Updating Document Visibility: ' + res.getBody());
        }
    }
    public static void  sendEnvelope(String envelopeId){
         HttpRequest req = new HttpRequest();
    
    // Status update JSON body
    Map<String, Object> statusUpdate = new Map<String, Object>();
    statusUpdate.put('status', 'sent');

    // Convert to JSON
    String requestBody = JSON.serialize(statusUpdate);
    System.debug('Envelope Status Update JSON: ' + requestBody);

    // Set endpoint with envelopeId
    String endpoint = 'callout:DocuSign/restapi/v2.1/accounts/9cf40451-f98f-4c93-9b05-27b88c44c7f1/envelopes/' + envelopeId;
    req.setEndpoint(endpoint);
    req.setMethod('PUT');
    req.setHeader('Content-Type', 'application/json');
    req.setBody(requestBody);

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
        System.debug('Envelope Status Updated to Sent: ' + res.getBody());
    } else {
        System.debug('Error Updating Envelope Status: ' + res.getBody());
    }
    }
    
    public static void sendCustomValue(){
          HttpRequest req = new HttpRequest();
          req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/31776368/envelopes/custom_fields');
		  req.setMethod('POST');
          req.setHeader('Content-Type', 'application/json');
           
       Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('templateId', '62e4af63-1c32-4c35-a0f8-cdf6a70a38af');

    String jsonBody = JSON.serialize(requestBody);
    System.debug('Generated JSON: ' + jsonBody);
    
    // Convert to JSON
         req.setBody(jsonBody);
        Http http = new Http();
		HttpResponse res = http.send(req);
    	System.debug(res.getBody()); 

    }
    
        public static void createEnvelopeWithTabs(Id agreementId){
          Apttus__APTS_Agreement__c agreement = [SELECT Id,Name,shouldSend__c from Apttus__APTS_Agreement__c where Id =:agreementId LIMIT 1];

          HttpRequest req = new HttpRequest();
          req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/31776368/envelopes');
		  req.setMethod('POST');
          req.setHeader('Content-Type', 'application/json');
           
       Map<String, Object> requestBody = new Map<String, Object>();
    requestBody.put('templateId', '62e4af63-1c32-4c35-a0f8-cdf6a70a38af');

    String jsonBody = JSON.serialize(requestBody);
    System.debug('Generated JSON: ' + jsonBody);
    
    // Convert to JSON
         req.setBody(jsonBody);
        Http http = new Http();
		HttpResponse res = http.send(req);
    	System.debug(res.getBody()); 

    }
    
}