-module(test_flare).

-define(TOPIC, <<"benchmark">>).

-export([
    test/0
]).

test() ->
    flare_app:start(),
    flare_topic:start(<<"benchmark">>, [{compression, snappy}]),
    Timestamp = flare_utils:timestamp(),
    flare:produce(<<"benchmark">>, Timestamp, <<"key">>, <<"value">>, [], 500).

