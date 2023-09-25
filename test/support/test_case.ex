defmodule Franz.TestCase do
  @moduledoc """
  This module defines the setup for this library's tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Franz.TestCase
    end
  end
end
