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

-export([
    cors_headers/0,
    handler_mod/1,
    permissions_for/1
]).

-spec cors_headers() -> riak_api_web_headers:header_list().
cors_headers() ->
    [
        {<<"Access-Control-Allow-Origin">>, <<"*">>},
        {<<"Access-Control-Allow-Credentials">>, "true"},
        {<<"Access-Control-Allow-Methods">>, <<"POST,OPTIONS">>},
        {<<"Access-Control-Allow-Headers">>, <<
            "host,"
            "origin,"
            "authorization,"
            "content-type,"
            "content-md5,"
            "accept,"
            "accept-encoding"
        >>}
    ].

-spec handler_mod(binary()) -> undefined | not_enabled | module().
handler_mod(A) ->
    {ok, Classes} = application:get_env(riak_admin_api, sec_group),
    EnabledClasses = [C || {C, F} <- Classes, F == true],
    case i(A) of
        undefined ->
            undefined;
        {Mod, Class} ->
            case lists:member(Class, EnabledClasses) of
                false ->
                    not_enabled;
                true ->
                    Mod
            end
    end.

i(<<"ClusterGetStatus">>) -> {riak_admin_api_ag_ctl_cluster, monitoring};
i(<<"ClusterPlan">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterClearPlan">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterCommitPlan">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterStageJoin">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterStageLeave">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterStageRemove">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterStageReplace">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterStageForceReplace">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterDownNode">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"ClusterStopNode">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"NodeGetAppEnv">>) -> {riak_admin_api_ag_ctl_cluster, monitoring};
i(<<"NodePutAppEnv">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"NodeGetAdvancedConfig">>) -> {riak_admin_api_ag_ctl_cluster, monitoring};
i(<<"NodePutAdvancedConfig">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"NodeRestart">>) -> {riak_admin_api_ag_ctl_cluster, admin};
i(<<"VnodeGetStatus">>) -> {riak_admin_api_ag_ctl_vnode, monitoring};
i(<<"TictacaaeGetStatus">>) -> {riak_admin_api_ag_ctl_tictacaae, monitoring};
i(<<"SystemGetVersionInfo">>) -> {riak_admin_api_ag_ctl_version_info, monitoring};
i(<<"SystemGetListeners">>) -> {riak_admin_api_ag_ctl_version_info, monitoring};
i(<<"SecurityListUsers">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityCreateUser">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecuritySetUserExpiry">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecuritySetUserTags">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityDeleteUser">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityListGroups">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityCreateGroup">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityDeleteGroup">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityAddUserGroups">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityDeleteUserGroups">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityAddUserPermissions">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityDeleteUserPermissions">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityAddGroupPermissions">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityDeleteGroupPermissions">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(<<"SecurityListPermissions">>) -> {riak_admin_api_ag_ctl_security, superuser};
i(_) -> undefined.

permissions_for(<<"ClusterGetStatus">>) -> [cluster_observer];
permissions_for(<<"ClusterPlan">>) -> [cluster_observer, cluster_admin];
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
permissions_for(<<"SystemGetVersionInfo">>) -> [cluster_observer];
permissions_for(<<"SystemGetListeners">>) -> [cluster_observer];
permissions_for(<<"SecurityListUsers">>) -> [security];
permissions_for(<<"SecurityCreateUser">>) -> [security];
permissions_for(<<"SecuritySetUserExpiry">>) -> [security];
permissions_for(<<"SecuritySetUserTags">>) -> [security];
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
