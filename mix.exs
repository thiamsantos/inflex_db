defmodule InflexDB.MixProject do
  use Mix.Project

  def project do
    [
      app: :inflex_db,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir client for InfluxDB",
      package: package(),
      name: "InflexDB",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp package do
    [
      maintainers: ["Thiago Santos"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/thiamsantos/inflex_db"}
    ]
  end

  defp docs do
    [
      main: "InflexDB",
      source_url: "https://github.com/thiamsantos/inflex_db"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1", optional: true},
      {:jose, "~> 1.10", optional: true},
      {:bypass, "~> 1.0", only: :test},
      {:mox, "~> 0.5.2", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
