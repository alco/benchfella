defmodule Benchfella do
  @bench_tab __MODULE__
  @results_tab :"#{__MODULE__}:results"
  @attr_name :"#{__MODULE__}:bench"

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: :macros
    end
  end

  def start do
    :ets.new(@bench_tab, [:named_table, :set])
    System.at_exit(&run/1)
  end

  def run(_) do
    :ets.new(@results_tab, [:named_table, :set])
    :ets.foldl(&run_bench/2, 0, @bench_tab)
    {results, max_len} = :ets.foldl(&collect_results/2, {[], 0}, @results_tab)
    results
    |> Enum.sort(fn {_, _, n1}, {_, _, n2} -> n1 < n2 end)
    |> Enum.each(fn {name, n, musec} ->
      :io.format('~*.s ~10B   ~.2f µs/op~n', [-max_len, name, n, musec])
    end)
  end

  defp run_bench({{mod, func}}, count) do
    {n, elapsed} = measure_func(mod, func)
    :ets.insert(@results_tab, {{mod, func}, n, elapsed})
    count+1
  end

  defp collect_results({{mod, f}, n, elapsed}, {list, max_len}) do
    musec = elapsed / n
    name = "#{inspect mod}.#{f}:"
    result = {name, n, musec}
    {[result|list], max(String.length(name), max_len)}
  end

  @bench_time 1_000_000

  defp measure_func(mod, f) do
    {elapsed, result} = measure_once(mod, f, 1)
    measure_func(mod, f, {1, elapsed, result})
  end

  defp measure_func(mod, f, {n, elapsed, result}) when elapsed < @bench_time do
    n = predict_n(n, elapsed)
    case measure_n(mod, f, n) do
      {elapsed, ^result, n} ->
        measure_func(mod, f, {n, elapsed, result})
      _ ->
        raise "Got different result between iterations"
    end
  end

  defp measure_func(_, _, {n, elapsed, _}) do
    {n, elapsed}
  end

  defp predict_n(n, elapsed) do
    last = n
    quot = div(elapsed, n)
    n = if quot == 0 do
      1_000_000_000
    else
      div(@bench_time, quot)
    end
    # Run more iterations than we think we'll need for a second (1.5x).
    # Don't grow too fast in case we had timing errors previously.
    # Be sure to run at least one more than last time.
    max(min(n+div(n,2), 10*last), last+1) |> round_up()
  end

  # round n up to an easy to read number; one of 10eX, 20eX, 50eX
  defp round_up(n) do
    base = round_down(n, 10)
    cond do
      n <= base   -> base
      n <= 2*base -> 2*base
      n <= 5*base -> 5*base
      true        -> 10*base
    end
  end

  defp round_down(n, p) do
    round_down(n, p, 0)
  end

  defp round_down(n, p, count) when n >= p do
    round_down(div(n, p), p, count+1)
  end

  defp round_down(_, p, count) do
    trunc(:math.pow(p, count))
  end

  defp measure_n(mod, f, n) do
    parent = self()
    pid = spawn(fn -> send(parent, {self(), measure_once(mod, f, n)}) end)
    receive do
      {^pid, {elapsed, result}} -> {elapsed, result, n}
    end
  end

  defp measure_once(mod, f, n) do
    :timer.tc(mod, f, [n])
  end

  defmacro bench(name, [do: body]) do
    func_name = String.to_atom(name)
    :ets.insert(@bench_tab, {{__CALLER__.module, func_name}})
    quote do
      def unquote(func_name)(n) do
        Enum.each(1..n, fn _ ->
          unquote(body)
        end)
      end
    end
  end
end
