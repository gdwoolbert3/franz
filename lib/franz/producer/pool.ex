defmodule Franz.Producer.Pool do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - Terminology (server -> client)?
  # TODO(Gordon) - Better declaration of pool opts

  alias Franz.Producer.Server

  @pool_opts [
    pool_name: :franz_producer_pool,
    pool_size: 3,
    max_overflow: 0,
    strategy: :lifo,
    worker_module: Server
  ]

  ################################
  # Public API
  ################################

  @doc """
  Starts the producer server pool
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    worker_opts = Keyword.drop(opts, [:pool_name, :pool_size, :max_overflow, :strategy])
    :poolboy.start_link(@pool_opts, worker_opts)
  end
end
