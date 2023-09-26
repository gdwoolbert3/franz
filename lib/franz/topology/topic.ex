defmodule Franz.Topology.Topic do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  alias Franz.Topology

  @enforce_keys [:name, :num_partitions, :replication_factor, :configs]
  defstruct [:name, :num_partitions, :replication_factor, :configs]

  @type config :: {name :: binary(), value :: any(), status :: :assumed | :confirmed}

  @type t :: %__MODULE__{
          name: binary(),
          num_partitions: pos_integer(),
          replication_factor: pos_integer(),
          configs: [config()]
        }

  ################################
  # Public API
  ################################

  @spec new(Topology.topic_create_config()) :: t()
  def new(config) do
    %__MODULE__{
      name: Keyword.get(config, :name),
      num_partitions: Keyword.get(config, :num_partitions),
      replication_factor: Keyword.get(config, :replication_factor),
      configs: serialize_configs(Keyword.get(config, :configs, []))
    }
  end

  ################################
  # Private API
  ################################

  defp serialize_configs(configs) do
    Enum.map(configs, fn {key, val} -> {key, val, :confirmed} end)
  end
end
