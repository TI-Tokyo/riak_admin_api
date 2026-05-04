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

-module(riak_admin_api_wm_ctl).

-export([init/1,
         options/2,
         service_available/2,
         allowed_methods/2,
         is_authorized/2,
         content_types_provided/2,
         content_types_accepted/2,
         process_post/2
        ]).

-include("riak_admin_api.hrl").
-include_lib("webmachine/include/webmachine.hrl").
-include_lib("kernel/include/logger.hrl").

-record(context, {request :: undefined | map(),
                  user :: undefined | user()}).

init([]) ->
    {ok, #context{}}.

-spec service_available(#wm_reqdata{}, #context{}) ->
          {boolean(), #wm_reqdata{}, #context{}}.
service_available(RD, Ctx) ->
    {ok, Enabled} = application:get_env(riak_admin_api, admin_api_enabled),
    {Enabled,
     wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD), Ctx}.

-spec allowed_methods(#wm_reqdata{}, #context{}) ->
          {[atom()], #wm_reqdata{}, #context{}}.
allowed_methods(RD, Ctx) ->
    {['OPTIONS', 'POST'],
     wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD), Ctx}.

-spec options(#wm_reqdata{}, #context{}) ->
          {[{string(), string()}], #wm_reqdata{}, #context{}}.
options(RD, Ctx) ->
    {riak_admin_api_web:cors_headers(), RD, Ctx}.

-spec is_authorized(#wm_reqdata{}, #context{}) ->
          {true|{halt, 401}, #wm_reqdata{}, #context{}}.
is_authorized(RD, Ctx) ->
    case wrq:method(RD) of
        'OPTIONS' ->
            {true, wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD), Ctx};
        _ ->
            is_authorized2(RD, Ctx)
    end.
is_authorized2(RD, Ctx) ->
    Request = riak_kv_wm_json:decode(wrq:req_body(RD)),
    RD1 = wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD),
    case extract_usercreds(RD) of
        undefined ->
            {{halt, 401}, RD1, Ctx};
        {Name, Creds} ->
            is_authorized3(Name, Creds, RD1, Ctx#context{request = Request})
        end.
is_authorized3(Name, Creds, RD, Ctx = #context{request = #{<<"action">> := Action}}) ->
    case riak_admin_api_ug:get_user(Name) of
        {error, notfound} ->
            {{halt, 401}, RD, Ctx};
        {ok, User = ?USER{permissions = UserPermissions,
                          auth_details = AuthDetails}} ->
            case riak_admin_api_auth:authenticate(AuthDetails, Creds) of
                true ->
                    ReqPermissions = riak_admin_api_web:permissions_for(Action),
                    case intersect(UserPermissions, ReqPermissions) of
                        true ->
                            {true, RD, Ctx#context{user = User}};
                        false ->
                            {{halt, 403}, RD, Ctx}
                    end;
                false ->
                    {{halt, 401}, RD, Ctx}
            end
    end.

extract_usercreds(RD) ->
    case wrq:get_req_header("Authorization", RD) of
        "Basic " ++ Base64 ->
            UserPass = base64:decode_to_string(Base64),
            [User, Pass] = [list_to_binary(X) || X <- string:tokens(UserPass, ":")],
            {User, #{method => password,
                     details => #{password => Pass}}};
        _ ->
            undefined
    end.

intersect([], _) ->
    true;
intersect(_, []) ->
    true;
intersect(AA, BB) ->
    lists:any(fun(A) -> lists:member(A, BB) end, AA).


-spec content_types_provided(#wm_reqdata{}, #context{}) ->
          {[{string(), atom()}], #wm_reqdata{}, #context{}}.
content_types_provided(RD, Ctx) ->
    {[{"application/json", nonexistent_to_json}], RD, Ctx}.

-spec content_types_accepted(#wm_reqdata{}, #context{}) ->
          {[{string(), atom()}], #wm_reqdata{}, #context{}}.
content_types_accepted(RD, Ctx) ->
    {[{"application/json", nonexistent_from_json}], RD, Ctx}.


-spec process_post(#wm_reqdata{}, #context{}) ->
          {boolean()|{halt, 400..500}, #wm_reqdata{}, #context{}}.
process_post(RD, Ctx = #context{request = Request}) ->
    #{<<"action">> := Action} = Request,
    try
        case riak_admin_api_web:handler_mod(Action) of
            undefined ->
                {{halt, 400},
                 wrq:append_to_resp_body(
                   riak_kv_wm_json:encode(
                     #{error => iolist_to_binary([<<"Invalid request action ">>, Action])}), RD), Ctx};
            Mod ->
                case Mod:process_request(Request) of
                    {ok, Res} ->
                        {true,
                         wrq:append_to_resp_body(
                           riak_kv_wm_json:encode(#{result => Res}), RD), Ctx};
                    {StatusCode, Err} ->
                        {{halt, StatusCode},
                         wrq:append_to_resp_body(
                           riak_kv_wm_json:encode(#{error => Err}), RD), Ctx}
                end
        end
    catch
        _t:_e:_st ->
            {{halt, 400},
             wrq:append_to_resp_body(
               riak_kv_wm_json:encode(
                 #{error => <<"Malformed request">>}), RD), Ctx}
    end.
