---
title: Riak Admin API
nav_order: 1
layout : default
---

# Riak Admin API

Riak Admin API provides an AWS-style set of HTTP requests to enable
authenticated clients to:

* monitor the state of a cluster and perform operations on nodes,
  emulating CLI commands under `riak admin cluster`;
* view backend status details on selected nodes and partitions,
  similar to `riak admin vnode-status`;
* view TictacAAE tree rebuild status (`riak admin tictacaae
  treestatus`);
* manage users and groups (`riak admin security`).

All requests are POSTs, with body as a JSON object of the form:

```
{
    "action": ACTION,
    "params": PARAMETER_MAP
}
```
ACTION is the command name, and PARAMETER_MAP is a map of
parameters, detailed below.

A response will have a JSON object specific to the request under key
`"result"`, or an error message string under key `"error"`.

For parameters, returned JSON objects and status codes, see sections below:

* [General requests](RiakAdminAPI-General.md).
* [Cluster monitoring and administration](RiakAdminAPI-ClusterOps.md).
* [Vnode & backend status](RiakAdminAPI-VnodeOps.md).
* [TictacAAE tree status](RiakAdminAPI-TictacAAEOps.md).
* [Security (users, groups, permissions etc)](RiakAdminAPI-SecurityOps.md)
