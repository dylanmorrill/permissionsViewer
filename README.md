# Permission Viewer
 
**NOTE: this is very much in development (as of 09/30/21). This a long project I am working on that I'd estimate is 5% done.**
 
I am working on trying to create a lightning app that shows an aggregated view of the following permissions for any user selected:
- Object permissions (create, read, write, delete, view all, mod all)
- Field permissions (read, write)
- System Permissions
- Record Access
  - How many records of object x can the user view; view and edit; or view, edit and delete
 
I have found that determining if a user has a specific permission, and if so, which permission sets or profiles are granting that permission, is difficult. To do this, I typically run queries on the relevant objects (ObjectPermissions, FieldPermissions, etc). This app will be my attempt to show a user all the permissions that one user has been granted. The page will be interactive, allowing users to determine which permissions sets or profiles are granting that permission. It will also allow users to update / create new permission sets and profiles if need be.
 
## Current app
 
The current app allows you to select a user, and then aggregates all the user's object and system permissions below. Clicking on a box that is true (the user has that permission) shows a tooltip listing all the profiles and permission sets that are granting the user that permission.
 
![App view](https://i.imgur.com/up0g86Z.png)
