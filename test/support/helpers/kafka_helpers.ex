defmodule Franz.KafkaHelpers do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  alias Franz.Connection

  ################################
  # Public API
  ################################

  @doc """
  Deletes all Kafka topics.
  """
  @spec delete_all_topics(Connection.endpoints()) :: {:ok, list()} | {:error, any()}
  def delete_all_topics(endpoints) do
    {:ok, metadata} = get_metadata(endpoints)
    topic_names = get_topic_names(metadata)

    case delete_topics(endpoints, topic_names) do
      :ok -> {:ok, topic_names}
      error -> error
    end
  end

  @doc """
  Deletes Kafka topics.
  """
  @spec delete_topics(Connection.endpoints(), list()) :: :ok | {:error, any()}
  def delete_topics(endpoints, topics) do
    :brod.delete_topics(endpoints, topics, 5_000)
  end

  @doc """
  Returns Kafka metadata.
  """
  @spec get_metadata(Connection.endpoints()) :: {:ok, map()} | {:error, any()}
  def get_metadata(endpoints), do: :brod.get_metadata(endpoints)

  ################################
  # Private API
  ################################

  defp get_topic_names(metadata) do
    Enum.map(metadata.topics, & &1.name)
  end
end
