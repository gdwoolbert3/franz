defmodule Franz.Utilities do
  @moduledoc """
  TODO(Gordon) - Add this
  """

  # TODO(Gordon) - add tests?

  ################################
  # Public API
  ################################

  @doc """
  Validates the given keyword matches the given schema.
  """
  @spec validate_keyword(keyword(), KeywordValidator.schema(), keyword()) ::
          {:ok, keyword} | {:error, KeywordValidator.invalid()}
  def validate_keyword(keyword, schema, opts \\ []) do
    KeywordValidator.validate(keyword, schema, opts)
  end
end
