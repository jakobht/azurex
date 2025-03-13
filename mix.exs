defmodule Azurex.MixProject do
  use Mix.Project

  def project do
    [
      app: :azurex,
      version: "1.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "AzureX",
      source_url: "https://github.com/jakobht/azurex"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:bypass, "~> 2.1", only: :test},
      {:httpoison, "~> 1.8 or ~> 2.2"},
      {:jason, "~> 1.4.4"}
    ]
  end

  defp description do
    "Implementation of the Azure Blob storage rest API."
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["Apache-2.0", "MIT"],
      links: %{"GitHub" => "https://github.com/jakobht/azurex"}
    ]
  end
end
