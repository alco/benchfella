defmodule Mix.Tasks.Bench.Graph do
  use Mix.Task

  @shortdoc "Produce an HTML page with graphs built from given snapshots"

  @moduledoc """
  ## Usage

      mix bench.graph [options] <snapshot>...

  Takes one or more snapshots and produces an HTML page with graphs. When more
  than one snapshot is given, it allows for grouping multiple runs of
  corresponding tests for comparison.

  ## Options

      --no-js
          Produce a single HTML file with no JavaScript and with all the CSS
          embedded within a `<style>` tag.

  """

  alias Benchfella.Snapshot
  alias Benchfella.CLI.Util

  def run(args) do
    switches = [no_js: :boolean]
    {snapshots, options} =
      case OptionParser.parse(args, strict: switches) do
        {opts, [], []} ->
          {["-"], opts}
        {opts, snapshots, []} ->
          {snapshots, opts}
        {_, _, [{opt, val}|_]} ->
          valstr = if val do "=#{val}" end
          Mix.raise "Invalid option: #{opt}#{valstr}"
      end

    make_graph(snapshots, Keyword.get(options, :no_js, false))
  end

  defp make_graph(["-"], no_js) do
    data = Util.read_all_input()
    do_make_graph([{"-", Snapshot.parse(data)}], no_js)
  end

  defp make_graph(paths, no_js) do
    snapshots = Enum.map(paths, fn path ->
      {path, path |> File.read! |> Snapshot.parse}
    end)
    do_make_graph(snapshots, no_js)
  end

  defp do_make_graph(snapshots, no_js) do
    snapshots |> Snapshot.snapshots_to_json |> make_index
  end

  defp make_index(json) do
    graph_dir_path = "bench/graphs"
    graph_path = Path.join([graph_dir_path, "index.html"])
    File.mkdir_p(graph_dir_path)
    html = index(json, File.read!("priv/ui.css"), File.read!("priv/ui.js"))
    File.write!(graph_path, html)
    IO.puts :stderr, "Wrote #{graph_path}"
  end

  @app Mix.Project.config[:app]

  require EEx
  path = Path.join([List.to_string(:code.priv_dir(@app)), "templates", "index.html.eex"])
  EEx.function_from_file :def, :index, path, [:json, :style, :javascript]
end
