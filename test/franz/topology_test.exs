defmodule Franz.TopologyTest do
  @moduledoc false

  # TODO(Gordon) - Rethink setup callback

  use Franz.TestCase, async: true

  alias Franz.{Connection, Topology}

  setup_all do
    conn = %Connection{endpoints: [{"localhost", 9094}], config: []}
    delete_all_topics(conn.endpoints)

    topic = [
      assignments: [],
      configs: %{
        "retention.ms" => 60_000,
        "compression.type" => "snappy"
      },
      name: "test_topic",
      num_partitions: 1,
      replication_factor: 1
    ]

    %{conn: conn, topic: topic}
  end

  describe "start_link/1" do
    test "will start the Topology process", ctx do
      opts = [connection: ctx.conn, topics: [ctx.topic]]

      start_supervised!({Topology, opts})

      assert {:ok, %Topology{topics: [_]}} = Topology.get(Topology, ctx.conn)
    end
  end
end
