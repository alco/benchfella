defmodule Benchfella.Mixfile do
  use Mix.Project

  @source_url "https://github.com/alco/benchfella"
  @version "0.3.5"

  def project do
    [
      app: :benchfella,
      version: @version,
      elixir: "~> 1.3",
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      applications: [],
      extra_applications: [:eex]
    ]
  end

  defp package do
    [
      description: "Microbenchmarking tool for Elixir.",
      files: ["lib", "priv", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Alexei Sholik"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp deps do
    [{:ex_doc, "> 0.0.0", only: :dev, runtime: false}]
  end

  defp docs do
    [
      extras: [{:LICENSE, [title: "License"]}, "README.md"],
      main: "readme",
      source_url: @source_url,
      assets: "assets",
      formatters: ["html"]
    ]
  end
end
