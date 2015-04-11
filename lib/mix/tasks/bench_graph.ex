defmodule Mix.Tasks.Bench.Graph do
  use Mix.Task

  @shortdoc "Produce an HTML page with graphs built from given snapshots"

  @moduledoc """
  ## Usage

      mix bench.graph [options] <snapshot>...

  Takes one or more snapshots and produces an HTML page with graphs. When more
  than one snapshot is given, it allows for grouping multiple runs of
  corresponding tests for comparison.

  If no arguments are given, bench.cmp will try to read one or two latest
  snapshots from the bench/snapshots directory.

  Giving `-` instead of a file name will make bench.cmp read from standard
  input.

  ## Options

      -n <number>
          Specify how many snapshots to compare. This option is only useful
          when no arguments are given.

          Default: 2.

      --no-js
          Produce a single HTML file with graphs rendered as SVG and no
          JavaScript on the page.

  """

  @app Mix.Project.config[:app]
  @priv_dir List.to_string(:code.priv_dir(@app))
  @ui_css File.read!(Path.join(@priv_dir, "ui.css"))
  @ui_js File.read!(Path.join(@priv_dir, "ui.js"))

  alias Benchfella.Snapshot
  alias Benchfella.CLI.Util

  def run(args) do
    switches = [no_js: :boolean, n: :integer]
    {snapshots, options} =
      case OptionParser.parse(args, strict: switches, aliases: [n: :n]) do
        {opts, [], []} ->
          count = Keyword.get(opts, :n, 2)
          {Util.locate_snapshots(count), opts}
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

  defp do_make_graph(snapshots, false) do
    snapshots |> Snapshot.snapshots_to_json |> make_index
  end

  defp do_make_graph(_snapshots, true) do
    Mix.raise "Not implemented yet (sorry)"
  end

  defp make_index(json) do
    graph_dir_path = "bench/graphs"
    graph_path = Path.join([graph_dir_path, "index.html"])
    File.mkdir_p(graph_dir_path)
    html = index(json, @ui_css, @ui_js)
    File.write!(graph_path, html)
    IO.puts :stderr, "Wrote #{graph_path}"
  end

  require EEx
  path = Path.join([@priv_dir, "templates", "index.html.eex"])
  EEx.function_from_file :def, :index, path, [:json, :style, :javascript]
end
