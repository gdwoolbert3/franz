defmodule Franz.ConnectionTest do
  @moduledoc false

  # TODO(Gordon) - Rethink setup callback
  # TODO(Gordon) - explicit "get" test?

  use Franz.TestCase, async: true

  alias Franz.Connection

  setup_all do
    %{uri: "kafka://localhost:9094"}
  end

  describe "start_link/1" do
    test "will start the connection process", ctx do
      start_supervised!({Connection, [uri: ctx.uri]})

      assert %Connection{} = Connection.get(Connection)
    end

    test "will start with explicit connection opts" do
      start_supervised!({Connection, [host: "localhost", port: 9094]})

      assert %Connection{} = Connection.get(Connection)
    end
  end
end
