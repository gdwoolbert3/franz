defmodule Franz.MixProject do
  use Mix.Project

  @version "0.1.0"

  # TODO(Gordon) - package stuff
  # TODO(Gordon) - docs stuff
  # TODO(Gordon) - aliases (specifically, ci but in test env)

  def project do
    [
      app: :franz,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support/factories"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    """
    A user-friendly Kafka library for Elixir.
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:brod, "~> 3.16.5"},
      {:kafka_protocol, "~> 4.1.0"},
      {:keyword_validator, "~> 2.0.1"},
      {:poolboy, "~> 1.5.1"},
      {:ex_machina, "~> 2.7.0", only: [:dev, :test]},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13.0", only: [:dev, :test], runtime: false}
    ]
  end
end
