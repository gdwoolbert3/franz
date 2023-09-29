defmodule Franz do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - supervisor init type spec
  # TODO(Gordon) - expose Topology functions
  # TODO(Gordon) - Add standardized errors

  use Supervisor

  alias Franz.{Connection, Topology}

  ################################
  # Public API
  ################################

  @doc """
  Starts the Franz supervisor
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns the broker's connection struct.
  """
  @spec get_connection :: Connection.t()
  def get_connection, do: Connection.get(Connection)

  ################################
  # Supervisor Callbacks
  ################################

  @doc false
  @impl Supervisor
  def init(opts \\ []) do
    children = [{Connection, Keyword.get(opts, :connection, [])}]
    children = maybe_with_topology(children, opts)

    Supervisor.init(children, strategy: :one_for_one)
  end

  ################################
  # Private API
  ################################

  defp maybe_with_topology(children, opts) do
    case Keyword.get(opts, :topology) do
      nil -> children
      topology_opts -> children ++ [{Topology, topology_opts}]
    end
  end
end
