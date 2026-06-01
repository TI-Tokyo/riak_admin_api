---
title: Riak Admin API
nav_order: 1
layout : default
---

# Riak Admin API

Riak Admin API provides an AWS-style set of HTTP requests to enable
authenticated clients to:

* monitor the state of a cluster and perform operations on nodes,
  emulating CLI commands under `riak admin cluster` but also providing
  requests to restart nodes, pull and set all application environment
  vars and node's advanced.config;
* view backend status details on selected nodes and partitions,
  similar to `riak admin vnode-status`;
* view TictacAAE tree rebuild status (`riak admin tictacaae
  treestatus`);
* manage users and groups (`riak admin security`).

## Ping request

A GET request to /ctl/ping, returning "OK" ("text/plain" content
type). It is implemented here in order to provide a ping response on
nodes with the standard http listener disabled.

## Security

The entities, namely users and groups, managed by Riak Admin API are
distinct and different from the traditional users and groups handled
by `riak admin security` subcommands.  They exist in separate
namespaces.  While the latter are meant to represent clients with
specific restrictions on buckets or connecting from specific intranet
networks (typically operated by the application accessing Riak), Riak
Admin API principals are intended to represent human roles, such as
cluster observers and cluster admins.

### Superuser

As all Riak Admin API HTTP requests require authentication, the
original "superuser" will need to be created via `riak admin
admin-api add-user` CLI command.

### Authentication

Basic auth is currently the only method supported.

### Permissions

There are three permissions: `cluster_observer`, `cluster_admin` and
`security`. To be able to execute a request, user's own permissions
combined with all permissions from groups they are a member of, must
include all required permissions of that request (listed in the
descriptions of each request).  See requests `SecurityAddUserPermissions`,
`SecurityDeleteUserPermissions`, `SecurityAddGroupPermissions`,
`SecurityDeleteGroupPermissions`.

### User expiry

Users are automatically deleted if they are accessed (e.g., with
`SecurityListUsers`) or attempt to execute a request on or after the
date in their `expires` field (unless it is `"never"`).

## Requests

Except for ping, all requests are POSTs to /ctl/ACTION, with body as a
JSON object of the form:

```
{
   "params" : PARAMETERS
}
```
ACTION is the command name, and PARAMETERS is a map of parameters,
detailed in sections below.

A response will have a JSON object specific to the request under key
`"result"`, or an error message string under key `"error"`.

For parameters, returned JSON objects and status codes, see the
following sections:

* [General informational requests](RiakAdminAPI-General.md).
* [Cluster monitoring and administration](RiakAdminAPI-ClusterOps.md).
* [Vnode & backend status](RiakAdminAPI-VnodeOps.md).
* [TictacAAE tree status](RiakAdminAPI-TictacAAEOps.md).
* [Security (users, groups, permissions etc)](RiakAdminAPI-SecurityOps.md)

Unless stated specifically, the standard response is:

On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### CLI commands

Riak Admin API exposes a set of `riak admin` commands, under
`admin-api` group.  These are to be used to turn the subsystem on and
off at runtime, and also to manage users. See [CLI
commands](RiakAdminAPI-CLI.md).

### Configuration

#### riak.conf

```
admin_api_enabled = true | false
```
Default: false

```
listener.admin.https.internal = IP:PORT
```
Default: "0.0.0.0:8084" on rel release, "0.0.0.0:10014" for dev1, with PORT
incrementing by 10 for each devN on devrel release.

```
admin_api.security.monitoring = enabled
admin_api.security.admin = disabled
admin_api.security.superuser = disabled
```
Disable/enable individual request groups (defaults shown).
