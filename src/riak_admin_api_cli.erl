%% -------------------------------------------------------------------
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

-module(riak_admin_api_cli).

-behaviour(clique_handler).

-include("riak_admin_api.hrl").
-include_lib("kernel/include/logger.hrl").

-export([register_cli/0]).

register_cli() ->
    register_all_usage(),
    register_all_commands().

register_all_usage() ->
    clique:register_usage(["riak-admin", "admin-api"], main_usage()),
    clique:register_usage(["riak-admin", "admin-api", "status"], status_usage()),
    clique:register_usage(["riak-admin", "admin-api", "status", '*'], status_usage()),
    clique:register_usage(["riak-admin", "admin-api", "add-user"], add_user_usage()),
    clique:register_usage(["riak-admin", "admin-api", "del-user"], del_user_usage()),
    clique:register_usage(["riak-admin", "admin-api", "list-users"], list_users_usage()),
    clique:register_usage(["riak-admin", "admin-api", "reset"], reset_usage()).

register_all_commands() ->
    lists:foreach(
      fun(Args) -> apply(clique, register_command, Args) end,
      [status0_spec(),
       status1_spec(),
       add_user_spec(),
       del_user_spec(),
       list_users_spec(),
       reset_spec()
      ]).

main_usage() ->
    ["riak admin admin-api { status | add-user | del-user\n"
     "                            | list-users | reset }\n",
     "\n",
     "Commands to control HTTP admin API.\n",
     "See individual subcommand usage for options and arguments\n"
    ].

status_usage() ->
    ["riak admin admin-api status [enable | disable]\n",
     "\n",
     "Without arguments, shows whether the HTTP Admin API subsystem can be,\n",
     "and is effectively, enabled, as well as number of users and groups.\n",
     "With \"enable\" or \"disable\", attempts to turn it on or off.\n",
     "Note that if the riak.conf setting `admin_api_enabled` is set to `false`,\n",
     "it cannot be enabled.\n"
    ].

status0_spec() ->
    [["riak-admin", "admin-api", "status"],
     '_', [],
     fun status_cmd/3
    ].
status1_spec() ->
    [["riak-admin", "admin-api", "status", '*'],
     '_', [],
     fun status_cmd/3
    ].

status_cmd([_, _, _], _, _Options) ->
    {Effective, Extra} = riak_admin_api:status(),
    Rows =
        [[{effective, Effective},
          {enabled_in_riak_conf, proplists:get_value(enabled_in_riak_conf, Extra)},
          {users, proplists:get_value(users, Extra)},
          {groups, proplists:get_value(groups, Extra)}
         ]
        ],
    [clique_status:table(Rows)];
status_cmd([_, _, _, "enable"], _, _) ->
    Res =
        case riak_admin_api:enable() of
            ok ->
                [];
            {error, disabled_in_riak_conf} ->
                "Disabled in riak.conf"
        end,
    [clique_status_text(Res)];
status_cmd([_, _, _, "disable"], _, _) ->
    Res =
        case riak_admin_api:disable() of
            ok ->
                [];
            {error, disabled_in_riak_conf} ->
                "Disabled in riak.conf"
        end,
    [clique_status_text(Res)];
status_cmd([_, _, _ | _], _, _) ->
    clique_status:usage().



main(Fun, A, B, C) ->
    case riak_admin_api:is_effective() of
        true ->
            try
                Fun(A, B, C)
            catch
                _:_ ->
                    clique_status:usage()
            end;
        false ->
            [clique_status_alert("HTTP Admin API not enabled")]
    end.

add_user_usage() ->
    ["riak admin admin-api add-user PATH\n",
     "\n",
     "Add a user, reading user specs from a file.\n",
     "This is the way to add an initial superuser.\n",
     "\n",
     "The file read at PATH should be a JSON of the form:\n",
     "  {\n",
     "    \"name\": \"john\"\n",
     "    \"password\": \"PASSWORD\",\n",
     "    \"expires\": EXPIRES,\n",
     "    \"permissions\": PERMISSIONS\n",
     "  }\n",
     "where PASSWORD is given in plain text, EXPIRES is a unixtime,\n",
     "in seconds, or as a rfc3339 string of a time in future, PERMISSIONS\n",
     "is either \"all\" or an array of any of\n",
     "[\"cluster_observer\", \"cluster_admin\", \"security\"].\n"
    ].

add_user_spec() ->
    [["riak-admin", "admin-api", "add-user", '*'],
     '_', [],
     fun(A, B, C) -> main(fun add_user_cmd/3, A, B, C) end
    ].

add_user_cmd([_, _, _, UserDataPath], _, _) ->
    case file:read_file(UserDataPath) of
        {ok, Blob} ->
            case riak_kv_wm_json:decode(Blob) of
                #{<<"name">> := Name,
                  <<"password">> := Password,
                  <<"expires">> := Expires_,
                  <<"permissions">> := Permissions_} ->
                    {Hash, Salt} = riak_admin_api_auth:hash_password(Password),
                    case {validate_perms(Permissions_), validate_expires(Expires_)} of
                        {{valid, Permissions}, {valid, Expires}} ->
                            User = ?USER{groups = [],
                                         expires = Expires,
                                         permissions = Permissions,
                                         auth_details = #{method => password,
                                                          details => #{password_hash => Hash,
                                                                       salt => Salt}}
                                        },
                            case riak_admin_api_ug:add_user(Name, User) of
                                ok ->
                                    [];
                                {error, already_exists} ->
                                    [clique_status_alert("Already exists")]
                            end;
                        _ ->
                            [clique_status_alert("Invalid user permissions or expiry")]
                    end;
                _ ->
                    [clique_status_alert("Invalid user specs")]
            end;
        _ ->
            [clique_status_alert("User data file not readable")]
    end.

-define(ALL_PERMS, [<<"cluster_observer">>, <<"cluster_admin">>, <<"security">>]).

validate_perms(<<"all">>) ->
    {valid, [cluster_observer, cluster_admin, security]};
validate_perms(PP_) when is_list(PP_) ->
    PP = [binary_to_atom(P) || P <- PP_, lists:member(P, ?ALL_PERMS)],
    if length(PP) == length(PP_) ->
            {valid, PP};
       el/=se ->
            invlaid
    end;
validate_perms(_) ->
    invlaid.

validate_expires(<<"never">>) ->
    {valid, never};
validate_expires(A) when is_integer(A) ->
    case os:system_time(second) > A of
        true ->
            invlaid;
        false ->
            {valid, A}
    end;
validate_expires(A) when is_binary(A) ->
    try
        E = calendar:rfc3339_to_system_time(binary_to_list(A), [{unit, millisecond}]),
        {valid, E}
    catch
        _:_ ->
            invlaid
    end;
validate_expires(_a) ->
    invlaid.


del_user_usage() ->
    ["riak admin admin-api del-user NAME\n",
     "\n",
     "Delete a user with name NAME.\n"
    ].

del_user_spec() ->
    [["riak-admin", "admin-api", "del-user", '*'],
     '_', [],
     fun(A, B, C) -> main(fun del_user_cmd/3, A, B, C) end
    ].

del_user_cmd([_, _, _, Name], _, _) ->
    case riak_admin_api_ug:del_user(list_to_binary(Name)) of
        ok ->
            [];
        {error, notfound} ->
            [clique_status_alert("No such user")]
    end.


list_users_usage() ->
    ["riak admin admin-api list-users\n",
     "\n",
     "List users.\n"
    ].

list_users_spec() ->
    [["riak-admin", "admin-api", "list-users"],
     '_', [],
     fun(A, B, C) -> main(fun list_users_cmd/3, A, B, C) end
    ].

list_users_cmd([_, _, _], _, _) ->
    Tf = fun(never) -> <<"never">>;
            (A) -> calendar:system_time_to_rfc3339(A, [{unit, millisecond}]) end,
    Pf = fun(PP) when length(PP) == 3 -> "*";
            (PP) -> string:join([fmtp(P) || P <- PP], ",")
         end,
    Rows =
        [[{name, Name},
          {groups, Groups},
          {created, Tf(Created)},
          {modified, Tf(Modified)},
          {expires, Tf(Expires)},
          {permissions, Pf(Permissions)},
          {auth_method, AuthMethod}]
         || {Name, ?USER{groups = Groups,
                         created = Created,
                         modified = Modified,
                         expires = Expires,
                         permissions = Permissions,
                         auth_details = #{method := AuthMethod}
                        }
            } <- riak_admin_api_ug:list_users() ],
    [clique_status:table(Rows)].

fmtp(cluster_admin) -> "adm";
fmtp(cluster_observer) -> "obs";
fmtp(security) -> "sec".


reset_usage() ->
    ["riak admin admin-api reset\n",
     "\n",
     "Delete all users and groups\n"
    ].

reset_spec() ->
    [["riak-admin", "admin-api", "reset"],
     '_', [],
     fun reset_cmd/3
    ].

reset_cmd([_, _, _], _, _) ->
    [riak_admin_api_ug:del_group(G) || {G, _} <- riak_admin_api_ug:list_groups()],
    [riak_admin_api_ug:del_user(U) || {U, _} <- riak_admin_api_ug:list_users()],
    [clique_status_alert("All groups and users deleted")].


clique_status_text(F) ->
    clique_status_text(F, []).
clique_status_text(F, A) ->
    clique_status:text(io_lib:format(F, A)).
clique_status_alert(S) ->
    clique_status_alert(S, []).
clique_status_alert(F, A) ->
    clique_status:alert([clique_status_text(F, A)]).
