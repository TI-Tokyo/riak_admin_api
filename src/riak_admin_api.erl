%% -------------------------------------------------------------------
%%
%% riak_admin_api: admin api status & kill switch
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

-module(riak_admin_api).

-include("riak_admin_api.hrl").
-include_lib("kernel/include/logger.hrl").

-export([
    enable/0,
    disable/0,
    is_effective/0,
    status/0
]).

-spec enable() -> ok | {error, disabled_in_riak_conf}.
enable() ->
    case application:get_env(riak_admin_api, admin_api_enabled) of
        {ok, true} ->
            ok = application:set_env(riak_admin_api, admin_api_effective, true),
            ok;
        _ ->
            {error, disabled_in_riak_conf}
    end.

-spec disable() -> ok | {error, disabled_in_riak_conf}.
disable() ->
    case application:get_env(riak_admin_api, admin_api_enabled) of
        {ok, true} ->
            ok = application:set_env(riak_admin_api, admin_api_effective, false),
            ok;
        _ ->
            {error, disabled_in_riak_conf}
    end.

-spec is_effective() -> boolean().
is_effective() ->
    {ok, Res} = application:get_env(riak_admin_api, admin_api_effective),
    Res.

-spec status() -> {boolean(), proplists:proplist()}.
status() ->
    {ok, EnabledInConf} = application:get_env(riak_admin_api, admin_api_enabled),
    Enabled = application:get_env(riak_admin_api, admin_api_effective, EnabledInConf),
    Extra =
        [
            {enabled_in_riak_conf, EnabledInConf},
            {users, length(riak_admin_api_ug:list_users())},
            {groups, length(riak_admin_api_ug:list_groups())}
        ],
    {Enabled, Extra}.
