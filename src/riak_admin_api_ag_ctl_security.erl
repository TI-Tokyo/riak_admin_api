%% -------------------------------------------------------------------
%%
%% riak_admin_api_wm_ctl_security: Riak Admin API, requests
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

-module(riak_admin_api_ag_ctl_security).

-export([process_request/1]).

-include("riak_admin_api.hrl").
-include_lib("kernel/include/logger.hrl").

-spec process_request(#{}) ->
    {ok, binary() | map() | [map()]} | {400..500, binary()}.
process_request(Request) ->
    Res =
        case Request of
            #{<<"action">> := <<"SecurityListUsers">>} ->
                A = [
                    #{
                        name => Name,
                        created => ts2bin(Created),
                        modified => ts2bin(Modified),
                        expires => ts2bin(Expires),
                        groups => Groups,
                        auth_method => AuthMethod,
                        permissions => Permissions,
                        tags => Tags
                    }
                 || {Name, ?USER{
                        groups = Groups,
                        created = Created,
                        modified = Modified,
                        expires = Expires,
                        permissions = Permissions,
                        auth_details = #{method := AuthMethod},
                        tags = Tags
                    }} <-
                        riak_admin_api_ug:list_users()
                ],
                {ok, A};
            #{
                <<"action">> := <<"SecurityCreateUser">>,
                <<"params">> := #{<<"name">> := Name} = Params
            } ->
                case make_user(Params) of
                    {ok, User} ->
                        riak_admin_api_ug:add_user(Name, User);
                    ER ->
                        ER
                end;
            #{
                <<"action">> := <<"SecuritySetUserExpiry">>,
                <<"params">> := #{
                    <<"name">> := Name,
                    <<"expires">> := Expires_
                }
            } ->
                try
                    Expires =
                        case Expires_ of
                            <<"never">> ->
                                never;
                            Millis when is_integer(Millis) ->
                                Millis;
                            MustBeRfc3339 ->
                                calendar:rfc3339_to_system_time(
                                    binary_to_list(MustBeRfc3339), [{unit, millisecond}]
                                )
                        end,
                    riak_admin_api_ug:set_user_expiry(Name, Expires)
                catch
                    error:badarg ->
                        {error, invalid_arg}
                end;
            #{
                <<"action">> := <<"SecuritySetUserTags">>,
                <<"params">> := #{
                    <<"name">> := Name,
                    <<"tags">> := Tags
                }
            } ->
                riak_admin_api_ug:set_user_tags(Name, Tags);
            #{
                <<"action">> := <<"SecurityDeleteUser">>,
                <<"params">> := #{<<"name">> := Name}
            } ->
                riak_admin_api_ug:del_user(Name);
            #{<<"action">> := <<"SecurityListGroups">>} ->
                A = [
                    #{
                        name => Name,
                        created => ts2bin(Created),
                        modified => ts2bin(Modified),
                        permissions => Permissions,
                        tags => Tags
                    }
                 || {Name, ?GROUP{
                        created = Created,
                        modified = Modified,
                        permissions = Permissions,
                        tags = Tags
                    }} <-
                        riak_admin_api_ug:list_groups()
                ],
                {ok, A};
            #{
                <<"action">> := <<"SecurityCreateGroup">>,
                <<"params">> := #{<<"name">> := Name} = Params
            } ->
                case make_group(Params) of
                    {ok, Group} ->
                        riak_admin_api_ug:add_group(Name, Group);
                    ER ->
                        ER
                end;
            #{
                <<"action">> := <<"SecurityDeleteGroup">>,
                <<"params">> := #{<<"name">> := Name}
            } ->
                riak_admin_api_ug:del_group(Name);
            #{
                <<"action">> := <<"SecurityAddUserGroups">>,
                <<"params">> := #{
                    <<"user">> := User,
                    <<"groups">> := Groups
                }
            } ->
                riak_admin_api_ug:add_user_groups(User, Groups);
            #{
                <<"action">> := <<"SecurityDeleteUserGroups">>,
                <<"params">> := #{
                    <<"user">> := User,
                    <<"groups">> := Groups
                }
            } ->
                riak_admin_api_ug:del_user_groups(User, Groups);
            #{
                <<"action">> := <<"SecurityAddUserPermissions">>,
                <<"params">> := #{
                    <<"user">> := User,
                    <<"permissions">> := Perms_
                }
            } ->
                case validate_permissions(Perms_) of
                    false ->
                        {error, invalid_arg};
                    {ok, Perms} ->
                        riak_admin_api_ug:add_user_permissions(User, Perms)
                end;
            #{
                <<"action">> := <<"SecurityDeleteUserPermissions">>,
                <<"params">> := #{
                    <<"user">> := User,
                    <<"permissions">> := Perms_
                }
            } ->
                case validate_permissions(Perms_) of
                    false ->
                        {error, invalid_arg};
                    {ok, Perms} ->
                        riak_admin_api_ug:del_user_permissions(User, Perms)
                end;
            #{
                <<"action">> := <<"SecurityAddGroupPermissions">>,
                <<"params">> := #{
                    <<"group">> := Group,
                    <<"permissions">> := Perms_
                }
            } ->
                case validate_permissions(Perms_) of
                    false ->
                        {error, invalid_arg};
                    {ok, Perms} ->
                        riak_admin_api_ug:add_group_permissions(Group, Perms)
                end;
            #{
                <<"action">> := <<"SecurityDeleteGroupPermissions">>,
                <<"params">> := #{
                    <<"group">> := Group,
                    <<"permissions">> := Perms_
                }
            } ->
                case validate_permissions(Perms_) of
                    false ->
                        {error, invalid_arg};
                    {ok, Perms} ->
                        riak_admin_api_ug:del_group_permissions(Group, Perms)
                end;
            #{<<"action">> := <<"SecurityListPermissions">>} ->
                {ok, [atom_to_binary(P) || P <- riak_admin_api_ug:all_permissions()]};
            #{<<"action">> := A} ->
                {error, iolist_to_binary([<<"Missing request parameters for action ">>, A])}
        end,

    case Res of
        ok ->
            {ok, <<"ok">>};
        {ok, GoodResult} ->
            {ok, GoodResult};
        {error, already_exists} ->
            {412, <<"User or group already exists">>};
        {error, notfound} ->
            {404, <<"No such user or group">>};
        {error, no_such_group} ->
            {412, <<"No such user or group">>};
        {error, invalid_spec} ->
            {400, <<"Invalid parameter">>};
        {error, invalid_arg} ->
            {400, <<"Invalid parameter">>};
        {error, Reason} when is_binary(Reason) ->
            {400, Reason}
    end.

make_user(
    #{
        <<"auth_details">> := #{
            <<"method">> := <<"password">>,
            <<"password">> := Password
        }
    } = Params
) ->
    Tags = maps:get(<<"tags">>, Params, #{}),
    Perms_ = maps:get(<<"permissions">>, Params, []),

    try
        {ok, Perms} = validate_permissions(Perms_),
        Expires =
            case maps:get(<<"expires">>, Params, <<"never">>) of
                <<"never">> ->
                    never;
                Defined ->
                    case catch binary_to_integer(Defined) of
                        Secs when is_integer(Secs) ->
                            Secs * 1000;
                        _ ->
                            calendar:rfc3339_to_system_time(
                                binary_to_list(Defined), [{unit, millisecond}]
                            )
                    end
            end,
        {Hash, Salt} = riak_admin_api_auth:hash_password(Password),
        {ok, ?USER{
            auth_details = #{
                method => password,
                details => #{
                    password_hash => Hash,
                    salt => Salt
                }
            },
            groups = [],
            permissions = Perms,
            expires = Expires,
            tags = Tags
        }}
    catch
        error:_ ->
            {error, invalid_arg}
    end;
make_user(_) ->
    {error, invalid_spec}.

make_group(Params) ->
    Tags = maps:get(<<"tags">>, Params, #{}),
    Perms_ = maps:get(<<"permissions">>, Params, []),
    try
        {ok, Perms} = validate_permissions(Perms_),
        {ok, ?GROUP{
            permissions = Perms,
            tags = Tags
        }}
    catch
        error:_ ->
            {error, invalid_arg}
    end.

validate_permissions(PP) ->
    Res =
        lists:foldl(
            fun
                (_, false) ->
                    false;
                (P, Q) ->
                    case vp(P) of
                        false ->
                            false;
                        ValidConverted ->
                            [ValidConverted | Q]
                    end
            end,
            [],
            PP
        ),
    case Res of
        false ->
            false;
        _ ->
            {ok, Res}
    end.

vp(<<"cluster_observer">>) -> cluster_observer;
vp(<<"cluster_admin">>) -> cluster_admin;
vp(<<"security">>) -> security;
vp(_) -> false.

ts2bin(never) ->
    <<"never">>;
ts2bin(A) ->
    list_to_binary(calendar:system_time_to_rfc3339(A, [{unit, millisecond}])).
