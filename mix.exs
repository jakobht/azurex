defmodule Azurex.MixProject do
  use Mix.Project

  def project do
    [
      app: :azurex,
      version: "0.1.5",
      elixir: "~> 1.9",
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
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:httpoison, "~> 1.6"},
      {:timex, "~> 3.7"}
    ]
  end

  defp description do
    "Implementation of the Azure Blob storage rest API."
  end

  defp package do
    [
      licenses: ["Apache-2.0", "MIT"],
      links: %{"GitHub" => "https://github.com/jakobht/azurex"}
    ]
  end
end
