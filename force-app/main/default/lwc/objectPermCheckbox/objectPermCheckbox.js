import { LightningElement, api } from 'lwc';



export default class ObjectPermCheckbox extends LightningElement{ 

        booleaner = false;
        @api obj;

        theMethod(){
                this.booleaner = !this.booleaner
        }

}