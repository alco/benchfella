defmodule Benchfella.Mixfile do
  use Mix.Project

  def project do
    [
      app: :benchfella,
      version: "0.3.3",
      elixir: "~> 1.0",
      description: description(),
      package: package(),
      deps: deps(),
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

  defp deps do
    [{:ex_doc, "> 0.0.0", only: :dev}]
  end
end
