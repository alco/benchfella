defmodule Benchfella.Snapshot do
  defstruct options: %{}, tests: []

  @precision 2

  alias __MODULE__
  alias Benchfella.Json

  def prepare(duration, mem_stats?, sys_mem_stats?, results) do
    ["duration:", "#{duration};",
     "mem stats:", "#{mem_stats?};",
     "sys mem stats:", "#{sys_mem_stats?}",
     "\nmodule;test;tags;iterations;elapsed\n",
    ] ++ Enum.map(results, fn
      {{mod, fun}, {iter, elapsed, _mem_stats}} ->
        '~s\t~s\t\t~B\t~B~n'
        |> :io_lib.format([inspect(mod), "#{fun}", iter, elapsed])
      _otherwise -> ""
    end)
  end

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
      |> Enum.map(&String.split(&1, "\t"))
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
    {test_map1, name_set1} = extract_test_names(tests1)
    {test_map2, name_set2} = extract_test_names(tests2)
    common_tests = Set.intersection(name_set1, name_set2)
    diffs = Enum.reduce(common_tests, %{}, fn key, diffs ->
      {count, elapsed} = test_map1[key]
      result1 = elapsed / count

      {count, elapsed} = test_map2[key]
      result2 = elapsed / count

      Map.put(diffs, key, diff(result1, result2, format))
    end)
    grouped_diffs = Enum.reduce(diffs, %{}, fn {{mod, test}, diff}, groups ->
      Map.update(groups, mod, Map.put(%{}, test, diff), &Map.put(&1, test, diff))
    end)
    {grouped_diffs, symm_diff(name_set1, name_set2) |> Enum.into([])}
  end

  defp extract_test_names(tests) do
    Enum.reduce(tests, {%{}, HashSet.new}, fn {mod, test, _tags, iter, elapsed}, {map, set} ->
      name = {mod, test}
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
    {tests, max_name_len} =
      Enum.map_reduce(tests, 0, fn {mod_name, test_name, _, iter, elapsed}, max_len ->
        len = String.length(test_name)
        {{mod_name, test_name, iter, elapsed}, max(len, max_len)}
      end)
    groups = Enum.group_by(tests, &elem(&1, 0))
    Enum.each(groups, fn {group_name, tests} ->
      IO.puts ["## ", group_name]
      tests = Enum.map(tests, fn {_, test_name, iter, elapsed} -> {test_name, iter, elapsed} end)
      pretty_print_group(tests, max_name_len)
    end)
  end

  defp pretty_print_group(tests, max_name_len) do
    tests
    |> Enum.sort(fn {_, iter1, elapsed1}, {_, iter2, elapsed2} ->
      elapsed1/iter1 < elapsed2/iter2
    end)
    |> Enum.each(fn {name, n, elapsed} ->
      musec = elapsed / n
      :io.format('~*.s ~10B   ~.2f µs/op~n', [-max_name_len-1, name, n, musec])
    end)
    IO.puts ""
  end

  def bench_name(mod, test), do: "[#{mod}] #{test}"


  def to_json(%Snapshot{tests: tests, options: options}) do
    """
    {
      "options": #{Json.encode(options)},
      "tests": #{json_encode_tests(tests)}
    }
    """ |> String.rstrip
  end

  def snapshots_to_json(snapshots) when is_list(snapshots) do
    fields = Enum.map(snapshots, fn {name, snapshot} ->
      ~s("#{name}": #{to_json(snapshot)})
    end)
    "{" <> Enum.join(fields, ",") <> "}"
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
