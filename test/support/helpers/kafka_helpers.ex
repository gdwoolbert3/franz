defmodule Franz.KafkaHelpers do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  alias Franz.Connection

  ################################
  # Public API
  ################################

  @doc """
  Deletes all Kafka topics
  """
  @spec delete_all_topics(Connection.endpoints()) :: {:ok, list()} | {:error, any()}
  def delete_all_topics(hosts) do
    {:ok, metadata} = get_metadata(hosts)
    topic_names = get_topic_names(metadata)

    case delete_topics(hosts, topic_names) do
      :ok -> {:ok, topic_names}
      error -> error
    end
  end

  @doc """
  Deletes Kafka topics
  """
  @spec delete_topics(Connection.endpoints(), list()) :: :ok | {:error, any()}
  def delete_topics(hosts, topics) do
    :brod.delete_topics(hosts, topics, 5_000)
  end

  @doc """
  Returns Kafka metadata
  """
  @spec get_metadata(Connection.endpoints()) :: {:ok, map()} | {:error, any()}
  def get_metadata(hosts), do: :brod.get_metadata(hosts)

  @doc """
  Returns the test environment endpoints
  """
  @spec hosts :: Connection.endpoints()
  def hosts, do: [{"localhost", 9094}]

  @doc """
  Returns the test environment URI
  """
  @spec uri :: binary()
  def uri, do: System.fetch_env!("FRANZ_KAFKA_URI")

  ################################
  # Private API
  ################################

  defp get_topic_names(metadata) do
    Enum.map(metadata.topics, & &1.name)
  end
end
