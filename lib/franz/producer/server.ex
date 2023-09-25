defmodule Franz.Producer.Server do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - Safer client ID generation?
  # TODO(Gordon) - Terminology (server -> client)?

  use GenServer

  @server_opts [
    client_config: [
      auto_start_producers: true,
      default_producer_config: [
        compression: :snappy,
        required_acks: 1
      ]
    ]
  ]

  ################################
  # Public API
  ################################

  @doc """
  Starts the producer server process
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    opts = Keyword.merge(@server_opts, opts)
    GenServer.start_link(__MODULE__, opts)
  end

  ################################
  # GenServer Callbacks
  ################################

  @doc false
  @impl GenServer
  @spec init(keyword()) :: {:ok, map()} | {:stop, any()}
  def init(opts) do
    start_client(opts)
  end

  @doc false
  @impl GenServer
  @spec handle_call(atom(), tuple(), map()) :: {:reply, atom(), map()}
  def handle_call(:client_id, _from, state) do
    {:reply, state.client_id, state}
  end

  @doc false
  @impl GenServer
  @spec terminate(any(), map()) :: :ok
  def terminate(_reason, state) do
    :brod.stop_client(state.client_id)
  end

  ################################
  # Private API
  ################################

  defp start_client(opts) do
    client_id = generate_client_id()
    {hosts, config} = parse_opts(opts)

    case :brod.start_client(hosts, client_id, config) do
      :ok -> {:ok, %{client_id: client_id}}
      {:error, reason} -> {:stop, reason}
    end
  end

  defp generate_client_id do
    short_uuid = Enum.at(String.split(UUID.uuid4(), "-"), 0)
    String.to_atom("franz_producer_#{short_uuid}")
  end

  defp parse_opts(opts) do
    hosts = Keyword.get(opts, :hosts, [])
    conn_config = Keyword.get(opts, :conn_config, [])
    client_config = Keyword.get(opts, :client_config, [])
    config = Keyword.merge(conn_config, client_config)
    {hosts, config}
  end
end
