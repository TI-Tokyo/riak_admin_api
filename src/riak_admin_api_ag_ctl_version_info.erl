%% -------------------------------------------------------------------
%%
%% riak_admin_api_wm_ctl_version_info: Riak Control, SystemGetVersionInfo request.
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

-module(riak_admin_api_ag_ctl_version_info).

-export([process_request/1]).

-include_lib("kernel/include/logger.hrl").

-spec process_request(#{}) ->
    {ok, map()} | {412, binary()}.
process_request(Request) ->
    Res =
        case Request of
            #{
                <<"action">> := <<"SystemGetVersionInfo">>,
                <<"params">> := #{<<"nodes">> := Nodes_}
            } ->
                Res2 =
                    lists:foldl(
                        fun(N, Q) ->
                            case catch erpc:call(N, riak_kv_util, system_info, []) of
                                {'EXIT', _} ->
                                    maps:put(N, <<"Node not reachable">>, Q);
                                Info ->
                                    maps:put(N, Info, Q)
                            end
                        end,
                        #{},
                        nodes_from_params(Nodes_)
                    ),
                {ok, Res2};
            #{
                <<"action">> := <<"SystemGetListeners">>,
                <<"params">> := #{<<"nodes">> := Nodes_}
            } ->
                Res2 =
                    lists:foldl(
                        fun(N, Q) ->
                            LL =
                                lists:foldl(
                                    fun(K, Q2) ->
                                        case get_listener(N, K) of
                                            undefined ->
                                                Q2;
                                            A ->
                                                Q2#{K => A}
                                        end
                                    end,
                                    #{},
                                    [pb, http, https]
                                ),
                            maps:put(N, LL, Q)
                        end,
                        #{},
                        nodes_from_params(Nodes_)
                    ),
                {ok, Res2};
            #{<<"action">> := A} ->
                {error, iolist_to_binary([<<"Missing request parameters for action ">>, A])}
        end,
    case Res of
        {ok, GoodResult} ->
            {ok, GoodResult};
        {error, Reason} when is_binary(Reason) ->
            {400, Reason}
    end.

nodes_from_params(Nodes_) ->
    All = [node() | nodes()],
    case Nodes_ of
        <<"all">> ->
            All;
        Some when is_list(Some) ->
            [N || N <- All, lists:member(atom_to_binary(N), Some)]
    end.

get_listener(Node, Kind) ->
    case catch erpc:call(Node, application, get_env, [riak_api, Kind]) of
        undefined ->
            undefined;
        {ok, [{IP, Port}]} ->
            iolist_to_binary(
                io_lib:format("~s://~s:~b", [Kind, IP, Port])
            );
        {'EXIT', _} ->
            <<"Node not reachable">>
    end.
