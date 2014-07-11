defmodule Mix.Tasks.Bench.Cmp do
  use Mix.Task

  @shortdoc "Compare benchmark snapshots"

  @moduledoc """
  Usage:

    mix bench.cmp [options] <snapshot1> <snapshot2>

  Options:

    -f=<fmt>, --format=<fmt>
        Which format to use for the difference. One of: ratio, percent.
  """

  def run(args) do
    case OptionParser.parse(args, strict: [format: :string], aliases: [f: :format]) do
      {opts, [snapshot1, snapshot2], []} ->
        compare(snapshot1, snapshot2, parse_format(Keyword.get(opts, :format, "ratio")))
      {_, _, []} ->
        Mix.raise "Expected exactly two arguments"

      {_, _, [{opt, val}|_]} ->
        valstr = if val do "=#{val}" end
        Mix.raise "Invalid option: #{opt}#{valstr}"
    end
  end

  defp parse_format("ratio"), do: :ratio
  defp parse_format("percent"), do: :percent
  defp parse_format(other), do: Mix.raise "Undefined format: #{other}"

  alias Benchfella.Snapshot

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
end
