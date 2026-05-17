%% -------------------------------------------------------------------
%%
%% riak_admin_api_wm_ctl: a Webmachine resource for riak_control operations.
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

-module(riak_admin_api_ag_ctl).

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

-record(context, {
    method :: riak_api_web_acceptor:method(),
    request :: undefined | map(),
    creds :: undefined | map(),
    user :: undefined | user(),
    req_body :: undefined | riak_api_web_body:req_body()
}).

-define(TXT_HEADER, {'Content-Type', <<"text/plain">>}).
-define(JSN_HEADER, {'Content-Type', <<"application/json">>}).

-spec match_route(
    riak_api_web_acceptor:method(),
    unicode:chardata(),
    list(unicode:chardata())
) ->
    nomatch
    | {method_not_allowed, list(riak_api_web_acceptor:method())}
    | {ok, riak_api_web_handler:limits(), #context{}}.
match_route(Method, Path, _) ->
    case {Path, Method} of
        {<<"/ctl">>, 'OPTIONS'} ->
            {ok, size_limits(), #context{method = Method}};
        {<<"/ctl">>, 'POST'} ->
            {ok, size_limits(), #context{method = Method}};
        {<<"/ctl">>, _} ->
            {method_not_allowed, ['POST', 'OPTIONS']};
        _ ->
            nomatch
    end.

size_limits() ->
    {
        20,
        1024,
        10 * 1024
    }.

-spec check_permissions(
    riak_api_web_headers:headers(),
    riak_api_web_socket:scheme(),
    riak_api_web_handler:peer_ip(),
    riak_api_web_handler:peer_cert(),
    #context{}
) ->
    {ok, #context{}} | riak_api_web_acceptor:halt_response().
check_permissions(_ReqHeaders, http, _Peer, _Cert, _Ctx) ->
    {halt, 426, [?TXT_HEADER], <<"Upgrade required to https">>, []};
check_permissions(_ReqHeaders, _Scheme, _Peer, _Cert, Ctx = #context{method = 'OPTIONS'}) ->
    {ok, Ctx};
check_permissions(_ReqHeaders, _Scheme, _Peer, _Cert, Ctx) ->
    {ok, Enabled} = application:get_env(riak_admin_api, admin_api_enabled),
    case Enabled of
        true ->
            %% proper permissions check depends on action,
            %% which is in request body; therefore, defer checks
            {ok, Ctx};
        false ->
            {halt, 428, [?TXT_HEADER], <<"Service unavailable">>, []}
    end.

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
    {ok, #context{}} | riak_api_web_acceptor:halt_response().
parse_request_headers(_, Ctx = #context{method = 'OPTIONS'}) ->
    {ok, Ctx};
parse_request_headers(ReqHeaders, Ctx) ->
    case extract_usercreds(ReqHeaders) of
        undefined ->
            {halt, 401, [?TXT_HEADER], <<"Missing user or credentials">>, []};
        {Name, Creds} ->
            case riak_admin_api_ug:get_user(Name) of
                {error, notfound} ->
                    {halt, 401, [?TXT_HEADER], <<"Unauthorized">>, []};
                {ok, User} ->
                    {ok, Ctx#context{
                        user = User,
                        creds = Creds
                    }}
            end
    end.

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
process_request(ReqBody, #context{method = 'OPTIONS'} = Ctx) ->
    {ok, {200, riak_admin_api_web:cors_headers(), <<>>, true, ReqBody}, Ctx};
process_request(none, _Ctx) ->
    {halt, 400, [?TXT_HEADER], <<"No request body">>, []};
process_request(ReqBody, Ctx0) ->
    case authorize(ReqBody, Ctx0) of
        {true, Ctx1} ->
            process_post(Ctx1);
        HaltResponse ->
            HaltResponse
    end.

authorize(ReqBody, Ctx) ->
    case riak_api_web_body:get_body(ReqBody, all, ?MAX_REQ_SIZE) of
        {error, content_too_large} ->
            {halt, 413, [], <<>>, []};
        {ObjBody, UpdReqBody} when is_binary(ObjBody) ->
            case catch riak_kv_wm_json:decode(ObjBody) of
                Request when is_map(Request) ->
                    authorize2(Ctx#context{request = Request, req_body = UpdReqBody});
                _w ->
                    {halt, 400, [?TXT_HEADER], <<"Malformed request">>, []}
            end
    end.
authorize2(
    Ctx = #context{
        request = #{<<"action">> := Action},
        user = ?USER{
            permissions = UserPermissions,
            auth_details = AuthDetails
        },
        creds = Creds
    }
) ->
    case riak_admin_api_auth:authenticate(AuthDetails, Creds) of
        true ->
            ReqPermissions = riak_admin_api_web:permissions_for(Action),
            case intersect(UserPermissions, ReqPermissions) of
                true ->
                    {true, Ctx};
                false ->
                    {halt, 403, <<"Not authorised">>, Ctx}
            end;
        false ->
            {halt, 403, <<"Not authenticated">>, Ctx}
    end.

extract_usercreds(ReqHeaders) ->
    case riak_api_web_headers:get_value('Authorization', ReqHeaders) of
        undefined ->
            undefined;
        <<"Basic ", Base64/binary>> ->
            UserPass = list_to_binary(base64:decode_to_string(Base64)),
            case binary:split(UserPass, <<":">>) of
                [User, Pass] ->
                    {User, #{
                        method => password,
                        details => #{password => Pass}
                    }};
                _ ->
                    undefined
            end;
        _ ->
            undefined
    end.

intersect([], _) ->
    true;
intersect(_, []) ->
    true;
intersect(AA, BB) ->
    lists:any(fun(A) -> lists:member(A, BB) end, AA).

process_post(
    Ctx = #context{
        request = Request,
        req_body = ReqBody
    }
) ->
    #{<<"action">> := Action} = Request,
    try
        case riak_admin_api_web:handler_mod(Action) of
            undefined ->
                {halt, 400, riak_admin_api_web:cors_headers() ++ [?JSN_HEADER],
                 riak_kv_wm_json:encode(
                   #{error => <<"Invalid request action">>}), []};
            not_enabled ->
                {halt, 403, riak_admin_api_web:cors_headers() ++ [?JSN_HEADER],
                 riak_kv_wm_json:encode(#{error => <<"Request disabled">>}), []};
            Mod ->
                case Mod:process_request(Request) of
                    {ok, Res} ->
                        {ok,
                         {200, riak_admin_api_web:cors_headers() ++ [?JSN_HEADER],
                          iolist_to_binary(riak_kv_wm_json:encode(#{result => Res})), true,
                          ReqBody},
                         Ctx};
                    {StatusCode, Err} ->
                        {halt, StatusCode, riak_admin_api_web:cors_headers() ++ [?JSN_HEADER],
                         riak_kv_wm_json:encode(#{error => Err}), []}
                end
        end
    catch
        _t:_e:_st ->
            ?LOG_WARNING("Unhandled error serving admin-api request ~p: ~p:~p ~p", [_t, _e, _st]),
            {halt, 500, riak_admin_api_web:cors_headers() ++ [?JSN_HEADER],
                riak_kv_wm_json:encode(
                    #{error => <<"Internal error">>}
                ),
                []}
    end.

-spec record_request(
    riak_api_web_handler:timings(),
    riak_api_web_handler:completion(),
    #context{}
) ->
    ok.
record_request(_Timings, _Completion, _Ctx) ->
    ok.
