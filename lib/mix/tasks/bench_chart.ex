defmodule Mix.Tasks.Bench.Chart do
  use Mix.Task

  @shortdoc "Produce an HTML page with charts built from given snapshots"

  @moduledoc """
  ## Usage

      mix bench.chart [options] <snapshot>...

  ## Options

  """

  alias Benchfella.Snapshot

  def run(args) do
    [path] = args
    snapshot = Snapshot.parse(File.read!(path))
    Snapshot.to_json(snapshot) |> IO.puts
  end
end

