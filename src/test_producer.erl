-module(test_producer).

-define(TOPIC, <<"benchmark">>).

-export([
    delivery_report/2,
    stats_callback/2,
    create_producer/0,
    produce/2,
    produce/3
]).

-behaviour(erlkaf_producer_callbacks).

delivery_report(DeliveryStatus, Message) ->
    io:format("received delivery report: ~p ~n", [{DeliveryStatus, Message}]),
    ok.

stats_callback(ClientId, Stats) ->
    io:format("stats_callback: ~p stats:~p ~n", [ClientId, length(Stats)]).

create_producer() ->
    erlkaf:start(),
    
    io:format("erlkaf started: ~n", []),

    ProducerConfig = [
        {bootstrap_servers, <<"127.0.0.1:29092">>},
        {delivery_report_only_error, true},
        {delivery_report_callback, ?MODULE}
    ],
    ok = erlkaf:create_producer(client_producer, ProducerConfig),
    io:format("erlkaf1: ~n", []),
    ok = erlkaf:create_topic(client_producer, ?TOPIC, [{request_required_acks, 1}]),
    io:format("erlkaf2 ~n", []),
    ok.

produce(Key, Value) ->
    ok = erlkaf:produce(client_producer, ?TOPIC, Key, Value).

produce(0, _Key, _Value) ->
    ok;
produce(Count, Key, Value) ->
    ok = erlkaf:produce(client_producer, ?TOPIC, Key, Value),
    produce(Count -1, Key, Value).
