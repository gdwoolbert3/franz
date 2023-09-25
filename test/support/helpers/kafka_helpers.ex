defmodule Franz.KafkaHelpers do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  ################################
  # Public API
  ################################

  @doc """
  Returns the default connection URI.
  """
  @spec default_connection_uri :: binary()
  def default_connection_uri do
    System.fetch_env!("FRANZ_KAFKA_URI")
  end
end
