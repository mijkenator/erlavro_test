-module(test_brod).

-define(TOPIC, <<"benchmark">>).

-export([
    test/0
]).

test() ->
    {ok, _} = application:ensure_all_started(brod),
    io:format("BROD1 ~n", []),
    KafkaBootstrapEndpoints = [{"localhost", 9092}],
    Topic = ?TOPIC,
    Partition = 0,
    ok = brod:start_client(KafkaBootstrapEndpoints, client1),
    io:format("BROD2 ~n", []),
    ok = brod:start_producer(client1, Topic, _ProducerConfig = []),
    io:format("BROD3 ~n", []),
    ok = brod:produce_sync(client1, Topic, Partition, <<"key2">>, <<"value2">>),
    io:format("BROD4 ~n", []),
    ok.
