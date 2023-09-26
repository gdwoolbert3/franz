defmodule FranzTest do
  @moduledoc false

  use Franz.TestCase, async: true

  import Franz.KafkaHelpers

  alias Franz.{Connection, Topology}

  setup_all do
    hosts = hosts()
    delete_all_topics(hosts)

    opts = [
      connection: [uri: uri()],
      topology: [
        topics: [
          [
            assignments: [],
            configs: %{
              "retention.ms" => 300_000,
              "compression.type" => "snappy"
            },
            name: "test_topic_1",
            num_partitions: 3,
            replication_factor: 1
          ],
          [
            assignments: [],
            configs: %{
              "retention.ms" => 300_000,
              "compression.type" => "snappy"
            },
            name: "test_topic_2",
            num_partitions: 1,
            replication_factor: 1
          ]
        ]
      ]
    ]

    start_supervised!({Franz, opts})

    %{hosts: hosts, opts: opts}
  end

  describe "messing around" do
    test "that stuff will work", ctx do
      IO.inspect("success!")
    end
  end
end
