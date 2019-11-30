defmodule Azurex.MixProject do
  use Mix.Project

  def project do
    [
      app: :azurex,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:httpoison, "~> 1.6"},
      {:timex, "~> 3.6"}
    ]
  end
end
