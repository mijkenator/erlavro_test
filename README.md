erlavro_test
=====

An OTP application

Build
-----

    export LIBRARY_PATH=~/.asdf/installs/erlang/24.3.4/lib/erl_interface-5.2.2/lib/
    $ rebar3 compile

    docker-compose -f docker_compose_kafka.yml up -d



    kafka-topics --describe --bootstrap-server localhost:29092 --topic benchmark
    kafka-console-consumer --topic benchmark --bootstrap-server localhost:29092
    kafka-leader-election --all-topic-partitions --bootstrap-server localhost:9092
