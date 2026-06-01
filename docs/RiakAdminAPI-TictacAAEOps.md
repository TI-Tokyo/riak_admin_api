# TictacAAE tree status report

## TictacaaeGetStatus
**Permissions required**: cluster\_observer.
### Parameters
```
{"node": NODE}
```

Collect the status of TictacAAE trees on NODE.

Example:
```
{
   "result" : [
      {
         "controller_pid" : "<0.1869.0>",
         "last_rebuild" : "never",
         "next_rebuild" : "2026-09-07T05:07:14.622+01:00",
         "partition" : "0",
         "status" : "empty",
         "total_dirty_segments" : 0
      },
      {
         "controller_pid" : "<0.1942.0>",
         "last_rebuild" : "never",
         "next_rebuild" : "2026-09-02T02:47:20.634+01:00",
         "partition" : "114179815416476790484662877555959610910619729920",
         "status" : "empty",
         "total_dirty_segments" : 0
      },
...
   ]
}
```
