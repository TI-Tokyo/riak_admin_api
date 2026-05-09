%% -------------------------------------------------------------------
%%
%% riak_admin_api_auth: authentication
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

-module(riak_admin_api_auth).

-export([hash_password/1, authenticate/2]).

-include("riak_admin_api.hrl").

%% borrowing heavily from riak_core_pw_auth.

-define(SALT_LENGTH, 16).
-define(HASH_FUNCTION, sha).
-define(HASH_ITERATIONS, 65536).

-spec hash_password(binary()) -> {binary(), binary()}.
hash_password(Pass) ->
    Salt = crypto:strong_rand_bytes(?SALT_LENGTH),
    {ok, HashedPass} = pbkdf2:pbkdf2(?HASH_FUNCTION, Pass, Salt, ?HASH_ITERATIONS),
    HexPass = pbkdf2:to_hex(HashedPass),
    {HexPass, Salt}.

check_password(BinaryPass, HashedPassword, Salt) ->
    {ok, HashedPass} = pbkdf2:pbkdf2(?HASH_FUNCTION, BinaryPass, Salt, ?HASH_ITERATIONS),
    HexPass = pbkdf2:to_hex(HashedPass),
    pbkdf2:compare_secure(HexPass, HashedPassword).

-spec authenticate(auth_details(), map()) -> boolean().
authenticate(
    #{method := password, details := #{password_hash := Hash, salt := Salt}},
    #{method := password, details := #{password := Pass}}
) ->
    check_password(Pass, Hash, Salt);
authenticate(_, _) ->
    false.
