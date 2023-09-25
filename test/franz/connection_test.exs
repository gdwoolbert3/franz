defmodule Franz.ConnectionTest do
  @moduledoc false

  use Franz.TestCase, async: true

  import Franz.KafkaHelpers

  alias Franz.Connection

  setup_all do
    opts = [uri: default_connection_uri()]
    start_supervised!({Connection, opts})
    :ok
  end

  describe "get/1" do
    test "will return a connection's config" do
      assert (%Connection{} = connection) = Connection.get(Connection)
      assert connection.endpoints == [{"localhost", 9094}]
      assert connection.config == []
    end
  end
end
