defmodule Benchfella.Snapshot do
  alias __MODULE__
  defstruct options: %{}, tests: []

  @precision 2

  def parse(str) do
    [header, _titles | rest] = String.split(str, "\n")

    options =
      header
      |> String.split(";")
      |> Enum.map(&String.split(&1, ":"))
      |> Enum.map(fn [name, val] -> {name, parse_opt(name, val)} end)

    tests =
      rest
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.split(&1, ";"))
      |> Enum.map(fn [mod, test, tags, iter, elapsed] ->
        tags =
          String.split(tags, ",")
          |> Enum.map(&String.strip/1)
          |> Enum.reject(&(&1 == ""))
        iter = String.to_integer(iter)
        elapsed = String.to_integer(elapsed)
        {mod, test, tags, iter, elapsed}
      end)

    %Snapshot{options: Enum.into(options, %{}), tests: tests}
  end

  defp parse_opt("duration", val), do: String.to_float(val)
  defp parse_opt("mem stats", val), do: parse_bool(val)
  defp parse_opt("sys mem stats", val), do: parse_bool(val)

  defp parse_bool("false"), do: false
  defp parse_bool("true"), do: true

  def compare(%Snapshot{tests: tests1}, %Snapshot{tests: tests2}, format \\ :ratio) do
    {test_map1, name_set1} = extrace_test_names(tests1)
    {test_map2, name_set2} = extrace_test_names(tests2)
    common_tests = Set.intersection(name_set1, name_set2)
    diffs = Enum.reduce(common_tests, %{}, fn name, diffs ->
      {count, elapsed} = test_map1[name]
      result1 = elapsed / count

      {count, elapsed} = test_map2[name]
      result2 = elapsed / count

      Map.put(diffs, name, diff(result1, result2, format))
    end)
    {diffs, symm_diff(name_set1, name_set2) |> Enum.into([])}
  end

  defp extrace_test_names(tests) do
    Enum.reduce(tests, {%{}, HashSet.new}, fn {mod, test, _tags, iter, elapsed}, {map, set} ->
      name = bench_name(mod, test)
      {Map.put(map, name, {iter, elapsed}), Set.put(set, name)}
    end)
  end

  def format_percent(0.0) do
    "--"
  end

  def format_percent(num) do
    str = if num > 0 do <<?+>> else <<>> end
    str <> Float.to_string(num, decimals: @precision) <> "%"
  end

  defp diff(r1, r2, :ratio), do: Float.round(r2 / r1, @precision)
  defp diff(r1, r2, :percent), do: Float.round((r2 - r1) / r1 * 100, @precision)

  defp symm_diff(set1, set2) do
    Set.union(Set.difference(set1, set2), Set.difference(set2, set1))
  end


  def pretty_print(%Snapshot{tests: tests}) do
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


  alias Benchfella.Json

  def to_json(%Snapshot{tests: tests, options: options}) do
    """
    {
      "options": #{Json.encode(options)},
      "tests": #{json_encode_tests(tests)}
    }
    """
  end

  defp json_encode_tests(tests) do
    Enum.map(tests, fn {mod, test, tags, iter, elapsed} ->
      %{
        module: mod,
        test: test,
        tags: tags,
        iter: iter,
        elapsed: elapsed,
      }
    end)
    |> Json.encode()
  end
end
