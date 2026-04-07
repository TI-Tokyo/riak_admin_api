%% -------------------------------------------------------------------
%%
%% riak_admin_api_ug: user/group management for riak admin
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

-module(riak_admin_api_ug).

-include("riak_admin_api.hrl").
-include_lib("kernel/include/logger.hrl").

-export([get_user/1,
         add_user/2,
         del_user/1,
         list_users/0,
         get_group/1,
         add_group/2,
         del_group/1,
         list_groups/0,
         add_user_group/2,
         del_user_group/2,
         add_user_permission/2,
         del_user_permission/2,
         add_group_permission/2,
         del_group_permission/2
        ]).


-define(TOMBSTONE, '$deleted').  %% must match value defined in riak_core_metadata.erl

-spec get_user(id()) -> {ok, user()} | {error, notfound}.
get_user(Name) ->
    case riak_core_metadata:get({?CORE_MD_PREFIX, <<"u">>}, Name) of
        undefined ->
            {error, notfound};
        Defined ->
            {ok, Defined}
    end.

-spec add_user(id(), user()) -> ok.
add_user(Name, Record) ->
    riak_core_metadata:put({?CORE_MD_PREFIX, <<"u">>}, Name, Record, []).

-spec del_user(id()) -> ok | {error, notfound}.
del_user(Name) ->
    case get_user(Name) of
        undefined ->
            {error, notfound};
        _ ->
            riak_core_metadata:delete({?CORE_MD_PREFIX, <<"u">>}, Name)
    end.

-spec list_users() -> [user()].
list_users() ->
    riak_core_metadata:fold(
      fun({_, [?TOMBSTONE]}, Acc) ->
              Acc;
         ({Name, A}, Acc) ->
              [{Name, A} | Acc]
      end,
      [], {?ADMIN_MD_PREFIX, <<"u">>}
     ).


-spec get_group(id()) -> {ok, group()} | {error, notfound}.
get_group(Name) ->
    riak_core_metadata:get({?CORE_MD_PREFIX, <<"g">>}, Name).

-spec add_group(id(), group()) -> ok.
add_group(Name, Record) ->
    riak_core_metadata:put({?CORE_MD_PREFIX, <<"g">>}, Name, Record, []).

-spec del_group(id()) -> ok | {error, notfound}.
del_group(Name) ->
    case get_group(Name) of
        undefined ->
            {error, notfound};
        _ ->
            riak_core_metadata:delete({?CORE_MD_PREFIX, <<"g">>}, Name)
    end.

-spec list_groups() -> [group()].
list_groups() ->
    riak_core_metadata:fold(
      fun({_, [?TOMBSTONE]}, Acc) ->
              Acc;
         ({Name, A}, Acc) ->
              [{Name, A} | Acc]
      end,
      [], {?ADMIN_MD_PREFIX, <<"g">>}
     ).

