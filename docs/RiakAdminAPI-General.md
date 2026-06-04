# General requests

## SystemGetVersionInfo
**Permissions required**: cluster\_observer.
### Parameters
```
{"nodes": NODES}
```

NODES can be `"this"`, `"all"` or a list of specific nodes.

Returns OTP and Riak release versions on NODES, as well as uptime of
each node.

## Response
Example:
```
{
   "result" : {
      "dev1@127.0.0.1" : {
         "nodename" : "dev1@127.0.0.1",
         "riak_version" : "4.0-prototype",
         "system_version" : "Erlang/OTP 26 [erts-14.2.4] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:64] [jit:ns]",
         "uptime" : 54200,
         "uptime_str" : "15 hours, 3 minutes, 20 sec"
      }
   }
}
```

## SystemGetListeners
**Permissions required**: cluster\_observer.

### Parameters
```
{"nodes": NODES}
```

NODES can be `"all"` or a list of specific nodes.

Returns URLs of all listeners on NODES, e.g.:
```
{
   "result" : {
      "dev1@127.0.0.1" : {
         "http" : "http://127.0.0.1:10018",
         "pb" : "pb://127.0.0.1:10017"
      },
      "dev2@127.0.0.1" : {
         "http" : "http://127.0.0.1:10028",
         "pb" : "pb://127.0.0.1:10027"
      }
   }
}
```
