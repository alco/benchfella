defmodule Benchfella.Mixfile do
  use Mix.Project

  def project do
    [app: :benchfella,
     version: "0.0.2",
     elixir: ">= 0.15.0 and < 2.0.0"]
  end

  def application do
    [applications: []]
  end

  # no deps
  # --alco
end
