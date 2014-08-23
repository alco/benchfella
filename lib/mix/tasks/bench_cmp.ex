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

      -f <fmt>, --format=<fmt>
          Which format to use for the deltas when pretty-printing.

          One of: ratio, percent.
  """

  alias Benchfella.Snapshot
  alias Benchfella.CLI.Util

  def run(args) do
    switches = [format: :string]
    aliases = [f: :format]
    {snapshots, options} =
      case OptionParser.parse(args, strict: switches, aliases: aliases) do
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
        compare(first, last, Map.get(options, :format, :ratio))
    end
  end

  defp normalize_options({snapshots, options}) do
    options =
      Enum.reduce(options, %{}, fn
        {:format, fmt}, acc -> Map.put(acc, :format, parse_pretty_format(fmt))
      end)
    {snapshots, options}
  end

  defp parse_pretty_format("ratio"), do: :ratio
  defp parse_pretty_format("percent"), do: :percent
  defp parse_pretty_format(other), do: Mix.raise "Undefined pretty format: #{other}"

  defp pretty_print("-") do
    Util.read_all_input() |> Snapshot.parse |> Snapshot.pretty_print
  end

  defp pretty_print(path) do
    IO.puts "#{path}\n"
    path |> File.read! |> Snapshot.parse |> Snapshot.pretty_print
  end

  defp compare(path1, path2, format) do
    IO.puts "#{path1} vs\n#{path2}\n"

    snapshot1 = File.read!(path1) |> Snapshot.parse()
    snapshot2 = File.read!(path2) |> Snapshot.parse()
    {diffs, leftover} = Snapshot.compare(snapshot1, snapshot2, format)

    max_len = Enum.reduce(diffs, 0, fn {name, _}, len -> max(len, String.length(name)) end)

    diffs
    |> Enum.sort(fn {_, diff1}, {_, diff2} -> diff1 < diff2 end)
    |> Enum.each(fn {name, diff} ->
      :io.format('~*.s ', [-max_len-1, name<>":"])
      color = choose_color(diff, format)
      if format == :percent do
        diff = Snapshot.format_percent(diff)
      end
      colordiff = IO.ANSI.format color ++ ["#{diff}"]
      IO.puts colordiff
    end)

    unless leftover == [] do
      # FIXME: when more than 2 snapshots are given, this wording may be imprecise
      IO.puts "\nThese tests appeared only in one of the snapshots:"
      Enum.each(leftover, fn x -> IO.write "  "; IO.puts x end)
    end
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
