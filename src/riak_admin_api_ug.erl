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

-export([all_permissions/0,

         get_user/1,
         add_user/2,
         del_user/1,
         list_users/0,

         get_group/1,
         add_group/2,
         del_group/1,
         list_groups/0,

         set_user_expiry/2,
         add_user_groups/2,
         del_user_groups/2,
         add_user_permissions/2,
         del_user_permissions/2,

         add_group_permissions/2,
         del_group_permissions/2
        ]).

-spec all_permissions() -> [permission()].
all_permissions() ->
    [cluster_observer, cluster_admin, security].

-define(TOMBSTONE, '$deleted').  %% must match value defined in riak_core_metadata.erl

-spec get_user(id()) -> {ok, user()} | {error, notfound | expired}.
get_user(Name) ->
    case riak_core_metadata:get({?CORE_MD_PREFIX, <<"u">>}, Name) of
        undefined ->
            {error, notfound};
        Defined = ?USER{expires = Expires} ->
            case Expires > now() of
                true ->
                    {ok, Defined};
                false ->
                    ok = riak_core_metadata:delete({?CORE_MD_PREFIX, <<"u">>}, Name)
                    {error, expired}
            end
    end.

-spec add_user(id(), user()) -> ok | {error, already_exists}.
add_user(Name, User) ->
    Record = User?USER{created = now(),
                       modified = now()},
    case riak_core_metadata:get({?CORE_MD_PREFIX, <<"u">>}, Name) of
        undefined ->
            put_user(Name, Record);
        _ ->
            {error, already_exists}
    end.

-spec del_user(id()) -> ok | {error, notfound | invalid_arg}.
del_user(Name) ->
    case get_user(Name) of
        undefined ->
            {error, notfound};
        _ ->
            riak_core_metadata:delete({?CORE_MD_PREFIX, <<"u">>}, Name)
    end.

-spec set_user_expiry(id(), never | non_neg_integer()) -> ok | {error, notfound}.
set_user_expiry(Name, Expires) ->
    case get_user(Name) of
        undefined ->
            {error, notfound};
        {ok, User} ->
            put_user(Name, User?USER{expires = Expires})
    end.


-spec list_users() -> [{id(), user()}].
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
    case riak_core_metadata:get({?CORE_MD_PREFIX, <<"g">>}, Name) of
        undefined ->
            {error, notfound};
        Defined ->
            {ok, Defined}
    end.

-spec add_group(id(), group()) -> ok.
add_group(Name, Record) ->
    put_group(Name, Record).

-spec del_group(id()) -> ok | {error, notfound | has_members}.
del_group(Name) ->
    case get_group(Name) of
        undefined ->
            {error, notfound};
        _ ->
            Members = [UName || {UName, ?USER{groups = UGroups}} <- list_users(),
                                lists:member(Name, UGroups)],
            if Members =:= [] ->
                    riak_core_metadata:delete({?CORE_MD_PREFIX, <<"g">>}, Name);
               el/=se ->
                    {error, has_members}
            end
    end.

-spec list_groups() -> [{id(), group()}].
list_groups() ->
    riak_core_metadata:fold(
      fun({_, [?TOMBSTONE]}, Acc) ->
              Acc;
         ({Name, A}, Acc) ->
              [{Name, A} | Acc]
      end,
      [], {?ADMIN_MD_PREFIX, <<"g">>}
     ).


-spec add_user_group(id(), [id()]) -> ok | {error, notfound | no_such_group}.
add_user_groups(Name, Groups) ->
    ExistingGG = list_group_names(),
    case lists:all(fun(G) -> lists:member(G, ExistingGG) end, Groups) of
        false ->
            {error, no_such_group};
        true ->
            case get_user(Name) of
                {error, notfound} ->
                    {error, notfound};
                {ok, User = ?USER{groups = GG0}} ->
                    case lists:usort(Groups ++ GG0) of
                        GG0 ->
                            ok;
                        GG9 ->
                            Record = User?USER{groups = GG9,
                                               modified = now()},
                            put_user(Name, Record)
                    end
            end
    end.

-spec del_user_groups(id(), [id()]) -> ok | {error, notfound}.
del_user_groups(Name, Groups) ->
    case get_user(Name) of
        {error, notfound} ->
            {error, notfound};
        {ok, User = ?USER{groups = GG0}} ->
            case GG0 -- Groups of
                GG0 ->
                    ok;
                GG9 ->
                    Record = User?USER{groups = GG9,
                                       modified = now()},
                    put_user(Name, Record)
            end
    end.


-spec add_user_permissions(id(), [permission()]) -> ok | {error, notfound}.
add_user_permissions(Name, Perms) ->
    mod_user_permissions(Name, Perms, '++').

-spec del_user_permissions(id(), [permission()]) -> ok | {error, notfound}.
del_user_permissions(Name, Perms) ->
    mod_user_permissions(Name, Perms, '--').

mod_user_permissions(Name, Perms, Op) ->
    case get_user(Name) of
        {error, notfound} ->
            {error, notfound};
        {ok, User = ?USER{permissions = PP0}} ->
            case lists:usort(erlang:Op(Perms, PP0)) of
                PP0 ->
                    ok;
                PP9 ->
                    Record = User?USER{permissions = PP9,
                                       modified = now()},
                    put_user(Name, Record)
            end
    end.

-spec add_group_permissions(id(), [permission()]) -> ok | {error, notfound}.
add_group_permissions(Name, Perms) ->
    mod_group_permissions(Name, Perms, '++').

-spec del_group_permissions(id(), [permission()]) -> ok | {error, notfound}.
del_group_permissions(Name, Perms) ->
    mod_group_permissions(Name, Perms, '--').

mod_group_permissions(Name, Perms, Op) ->
    case get_group(Name) of
        {error, notfound} ->
            {error, notfound};
        {ok, User = ?GROUP{permissions = PP0}} ->
            case lists:usort(erlang:Op(Perms, PP0)) of
                PP0 ->
                    ok;
                PP9 ->
                    Record = User?GROUP{permissions = PP9,
                                        modified = now()},
                    put_group(Name, Record)
            end
    end.

%% internal

put_user(Name, A) ->
    riak_core_metadata:put({?CORE_MD_PREFIX, <<"u">>}, Name, A, []).
put_group(Name, A) ->
    riak_core_metadata:put({?CORE_MD_PREFIX, <<"g">>}, Name, A, []).

list_group_names() ->
    riak_core_metadata:fold(
      fun({_, [?TOMBSTONE]}, Acc) ->
              Acc;
         ({Name, A}, Acc) ->
              [Name | Acc]
      end,
      [], {?ADMIN_MD_PREFIX, <<"g">>}
     ).


now() ->
    os:system_time(millisecond).
