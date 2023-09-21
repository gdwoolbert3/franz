defmodule Franz.MixProject do
  use Mix.Project

  @version "0.1.0"

  # TODO(Gordon) - package stuff
  # TODO(Gordon) - docs stuff
  # TODO(Gordon) - aliases (specifically, ci in test env)

  def project do
    [
      app: :franz,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      name: "Franz"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    A user-friendly Kafka library for Elixir.
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end