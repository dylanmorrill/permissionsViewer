public class permSetSingle implements Comparable{
    @AuraEnabled
    public String permission;
    @AuraEnabled
    public Boolean hasPermission;
    public permSetSingle(String permission, Boolean hasPermission){
        this.permission = permission;
        this.hasPermission = hasPermission;
    }
    
    public Integer compareTo(Object compareTo){
        permSetSingle p = (permSetSingle) compareTo;
        if (permission == p.permission) return 0;
        if (permission > p.permission) return 1;
        return -1;        
    }
}