defmodule Franz.TestCase do
  @moduledoc """
  This module defines the setup for this library's tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Franz.{KafkaHelpers, TestCase}
    end
  end

  @doc """
  Starts a non-process module with a `start_link/1` function
  """
  @spec start_module_supervised!(module(), keyword()) :: pid()
  def start_module_supervised!(module, opts) do
    start_supervised!(%{id: module, start: {module, :start_link, [opts]}})
  end
end
