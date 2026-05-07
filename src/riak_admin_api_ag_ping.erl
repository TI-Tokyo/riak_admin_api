%% -------------------------------------------------------------------
%%
%% riak_admin_api_wm_ping: a Webmachine resource for a CORS-enabled ping.
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

-module(riak_admin_api_ag_ping).

-behaviour(riak_api_web_handler).

-export(
    [
        match_route/3,
        check_permissions/5,
        parse_query_params/2,
        parse_request_headers/2,
        process_request/2,
        record_request/3
    ]
).

-include("riak_admin_api.hrl").
-include_lib("kernel/include/logger.hrl").

-record(context, {method :: riak_api_web_acceptor:method()}).

-define(TXT_HEADER, {'Content-Type', <<"text/plain">>}).


-spec match_route(
    riak_api_web_acceptor:method(),
    unicode:chardata(),
    list(unicode:chardata())
) ->
    nomatch
    | {method_not_allowed, list(riak_api_web_acceptor:method())}
    | {ok, riak_api_web_handler:limits(), #context{}}.
match_route(Method, Path, _) ->
    case {string:trim(Path, both, "/"), Method} of
        {"ctl/ping", 'OPTIONS'} ->
            {ok, size_limits(), #context{method = Method}};
        {"ctl/ping", 'GET'} ->
            {ok, size_limits(), #context{method = Method}};
        {"ctl/ping", _} ->
            {method_not_allowed, ['GET', 'OPTIONS']};
        _ ->
            nomatch
    end.

size_limits() ->
    {
        32,
        1024,
        0
    }.


-spec check_permissions(
    riak_api_web_headers:headers(),
    riak_api_web_socket:scheme(),
    riak_api_web_handler:peer_ip(),
    riak_api_web_handler:peer_cert(),
    #context{}
) ->
    {ok, #context{}} | riak_api_web_acceptor:halt_response().
check_permissions(_ReqHeaders, _Scheme, _Peer, _Cert, Ctx) ->
    {ok, Ctx}.


-spec parse_query_params(
    riak_api_web_handler:query_params(),
    #context{}
) ->
    {ok, #context{}} | riak_api_web_acceptor:halt_response().
parse_query_params([], Ctx) ->
    {ok, Ctx};
parse_query_params(_, _Ctx) ->
    {halt, 400, [?TXT_HEADER], <<"No request parameters acceptable">>, []}.


-spec parse_request_headers(
    riak_api_web_headers:headers(),
    #context{}
) ->
    {ok, #context{}}.
parse_request_headers(_ReqHeaders, Ctx) ->
    {ok, Ctx}.


-spec process_request(
    riak_api_web_body:req_body() | none,
    #context{}
) ->
    {
        ok,
        {
            riak_api_web_acceptor:response_code(),
            riak_api_web_headers:header_list(),
            riak_api_web_handler:response_body(),
            boolean(),
            riak_api_web_body:req_body() | none
        },
        #context{}
    }
    | riak_api_web_acceptor:halt_response().
process_request(_, #context{method = 'OPTIONS'} = Ctx) ->
    {ok, {200, riak_admin_api_web:cors_headers(), <<>>, true, none}, Ctx};
process_request(none, Ctx) ->
    {ok, {200, riak_admin_api_web:cors_headers() ++ [?TXT_HEADER], <<"OK">>, true, none}, Ctx};
process_request(_, _) ->
    {halt, 400, [?TXT_HEADER], <<"No request body acceptable">>, []}.


-spec record_request(
    riak_api_web_handler:timings(),
    riak_api_web_handler:completion(),
        #context{}
) ->
    ok.
record_request(_Timings, _Completion, _Ctx) ->
    ok.
