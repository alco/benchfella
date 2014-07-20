defmodule Mix.Tasks.Bench.Graph do
  use Mix.Task

  @shortdoc "Produce an HTML page with graphs built from given snapshots"

  @moduledoc """
  ## Usage

      mix bench.graph [options] <snapshot>...

  Takes one or more snapshots and produces and HTML page with graphs. For a
  single snapshot it builds some overview graphs. For multiple snapshots, it
  groups related tests together and also shows deltas.

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

    graph_dir_path = "bench/graphs"
    graph_path = Path.join([graph_dir_path, "index.html"])
    File.mkdir_p(graph_dir_path)
    File.write!(graph_path, index(snapshots_json))
    IO.puts "Wrote #{graph_path}"
  end

  @app Mix.Project.config[:app]

  require EEx
  path = Path.join([List.to_string(:code.priv_dir(@app)), "templates", "index.html.eex"])
  EEx.function_from_file :def, :index, path, [:json]
end

