defmodule HedwigMessenger.Mixfile do
  use Mix.Project

  def project do
    [app: :hedwig_messenger,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "A facebook messenger adapter for hedwig",
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  defp package do
    [
      maintainers: ["Erik Nilsen"],
      links: %{
        "GitHub" => "https://github.com/enilsen16/hedwig_messenger"
      },
      licenses: ["MIT"]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:cowboy, "~> 1.0", optional: true},
      {:hedwig, "~> 1.0"},
      {:httpoison, "~> 0.10"},
      {:plug, "~> 1.2", optional: true},
      {:poison, "~> 3.0"}
    ]
  end
end
