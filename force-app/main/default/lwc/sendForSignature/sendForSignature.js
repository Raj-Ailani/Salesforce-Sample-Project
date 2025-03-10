import { LightningElement,wire,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getAllDocuments from '@salesforce/apex/DocuSignController.getAllDocuments'
import createEnvelope from '@salesforce/apex/DocuSignController.createEnvelope'

export default class SendForSignature extends NavigationMixin(LightningElement) {
    @api recordId;

    recipient1 = '';
    recipient2 = '';
    selectedDocument = '';
    customerTemplate = true;
    loading = false;
    @wire(getAllDocuments,{agreementId: "$recordId"})
    documents;

    get options() {
       
         if(this.documents.data){
 
             return this.documents.data.map(doc => {
                 return { label: doc.Title, value: doc.Id }
             })
         }
      
     }

    get actionLabel() {
        return this.customerTemplate ? 'Finalize in DocuSign' : 'Send';
    }

    handleInputChange(event) {
        this[event.target.dataset.field] = event.target.value;
    }

    handleDocumentChange(event) {
        this.selectedDocument = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async handleSend() {
        if (this.recipient1 && this.recipient2 && this.selectedDocument) {
            if(this.customerTemplate){
                this.loading = true;
                // Create a envelope and direct to Docusign app, creation on evelope is an apex method
                await createEnvelope({
                    recipient1: this.recipient1,
                    recipient2: this.recipient2,
                    documentId: this.selectedDocument
                }).then(
                    (result) => {
                        // Display envelope Id
                        console.log('Envelope Id: ' + result);
                        this.loading=false;
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: 'https://apps-d.docusign.com/send/prepare/'+ result +'/add-fields' // Replace with the actual URL
                            }
                        });
                    }
                )
            }
            console.log('Sending document:', this.selectedDocument, 'to', this.recipient1, 'and', this.recipient2);
            this.dispatchEvent(new CustomEvent('success'));
        } else {
            alert('Please fill in all fields');
        }
    }
}