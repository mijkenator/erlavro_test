-module(benchmark_producer).

-define(TOPIC, <<"benchmark">>).

-export([
    delivery_report/2,
    benchmark/4
]).

-behaviour(erlkaf_producer_callbacks).

delivery_report(DeliveryStatus, Message) ->
    io:format("received delivery report: ~p ~n", [{DeliveryStatus, Message}]),
    ok.

benchmark(Driver, Concurrency, BytesPerMsg, MsgCount) ->
    init(Driver),
    Self = self(),

    %Message = <<0:BytesPerMsg/little-signed-integer-unit:8>>,
    Message = base64:encode(crypto:strong_rand_bytes(BytesPerMsg)),

    MsgsPerProc = MsgCount div Concurrency,

    ProcFun = fun() ->
        FunGen = fun(_) ->
            Key = integer_to_binary(rand(50000)),
            produce(Driver, Key, Message)
        end,

        ok = lists:foreach(FunGen, lists:seq(1, MsgsPerProc)),
        Self ! {self(), done}
    end,

    do_benchmark(Concurrency, BytesPerMsg, MsgCount, ProcFun).

do_benchmark(Concurrency, BytesPerMsg, MsgCount, Fun) ->
    List = lists:seq(1, Concurrency),

    A = os:timestamp(),
    Pids = [spawn_link(Fun) || _ <- List],
    [receive {Pid, done} -> ok end || Pid <- Pids],
    B = os:timestamp(),

    print(BytesPerMsg, MsgCount, A, B).

print(MsgBytesSize, MsgCount, A, B) ->
    Microsecs = timer:now_diff(B, A),
    Milliseconds = Microsecs/1000,
    Secs = Milliseconds/1000,

    MsgPerSec = MsgCount/Secs,
    BytesPerSec = (MsgCount*MsgBytesSize)/Secs,

    io:format("### time: ~p ms | msg count: ~p | msg/s: ~p | bytes/s: ~s ~n", [
        Milliseconds,
        MsgCount,
        MsgPerSec,
        format_size(BytesPerSec)
    ]).

init(erlkaf) ->
    erlkaf:start();
    %erlkaf:start(),
    %ProducerConfig = [
    %    {bootstrap_servers, <<"127.0.0.1:29092">>},
    %    {delivery_report_only_error, true},
    %    {delivery_report_callback, ?MODULE}
    %],
    %ok = erlkaf:create_producer(client_producer, ProducerConfig),
    %ok = erlkaf:create_topic(client_producer, ?TOPIC, [{request_required_acks, 1}]);
init(erlkafa) ->
    erlkaf:start();
init(brod) ->
    brod:start();
init(flare) ->
    flare_app:start(),
    flare_topic:start(?TOPIC, [{compression, snappy}]);
init(flarea) ->
    flare_app:start(),
    flare_topic:start(?TOPIC, [{compression, snappy}]).

produce(erlkaf, Key, Message) ->
    ok = erlkaf:produce(client_producer, ?TOPIC, Key, Message);
produce(erlkafa, Key, Message) ->
    ok = erlkaf:produce(client_producer, ?TOPIC, Key, Message);
produce(brod, _Key, _Message) ->
%    PartitionFun = fun(_Topic, PartitionsCount, _Key, _Value) ->
%        {ok, erlang:crc32(term_to_binary(Key)) rem PartitionsCount}
%    end,
%    ok = brod:produce_sync(kafka_client, ?TOPIC, PartitionFun, Key, Message);
    {T1, K1, V1} = make_unique_tkv(),
    ok = brod:produce_sync(kafka_client, ?TOPIC, 1, <<>>, [{T1, K1, V1}]);
    
produce(flare, Key, Message) ->
    flare:produce(?TOPIC, flare_utils:timestamp(), Key, Message, [], 500);
produce(flarea, _Key, Message) ->
    flare:async_produce(?TOPIC, flare_utils:timestamp(), undefined, Message, [], undefined );
produce(_, _Key, _Message) ->
    ok.

rand(N) ->
    {_, _, MicroSecs} = os:timestamp(),
    (MicroSecs rem N) + 1.

format_size(Size) ->
    format_size(Size, ["B","KB","MB","GB","TB","PB"]).

format_size(S, [_|[_|_] = L]) when S >= 1024 -> format_size(S/1024, L);
format_size(S, [M|_]) ->
    io_lib:format("~.2f ~s", [float(S), M]).

make_unique_kv() ->
  { iolist_to_binary(["key-", make_ts_str()])
  , iolist_to_binary(["val-", make_ts_str()])
  }.

make_unique_tkv() ->
  {K, V} = make_unique_kv(),
  {brod_utils:epoch_ms(), K, V}.

make_ts_str() -> brod_utils:os_time_utc_str().

