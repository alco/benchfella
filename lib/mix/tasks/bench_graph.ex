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

    chart_dir_path = "bench/charts"
    chart_path = Path.join([chart_dir_path, "index.html"])
    File.mkdir_p(chart_dir_path)
    File.write!(chart_path, index(snapshots_json))
    IO.puts "Wrote #{chart_path}"
  end

  @app Mix.Project.config[:app]

  require EEx
  path = Path.join([List.to_string(:code.priv_dir(@app)), "templates", "index.html.eex"])
  EEx.function_from_file :def, :index, path, [:json]
end

