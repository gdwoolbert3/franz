defmodule Franz.Topology.Topic.Config do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  @enforce_keys [:name, :value]
  defstruct [:name, :value]

  @type value :: boolean() | integer() | binary() | nil
  @type t :: %__MODULE__{name: binary(), value: value()}

  ################################
  # Public API
  ################################

  @doc """
  Creates a Config struct from a name, value tuple.
  """
  @spec from_tuple(tuple()) :: t()
  def from_tuple({name, value}) do
    %__MODULE__{name: name, value: convert_value(value)}
  end

  ################################
  # Private API
  ################################

  defp convert_value(""), do: nil
  defp convert_value("true"), do: true
  defp convert_value("false"), do: false

  defp convert_value(value) do
    String.to_integer(value)
  rescue
    ArgumentError -> value
  end
end
