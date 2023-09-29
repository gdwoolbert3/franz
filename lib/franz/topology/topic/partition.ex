defmodule Franz.Topology.Topic.Partition do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  @enforce_keys [:error_code, :isr_nodes, :leader_id, :partition_index, :replica_nodes]
  defstruct [:error_code, :isr_nodes, :leader_id, :partition_index, :replica_nodes]

  @type t :: %__MODULE__{
          error_code: atom(),
          isr_nodes: [non_neg_integer()],
          leader_id: non_neg_integer(),
          partition_index: non_neg_integer(),
          replica_nodes: [non_neg_integer()]
        }

  ################################
  # Public API
  ################################

  @doc """
  Creates a Partition struct from a map of params.
  """
  @spec from_map(map()) :: t()
  def from_map(map), do: struct(__MODULE__, map)
end
