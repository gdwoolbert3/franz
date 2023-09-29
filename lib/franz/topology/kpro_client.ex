defmodule Franz.Topology.KProClient do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - This as a process? In the Topology process state?
  # TODO(Gordon) - Add auth support

  alias Franz.Connection

  @api_versions [
    alter_topic_configs: 1,
    create_topic_partitions: 1,
    describe_topic_configs: 2
  ]

  @timeout 5_000
  @topic_resource_type 2

  ################################
  # Public API
  ################################

  @doc """
  Alters the given Kafka topic's configs.
  """
  @spec alter_topic_configs(:kpro.connection(), binary(), map()) :: :ok | {:error, any()}
  def alter_topic_configs(kpro_conn, topic_name, configs) do
    topic_name
    |> build_alter_topic_configs_request(configs)
    |> execute_request(kpro_conn)
    |> case do
      {:ok, msg} -> parse_alter_topic_configs_message(msg)
      error -> error
    end
  end

  @doc """
  Closes the given Kafka Protocol connection.
  """
  @spec close_connection(:kpro.connection()) :: :ok
  def close_connection(kpro_conn), do: :kpro.close_connection(kpro_conn)

  @doc """
  Creates partitions for the given Kafka topic.
  """
  @spec create_topic_partitions(:kpro.connection(), binary(), pos_integer(), list()) ::
          :ok | {:error, any()}
  def create_topic_partitions(kpro_conn, topic_name, partitions, assignments) do
    topic_name
    |> build_create_topic_partitions_request(partitions, assignments)
    |> execute_request(kpro_conn)
    |> case do
      {:ok, msg} -> parse_create_topic_partitions_message(msg)
      error -> error
    end
  end

  @doc """
  Describes the given Kafka topic's configs.
  """
  @spec describe_topic_configs(:kpro.connection(), binary(), [binary()]) ::
          {:ok, map()} | {:error, any()}
  def describe_topic_configs(kpro_conn, topic_name, config_names \\ []) do
    topic_name
    |> build_describe_topic_configs_request(config_names)
    |> execute_request(kpro_conn)
    |> case do
      {:ok, msg} -> parse_describe_topic_configs_message(msg)
      error -> error
    end
  end

  @doc """
  Creates a Kafka Protocol connection.
  """
  @spec get_connection(Connection.t()) :: {:ok, :kpro.connection()} | {:error, any()}
  def get_connection(conn), do: :kpro.connect_any(conn.endpoints, [])

  ################################
  # Private API
  ################################

  defp build_alter_topic_configs_request(topic_name, configs) do
    configs =
      Enum.map(configs, fn {key, val} ->
        %{config_name: key, config_value: to_string(val)}
      end)

    :kpro_req_lib.alter_configs(
      Keyword.get(@api_versions, :alter_topic_configs),
      [
        %{
          resource_type: @topic_resource_type,
          resource_name: topic_name,
          config_entries: configs
        }
      ],
      %{validate_only: false}
    )
  end

  defp parse_alter_topic_configs_message(message) do
    [%{error_code: error_code}] = message.resources

    case error_code do
      :no_error -> :ok
      code -> {:error, code}
    end
  end

  defp build_create_topic_partitions_request(topic_name, partitions, asignments) do
    :kpro_req_lib.create_partitions(
      Keyword.get(@api_versions, :create_topic_partitions),
      [
        %{
          topic: topic_name,
          new_partitions: %{assignment: asignments, count: partitions}
        }
      ],
      %{timeout: @timeout, validate_only: false}
    )
  end

  defp parse_create_topic_partitions_message(message) do
    [%{error_code: error_code}] = message.topic_errors

    case error_code do
      :no_error -> :ok
      code -> {:error, code}
    end
  end

  defp build_describe_topic_configs_request(topic_name, config_names) do
    :kpro_req_lib.describe_configs(
      Keyword.get(@api_versions, :describe_topic_configs),
      [
        %{
          resource_type: @topic_resource_type,
          resource_name: topic_name,
          config_names: config_names
        }
      ],
      %{include_synonyms: false}
    )
  end

  defp parse_describe_topic_configs_message(message) do
    [%{error_code: error_code, config_entries: configs}] = message.resources

    case error_code do
      :no_error ->
        configs =
          configs
          |> Enum.map(fn config -> {config.config_name, config.config_value} end)
          |> Enum.into(%{})

        {:ok, configs}

      code ->
        {:error, code}
    end
  end

  defp execute_request(request, kpro_conn) do
    kpro_conn
    |> :kpro.request_sync(request, @timeout)
    |> case do
      {:ok, {_, _, _, _, msg}} -> {:ok, msg}
      error -> error
    end
  end
end
