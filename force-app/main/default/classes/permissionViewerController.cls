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
        
        String systemPermQuery = 'SELECT profile.Name';
        
        for (String perm : allSystemPermsSet){  
            systemPermQuery += ', ' + perm;
        }
        
        systemPermQuery += ' FROM PermissionSet WHERE Id in (SELECT PermissionSetId' +
            ' FROM PermissionSetAssignment' + 
            ' WHERE AssigneeId = :userId)' +
            ' ORDER BY isOwnedByProfile DESC';
        
        for (PermissionSet permSet : database.query(systemPermQuery)){
            String label;
            
            if (permSet.IsOwnedByProfile){
                label = permSet.profile.Name;
            }else{
                label = permSet.label;
            }
            
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
                    
                    permSetSingle ps = new PermSetSingle(permLabel, hasPermission, new List<String>());
                    if (hasPermission){
                        ps.permissionSetLabels.add(label);
                    }
                    permToPermSetSingle.put(permLabel, ps);                
                    continue;
                }
                
                permSetSingle permissionCurrentValue = permToPermSetSingle.get(permLabel);
                
                if (hasPermission){
                    permissionCurrentValue.permissionSetLabels.add(label);
                    if (!permissionCurrentValue.hasPermission){
                        permissionCurrentValue.hasPermission = true;
                    }
                }
            }
        }
        
        
        List<permSetSingle> returnList = permToPermSetSingle.values();
        returnList.sort();
        return returnList;
    }
    
    public class objectPermWrapper{
        @AuraEnabled
        public String sObjectType;
        @AuraEnabled
        public permSetSingle createPerm;
        @AuraEnabled
        public permSetSingle readPerm;
        @AuraEnabled
        public permSetSingle editPerm;
        @AuraEnabled
        public permSetSingle deletePerm;
        @AuraEnabled
        public permSetSingle viewAllPerm;
        @AuraEnabled
        public permSetSingle modAllPerm;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<objectPermWrapper> getObjectPerms(Id userId){
        
        
        Map<String,objectPermWrapper> objectNameToUltPermissionMap = new Map<String,objectPermWrapper>();
        
        Set<ID> permSetIds = new Set<ID>();
        
        for (PermissionSetAssignment pm : [SELECT PermissionSetId
                                                   FROM PermissionSetAssignment
                                                   WHERE AssigneeId = :userId])
        {
            permSetIds.add(pm.PermissionSetId);
        }
        
        
        for (PermissionSet permSet : [SELECT label, profile.Name, isOwnedByProfile,
                                      (SELECT PermissionsCreate, PermissionsRead, PermissionsEdit,
                                       PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords,
                                       SobjectType
                                       FROM ObjectPerms
                                       ORDER BY SobjectType)
                                      FROM PermissionSet
                                      WHERE Id in :permSetIds
                                      
                                      ORDER BY isOwnedByProfile DESC])
        {
            String label;
            
            if (permSet.IsOwnedByProfile){
                label = permSet.profile.Name;
            }else{
                label = permSet.label;
            }
            
            System.debug(label);
            
            for (ObjectPermissions objectPerm : permSet.ObjectPerms){
                String currentSobjectType = objectPerm.SobjectType;
                Boolean currentCreatePerm = objectPerm.PermissionsCreate;
                Boolean currentReadPerm = objectPerm.PermissionsRead;
                Boolean currentEditPerm = objectPerm.PermissionsEdit;
                Boolean currentDeletePerm = objectPerm.PermissionsDelete;
                Boolean currentViewAllPerm = objectPerm.PermissionsViewAllRecords;
                Boolean currentModAllPerm = objectPerm.PermissionsModifyAllRecords;
                
                if (!objectNameToUltPermissionMap.containsKey(currentSobjectType)){
                    
                    objectPermWrapper objPermWrap = new objectPermWrapper();
                    objPermWrap.sObjectType = currentSobjectType;
                    
                    objPermWrap.createPerm = new permSetSingle(currentSobjectType + ' - Create', currentCreatePerm, new List<String>());
                    if (currentCreatePerm){
                        objPermWrap.createPerm.permissionSetLabels.add(label);
                    }
                    
                    objPermWrap.readPerm = new permSetSingle(currentSobjectType + ' - Read', currentReadPerm, new List<String>());
                    if (currentReadPerm){
                        objPermWrap.readPerm.permissionSetLabels.add(label);
                    }
                    
                    objPermWrap.editPerm = new permSetSingle(currentSobjectType + ' - Edit', currentEditPerm, new List<String>());
                    if (currentEditPerm){
                        objPermWrap.editPerm.permissionSetLabels.add(label);
                    }
                    
                    objPermWrap.deletePerm = new permSetSingle(currentSobjectType + ' - Delete', currentDeletePerm, new List<String>());
                    if (currentDeletePerm){
                        objPermWrap.deletePerm.permissionSetLabels.add(label);
                    }
                    
                    objPermWrap.viewAllPerm = new permSetSingle(currentSobjectType + ' - View All', currentViewAllPerm, new List<String>());
                    if (currentViewAllPerm){
                        objPermWrap.viewAllPerm.permissionSetLabels.add(label);
                    }
                    
                    objPermWrap.modAllPerm = new permSetSingle(currentSobjectType + ' - Modify All', currentModAllPerm, new List<String>());
                    if (currentModAllPerm){
                        objPermWrap.modAllPerm.permissionSetLabels.add(label);
                    }
                    objectNameToUltPermissionMap.put(currentSobjectType, objPermWrap);
               

                    
                }
                
                
                
                
                else{
                    
                    objectPermWrapper currentObjPermWrapper = objectNameToUltPermissionMap.get(currentSobjectType);

                    
                    if (currentCreatePerm){
                        
                        if (!currentObjPermWrapper.createPerm.permissionSetLabels.contains(label)){
                            currentObjPermWrapper.createPerm.permissionSetLabels.add(label);
                        }
                        
                        if(!currentObjPermWrapper.createPerm.hasPermission){
                            currentObjPermWrapper.createPerm.hasPermission = currentCreatePerm;
                        }
                    }
                    
                    if (currentReadPerm){
                        
                        if (!currentObjPermWrapper.readPerm.permissionSetLabels.contains(label)){
                            currentObjPermWrapper.readPerm.permissionSetLabels.add(label);
                        }
                        
                        if(!currentObjPermWrapper.readPerm.hasPermission){
                            currentObjPermWrapper.readPerm.hasPermission = currentReadPerm;
                        }
                    }
                    
                    if (currentEditPerm){
                        if (!currentObjPermWrapper.editPerm.permissionSetLabels.contains(label)){
                            currentObjPermWrapper.editPerm.permissionSetLabels.add(label);
                        }
                        
                        if (!currentObjPermWrapper.editPerm.hasPermission){
                            currentObjPermWrapper.editPerm.hasPermission = currentReadPerm;
                        }
                    }
                    
                    if (currentDeletePerm){
                        if (!currentObjPermWrapper.deletePerm.permissionSetLabels.contains(label)){
                            currentObjPermWrapper.deletePerm.permissionSetLabels.add(label);
                        }
                        
                        if (!currentObjPermWrapper.deletePerm.hasPermission){
                            currentObjPermWrapper.deletePerm.hasPermission = currentDeletePerm;
                        }
                    }
                    
                    if (currentViewAllPerm){
                        if (!currentObjPermWrapper.viewAllPerm.permissionSetLabels.contains(label)){
                            currentObjPermWrapper.viewAllPerm.permissionSetLabels.add(label);
                        }
                        
                        if (!currentObjPermWrapper.viewAllPerm.hasPermission){
                            currentObjPermWrapper.viewAllPerm.hasPermission = currentViewAllPerm;
                        }
                    }
                    
                    if (currentModAllPerm){
                        if (!currentObjPermWrapper.modAllPerm.permissionSetLabels.contains(label)){
                            currentObjPermWrapper.modAllPerm.permissionSetLabels.add(label);
                        }
                        
                        if (!currentObjPermWrapper.modAllPerm.hasPermission){
                            currentObjPermWrapper.modAllPerm.hasPermission = currentViewAllPerm;                        
                        }
                    }
                }
                
                
            }
        }
        
        return objectNameToUltPermissionMap.values();
    }
}