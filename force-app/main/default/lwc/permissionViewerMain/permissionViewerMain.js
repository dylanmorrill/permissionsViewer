import { LightningElement, track, wire } from 'lwc';
import getUsers from '@salesforce/apex/permissionViewerController.getUsers';
import getObjectPerms from '@salesforce/apex/permissionViewerController.getObjectPerms';
import getSystemPerms from '@salesforce/apex/permissionViewerController.getSystemPerms';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 300;


export default class PermissionViewerMain extends LightningElement {
    userId = '';
    userSelected = false;
    
    searchKey = '';
    @wire(getUsers, { searchKey: '$searchKey' })
    users;

    @wire(getObjectPerms, { userId: '$userId' })
    objectPerms;

    @wire(getSystemPerms, { userId: '$userId' })
    systemPerms;

    handleUserSelected(event){
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        this.objectPerms = '';
        this.systemPerms = '';
        this.userSelected = true;
        window.clearTimeout(this.delayTimeout);
        const userId = event.target.value;
        const searchKey = event.target.label;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
            this.userId = userId;
        }, DELAY);
    }

    handleKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, DELAY);
    }
}