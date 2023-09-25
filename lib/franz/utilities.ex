defmodule Franz.Utilities do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  ################################
  # Public API
  ################################

  @doc """
  Validates the given keyword matches the given schema.

  Designed for use in the context of a GenServer init call.
  """
  @spec validate_opts(keyword(), KeywordValidator.schema(), keyword()) ::
          {:ok, keyword} | {:stop, keyword()}
  def validate_opts(keyword, schema, opts \\ []) do
    case KeywordValidator.validate(keyword, schema, opts) do
      {:error, reason} -> {:stop, reason}
      {:ok, _} = result -> result
    end
  end
end
