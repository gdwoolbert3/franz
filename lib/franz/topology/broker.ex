defmodule Franz.Topology.Broker do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  @enforce_keys [:host, :node_id, :port, :rack]
  defstruct [:host, :node_id, :port, :rack]

  @type t :: %__MODULE__{
          host: binary(),
          node_id: non_neg_integer(),
          port: non_neg_integer(),
          rack: binary()
        }

  ################################
  # Public API
  ################################

  @doc """
  Creates a Broker struct from a map of params.
  """
  @spec from_map(map()) :: t()
  def from_map(map), do: struct(__MODULE__, map)
end
