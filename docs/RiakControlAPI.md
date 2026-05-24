---
title: Object API
nav_order: 1
layout : default
---

# Riak Control API

Riak Control API provides an AWS-style set of HTTP requests to enable
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
`result`, or an error message string under key `error`.


## Cluster monitoring and operations

### ClusterGetStatus
**Permissions required**: cluster\_observer.

Returns the current state of the cluster, collecting items about the
cluster similar to `riak admin cluster status`.

#### Parameters
None.

#### Response
On success, returns a JSON object of the
form
```
{
  "current_cluster": [CLUSTER_MEMBER1, ...],
  "down_nodes" : [DOWN_NODE1, ...],
  "final_cluster" : [FINAL_MEMBER1, ...],
  "staged_changes" : [STAGED_CHANGE1, ...],
  "transfers" : [TRANSFER1, ...]
}
```
Example: for a cluster of two devrel nodes with no staged changes and
all transfers completed, the response is as follows:

```
{
   "result" : {
      "current_cluster" : [
         {
            "claimant" : false,
            "is_me" : true,
            "low_mem" : false,
            "mem_erlang" : 91029576,
            "mem_total" : 16694644736,
            "mem_used" : 7158771712,
            "name" : "dev1@127.0.0.1",
            "pending_pct" : 0.5,
            "reachable" : true,
            "replacement" : null,
            "ring_pct" : 0.5,
            "services" : [
               "riak_repl",
               "riak_pipe",
               "riak_kv"
            ],
            "staged_action" : null,
            "status" : "valid",
            "system_info" : {
               "nodename" : "dev1@127.0.0.1",
               "riak_version" : "3.4.0",
               "system_version" : "Erlang/OTP 26 [erts-14.2.4] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:64] [jit:ns]",
               "uptime" : 2954,
               "uptime_str" : "49 minutes, 14 sec"
            }
         },
         {
            "claimant" : true,
            "is_me" : false,
            "low_mem" : false,
            "mem_erlang" : 77394144,
            "mem_total" : 16694644736,
            "mem_used" : 7158771712,
            "name" : "dev2@127.0.0.1",
            "pending_pct" : 0.5,
            "reachable" : true,
            "replacement" : null,
            "ring_pct" : 0.5,
            "services" : [
               "riak_repl",
               "riak_pipe",
               "riak_kv"
            ],
            "staged_action" : null,
            "status" : "valid",
            "system_info" : {
               "nodename" : "dev2@127.0.0.1",
               "riak_version" : "3.4.0",
               "system_version" : "Erlang/OTP 26 [erts-14.2.4] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:64] [jit:ns]",
               "uptime" : 2959,
               "uptime_str" : "49 minutes, 19 sec"
            }
         }
      ],
      "down_nodes" : [],
      "final_cluster" : [],
      "staged_changes" : [],
      "transfers" : []
   }
}
```
With ongoing transfers, the `"transfers"` key will have elements as
follows:
```
"transfers" :
  [
    {
      "count" : 32,
      "node" : "dev2@127.0.0.1",
      "state" : "stopped"
    },
    {
      "count" : 32,
      "node" : "dev1@127.0.0.1",
      "state" : "waiting_to_handoff"
    }
  ]
```

With leave/join operations planned, keys `"final_cluster"` and
`"staged_changes"` will contain the following elements:
```
"final_cluster" : [
   {
      "name" : "dev2@127.0.0.1",
      "pending_pct" : 0,
      "ring_pct" : 0
   },
   {
      "name" : "dev1@127.0.0.1",
      "pending_pct" : 100,
      "ring_pct" : 100
   },
"staged_changes" : [
   {
      "action" : "leave",
      "name" : "dev2@127.0.0.1"
   }
]
```
and the `"staged_action"` key in the affected node's `CLUSTER_MEMBER` entry under
`"current_cluster"` will change from `null` to the corresponding value
to indicate the action.

### ClusterPlan
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
None.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```

### ClusterClearPlan
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
None.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```

### ClusterCommitPlan
**Permissions required**: cluster\_admin.
#### Parameters
None.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### ClusterStageJoin
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to stage for joining the cluster.

#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### ClusterStageLeave
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to stage for leaving the cluster.

#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### ClusterStageRemove
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to stage for removing from the cluster.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### ClusterStageReplace
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME, "with": REPLACEMENT}
```
NODENAME is the node to be replaced with REPLACEMENT.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### ClusterStageForceReplace
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME, "with": REPLACEMENT}
```
NODENAME is the node to be force-replaced with REPLACEMENT.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### ClusterDownNode
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to down.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### ClusterStopNode
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to stop.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### NodeGetAppEnv
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to collect application environment
variables on.
#### Response
On success,
```
{"result": APPENV}
```
APPENV is a proplist of all Erlang applications and their
environments, as a string produced by passing it through
`io_lib:format("~120p\n", [AllAppEnvAsProplist])`.

On error,
```
{"error": ERROR_STRING}
```


### NodePutAppEnv
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME, "config": CONFIG}
```
NODENAME is the node to put application environment
variables on, and CONFIG is a string that can be parsed with
`erl_scan:string/1` and `erl_parse:parse_term/1`, of the result of
printing a proplist of all application environments with
`io_lib:format/2`,  or a fragment of such proplist. The final `.` is
not required.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### NodeGetAdvancedConfig
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to pull advanced.config from.
#### Response
On success,
```
{"result": CONFIG}
```
CONFIG is the contents of `$PLATFORM_ETC_DIR/advanced.cofig`, as a string produced by passing it through
`io_lib:format("~120p\n", [Config])`.
On error,
```
{"error": ERROR_STRING}
```

### NodePutAdvancedConfig
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME, "config": CONFIG}
```
NODENAME is the node to put application environment variables on, and
CONFIG is a string that can be parsed with `erl_scan:string/1` and
`erl_parse:parse_term/1`, of the the entire contents of
advanced.config, without a final `.`.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```


### NodeRestart
**Permissions required**: cluster\_admin.
#### Parameters
```
{"node": NODENAME}
```
NODENAME is the node to restart.
{: .note }
> This action requires `riak_deadmanshand`. If it is not running, the
> request will succeed but the node will not be restarted.
#### Response
On success,
```
{"result": "ok"}
```
On error,
```
{"error": ERROR_STRING}
```

## Cluster admin request status codes

On success, 200. On error, the status code will be, depending on
cluster condition:

---
| Condition | Code |
---
| ring_not_ready | 425 |
| plan_changed | 425 |
| not_reachable | 425 |
| claimant_is_down | 412 |
| invalid_replacement | 409 |
| already_replacement | 409 |
| not_member | 404 |
| not_single_node | 409 |
| is_claimant | 409 |
| only_member | 412 |
| self_join | 409 |
| already_leaving | 409 |
| is_up | 412 |
| nodedown | 412 |
| bad_config | 400 |
---


### VnodeGetStatus
**Permissions required**: cluster\_observer.
#### Parameters
```
{
  "node": NODENAME,
  "preflists": PREFLISTS
}
```
PREFLISTS is a list of vnodes as strings (not integers) to fetch the
status of, or \"all\", on node NODENAME.
#### Response
On success,
```
{"result": [PLSTATUS, ...]}
```
Each PLSTATUS has the following fields:
```
{
  "counter": COUNTER,
  "backend_status": {
    "mod": BACKEND_NAME,
    "status": BAKEND_STATUS,
    "key_count": KEYCOUNT
  },
  "idx": IDX,
  "vnodeid": VNODEID,
  "counter_lease": COUNTER_LEASE,
  "counter_lease_size": COUNTER_LEASE_SIZE,
  "counter_leasing": COUNTER_LEASING
}
```

On error,
```
{"error": ERROR_STRING}
```

TictacaaeGetStatus

SystemGetVersionInfo

SecurityListUsers
SecurityCreateUser
SecuritySetUserExpiry
SecurityDeleteUser
SecurityListGroups
SecurityCreateGroup
SecurityDeleteGroup
SecurityAddUserGroups
SecurityDeleteUserGroups
SecurityAddUserPermissions
SecurityDeleteUserPermissions
SecurityAddGroupPermissions
SecurityDeleteGroupPermissions
SecurityListPermissions
