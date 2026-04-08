%% -------------------------------------------------------------------
%%
%% riak_admin_api_web: Riak Admin, webmachine routes.
%%
%% Copyright (c) 2026 TI Tokyo.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(riak_admin_api_web).

-export([cors_headers/0,
         handler_mod/1,
         permissions_for/1
        ]).

cors_headers() ->
    [{"Access-Control-Allow-Origin", "*"},
     {"Access-Control-Allow-Credentials", "true"},
     {"Access-Control-Allow-Methods", "POST,OPTIONS"},
     {"Access-Control-Allow-Headers",
      "host,"
      "origin,"
      "authorization,"
      "content-type,"
      "content-md5,"
      "accept,"
      "accept-encoding"
     }
    ].


handler_mod(<<"ClusterGetStatus">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterClearPlan">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterCommitPlan">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterStageJoin">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterStageLeave">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterStageRemove">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterStageReplace">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterStageForceReplace">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterDownNode">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"ClusterStopNode">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"NodeGetAppEnv">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"NodePutAppEnv">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"NodeGetAdvancedConfig">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"NodePutAdvancedConfig">>) -> riak_admin_api_wm_ctl_cluster;
handler_mod(<<"NodeRestart">>) -> riak_admin_api_wm_ctl_cluster;

handler_mod(<<"VnodeGetStatus">>) -> riak_admin_api_wm_ctl_vnode;
handler_mod(<<"TictacaaeGetStatus">>) -> riak_admin_api_wm_ctl_tictacaae;

handler_mod(<<"SystemGetVersionInfo">>) -> riak_admin_api_wm_ctl_version_info;

handler_mod(<<"SecurityListUsers">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityCreateUser">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecuritySetUserExpiry">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityDeleteUser">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityListGroups">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityCreateGroup">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityDeleteGroup">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityAddUserGroups">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityDeleteUserGroups">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityAddUserPermissions">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityDeleteUserPermissions">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityAddGroupPermissions">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityDeleteGroupPermissions">>) -> riak_admin_api_wm_ctl_security;
handler_mod(<<"SecurityListPermissions">>) -> riak_admin_api_wm_ctl_security;

handler_mod(_) -> undefined.


permissions_for(<<"ClusterGetStatus">>) -> [cluster_observer];
permissions_for(<<"ClusterClearPlan">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterCommitPlan">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterStageJoin">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterStageLeave">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterStageRemove">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterStageReplace">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterStageForceReplace">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterDownNode">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"ClusterStopNode">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"NodeGetAppEnv">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"NodePutAppEnv">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"NodeGetAdvancedConfig">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"NodePutAdvancedConfig">>) -> [cluster_observer, cluster_admin];
permissions_for(<<"NodeRestart">>) -> [cluster_observer, cluster_admin];

permissions_for(<<"VnodeGetStatus">>) -> [cluster_observer];
permissions_for(<<"TictacaaeGetStatus">>) -> [cluster_observer];

permissions_for(<<"SystemGetVersionInfo">>) -> [];

permissions_for(<<"SecurityListUsers">>) -> [security];
permissions_for(<<"SecurityCreateUser">>) -> [security];
permissions_for(<<"SecuritySetUserExpiry">>) -> [security];
permissions_for(<<"SecurityDeleteUser">>) -> [security];
permissions_for(<<"SecurityListGroups">>) -> [security];
permissions_for(<<"SecurityCreateGroup">>) -> [security];
permissions_for(<<"SecurityDeleteGroup">>) -> [security];
permissions_for(<<"SecurityAddUserGroups">>) -> [security];
permissions_for(<<"SecurityDeleteUserGroups">>) -> [security];
permissions_for(<<"SecurityAddUserPermissions">>) -> [security];
permissions_for(<<"SecurityDeleteUserPermissions">>) -> [security];
permissions_for(<<"SecurityAddGroupPermissions">>) -> [security];
permissions_for(<<"SecurityDeleteGroupPermissions">>) -> [security];
permissions_for(<<"SecurityListPermissions">>) -> [security];

permissions_for(_) -> [].
