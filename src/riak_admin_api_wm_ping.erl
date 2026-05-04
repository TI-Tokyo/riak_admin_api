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

-module(riak_admin_api_wm_ping).

-export([init/1,
         options/2,
         service_available/2,
         allowed_methods/2,
         is_authorized/2,
         content_types_provided/2,
         content_types_accepted/2,
         to_html/2
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
    {['OPTIONS', 'GET'],
     wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD), Ctx}.

-spec options(#wm_reqdata{}, #context{}) ->
          {[{string(), string()}], #wm_reqdata{}, #context{}}.
options(RD, Ctx) ->
    {riak_admin_api_web:cors_headers(), RD, Ctx}.

-spec is_authorized(#wm_reqdata{}, #context{}) ->
          {true, #wm_reqdata{}, #context{}}.
is_authorized(RD, Ctx) ->
    {true, wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD), Ctx}.

-spec content_types_provided(#wm_reqdata{}, #context{}) ->
          {[{string(), atom()}], #wm_reqdata{}, #context{}}.
content_types_provided(RD, Ctx) ->
    {[{"text/html", to_html}], RD, Ctx}.

-spec content_types_accepted(#wm_reqdata{}, #context{}) ->
          {[{string(), atom()}], #wm_reqdata{}, #context{}}.
content_types_accepted(RD, Ctx) ->
    {[{"text/htmp", nonexistent_from_text}], RD, Ctx}.

-spec to_html(#wm_reqdata{}, #context{}) -> {string(), #wm_reqdata{}, #context{}}.
to_html(RD, Ctx) ->
    {"OK", wrq:set_resp_headers(riak_admin_api_web:cors_headers(), RD), Ctx}.
