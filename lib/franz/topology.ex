defmodule Franz.Topology do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - add partitions / alter configs
  # TODO(Gordon) - Delete topic support
  # TODO(Gordon) - Add support for common configs?
  # TODO(Gordon) - Add support for topic prefix?
  # TODO(Gordon) - Add connection to opts schema
  # TODO(Gordon) - update with brod metadata

  use GenServer

  import Franz.Utilities

  alias Franz.Connection
  alias Franz.Topology.Topic

  @enforce_keys [:topics]
  defstruct [:topics]

  @type request_timeout :: non_neg_integer()
  @type topic_opts :: keyword()
  @type t :: %__MODULE__{topics: [Topic.t()]}

  @topic_opts_schema KeywordValidator.schema!(
                       assignments: [is: :list, required: false],
                       configs: [is: :map, required: false],
                       name: [is: :binary, required: true],
                       num_partitions: [is: :integer, required: true],
                       replication_factor: [is: :integer, required: true]
                     )

  @opts_schema KeywordValidator.schema!(topics: [is: :list, required: true])

  ################################
  # Public API
  ################################

  @doc """
  Starts the topology process.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Creates a Kafka topic.
  """
  @spec create_topic(GenServer.name() | pid(), Connection.t(), topic_opts()) ::
          {:ok, Topic.t()} | {:error, any()}
  def create_topic(name_or_pid, connection, topic_opts) do
    GenServer.call(name_or_pid, {:create_topic, connection, topic_opts})
  end

  @doc """
  Returns a topology struct representing the given process.
  """
  @spec get(GenServer.name() | pid()) :: t()
  def get(name_or_pid), do: GenServer.call(name_or_pid, :get)

  ################################
  # GenServer Callbacks
  ################################

  @doc false
  @impl GenServer
  @spec init(keyword()) :: {:ok, map()} | {:stop, any()}
  def init(opts) do
    with {:ok, opts} <- validate(opts, @opts_schema) do
      opts
      |> Keyword.get(:connection, Franz.get_connection())
      |> create_topics(Keyword.get(opts, :topics))
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @doc false
  @impl GenServer
  @spec handle_call(atom() | tuple(), GenServer.from(), map()) :: {:reply, t(), map()}
  def handle_call(:get, _from, state), do: {:reply, struct(__MODULE__, state), state}

  def handle_call({:create_topic, connection, topic_opts}, _from, state) do
    case do_create_topic(connection, topic_opts, state) do
      {:ok, state} ->
        topic = serialize_topic(topic_opts)
        {:reply, {:ok, topic}, state}

      error ->
        {:reply, error, state}
    end
  end

  ################################
  # Private API
  ################################

  defp create_topics(connection, topics_opts, state \\ %{topics: []})
  defp create_topics(_, [], state), do: {:ok, state}

  defp create_topics(connection, [topic_opts | topics_opts], state) do
    case do_create_topic(connection, topic_opts, state) do
      {:ok, state} -> create_topics(connection, topics_opts, state)
      {:error, reason} -> {:stop, reason}
    end
  end

  defp do_create_topic(connection, topic_opts, state, timeout \\ 5_000) do
    with {:ok, topic_opts} <- validate(topic_opts, @topic_opts_schema) do
      topic = serialize_topic_opts(topic_opts)
      req_opts = %{timeout: timeout}

      case :brod.create_topics(connection.endpoints, [topic], req_opts, connection.config) do
        :ok -> {:ok, update_state(topic_opts, state)}
        error -> error
      end
    end
  end

  defp serialize_topic_opts(config) do
    %{
      assignments: Keyword.get(config, :assignments, []),
      configs: serialize_topic_configs(Keyword.get(config, :configs, [])),
      name: Keyword.get(config, :name),
      num_partitions: Keyword.get(config, :num_partitions),
      replication_factor: Keyword.get(config, :replication_factor)
    }
  end

  defp serialize_topic_configs(configs) do
    Enum.map(configs, fn {key, val} -> %{name: key, value: to_string(val)} end)
  end

  defp update_state(topic_opts, state) do
    topic = serialize_topic(topic_opts)
    topics = [topic | state.topics]
    Map.put(state, :topics, topics)
  end

  defp serialize_topic(topic_opts), do: Topic.new(topic_opts)
end
