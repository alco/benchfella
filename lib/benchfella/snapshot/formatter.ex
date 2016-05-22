defmodule Benchfella.Snapshot.Formatter do
  def format(%Benchfella.Snapshot{tests: tests}, format) do
    {tests, max_len} = max_name_len(tests)
    Enum.group_by(tests, &elem(&1, 0))
    |> Enum.reduce([], &format_group(&1, &2, max_len, format))
  end

  defp max_name_len(tests) do
    Enum.map_reduce tests, 0, fn {mod_name, test_name, _, iter, elapsed}, max_len ->
      max_len = max(String.length(test_name), max_len)
      {{mod_name, test_name, iter, elapsed}, max_len}
    end
  end

  defp format_group({group_name, tests}, acc, max_len, :plain) do
    [acc, ["## ", group_name, ?\n]] ++
    [format_header(max_len)] ++
     format_entries(tests, max_len)
  end

  defp format_group({group_name, tests}, acc, max_len, :markdown) do
    [[acc, ["* ", group_name, ?\n, ?\n, '```\n']] ++
    [format_header(max_len)] ++
    format_entries(tests, max_len) | '```\n']
  end

  defp format_header(max_len) do
    '~*.s ~10s   ~s ~n'
    |> :io_lib.format([-max_len - 1, "benchmark name", "iterations", "average time"])
  end

  defp format_entries(tests, max_len) do
    Enum.sort(tests, fn {_, _, iter1, elapsed1}, {_, _, iter2, elapsed2} ->
      elapsed1 / iter1 < elapsed2 / iter2
    end) |> Enum.map(&format_entry(&1, max_len))
  end

  defp format_entry({_, name, iter, elapsed}, max_len) do
    '~*.s ~10B   ~.2f µs/op~n'
    |> :io_lib.format([-max_len - 1, name, iter, elapsed / iter])
  end
end
