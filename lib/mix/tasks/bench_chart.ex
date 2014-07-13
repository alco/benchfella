defmodule Mix.Tasks.Bench.Chart do
  use Mix.Task

  @shortdoc "Produce an HTML page with charts built from given snapshots"

  @moduledoc """
  ## Usage

      mix bench.chart [options] <snapshot>...

  It takes one or more snapshot and produces and HTML page with the charts. For
  a single snapshot it builds some overview charts. For multiple snapshots, it
  groups related tests togather and also shows deltas.

  ## Options

  """

  alias Benchfella.Snapshot

  def run(args) do
    paths = args
    snapshots_json =
      paths
      |> Enum.map(fn path ->
        {path, path |> File.read! |> Snapshot.parse}
      end)
      |> Enum.map(fn {name, snapshot} ->
        ~s("#{name}": #{Snapshot.to_json(snapshot)})
      end)
      |> Enum.join(",")
    IO.puts "{#{snapshots_json}}"
  end
end

