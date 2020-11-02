public with sharing class permissionViewerController{
    
    public static Set<String> sillyPerms = new Set<String>{
        'name',
            'label',
            'hasactivationrequired',
            'type',
            'description',
            'namespaceprefix',
            'isownedbyprofile',
'iscustom'
     };
                
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers(String searchKey) {
        String key = '%' + searchKey + '%';
        
        List<User> allActiveUsers = [SELECT Id, Name, Email, FORMAT(CreatedDate), Profile.Name, 
                                     userRole.Name, Manager.Name
                                     FROM User
                                     WHERE isActive = true
                                     AND Name LIKE :key
                                     AND UserType = 'Standard'
                                     ORDER BY lastName ASC];
        
        return allActiveUsers;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<permSetSingle> getSystemPerms(Id userId){
        
        Map<String,permSetSingle> permToPermSetSingle = new Map<String,permSetSingle>();
        Map<String, Schema.SObjectField> allSystemPerms = Schema.SObjectType.permissionSet.fields.getMap();
        List<String> allSystemPermsSet = new List<String>(allSystemPerms.keySet());

        String systemPermQuery = 'SELECT';
        
        Boolean firstLoop = true;
        for (String perm : allSystemPermsSet){
            //String permLabel = allSystemPerms.get(perm).getDescribe().getLabel();

            if (firstLoop){
                firstLoop = false;
                systemPermQuery += ' ' + perm;
                continue;
            }
            systemPermQuery += ', ' + perm;
        }
        
        systemPermQuery += ' FROM PermissionSet WHERE Id in (SELECT PermissionSetId' +
                                                                ' FROM PermissionSetAssignment' + 
                                                                ' WHERE AssigneeId = :userId)';

        for (PermissionSet permSet : database.query(systemPermQuery)){
            for (String perm : allSystemPermsSet){
                
                if (sillyPerms.contains(perm)){
                    continue;
                }
                
                Boolean hasPermission;
                try{
                    Object hasPermissionObject = permSet.get(perm);
                    if (hasPermissionObject == null){
                        continue;
                    }
                    hasPermission = Boolean.valueOf(hasPermissionObject);
                }catch (System.TypeException e){
                    continue;
                }
                
                String permLabel = allSystemPerms.get(perm).getDescribe().getLabel();

                if (!permToPermSetSingle.containsKey(permLabel)){
                    permToPermSetSingle.put(permLabel, new PermSetSingle(permLabel, hasPermission));
                    continue;
                }
                
                Boolean permissionCurrentValue = permToPermSetSingle.get(permLabel).hasPermission;
                
                if (!permissionCurrentValue && hasPermission){
                    permToPermSetSingle.get(permLabel).hasPermission = hasPermission;
                }
                
                
                
            }
        }

        
        List<permSetSingle> returnList = permToPermSetSingle.values();
        returnList.sort();
        return returnList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ObjectPermissions> getObjectPerms(Id userId){
        
        
        Map<String,ObjectPermissions> objectNameToUltPermissionMap = new Map<String,ObjectPermissions>();
        
        for (ObjectPermissions objectPerm : [SELECT PermissionsCreate, PermissionsRead, PermissionsEdit,
                                             PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords,
                                             SobjectType
                                             FROM ObjectPermissions
                                             WHERE ParentId in (SELECT PermissionSetId
                                                                FROM PermissionSetAssignment
                                                                WHERE AssigneeId = :userId)
                                             ORDER BY SobjectType])
        {
            String currentSobjectType = objectPerm.SobjectType;
            
            Boolean currentCreatePerm = objectPerm.PermissionsCreate;
            Boolean currentReadPerm = objectPerm.PermissionsRead;
            Boolean currentEditPerm = objectPerm.PermissionsEdit;
            Boolean currentDeletePerm = objectPerm.PermissionsDelete;
            Boolean currentViewAllPerm = objectPerm.PermissionsViewAllRecords;
            Boolean currentModAllPerm = objectPerm.PermissionsModifyAllRecords;
            
            if (!objectNameToUltPermissionMap.containsKey(currentSobjectType)){
                objectNameToUltPermissionMap.put(currentSobjectType, objectPerm); 
                continue;
            }
            
            Boolean createPerm = objectNameToUltPermissionMap.get(currentSobjectType).PermissionsCreate;
            Boolean readPerm = objectNameToUltPermissionMap.get(currentSobjectType).PermissionsRead;
            Boolean editPerm = objectNameToUltPermissionMap.get(currentSobjectType).PermissionsEdit;
            Boolean deletePerm = objectNameToUltPermissionMap.get(currentSobjectType).PermissionsDelete;
            Boolean viewAllPerm = objectNameToUltPermissionMap.get(currentSobjectType).PermissionsViewAllRecords;
            Boolean modAllPerm = objectNameToUltPermissionMap.get(currentSobjectType).PermissionsModifyAllRecords;
            
            if (!createPerm && currentCreatePerm){
                objectNameToUltPermissionMap.get(currentSobjectType).PermissionsCreate = true;
            }
            
            if (!readPerm && currentReadPerm){
                objectNameToUltPermissionMap.get(currentSobjectType).PermissionsRead = true;
            }
            
            if (!editPerm && currentEditPerm){
                objectNameToUltPermissionMap.get(currentSobjectType).PermissionsEdit = true;
            }
            
            if (!deletePerm && currentDeletePerm){
                objectNameToUltPermissionMap.get(currentSobjectType).PermissionsDelete = true;
            }
            
            if (!viewAllPerm && currentViewAllPerm){
                objectNameToUltPermissionMap.get(currentSobjectType).PermissionsViewAllRecords = true;
            }
            
            if (!modAllPerm && currentModAllPerm){
                objectNameToUltPermissionMap.get(currentSobjectType).PermissionsModifyAllRecords = true;
            }
            
        }
        return objectNameToUltPermissionMap.values();
    }
}