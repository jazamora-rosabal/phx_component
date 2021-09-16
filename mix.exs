defmodule PhoenixComponents.Mixfile do
  use Mix.Project

  def project do
    [
      app: :phoenix_components,
      version: "0.1.0",
      elixir: "~> 1.7",
      deps: deps(),
      name: "Phoenix.Components",
      description: "Componentes para Phoenix Liveview",
      package: package()
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
      {:ex_doc, "~> 0.18", only: :docs},
      {:phoenix_live_view, "~> 0.11.0 or ~> 0.12.0 or ~> 0.13.0 or ~> 0.14.0 or ~> 0.15.0"},
      {:phoenix_html, "~> 2.11"},
      {:timex, "~> 3.7.6"}
    ]
  end

  defp package do
    [
      maintainers: ["Leonardo E. Reyna Castro"],
      licenses: ["MIT"],
      links: %{bitbucket: "https://bitbucket.org/teamdox/phoenix_components"},
      files: ~w(lib mix.exs README.md)
    ]
  end
end
