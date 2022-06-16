-module(test_avro).


-export([
    avro/0,
    avro/2,
    send_avro/4,
    register_schema/1
]).

-define(VSN, 0).

avro() ->
    {ok, SchemaJSON} = file:read_file("priv/create-user-request.avsc"),
    Encoder = avro:make_simple_encoder(SchemaJSON, []),
    Rec = [{"email", "mkh@nkh.com"},{"firstName","Karabas"},{"lastName", "Barabas"}],
    iolist_to_binary(Encoder(Rec)).

avro(Subject, Rec) ->
    {ok, SchemaJSON} = file:read_file("priv/create-user-request.avsc"),
    Encoder = avro:make_simple_encoder(SchemaJSON, []),
    AvroBinary = iolist_to_binary(Encoder(Rec)),
    {ok, SchemaId} = register_schema(Subject, SchemaJSON),
    tag_data(SchemaId, AvroBinary).

send_avro(erlkaf, Topic, Key, Rec) ->
    erlkaf:start(),
    ProducerConfig = [{bootstrap_servers, <<"127.0.0.1:29092">>}],
    erlkaf:create_producer(client_producer_avro, ProducerConfig),
    erlkaf:create_topic(client_producer_avro, Topic, [{request_required_acks, 1}]),
    erlkaf:produce(client_producer_avro, Topic, Key, avro("test_schema", Rec));
send_avro(flare, Topic, _Key, Rec) ->
    flare_app:start(),
    flare_topic:start(Topic, [{compression, snappy}]),
    flare:async_produce(Topic, flare_utils:timestamp(), undefined, avro("test_schema", Rec), [], undefined ).

tag_data(SchemaId, AvroBinary) ->
  iolist_to_binary([<<?VSN:8, SchemaId:32/unsigned-integer>>, AvroBinary]).

%% @doc Get schema registeration ID and avro binary from tagged data.
%untag_data(<<?VSN:8, RegId:32/unsigned-integer, Body/binary>>) ->
%  {RegId, Body}.


register_schema(SchemaJSON) -> do_register_schema("test_schema", SchemaJSON).
register_schema(Subject, SchemaJSON) -> do_register_schema(Subject, SchemaJSON).
   
do_register_schema(Subject, SchemaJSON) ->
  {SchemaRegistryURL, SchemaRegistryHeaders} = {"http://localhost:8081", []},
  URL = SchemaRegistryURL ++ "/subjects/" ++ Subject ++ "/versions",
  Body = make_schema_reg_req_body(SchemaJSON),
  Req = {URL, SchemaRegistryHeaders, "application/vnd.schemaregistry.v1+json", Body},
  Result = httpc:request(post, Req, [{timeout, 10000}], []),
  case Result of
    {ok, {{_, OK, _}, _RspHeaders, RspBody}} when OK >= 200, OK < 300 ->
      #{<<"id">> := Id} = jsone:decode(iolist_to_binary(RspBody)),
      {ok, Id};
    {ok, {{_, Other, _}, _RspHeaders, RspBody}} ->
      error_logger:error_msg("~p: Failed to register schema to ~s:\n~s",
                             [?MODULE, URL, RspBody]),
      {error, {bad_http_code, Other}};
    {error, Reason} ->
      error_logger:error_msg("~p: Failed to register schema to ~s:\n~p",
                             [?MODULE, URL, Reason]),
      {error, Reason}
  end.

%% Make schema registry POST request body.
%% which is: the schema JSON is escaped and wrapped by another JSON object.
-spec make_schema_reg_req_body(binary()) -> binary().
make_schema_reg_req_body(SchemaJSON) ->
  jsone:encode(#{<<"schema">> => SchemaJSON}).
