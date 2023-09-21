defmodule FranzTest do
  use ExUnit.Case
  doctest Franz

  test "greets the world" do
    assert Franz.hello() == :world
  end
end
