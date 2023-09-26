defmodule Franz.Utilities do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  ################################
  # Public API
  ################################

  @doc """
  Validates the given keyword matches the given schema.
  """
  @spec validate(keyword(), KeywordValidator.schema(), keyword()) ::
          {:ok, keyword} | {:error, KeywordValidator.invalid()}
  def validate(keyword, schema, opts \\ []) do
    KeywordValidator.validate(keyword, schema, opts)
  end
end
