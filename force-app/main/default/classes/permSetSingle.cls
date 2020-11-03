public class permSetSingle implements Comparable{
    @AuraEnabled
    public String permission;
    
    @AuraEnabled
    public Boolean hasPermission;
    
    @AuraEnabled
    public List<String> permissionSetLabels;
        
    public permSetSingle(String permission, Boolean hasPermission, List<String> permissionSetLabels){
        this.permission = permission;
        this.hasPermission = hasPermission;
        this.permissionSetLabels = permissionSetLabels;
    }
    
    public Integer compareTo(Object compareTo){
        permSetSingle p = (permSetSingle) compareTo;
        if (permission == p.permission) return 0;
        if (permission > p.permission) return 1;
        return -1;        
    }
}