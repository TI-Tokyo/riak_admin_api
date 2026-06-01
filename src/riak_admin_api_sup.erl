%% -------------------------------------------------------------------
%%
%% riak_admin_api_sup: Riak Admin supervisor.
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

-module(riak_admin_api_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}} | ignore.
init([]) ->
    SupFlags =
        #{
            strategy => one_for_one,
            intensity => 10,
            period => 10
        },
    case application:get_env(riak_admin_api, admin_api_enabled) of
        {ok, true} ->
            {ok, [{Ip, Port}]} = application:get_env(riak_admin_api, https),
            SMName = riak_api_web:spec_name(https, Ip, Port),
            WMConfig =
                [
                    {name, SMName},
                    {ip, Ip},
                    {port, Port},
                    {ssl, true},
                    {ssl_opts, riak_api_ssl:options()},
                    {nodelay, true}
                ],
            ChildSpecs =
                [
                    #{
                        id => SMName,
                        start => {riak_api_web_socket, start_link, [WMConfig]},
                        modules => [riak_api_web_socket]
                    },
                    #{
                        id => riak_admin_api_ug,
                        start => {riak_admin_api_ug, start_link, []}
                    }
                ],
            {ok, {SupFlags, ChildSpecs}};
        _ ->
            {ok, {SupFlags, []}}
    end.
