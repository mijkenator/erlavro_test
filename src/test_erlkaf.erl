-module(test_erlkaf).

-define(TOPIC, <<"benchmark">>).

-export([
    test/0
]).

test() ->
    ok = test_producer:create_producer(),
    test_producer:produce(<<"key1">>, <<"val1">>).

