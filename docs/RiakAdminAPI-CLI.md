# Riak Admin API CLI commands

The following commands are available under `admin-api` group:

## `riak admin admin-api status [enable | disable]`

```
+---------+--------------------+-----+------+
|effective|enabled_in_riak_conf|users|groups|
+---------+--------------------+-----+------+
|  true   |        true        |  3  |  1   |
+---------+--------------------+-----+------+
```

With `enable` or `disable`, temporarily enable/disable the Riak Admin
API subsystem.

## `riak admin admin-api add-user PATH_TO_USERSPEC`

`PATH_TO_USERSPEC` is a path to file containing a JSON object with
the following fields:
```
{
   "name" : NAME,
   "password" : PLAINTEXT_PASSWORD,
   "expires" : EXPIRES,
   "permissions" : PERMISSIONS
}
```

Create the (initial) superuser, with specific EXPIRES and PERMISSIONS.

## `riak admin admin-api del-user NAME`

Delete user USER.

## `riak admin admin-api list-users`

List users.

## `riak admin admin-api reset`

Delete all users and groups.
