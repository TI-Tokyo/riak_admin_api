# Vnode Operations

## VnodeGetStatus
**Permissions required**: cluster\_observer.

### Parameters
```
{
  "node": NODE,
  "preflists": PREFLISTS
}
```
PREFLISTS is a list of vnodes as strings (not integers) to fetch the
status of, or \"all\" (default), on node NODE.

### Response
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

BACKEND_STATUS is backend-specific:

* bitcask:
```
{
   "result" : [
      {
         "backend_status" : {
            "key_count" : 0,
            "mod" : "riak_kv_bitcask_backend",
            "status" : []
         },
         "counter" : 10000,
         "counter_lease" : 20000,
         "counter_lease_size" : 10000,
         "counter_leasing" : false,
         "idx" : "0",
         "vnodeid" : "e42f1fd931a6049c"
      }
   ]
}
```
* memory:
```
{
   "result" : [
      {
         "backend_status" : {
            "data_table_status" : {
               "compressed" : false,
               "decentralized_counters" : false,
               "heir" : "none",
               "id" : "#Ref<0.3920726211.3486646278.9229>",
               "keypos" : 1,
               "memory" : 139,
               "name" : "riak_kv_0",
               "named_table" : false,
               "node" : "dev1@127.0.0.1",
               "owner" : "<0.1744.0>",
               "protection" : "protected",
               "read_concurrency" : false,
               "size" : 0,
               "type" : "ordered_set",
               "write_concurrency" : false
            },
            "index_table_status" : {
               "compressed" : false,
               "decentralized_counters" : false,
               "heir" : "none",
               "id" : "#Ref<0.3920726211.3486646278.9228>",
               "keypos" : 1,
               "memory" : 139,
               "name" : "riak_kv_0_i",
               "named_table" : false,
               "node" : "dev1@127.0.0.1",
               "owner" : "<0.1744.0>",
               "protection" : "protected",
               "read_concurrency" : false,
               "size" : 0,
               "type" : "ordered_set",
               "write_concurrency" : false
            },
            "mod" : "riak_kv_memory_backend",
            "put_obj_size" : 0,
            "used_memory" : 0
         },
         "counter" : 30000,
         "counter_lease" : 40000,
         "counter_lease_size" : 10000,
         "counter_leasing" : false,
         "idx" : "0",
         "vnodeid" : "e42f1fd931a6049c"
      }
   ]
}
```
* leveldb:
```
{
   "result" : [
      {
         "backend_status" : {
            "compactions" : null,
            "files_size_mb" : null,
            "fixed_indexes" : true,
            "level" : null,
            "mod" : "riak_kv_eleveldb_backend",
            "read_block_error" : "0",
            "read_mb" : null,
            "time" : null,
            "write_mb" : null
         },
         "counter" : 40000,
         "counter_lease" : 50000,
         "counter_lease_size" : 10000,
         "counter_leasing" : false,
         "idx" : "0",
         "vnodeid" : "e42f1fd931a6049c"
      }
   ]
}
```
* leveled:
```
{
   "result" : [
      {
         "backend_status" : {
            "fetch_count_by_level" : {
               "0" : {
                  "count" : 0,
                  "time" : 0
               },
               "1" : {
                  "count" : 0,
                  "time" : 0
               },
               "2" : {
                  "count" : 0,
                  "time" : 0
               },
               "3" : {
                  "count" : 0,
                  "time" : 0
               },
               "lower" : {
                  "count" : 0,
                  "time" : 0
               },
               "mem" : {
                  "count" : 0,
                  "time" : 0
               },
               "not_found" : {
                  "count" : 0,
                  "time" : 0
               }
            },
            "get_body_time" : 0,
            "get_sample_count" : 0,
            "head_rsp_time" : 0,
            "head_sample_count" : 0,
            "journal_last_compaction_duration" : null,
            "journal_last_compaction_max" : null,
            "journal_last_compaction_mean" : null,
            "journal_last_compaction_runlength" : null,
            "journal_last_compaction_score" : null,
            "journal_last_compaction_time" : null,
            "ledger_cache_size" : null,
            "level_files_count" : [],
            "mod" : "riak_kv_leveled_backend",
            "n_active_journal_files" : 1,
            "penciller_inmem_cache_size" : null,
            "penciller_last_merge_time" : null,
            "penciller_work_backlog_status" : {
               "backlog" : false,
               "l0_full" : false,
               "work_items" : 0
            },
            "put_ink_time" : 0,
            "put_mem_time" : 0,
            "put_prep_time" : 0,
            "put_sample_count" : 0
         },
         "counter" : 20000,
         "counter_lease" : 30000,
         "counter_lease_size" : 10000,
         "counter_leasing" : false,
         "idx" : "0",
         "vnodeid" : "e42f1fd931a6049c"
      }
   ]
}
```

On error,
```
{"error": ERROR_STRING}
```
