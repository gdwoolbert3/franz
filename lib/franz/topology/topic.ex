defmodule Franz.Topology.Topic do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  alias Franz.Topology.Topic.{Config, Partition}

  @enforce_keys [:error_code, :is_internal, :name, :partitions, :configs]
  defstruct [:error_code, :is_internal, :name, :partitions, :configs]

  @type t :: %__MODULE__{
          error_code: atom(),
          is_internal: boolean(),
          name: binary(),
          partitions: [Partition] | :skipped,
          configs: [Config]
        }

  ################################
  # Public API
  ################################

  @doc """
  Creates a Topic struct from a map of params and a map of configs.
  """
  @spec from_map(map(), map()) :: t()
  def from_map(map, configs \\ %{}) do
    %__MODULE__{
      error_code: map.error_code,
      is_internal: map.is_internal,
      name: map.name,
      partitions: build_partitions(map.partitions),
      configs: build_configs(configs)
    }
  end

  ################################
  # Private API
  ################################

  defp build_configs(%{}), do: :skipped

  defp build_configs(configs) do
    Enum.map(configs, &Config.from_tuple/1)
  end

  defp build_partitions(partitions) do
    Enum.map(partitions, &Partition.from_map/1)
  end
end
