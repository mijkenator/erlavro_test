-module(test_avro).


-export([
    avro/0,
    avro/1,
    send_avro/4
]).

avro() ->
    {ok, SchemaJSON} = file:read_file("priv/create-user-request.avsc"),
    Encoder = avro:make_simple_encoder(SchemaJSON, []),
    Rec = [{"email", "mkh@nkh.com"},{"firstName","Karabas"},{"lastName", "Barabas"}],
    iolist_to_binary(Encoder(Rec)).

avro(Rec) ->
    {ok, SchemaJSON} = file:read_file("priv/create-user-request.avsc"),
    Encoder = avro:make_simple_encoder(SchemaJSON, []),
    iolist_to_binary(Encoder(Rec)).

send_avro(erlkaf, Topic, Key, Rec) ->
    erlkaf:start(),
    ProducerConfig = [{bootstrap_servers, <<"127.0.0.1:29092">>}],
    erlkaf:create_producer(client_producer_avro, ProducerConfig),
    erlkaf:create_topic(client_producer_avro, Topic, [{request_required_acks, 1}]),
    erlkaf:produce(client_producer_avro, Topic, Key, avro(Rec));
send_avro(flare, Topic, _Key, Rec) ->
    flare_app:start(),
    flare_topic:start(Topic, [{compression, snappy}]),
    flare:async_produce(Topic, flare_utils:timestamp(), undefined, avro(Rec), [], undefined ).
