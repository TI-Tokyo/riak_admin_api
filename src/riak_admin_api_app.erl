%% -------------------------------------------------------------------
%%
%% riak_admin_api: Riak Admin, a dedicated silvermachine instance
%%                 serving riak control requests at /ctl.
%%                 An evolution of riak_control.
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

-module(riak_admin_api_app).

-behaviour(application).

-export([start/2, stop/1]).

-include_lib("kernel/include/logger.hrl").

-spec start(application:start_type(), term()) ->
    {ok, pid()} | {error, supervisor:startlink_err()}.
start(_Type, _) ->
    riak_core_util:start_app_deps(riak_admin_api),
    case riak_admin_api_sup:start_link() of
        {ok, Pid} ->
            case application:get_env(riak_admin_api, admin_api_enabled, false) of
                true ->
                    ok = riak_api_web:add_routes(
                        [
                            {5, riak_admin_api_ag_ctl},
                            {10, riak_admin_api_ag_ping}
                        ]
                    ),
                    ok = clique:register([riak_admin_api_cli]),
                    application:set_env(riak_admin_api, admin_api_effective, true);
                false ->
                    application:set_env(riak_admin_api, admin_api_effective, false)
            end,
            {ok, Pid};
        {error, Reason} ->
            {error, Reason}
    end.

-spec stop(term()) -> ok.
stop(_State) ->
    ok.
