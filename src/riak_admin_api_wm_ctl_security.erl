%% -------------------------------------------------------------------
%%
%% riak_admin_api_wm_ctl_security: Riak Control, requests
%%                                 to manage users, groups and permissions.
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

-module(riak_admin_api_wm_ctl_security).

-export([process_request/1]).

-include("riak_admin_api.hrl").
-include_lib("kernel/include/logger.hrl").

-spec process_request(#{}) ->
          {ok, binary() | map() | [map()]} | {400..500, binary()}.
process_request(Request) ->
    Res =
        case Request of
            #{<<"action">> := <<"SecurityListUsers">>} ->
                A = [ #{name => Name,
                        created => Created,
                        modified => Modified,
                        expires => Expires,
                        groups => Groups,
                        auth_method => AuthMethod,
                        permissions => Permissions}
                      || {Name, ?USER#{groups = Groups,
                                       created = Created,
                                       modified = Modified,
                                       expires = Expires,
                                       permissions = Permissions,
                                       auth_details = #{auth_method := AuthMethod}}}
                             <- riak_admin_api_ug:list_users() ],
                {ok, A};

            #{<<"action">> := <<"SecurityCreateUser">>,
              <<"params">> := #{<<"name">> := Name,
                                <<"options">> := Options}} ->
                case make_user(Options) of
                    {ok, User} ->
                        riak_admin_api_ug:add_user(Name, User);
                    ER ->
                        ER
                end;

            #{<<"action">> := <<"SecuritySetUserExpiry">>,
              <<"params">> := #{<<"name">> := Name,
                                <<"expires">> := Expires_}} ->
                try
                    Expires =
                        case Expires_ of
                            <<"never">> ->
                                never;
                            _ ->
                                binary_to_integer(Expires_)
                        end,
                    riak_admin_api_ug:set_user_expiry(Name, Expires)
                catch
                    error:badarg ->
                        {error, invalid_arg}
                end;

            #{<<"action">> := <<"SecurityDeleteUser">>,
              <<"params">> := #{<<"name">> := Name}} ->
                riak_admin_api_ug:del_user(Name);

            #{<<"action">> := <<"SecurityListGroups">>} ->
                A = [ #{name => Name,
                        created => Created,
                        modified => Modified,
                        permissions => Permissions}
                      || {Name, ?GROUP{created = Created,
                                       modified = Modified,
                                       permissions = Permissions}}
                             <- riak_admin_api_ug:list_groups() ],
                {ok, A};

            #{<<"action">> := <<"SecurityCreateGroup">>,
              <<"params">> := #{<<"name">> := Name,
                                <<"options">> := Options}} ->
                case make_group(Options) of
                    {ok, Group} ->
                        riak_admin_api_ug:add_group(Name, Group);
                    ER ->
                        ER
                end;

            #{<<"action">> := <<"SecurityDeleteGroup">>,
              <<"params">> := #{<<"name">> := Name}} ->
                riak_admin_api_ug:del_group(Name);

            #{<<"action">> := <<"SecurityAddUserGroups">>,
              <<"params">> := #{<<"user">> := User,
                                <<"groups">> := Groups}} ->
                riak_admin_api_ug:add_user_groups(User, Groups);

            #{<<"action">> := <<"SecurityDeleteUserGroups">>,
              <<"params">> := #{<<"user">> := User,
                                <<"groups">> := Groups}} ->
                riak_admin_api_ug:del_user_groups(User, Groups);

            #{<<"action">> := <<"SecurityAddUserPermissions">>,
              <<"params">> := #{<<"user">> := User,
                                <<"permissions">> := Perms_}} ->
                case lists:foldl(fun validate_permission_/2, [], Perms_) of
                    [] ->
                        {error, invalid_arg};
                    Perms ->
                        riak_admin_api_ug:add_user_permissions(User, Perms)
                end;

            #{<<"action">> := <<"SecurityDeleteUserPermissions">>,
              <<"params">> := #{<<"user">> := User,
                                <<"permissions">> := Perms_}} ->
                case lists:foldl(fun validate_permission_/2, [], Perms_) of
                    [] ->
                        {error, invalid_arg};
                    Perms ->
                        riak_admin_api_ug:del_user_permissions(User, Perms)
                end;

            #{<<"action">> := <<"SecurityAddGroupPermissions">>,
              <<"params">> := #{<<"group">> := Group,
                                <<"permissions">> := Perms_}} ->
                case lists:foldl(fun validate_permission_/2, [], Perms_) of
                    [] ->
                        {error, invalid_arg};
                    Perms ->
                        riak_admin_api_ug:add_group_permissions(Group, Perms)
                end;

            #{<<"action">> := <<"SecurityDeleteGroupPermissions">>,
              <<"params">> := #{<<"group">> := Group,
                                <<"permissions">> := Perms_}} ->
                case lists:foldl(fun validate_permission_/2, [], Perms_) of
                    [] ->
                        {error, invalid_arg};
                    Perms ->
                        riak_admin_api_ug:del_group_permissions(Group, Perms)
                end;


            #{<<"action">> := <<"SecurityListPermissions">>} ->
                {ok, [atom_to_binary(P) || P <- riak_admin_api_ug:all_permissions()]}
        end,

    case Res of
        ok ->
            {ok, <<"ok">>};
        {ok, GoodResult} ->
            {ok, GoodResult};
        {error, notfound} ->
            {404, <<"No such user or group">>};
        {error, no_such_group} ->
            {412, <<"No such user or group">>};
        {error, invalid_spec} ->
            {400, <<"Invalid parameter">>};
        {error, invalid_arg} ->
            {400, <<"Invalid parameter">>}
    end.


make_user(#{<<"name">> := Name,
            <<"auth_details">> := #{<<"method">> := <<"password">>,
                                    <<"password_hash">> := PwdHash}} = Options) ->
    Now = os:system_time(millisecond),
    try
        Expires =
            case maps:get(<<"expires">>, Options, undefined) of
                undefined ->
                    never;
                Defined ->
                    binary_to_integer(Defined)
            end,
        {ok, ?USER{auth_details = #{method => password,
                                    password_hash => PwdHash},
                   groups = [],
                   permissions = [],
                   created = Now,
                   modified = Now,
                   expires = Expires}}
    catch
        error:badarg ->
            {error, invalid_arg}
    end;
make_user(_) ->
    {error, invalid_spec}.

make_group(#{<<"name">> := Name} = Options) ->
    Now = os:system_time(millisecond),
    {ok, ?GROUP{created = Now,
                modified = Now,
                permissions = []}};
make_group(_) ->
    {error, invalid_spec}.


validate_permission_(<<"cluster_observer">>, Q) -> [cluster_observer | Q];
validate_permission_(<<"cluster_admin">>, Q) -> [cluster_admin | Q];
validate_permission_(<<"security">>, Q) -> [security, Q];
validate_permission_(_, Q) -> Q.

deep_binary_to_list(A) ->
    maps:fold(
      fun(K, V, Q) when is_binary(V) -> maps:put(binary_to_list(K), binary_to_list(V), Q);
         (K, V, Q) when is_map(V) -> maps:put(binary_to_list(K), deep_binary_to_list(V), Q)
      end, #{}, A).
