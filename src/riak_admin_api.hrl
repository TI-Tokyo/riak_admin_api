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

-ifndef(RIAK_ADMIN_API_HRL).
-define(RIAK_ADMIN_API_HRL, included).

-type id() :: binary().
-type ts() :: non_neg_integer().

-type permission() :: cluster_observer | cluster_admin | security.

-type auth_method() :: password.
-type auth_details() :: #{method := auth_method(),
                          details := map()}.

-record(user_v1, {groups :: [id()],
                  created :: undefined | ts(),
                  modified :: undefined | ts(),
                  expires :: never | ts(),
                  permissions :: [permission()],
                  auth_details :: #{method := auth_method(),
                                    details := map()}
                 }).
-type user() :: #user_v1{}.
-define(USER, #user_v1).

-record(group_v1, {created :: ts(),
                   modified :: ts(),
                   permissions :: [permission()]
                  }).
-type group() :: #group_v1{}.
-define(GROUP, #group_v1).

-define(ADMIN_MD_PREFIX, <<"admin_api">>).

-endif.
