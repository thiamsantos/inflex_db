defmodule InflexDB.MixProject do
  use Mix.Project

  def project do
    [
      app: :inflex_db,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1", optional: true},
      {:jose, "~> 1.10", optional: true}
    ]
  end
end
