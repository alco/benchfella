defmodule Mix.Tasks.Bench.Cmp do
  use Mix.Task

  @shortdoc "Compare benchmark snapshots"

  @moduledoc """
  ## Usage

      mix bench.cmp [options] <snapshot>...

  ## Description

  A snapshot is the output of a single run of `mix bench` without the
  `--pretty` flag.

  When given one snapshot, `mix bench.cmp` will pretty-print the results.

  When given two or more snapshots, it will pretty-print the comparison between
  the first and the last one.

  ## Options

      -o=<fmt>, --output=<fmt>
          Output format. One of: pretty, json.

          The json format can be fed into `mix bench.graph`.

      -f=<fmt>, --format=<fmt>
          Which format to use for the deltas when pretty-printing.

          One of: ratio, percent.
  """

  def run(args) do
    switches = [output: :string, format: :string]
    aliases = [o: :output, f: :format]
    {snapshots, options} =
      case OptionParser.parse(args, strict: switches, aliases: aliases) do
        {opts, [], []} ->
          {["-"], opts}
        {opts, snapshots, []} ->
          {snapshots, opts}
        {_, _, [{opt, val}|_]} ->
          valstr = if val do "=#{val}" end
          Mix.raise "Invalid option: #{opt}#{valstr}"
      end
      |> normalize_options()

    case Map.get(options, :output, :pretty) do
      :pretty ->
        case snapshots do
          [snapshot] -> pretty_print(snapshot)
          [first|rest] ->
            last = List.last(rest)
            compare(first, last, Map.get(options, :format, :ratio))
        end
      :json ->
        to_json(List.wrap(snapshots))
    end
  end

  defp normalize_options({snapshots, options}) do
    options =
      Enum.reduce(options, %{}, fn
        {:output, fmt}, acc -> Map.put(acc, :output, parse_output_format(fmt))
        {:format, fmt}, acc -> Map.put(acc, :format, parse_pretty_format(fmt))
      end)
    {snapshots, options}
  end

  defp parse_output_format("pretty"), do: :pretty
  defp parse_output_format("json"), do: :json
  defp parse_output_format(other), do: Mix.raise "Undefined output format: #{other}"

  defp parse_pretty_format("ratio"), do: :ratio
  defp parse_pretty_format("percent"), do: :percent
  defp parse_pretty_format(other), do: Mix.raise "Undefined pretty format: #{other}"

  alias Benchfella.Snapshot

  defp pretty_print("-") do
    read_all_input() |> Snapshot.parse |> do_pretty_print
  end

  defp pretty_print(path) do
    path |> File.read! |> Snapshot.parse |> do_pretty_print
  end

  defp do_pretty_print(%Snapshot{tests: tests}) do
    {tests, max_len} = Enum.map_reduce(tests, 0, fn {mod, test, _, iter, elapsed}, max_len ->
      name = bench_name(mod, test)
      len = String.length(name)
      { {name, iter, elapsed}, max(len, max_len)}
    end)

    tests
    |> Enum.sort(fn {_, iter1, elapsed1}, {_, iter2, elapsed2} ->
      elapsed1/iter1 < elapsed2/iter2
    end)
    |> Enum.each(fn {name, n, elapsed} ->
      musec = elapsed / n
      name = [name, ?:]
      :io.format('~*.s ~10B   ~.2f µs/op~n', [-max_len-1, name, n, musec])
    end)
  end

  defp bench_name(mod, test), do: "#{mod}.#{test}"

  defp read_all_input() do
    read_all_input([])
  end

  defp read_all_input(lines) do
    case IO.binread(:line) do
      :eof ->
        lines |> Enum.reverse |> Enum.join("")
      {:error, reason} ->
        Mix.raise "Error reading from input: #{inspect reason}"
      line ->
        read_all_input([line|lines])
    end
  end

  defp compare(path1, path2, format) do
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
      colordiff = IO.ANSI.escape "#{color}#{diff}"
      IO.puts colordiff
    end)

    unless leftover == [] do
      IO.puts "Non-matching benches:"
      Enum.each(leftover, fn x -> IO.write "  "; IO.puts x end)
    end
  end

  defp choose_color(diff, :ratio) do
    cond do
      diff < 1.0 -> "%{green}"
      diff > 1.0 -> "%{red}"
      true -> nil
    end
  end

  defp choose_color(diff, :percent) do
    cond do
      diff < 0 -> "%{green}"
      diff > 0 -> "%{red}"
      true -> nil
    end
  end

  defp to_json(paths) do
    paths
    |> Enum.map(fn path ->
      {path, path |> File.read! |> Snapshot.parse}
    end)
    |> Enum.map(fn {name, snapshot} ->
      ~s("#{name}": #{Snapshot.to_json(snapshot)})
    end)
    |> Enum.join(",")
  end
end
