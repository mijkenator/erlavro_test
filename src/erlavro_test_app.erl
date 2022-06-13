%%%-------------------------------------------------------------------
%% @doc erlavro_test public API
%% @end
%%%-------------------------------------------------------------------

-module(erlavro_test_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    erlavro_test_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
