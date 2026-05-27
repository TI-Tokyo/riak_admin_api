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
#### Parameters
None.

Returns the current state of the cluster, collecting items about the
cluster similar to `riak admin cluster status`.

#### Response
On success, returns a JSON object of the form:
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
```
{"include_transitions" : OPTION }
```

Get a plan of staged changes. Equivalent to `riak admin cluster plan`.

Parameter `"include_transitions"` is optional; if `OPTION` is "full"
(default), key `transitions` will include all items returned by
`riak_core_claimant:plan/0`. If it is `"short"`, `chring.node_entries`
and `members[].md` fields from `ring` and `new_ring` will be omitted.

#### Response
On success,
```
{"result":
  {
    "actions" : ACTIONS,
    "transitions" : TRANSITIONS
  }
}
```

Example (with `"include_transitions" : "full"`):
```
{
   "result" : {
      "actions" : [
         {
            "action" : "leave",
            "node" : "dev2@127.0.0.1"
         }
      ],
      "transitions" : [
         {
            "new_ring" : {
               "chring" : {
                  "node_entries" : [
                     {
                        "idx" : "0",
                        "node" : "dev1@127.0.0.1"
                     },
                     {
                        "idx" : "22835963083295358096932575511191922182123945984",
                        "node" : "dev1@127.0.0.1"
                     },
...
                  ],
                  "num_partitions" : 64
               },
               "claimant" : "dev2@127.0.0.1",
               "clustername" : {
                  "name" : "dev2@127.0.0.1",
                  "ts" : "2026-05-24T19:51:16+01:00"
               },
               "members" : [
                  {
                     "md" : {
                        "$riak_capabilities" : {
                           "riak_core:bucket_types" : "[true,false]",
...
                        },
                        "gossip_vsn" : 2,
                        "participate_in_coverage" : true
                     },
                     "member_status" : "valid",
                     "node" : "dev1@127.0.0.1",
                     "vclock" : [
                        {
                           "counter" : 28,
                           "node" : "dev1@127.0.0.1",
                           "ts" : 63946928738
                        },
...
                     ]
                  },
...
               ],
               "meta" : {
                  "$nodes_locations_changed" : {
                     "lastmod" : 63946867882,
                     "value" : false
                  }
               },
               "next" : [
                  {
                     "idx" : "45671926166590716193865151022383844364247891968",
                     "mods" : [],
                     "next_owner" : "dev1@127.0.0.1",
                     "owner" : "dev2@127.0.0.1",
                     "status" : "awaiting"
                  },
...
               ],
               "nodename" : "dev2@127.0.0.1",
               "rvsn" : [
                  {
                     "counter" : 7,
                     "node" : "dev2@127.0.0.1",
                     "ts" : 63946971039
                  }
               ],
               "seen" : [
                  {
                     "nodename" : "dev1@127.0.0.1",
                     "vclock" : [
                        {
                           "counter" : 29,
                           "node" : "dev1@127.0.0.1",
                           "ts" : 63946928757
                        },
                        {
                           "counter" : 119,
                           "node" : "dev2@127.0.0.1",
                           "ts" : 63946928757
                        }
                     ]
                  },
                  {
                     "nodename" : "dev2@127.0.0.1",
                     "vclock" : [
                        {
                           "counter" : 29,
                           "node" : "dev1@127.0.0.1",
                           "ts" : 63946928757
                        },
                        {
                           "counter" : 119,
                           "node" : "dev2@127.0.0.1",
                           "ts" : 63946928757
                        }
                     ]
                  }
               ],
               "vclock" : [
                  {
                     "counter" : 29,
                     "node" : "dev1@127.0.0.1",
                     "ts" : 63946928757
                  },
                  {
                     "counter" : 120,
                     "node" : "dev2@127.0.0.1",
                     "ts" : 63946971039
                  }
               ]
            },
            "ring" : {
...
            }
```

On error,
```
{"error": ERROR_STRING}
```


### ClusterClearPlan
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
None.

Clear the plan of staged changes, if it exists. Equivalent to `riak admin cluster clear`.

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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
None.

Commits the plan. Equivalent to `riak admin cluster commit`.

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
**Permissions required**: cluster\_observer, cluster\_admin.

#### Parameters
```
{"node": NODE}
```
NODENAME is the node to stage for joining the cluster.

Equivalent to `riak admin cluster join NODE`.

Stage a node to join the cluster.

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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE}
```
NODENAME is the node to stage for leaving.

Equivalent to `riak admin cluster leave NODE`.

Stage a node to leave the cluster. If committed, the affected node
will hand off all its data to other nodes in the cluster and shut down.

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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE}
```
NODENAME is the node to stage for removing.

Equivalent to `riak admin cluster remove NODE`.

Stage a request for a node to be forcefully removed from the cluster.
If committed, all partitions owned by the node will immediately be
reassigned to other nodes.  No data on the affected node will be transfered to
other nodes, and all replicas on it will be lost.

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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE1, "with": NODE2}
```
NODENAME is the node to be replaced with REPLACEMENT.

Equivalent to `riak admin cluster replace NODE1 NODE2`.

Stage a node to be replaced with another in the cluster.  When
committed, node NODE1 will handoff all of its data to NODE2 and then
shut down. The current implementation requires NODE2 to be a fresh node that
is joining the cluster and does not yet own any partitions of its own.

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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE1, "with": NODE2}
```
NODE1 is the node to be force-replaced with NODE2.

Stage a request for NODE1 to be forcefully replaced by NODE2.
If committed, all partitions owned by NODE1 will immediately be
reassigned to NODE2.  No data on NODE1 will be transfered,
and all replicas on NODE1 will be lost. As with `ClusterStageReplace`,
NODE2 must be a fresh node that is joining the cluster
and does not yet own any partitions of its own.

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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE}
```
NODE is the node to mark as 'down'.

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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE}
```
NODE is the node to stop.

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
{"node": NODE}
```
NODE is the node to collect application environment
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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE, "config": CONFIG}
```
NODE is the node to put application environment
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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE}
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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE, "config": CONFIG}
```
NODE is the node to put application environment variables on, and
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
**Permissions required**: cluster\_observer, cluster\_admin.
#### Parameters
```
{"node": NODE}
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

On success, all requests return 200. On error, the status code will be, depending on
cluster condition:

| Condition | Code |
| --- | --- |
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
