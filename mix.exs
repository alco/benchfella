defmodule Benchfella.Mixfile do
  use Mix.Project

  def project do
    [
      app: :benchfella,
      version: "0.3.2",
      elixir: "~> 1.0",
      description: description,
      package: package,
    ]
  end

  def application do
    [applications: []]
  end

  defp description do
    "Microbenchmarking tool for Elixir."
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Alexei Sholik"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/alco/benchfella",
      }
    ]
  end

  # no deps
  # --alco
end
