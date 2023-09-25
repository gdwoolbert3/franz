defmodule Franz do
  @moduledoc """
  TODO(Gordon) - Add this
  TODO(Gordon) - supervisor init type spec
  """

  use Supervisor

  alias Franz.Connection

  ################################
  # Public API
  ################################

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
    children = [
      {Connection, Keyword.get(opts, :connection, [])}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
