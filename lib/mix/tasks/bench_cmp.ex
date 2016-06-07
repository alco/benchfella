defmodule Mix.Tasks.Bench.Cmp do
  use Mix.Task

  @shortdoc "Compare benchmark snapshots"

  @moduledoc """
  ## Usage

      mix bench.cmp [options] <snapshot>...

  A snapshot is the output of a single run of `mix bench`.

  If no arguments are given, bench.cmp will try to read one or two latest
  snapshots from the bench/snapshots directory.

  When given one snapshot, `mix bench.cmp` will pretty-print the results.
  Giving `-` instead of a file name will make bench.cmp read from standard
  input.

  When given two or more snapshots, it will pretty-print the comparison between
  the first and the last one.

  ## Options

      -d <fmt>, --diff=<fmt>
          Which format to use for the deltas when pretty-printing.

          One of: ratio, percent.
  """

  alias Benchfella.Snapshot
  alias Benchfella.CLI.Util

  @switches [diff: :string]
  @aliases [d: :diff]

  def run(args) do
    {snapshots, options} =
      case OptionParser.parse(args, strict: @switches, aliases: @aliases) do
        {opts, [], []} ->
          {Util.locate_snapshots(), opts}
        {opts, snapshots, []} ->
          {snapshots, opts}
        {_, _, [{opt, val}|_]} ->
          valstr = if val do "=#{val}" end
          Mix.raise "Invalid option: #{opt}#{valstr}"
      end
      |> normalize_options()

    case snapshots do
      [snapshot] -> pretty_print(snapshot)
      [first|rest] ->
        last = List.last(rest)
        compare(first, last, Map.get(options, :diff, :ratio))
    end
  end

  defp normalize_options({snapshots, options}) do
    options =
      Enum.reduce(options, %{}, fn
        {:diff, fmt}, acc -> Map.put(acc, :diff, parse_pretty_format(fmt))
      end)
    {snapshots, options}
  end

  defp parse_pretty_format("ratio"), do: :ratio
  defp parse_pretty_format("percent"), do: :percent
  defp parse_pretty_format(other), do: Mix.raise "Undefined diff format: #{other}"

  defp pretty_print("-") do
    Util.read_all_input() |> Snapshot.parse |> Snapshot.print(:plain)
  end

  defp pretty_print(path) do
    IO.puts "#{path}\n"
    File.read!(path) |> Snapshot.parse |> Snapshot.print(:plain)
  end

  defp compare(path1, path2, format) do
    IO.puts "#{path1} vs\n#{path2}\n"

    snapshot1 = File.read!(path1) |> Snapshot.parse()
    snapshot2 = File.read!(path2) |> Snapshot.parse()
    {grouped_diffs, leftover} = Snapshot.compare(snapshot1, snapshot2, format)

    max_name_len =
      grouped_diffs
      |> Enum.flat_map(fn {_, diffs} -> diffs end)
      |> Enum.reduce(0, fn {name, _}, len -> max(len, String.length(name)) end)

    Enum.each(grouped_diffs, fn {mod, diffs} ->
      IO.puts ["## ", mod]
      print_diffs(diffs, max_name_len, format)
      IO.puts ""
    end)

    unless leftover == [] do
      # FIXME: when more than 2 snapshots are given, this wording may be imprecise
      IO.puts "These tests appeared only in one of the snapshots:"
      Enum.each(leftover, fn {mod, test} -> IO.puts ["[", mod, "] ", test] end)
    end
  end

  defp print_diffs(diffs, max_name_len, format) do
    diffs
    |> Enum.sort(fn {_, diff1}, {_, diff2} -> diff1 < diff2 end)
    |> Enum.each(fn {name, diff} ->
      spacing = 3
      :io.format('~*.s ', [-max_name_len-spacing, name])
      color = choose_color(diff, format)
      diff = case format do
        :percent -> Snapshot.format_percent(diff)
        _        -> diff
      end
      colordiff = IO.ANSI.format color ++ ["#{diff}"]
      IO.puts colordiff
    end)
  end

  defp choose_color(diff, :ratio) do
    cond do
      diff < 1.0 -> [:green]
      diff > 1.0 -> [:red]
      true -> []
    end
  end

  defp choose_color(diff, :percent) do
    cond do
      diff < 0 -> [:green]
      diff > 0 -> [:red]
      true -> []
    end
  end
end
