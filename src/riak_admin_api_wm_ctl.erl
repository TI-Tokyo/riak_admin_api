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

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("kernel/include/logger.hrl").

-record(context, {request :: undefined | #{},
                  user :: string()}).

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
          {boolean(), #wm_reqdata{}, #context{}}.
is_authorized(RD, Ctx) ->
    Request = #{<<"action">> := Action} =
        riak_kv_wm_json:decode(wrq:req_body(RD)),
    User = extract_user(RD),
    UserPermissions = get_user_permissions(User),
    ReqPermissions = riak_admin_api_web:permissions_for(Action),
    Res =
        case intersect(UserPermissions, ReqPermissions) of
            true ->
                true;
            false ->
                {halt, 401}
        end,
    {Res, wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD),
     Ctx#context{request = Request, user = User}}.

extract_user(RD) ->
    wrq:get_req_header("X-Riak-User", RD).
get_user_permissions(User) ->
    ?LOG_NOTICE("STUB: get_user_permissions(~p) returns all permissions", [User]),
    [cluster_observer, cluster_admin, security].
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
