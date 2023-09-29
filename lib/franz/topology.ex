defmodule Franz.Topology do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - add partitions / alter configs
  # TODO(Gordon) - Add connection to opts schema
  # TODO(Gordon) - metadata refresh for producers?
  # TODO(Gordon) - Add support for sasl with kpro
  # TODO(Gordon) - Check configs? In topology module?

  use GenServer

  import Franz.Utilities

  alias Franz.Connection
  alias Franz.Topology.{Broker, KProClient, Topic}

  @enforce_keys [:brokers, :cluster_id, :controller_id, :topics]
  defstruct [:brokers, :cluster_id, :controller_id, :topics]

  @type topic_opts :: keyword()
  @type t :: %__MODULE__{
          brokers: [Broker.t()],
          cluster_id: binary(),
          controller_id: non_neg_integer(),
          topics: [Topic.t()]
        }

  @dynamic_topic_configs [
    "cleanup.policy",
    "flush.messages",
    "flush.ms",
    "max.message.bytes",
    "min.insync.replicas",
    "retention.bytes",
    "retention.ms",
    "segment.bytes",
    "segment.jitter.ms",
    "segment.ms",
    "unclean.leader.election.enable"
  ]

  @timeout 5_000

  @topic_opts_schema KeywordValidator.schema!(
                       assignments: [is: :list, required: false],
                       configs: [is: :map, required: false],
                       name: [is: :binary, required: true],
                       num_partitions: [is: :integer, required: true],
                       replication_factor: [is: :integer, required: true]
                     )

  @opts_schema KeywordValidator.schema!(
                 connection: [is: :struct, required: false],
                 topics: [is: :list, required: true]
               )

  @partition_opts_schema KeywordValidator.schema!(
                           new_partitions: [is: :integer, required: true],
                           assignments: [is: :list, required: false]
                         )

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
  Alters the topics of the given Kafka topic.
  """
  @spec alter_topic_configs(GenServer.name() | pid(), Connection.t(), binary(), map()) ::
          :ok | {:error, any()}
  def alter_topic_configs(name_or_pid, _conn, topic_name, configs) do
    GenServer.call(name_or_pid, {:alter, topic_name, configs})
  end

  @doc """
  Creates a Kafka topic.
  """
  @spec create_topic(Connection.t(), topic_opts()) :: :ok | {:error, any()}
  def create_topic(conn, topic_opts) do
    with {:ok, topic_opts} <- validate_keyword(topic_opts, @topic_opts_schema) do
      topic = serialize_topic_opts(topic_opts)
      req_opts = %{timeout: @timeout}
      :brod.create_topics(conn.endpoints, [topic], req_opts, conn.config)
    end
  end

  @spec create_topic_partitions(GenServer.name() | pid(), Connection.t(), binary(), keyword()) ::
          :ok | {:error, any()}
  def create_topic_partitions(name_or_pid, conn, topic_name, partition_opts) do
    GenServer.call(name_or_pid, {:partitions, conn, topic_name, partition_opts})
  end

  @doc """
  Deletes a Kafka topic.
  """
  @spec delete_topic(Connection.t(), binary()) :: :ok | {:error, any()}
  def delete_topic(conn, topic_name) do
    :brod.delete_topics(conn.endpoints, [topic_name], @timeout, conn.config)
  end

  @doc """
  Returns a Topology struct representing the given process.
  """
  @spec get(GenServer.name() | pid(), Connection.t()) :: {:ok, t()} | {:error, any()}
  def get(name_or_pid, conn), do: GenServer.call(name_or_pid, {:get, conn})

  @doc """
  Returns a Topic struct for the given Kafka topic.
  """
  @spec get_topic(GenServer.name() | pid(), Connection.t(), binary()) ::
          {:ok, Topic.t()} | {:error, any()}
  def get_topic(name_or_pid, conn, topic_name) do
    GenServer.call(name_or_pid, {:get_topic, conn, topic_name})
  end

  ################################
  # GenServer Callbacks
  ################################

  @doc false
  @impl GenServer
  @spec init(keyword()) :: {:ok, map()} | {:stop, any()}
  def init(opts) do
    conn = get_connection(opts)

    with {:ok, opts} <- validate_keyword(opts, @opts_schema),
         :ok <- create_topics(conn, Keyword.get(opts, :topics)),
         {:ok, kpro_conn} <- KProClient.get_connection(conn) do
      {:ok, %{kpro_conn: kpro_conn}}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @doc false
  @impl GenServer
  @spec handle_call(tuple(), GenServer.from(), map()) :: {:reply, any(), map()}
  def handle_call({:alter, topic_name, configs}, _from, state) do
    {:reply, do_alter_topic_configs(state.kpro_conn, topic_name, configs), state}
  end

  def handle_call({:get, conn}, _from, state) do
    response =
      case get_metadata(conn) do
        {:ok, metadata} -> {:ok, build_topology(metadata)}
        error -> error
      end

    {:reply, response, state}
  end

  def handle_call({:get_topic, conn, topic_name}, _from, state) do
    response =
      case get_metadata(conn, [topic_name]) do
        {:ok, %{topics: [params]}} -> build_topic_with_configs(params, state)
        error -> error
      end

    {:reply, response, state}
  end

  def handle_call({:partitions, conn, topic_name, opts}, _from, state) do
    {:reply, do_create_partitions(state.krpo_conn, conn, topic_name, opts), state}
  end

  @doc false
  @impl GenServer
  @spec terminate(any(), map()) :: :ok
  def terminate(_reason, state), do: KProClient.close_connection(state.kpro_conn)

  ################################
  # Private API
  ################################

  defp get_connection(opts) do
    case Keyword.get(opts, :connection) do
      nil -> Franz.get_connection()
      conn -> conn
    end
  end

  defp do_alter_topic_configs(kpro_conn, topic_name, configs) do
    case valid_alter_configs?(configs) do
      true -> KProClient.alter_topic_configs(kpro_conn, topic_name, configs)
      false -> {:error, :static_config}
    end
  end

  defp valid_alter_configs?(configs) do
    configs
    |> Map.keys()
    |> MapSet.new()
    |> MapSet.subset?(MapSet.new(@dynamic_topic_configs))
  end

  defp do_create_partitions(kpro_conn, conn, topic_name, opts) do
    with {:ok, opts} <- validate_keyword(opts, @partition_opts_schema),
         {:ok, new} <- validate_new_partitions(opts),
         {:ok, assignments} <- validate_assignments(opts, new),
         {:ok, %{topics: [topic_opts]}} <- get_metadata(conn, [topic_name]) do
      partitions = length(topic_opts.partitions) + new
      KProClient.create_topic_partitions(kpro_conn, topic_name, partitions, assignments)
    end
  end

  defp validate_new_partitions(opts) do
    case Keyword.get(opts, :new_partitions) do
      num when num < 1 -> {:error, :must_add_partitions}
      num -> {:ok, num}
    end
  end

  defp validate_assignments(opts, new) do
    assignments = Keyword.get(opts, :assignments)

    cond do
      assignments == nil -> {:ok, Enum.map(1..new, fn _ -> [0] end)}
      length(assignments) != new -> {:error, :invalid_assignments}
      true -> {:ok, assignments}
    end
  end

  defp create_topics(_, []), do: :ok

  defp create_topics(conn, [topic_opts | topics_opts]) do
    case create_topic(conn, topic_opts) do
      :ok -> create_topics(conn, topics_opts)
      error -> error
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

  defp get_metadata(conn, topic_names \\ :all) do
    :brod.get_metadata(conn.endpoints, topic_names, conn.config)
  end

  defp build_topology(metadata) do
    %__MODULE__{
      brokers: Enum.map(metadata.brokers, &Broker.from_map/1),
      cluster_id: metadata.cluster_id,
      controller_id: metadata.controller_id,
      topics: Enum.map(metadata.topics, &Topic.from_map/1)
    }
  end

  defp build_topic_with_configs(params, state) do
    case KProClient.describe_topic_configs(state.kpro_conn, params.name) do
      {:ok, configs} -> {:ok, Topic.from_map(params, configs)}
      error -> error
    end
  end
end
