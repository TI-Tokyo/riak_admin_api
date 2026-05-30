# Security operations (users, groups, permissions)

## SecurityListUsers
**Permissions required**: security.

### Parameters
None.

List users.

## Response
Example:
```
{
   "result" : [
      {
         "auth_method" : "password",
         "created" : "2026-05-24T19:49:00.638+01:00",
         "expires" : "never",
         "groups" : [],
         "modified" : "2026-05-24T19:49:00.638+01:00",
         "name" : "admin",
         "permissions" : [
            "cluster_observer",
            "cluster_admin",
            "security"
         ],
         "tags" : {}
      },
      {
         "auth_method" : "password",
         "created" : "2026-05-28T23:30:38.438+01:00",
         "expires" : "never",
         "groups" : [],
         "modified" : "2026-05-28T23:30:38.438+01:00",
         "name" : "Cuyler",
         "permissions" : [],
         "tags" : {
            "fafa" : 1
         }
      },
   ]
}
```


## SecurityCreateUser
**Permissions required**: security.
### Parameters
```
{
   "name" : NAME,
   "auth_details" :
      {
         "method": "password",
         "password": PASSWORD
      },
   "expires" : EXPIRES,
   "permissions" : PERMISSIONS,
   "tags" : TAGS
}
```

Create a user with name NAME and given auth method and credentials
(only `"password"` method is currently supported), permissions and
tags.

EXPIRES is a string in rfc3339 format or, as an integer, seconds since
Unix epoch representing a time in future; default is "never".  TAGS is
a dictionary of string or numerical values. EXPIRES, PERMISSIONS and
TAGS are optional.

Example:
```
{
   "action" : "SecurityCreateUser",
   "params" :
      {
         "name" : "Cuyler",
         "auth_details" :
            {
               "method" : "password",
               "password" : "kjkjkj"
            },
         "permissions" : "all",
         "tags" : { "fafa" : 1 }
      }
}
```


## SecuritySetUserExpiry
**Permissions required**: security.

### Parameters
```
{
   "name" : NAME,
   "expires" : EXPIRES
}
```

Set expiry to EXPIRY (see `SecurityCreateUser` parameters for
acceptable values) for USER.


## SecurityDeleteUser
**Permissions required**: security.

### Parameters
```
{
   "name" : NAME
}
```

Delete user USER.


## SecurityListGroups
**Permissions required**: security.

### Parameters
None.

List groups. Example:
```
{
   "result" : [
      {
         "created" : "2026-05-30T01:58:36.787+01:00",
         "modified" : "2026-05-30T01:58:36.787+01:00",
         "name" : "g1",
         "permissions" : [
            "security"
         ],
         "tags" : {}
      }
   ]
}
```


## SecurityCreateGroup
**Permissions required**: security.

### Parameters
```
{
   "name" : NAME,
   "permissions" : PERMISSIONS,
   "tags" : TAGS
}
```

Create a group with name, permissions and tags.

TAGS is a dictionary of string or numerical values. PERMISSIONS and
TAGS are optional.

Example:
```
{
   "action" : "SecurityCreateGroup",
   "params" :
      {
         "name" : "Tristram",
         "permissions" : ["security"],
         "tags" : { "tag1" : "see tag1" }
      }
}
```

## SecurityDeleteGroup
**Permissions required**: security.

### Parameters
```
{
   "name" : NAME
}
```

Delete group NAME.


## SecurityAddUserGroups
SecurityDeleteUserGroups
SecurityAddUserPermissions
SecurityDeleteUserPermissions
SecurityAddGroupPermissions
SecurityDeleteGroupPermissions
SecurityListPermissions
