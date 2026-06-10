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

-behaviour(gen_server).

-export([
    all_permissions/0,

    get_user/1,
    add_user/2,
    del_user/1,
    list_users/0,

    get_group/1,
    add_group/2,
    del_group/1,
    list_groups/0,

    set_user_expiry/2,
    set_user_tags/2,
    add_user_groups/2,
    del_user_groups/2,
    add_user_permissions/2,
    del_user_permissions/2,

    add_group_permissions/2,
    del_group_permissions/2
]).
-export([start_link/0]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-spec all_permissions() -> [permission()].
all_permissions() ->
    [cluster_observer, cluster_admin, security].

-define(SERVER, ?MODULE).

-spec get_user(id()) -> {ok, user()} | {error, notfound | expired}.
get_user(Name) ->
    gen_server:call(?SERVER, {get_user, Name}, infinity).

-spec add_user(id(), user()) -> ok | {error, already_exists}.
add_user(Name, User) ->
    gen_server:call(?SERVER, {add_user, Name, User}, infinity).

-spec del_user(id()) -> ok | {error, notfound | invalid_arg}.
del_user(Name) ->
    gen_server:call(?SERVER, {del_user, Name}, infinity).

-spec set_user_expiry(id(), never | non_neg_integer()) -> ok | {error, invalid_arg | notfound}.
set_user_expiry(Name, Expires) ->
    gen_server:call(?SERVER, {set_user_expiry, Name, Expires}, infinity).

-spec set_user_tags(id(), #{}) -> ok | {error, notfound}.
set_user_tags(Name, Tags) ->
    gen_server:call(?SERVER, {set_user_tags, Name, Tags}, infinity).

-spec list_users() -> [{id(), user()}].
list_users() ->
    gen_server:call(?SERVER, list_users, infinity).

-spec get_group(id()) -> {ok, group()} | {error, notfound}.
get_group(Name) ->
    gen_server:call(?SERVER, {get_group, Name}, infinity).

-spec add_group(id(), group()) -> ok.
add_group(Name, Group) ->
    gen_server:call(?SERVER, {add_group, Name, Group}, infinity).

-spec del_group(id()) -> ok | {error, notfound | has_members}.
del_group(Name) ->
    gen_server:call(?SERVER, {del_group, Name}, infinity).

-spec list_groups() -> [{id(), group()}].
list_groups() ->
    gen_server:call(?SERVER, list_groups, infinity).

-spec add_user_groups(id(), [id()]) -> ok | {error, notfound | no_such_group}.
add_user_groups(Name, Groups) ->
    gen_server:call(?SERVER, {add_user_groups, Name, Groups}, infinity).

-spec del_user_groups(id(), [id()]) -> ok | {error, notfound}.
del_user_groups(Name, Groups) ->
    gen_server:call(?SERVER, {del_user_groups, Name, Groups}, infinity).

-spec add_user_permissions(id(), [permission()]) -> ok | {error, notfound}.
add_user_permissions(Name, Perms) ->
    gen_server:call(?SERVER, {add_user_permissions, Name, Perms}, infinity).

-spec del_user_permissions(id(), [permission()]) -> ok | {error, notfound}.
del_user_permissions(Name, Perms) ->
    gen_server:call(?SERVER, {del_user_permissions, Name, Perms}, infinity).

-spec add_group_permissions(id(), [permission()]) -> ok | {error, notfound}.
add_group_permissions(Name, Perms) ->
    gen_server:call(?SERVER, {add_group_permissions, Name, Perms}, infinity).

-spec del_group_permissions(id(), [permission()]) -> ok | {error, notfound}.
del_group_permissions(Name, Perms) ->
    gen_server:call(?SERVER, {del_group_permissions, Name, Perms}, infinity).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?SERVER, [], []).

-record(state, {}).

-spec init([]) -> {ok, #state{}}.
init([]) ->
    {ok, #state{}}.

handle_call({get_user, Name}, _From, State) ->
    {reply, do_get_user(Name, State), State};
handle_call({add_user, Name, User}, _From, State) ->
    {reply, do_add_user(Name, User, State), State};
handle_call({del_user, Name}, _From, State) ->
    {reply, do_del_user(Name, State), State};
handle_call({set_user_expiry, Name, Expires}, _From, State) ->
    {reply, do_set_user_expiry(Name, Expires, State), State};
handle_call({set_user_tags, Name, Tags}, _From, State) ->
    {reply, do_set_user_tags(Name, Tags, State), State};
handle_call(list_users, _From, State) ->
    {reply, do_list_users(State), State};
handle_call({get_group, Name}, _From, State) ->
    {reply, do_get_group(Name, State), State};
handle_call({add_group, Name, Group}, _From, State) ->
    {reply, do_add_group(Name, Group, State), State};
handle_call({del_group, Name}, _From, State) ->
    {reply, do_del_group(Name, State), State};
handle_call(list_groups, _From, State) ->
    {reply, do_list_groups(State), State};
handle_call({add_user_groups, Name, Groups}, _From, State) ->
    {reply, do_add_user_groups(Name, Groups, State), State};
handle_call({del_user_groups, Name, Groups}, _From, State) ->
    {reply, do_del_user_groups(Name, Groups, State), State};
handle_call({add_user_permissions, Name, Perms}, _From, State) ->
    {reply, do_add_user_permissions(Name, Perms, State), State};
handle_call({del_user_permissions, Name, Perms}, _From, State) ->
    {reply, do_del_user_permissions(Name, Perms, State), State};
handle_call({add_group_permissions, Name, Perms}, _From, State) ->
    {reply, do_add_group_permissions(Name, Perms, State), State};
handle_call({del_group_permissions, Name, Perms}, _From, State) ->
    {reply, do_del_group_permissions(Name, Perms, State), State}.

-spec handle_cast(term(), #state{}) -> {noreply, #state{}}.
handle_cast(_Msg, State) ->
    {noreply, State}.

-spec handle_info(term(), #state{}) -> {noreply, #state{}}.
handle_info(_Info, State) ->
    {noreply, State}.

-spec terminate(term(), #state{}) -> ok.
terminate(_Reason, #state{}) ->
    ok.

-spec code_change(term(), #state{}, term()) -> {ok, #state{}}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% must match value defined in riak_core_metadata.erl
-define(TOMBSTONE, '$deleted').

do_get_user(Name, _State) ->
    case riak_core_metadata:get({?ADMIN_MD_PREFIX, <<"u">>}, Name) of
        undefined ->
            {error, notfound};
        Defined = ?USER{expires = Expires} ->
            case Expires > now_ms() of
                true ->
                    {ok, Defined};
                false ->
                    ok = riak_core_metadata:delete({?ADMIN_MD_PREFIX, <<"u">>}, Name),
                    {error, expired}
            end
    end.

do_add_user(Name, User, _State) ->
    Now = now_ms(),
    Record = User?USER{
        created = Now,
        modified = Now
    },
    case riak_core_metadata:get({?ADMIN_MD_PREFIX, <<"u">>}, Name) of
        undefined ->
            put_user(Name, Record);
        _ ->
            {error, already_exists}
    end.

do_del_user(Name, State) ->
    case do_get_user(Name, State) of
        {error, notfound} ->
            {error, notfound};
        _ ->
            riak_core_metadata:delete({?ADMIN_MD_PREFIX, <<"u">>}, Name)
    end.

do_set_user_expiry(Name, Expires, State) ->
    case os:system_time(millisecond) > Expires of
        true ->
            {error, invalid_arg};
        false ->
            case do_get_user(Name, State) of
                {error, notfound} ->
                    {error, notfound};
                {ok, User} ->
                    put_user(Name, User?USER{
                        expires = Expires,
                        modified = now_ms()
                    })
            end
    end.

do_set_user_tags(Name, Tags, State) ->
    case do_get_user(Name, State) of
        {error, notfound} ->
            {error, notfound};
        {ok, User} ->
            put_user(Name, User?USER{
                tags = Tags,
                modified = now_ms()
            })
    end.

do_list_users(_State) ->
    riak_core_metadata:fold(
        fun
            ({_, [?TOMBSTONE]}, Acc) ->
                Acc;
            ({Name, [A | _]}, Acc) ->
                [{Name, A} | Acc]
        end,
        [],
        {?ADMIN_MD_PREFIX, <<"u">>}
    ).

do_get_group(Name, _State) ->
    case riak_core_metadata:get({?ADMIN_MD_PREFIX, <<"g">>}, Name) of
        undefined ->
            {error, notfound};
        Defined ->
            {ok, Defined}
    end.

do_add_group(Name, Group, _State) ->
    Now = now_ms(),
    Record = Group?GROUP{
        created = Now,
        modified = Now
    },
    case riak_core_metadata:get({?ADMIN_MD_PREFIX, <<"g">>}, Name) of
        undefined ->
            put_group(Name, Record);
        _ ->
            {error, already_exists}
    end.

do_del_group(Name, State) ->
    case do_get_group(Name, State) of
        {error, notfound} ->
            {error, notfound};
        _ ->
            Members = [
                UName
             || {UName, ?USER{groups = UGroups}} <- do_list_users(State),
                lists:member(Name, UGroups)
            ],
            if
                Members =:= [] ->
                    riak_core_metadata:delete({?ADMIN_MD_PREFIX, <<"g">>}, Name);
                el /= se ->
                    {error, has_members}
            end
    end.

do_list_groups(_State) ->
    riak_core_metadata:fold(
        fun
            ({_, [?TOMBSTONE]}, Acc) ->
                Acc;
            ({Name, [A | _]}, Acc) ->
                [{Name, A} | Acc]
        end,
        [],
        {?ADMIN_MD_PREFIX, <<"g">>}
    ).

do_add_user_groups(Name, Groups, State) ->
    ExistingGG = list_group_names(),
    case lists:all(fun(G) -> lists:member(G, ExistingGG) end, Groups) of
        false ->
            {error, no_such_group};
        true ->
            case do_get_user(Name, State) of
                {error, notfound} ->
                    {error, notfound};
                {ok, User = ?USER{groups = GG0}} ->
                    case lists:usort(Groups ++ GG0) of
                        GG0 ->
                            ok;
                        GG9 ->
                            Record = User?USER{
                                groups = GG9,
                                modified = now_ms()
                            },
                            put_user(Name, Record)
                    end
            end
    end.

do_del_user_groups(Name, Groups, State) ->
    case do_get_user(Name, State) of
        {error, notfound} ->
            {error, notfound};
        {ok, User = ?USER{groups = GG0}} ->
            case GG0 -- Groups of
                GG0 ->
                    ok;
                GG9 ->
                    Record = User?USER{
                        groups = GG9,
                        modified = now_ms()
                    },
                    put_user(Name, Record)
            end
    end.

do_add_user_permissions(Name, Perms, State) ->
    mod_user_permissions(Name, Perms, '++', State).

do_del_user_permissions(Name, Perms, State) ->
    mod_user_permissions(Name, Perms, '--', State).

mod_user_permissions(Name, Perms, Op, State) ->
    case do_get_user(Name, State) of
        {error, notfound} ->
            {error, notfound};
        {ok, User = ?USER{permissions = PP0}} ->
            case lists:usort(erlang:Op(PP0, Perms)) of
                PP0 ->
                    ok;
                PP9 ->
                    Record = User?USER{
                        permissions = PP9,
                        modified = now_ms()
                    },
                    put_user(Name, Record)
            end
    end.

do_add_group_permissions(Name, Perms, State) ->
    mod_group_permissions(Name, Perms, '++', State).

do_del_group_permissions(Name, Perms, State) ->
    mod_group_permissions(Name, Perms, '--', State).

mod_group_permissions(Name, Perms, Op, State) ->
    case do_get_group(Name, State) of
        {error, notfound} ->
            {error, notfound};
        {ok, User = ?GROUP{permissions = PP0}} ->
            case lists:usort(erlang:Op(Perms, PP0)) of
                PP0 ->
                    ok;
                PP9 ->
                    Record = User?GROUP{
                        permissions = PP9,
                        modified = now_ms()
                    },
                    put_group(Name, Record)
            end
    end.

%% internal

put_user(Name, A) ->
    riak_core_metadata:put({?ADMIN_MD_PREFIX, <<"u">>}, Name, A, []).
put_group(Name, A) ->
    riak_core_metadata:put({?ADMIN_MD_PREFIX, <<"g">>}, Name, A, []).

list_group_names() ->
    riak_core_metadata:fold(
        fun
            ({_, [?TOMBSTONE]}, Acc) ->
                Acc;
            ({Name, _}, Acc) ->
                [Name | Acc]
        end,
        [],
        {?ADMIN_MD_PREFIX, <<"g">>}
    ).

now_ms() ->
    os:system_time(millisecond).
