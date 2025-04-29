import { LightningElement, api } from 'lwc';
import Id from '@salesforce/user/Id';

export default class agentHome extends LightningElement {

    connectedCallback() {
        console.log('agentHome connectedCallback');
        console.log('current logged in user id',Id);
        const selectedEvent = new CustomEvent('Current_User_Id', {
            detail: {
                id: Id
            },
            bubbles: true,
            composed: true
        });
        window.dispatchEvent(selectedEvent);
        console.log('current logged in user id',Id);
    }
}