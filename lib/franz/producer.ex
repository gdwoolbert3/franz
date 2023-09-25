defmodule Franz.Producer do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - configure sync opts for producing

  alias Franz.Producer.Pool

  ################################
  # Public API
  ################################

  @doc """
  TODO(Gordon) - Add this
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    Pool.start_link(opts)
  end

  @doc """
  TODO(Gordon) - fix terminology here
  Publishes value to the specified topic.

  TODO(Gordon) - better spec here
  """
  @spec produce(binary(), binary(), :brod.value()) :: :ok | {:error, any()}
  def produce(topic, key, value) do
    :poolboy.transaction(:producer_pool, fn producer ->
      client_id = GenServer.call(producer, :client_id)
      do_produce(client_id, topic, key, value)
    end)
  end

  ################################
  # Private API
  ################################

  defp do_produce(client_id, topic, key, value) do
    :brod.produce_sync(client_id, topic, :random, key, value)
  end
end
