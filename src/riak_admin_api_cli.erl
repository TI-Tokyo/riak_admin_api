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

-include_lib("kernel/include/logger.hrl").

-export([register_cli/0]).

register_cli() ->
    register_all_usage(),
    register_all_commands().

register_all_usage() ->
    clique:register_usage(["riak-admin", "http-admin-api"], main_usage()),
    clique:register_usage(["riak-admin", "http-admin-api", "status"], status_usage()],
    clique:register_usage(["riak-admin", "http-admin-api", "status", '*'], status_usage()],
    clique:register_usage(["riak-admin", "http-admin-api", "add-user"], add_user_usage()),
    clique:register_usage(["riak-admin", "http-admin-api", "del-user"], del_user_usage()),
    clique:register_usage(["riak-admin", "http-admin-api", "list-users"], list_user_usage()),
    clique:register_usage(["riak-admin", "http-admin-api", "reset"], reset_usage()).

register_all_commands() ->
    lists:foreach(
      fun(Args) -> apply(clique, register_command, Args) end,
      [status0_spec(),
       status1_spec(),
       add_user_specs(),
       del_user_specs(),
       list_user_specs(),
       reset_specs()
      ]).

main_usage() ->
    ["riak-admin http-admin-api { status | add-user | del-user\n"
     "                          | list-users | reset }\n",
     "\n",
     "Commands to control HTTP admin API.\n",
     "See individual subcommand usage for options and arguments\n"
    ].

status0_spec() ->
    [["riak-admin", "http-admin-api", "status"],
     '_', [],
     status_cmd/3
    ].
status1_specs() ->
    [["riak-admin", "http-admin-api", "status", '*'],
     '_', [],
     status_cmd/3
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
                "OK";
            {error, disabled_in_riak_conf} ->
                "Disabled in riak.conf"
        end,
    [clique_status_text(Res)];
status_cmd([_, _, _, "disable"], _, _) ->
    Res =
        case riak_admin_api:disable() of
            ok ->
                "OK";
            {error, disabled_in_riak_conf} ->
                "Disabled in riak.conf"
        end,
    [clique_status_text(Res)].


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


add_user_specs() ->
    [["riak-admin", "http-admin-api", "add-user", '*'],
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
                                    [clique_status_text("OK")];
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

validate_perms(<<"all">>) ->
    [cluster_observer, cluster_admin, security];
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
    never;
validate_expires(A) when is_integer(A) ->
    case os:system_time(millisecond) > A of
        true ->
            invlaid;
        false ->
            {valid, A}
    end;
validate_expires(_) ->
    invlaid.



del_user_specs() ->
    [["riak-admin", "http-admin-api", "del-user", '*'],
     '_', [],
     fun(A, B, C) -> main(fun del_user_cmd/3, A, B, C) end
    ].

del_user_cmd([_, _, _, Name], _, _) ->
    case riak_admin_api_ug:del_user(Name) of
        ok ->
            [clique_status_text("OK")];
        {error, notfound} ->
            [clique_status_alert("No such user")]
    end.


list_user_specs() ->
    Tf =  fun(never) -> <<"never">>;
             (A) -> calendar:system_time_to_rfc3339(A, [{unit, millisecond}]) end,
    Rows =
        [[{name, Name},
          {groups, Groups},
          {created, Tf(Created)},
          {modified, Tf(Modified)},
          {expires, Tf(Expires)},
          {permissions, Permissions},
          {auth_method, AuthMethod}]
         || {Name, ?USER{groups = Groups,
                         created = Created,
                         modified = Modified,
                         expires = Expires,
                         permissions = Permissions
                         auth_details = #{method := AuthMethod}
                        }
            } <- riak_admin_api_ug:list_users() ],
    [clique_status:table(Rows)].


reset_specs() ->
    [["riak-admin", "http-admin-api", "reset"],
     '_', [],
     reset_cmd/3
    ].

reset_cmd([_, _, _], _, _) ->
    [riak_admin_api_ug:del_group(G) || {G, _} riak_admin_api_ug:list_groups()],
    [riak_admin_api_ug:del_user(U) || {U, _} riak_admin_api_ug:list_users()],
    [clique_status_alert("All groups and users deleted")].
