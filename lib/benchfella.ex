defmodule Benchfella do
  @bench_tab :"#{__MODULE__}:tests"
  @results_tab :"#{__MODULE__}:results"
  @bench_sec 1
  @default_outdir "bench/snapshots"

  alias Benchfella.Snapshot

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: :macros
    end
  end

  def start(opts \\ []) do
    cli_opts = Process.get(:"benchfella cli options", [])
    opts = Keyword.merge(opts, cli_opts)

    # spawn a zombie process to keep the table alive
    pid = spawn(fn ->
      receive do end
    end)
    :ets.new(@bench_tab, [:public, :named_table, :set, {:heir, pid, nil}])

    {collect_mem_stats, sys_mem_stats} =
      case Keyword.fetch(opts, :mem_stats) do
        {:ok, :include_sys} -> {true, true}
        {:ok, true}         -> {true, false}
        {:ok, false}        -> {false, false}
        :error              -> {false, false}
      end

    format = Keyword.get(opts, :format, :pretty)
    verbose = Keyword.get(opts, :verbose, true)

    outdir = case Keyword.fetch(opts, :output) do
      {:ok, path} when is_binary(path) -> path
      :error -> @default_outdir
    end
    if outdir != "", do: File.mkdir_p!(outdir)

    System.at_exit(fn
      0 -> run(Keyword.get(opts, :duration, @bench_sec) |> sec2musec,
                    verbose, format, outdir, collect_mem_stats, sys_mem_stats)
      status -> status
    end)
  end

  defp sec2musec(sec), do: trunc(sec * 1_000_000)
  defp musec2sec(musec), do: Float.round(musec/1_000_000, 2)

  defp log(msg), do: IO.puts(:stderr, msg)

  def run(bench_time, verbose, format, outdir, mem_stats, sys_mem_stats) do
    #if format == :machine do
      if mem_stats or sys_mem_stats do
        log ">> 'mem stats' flag is currently ignored"
      end
      mem_stats = false
      sys_mem_stats = false
    #end

    if verbose do
      log "Settings:"
      log "  duration:      #{musec2sec(bench_time)} s"
      log "  mem stats:     #{mem_stats}"
      log "  sys mem stats: #{sys_mem_stats}"
      log ""
    end

    :ets.new(@results_tab, [:named_table, :set])
    bench_count = :ets.info(@bench_tab, :size)
    bench_config = {bench_time, mem_stats}
    {total_time, _, _} =
      :ets.foldl(&run_bench(&1, &2, verbose, bench_config), {0, 1, bench_count}, @bench_tab)
    results = :ets.foldl(&collect_results/2, [], @results_tab)

    if verbose do
      sec = Float.round(total_time / 1_000_000, 2)
      log "Finished in #{sec} seconds"
      log ""
    end

    print_results(results, bench_time, format, outdir, mem_stats, sys_mem_stats)
  end

  defp print_results(results, bench_time, format, outdir, collect_mem_stats, sys_mem_stats) do
    iodata = [
      "duration:", "#{musec2sec(bench_time)};",
      "mem stats:", "#{collect_mem_stats};",
      "sys mem stats:", "#{sys_mem_stats}",
      "\nmodule;test;tags;iterations;elapsed\n",
    ] ++ Enum.map(results, fn {{mod, f}, n, elapsed, _mem_stats} ->
      :io_lib.format('~s;~s;;~B;~B~n', [inspect(mod), "#{f}", n, elapsed])
      #if collect_mem_stats do
      #  print_mem_stats(n, mem_stats, sys_mem_stats)
      #end
    end)
    print_formatted_data(iodata, format, outdir)
  end

  defp print_formatted_data(iodata, :machine, outdir) do
    write_snapshot(iodata, outdir)

    IO.write(iodata)
  end

  defp print_formatted_data(iodata, :pretty, outdir) do
    write_snapshot(iodata, outdir)

    iodata
    |> Enum.map(&IO.iodata_to_binary/1)
    |> Enum.join("")
    |> Snapshot.parse
    |> Snapshot.pretty_print
  end

  defp write_snapshot(_iodata, "") do
    nil
  end

  defp write_snapshot(iodata, dir) do
    filename = gen_snapshot_name()
    File.write!(Path.join(dir, filename), iodata)
  end

  defp gen_snapshot_name() do
    # FIXME: think about including additional info in the filename, like
    # indication of which tests were run or test settings
    {{year,month,day}, {hour,min,sec}} = :calendar.now_to_local_time(:erlang.now)
    :io_lib.format('~B-~2..0B-~2..0BT~2..0B:~2..0B:~2..0B.snapshot',
                                            [year, month, day, hour, min, sec])
    |> List.to_string
  end

  #  defp print_mem_stats(n, {mem_before, mem_after, mem_after_gc,
  #                  mem_bin_before, mem_atom_before, mem_bin_after, mem_atom_after},
  #                show_sys)
  #  do
  #    str_initial = "  mem initial:  #{mem_before}"
  #    if show_sys do
  #      str_initial = str_initial
  #                    <> " proc + #{b2kib(mem_bin_before)} KiB bin +"
  #                    <> " #{b2kib(mem_atom_before)} KiB atom"
  #    end
  #    IO.puts str_initial
  #
  #    str_after = "  mem after:    #{mem_after}"
  #    if show_sys do
  #      str_after = str_after
  #                  <> " proc + #{b2kib(mem_bin_after)} KiB bin +"
  #                  <> " #{b2kib(mem_atom_after)} KiB atom"
  #    end
  #    IO.puts str_after
  #
  #    diff_proc = Float.round((mem_after-mem_before) / n, 2)
  #    str_diff = "  mem diff:     #{diff_proc} bytes/op"
  #    if show_sys do
  #      diff_sys = Float.round((mem_bin_after-mem_bin_before + mem_atom_after-mem_atom_before) / n, 2)
  #      str_diff = str_diff
  #                 <> " proc, #{diff_sys} bytes/op sys"
  #    end
  #    IO.puts str_diff
  #
  #    gc_diff = mem_after_gc - mem_before
  #    if gc_diff > 0 do
  #      IO.puts "  res after gc: #{gc_diff}"
  #    end
  #    IO.puts ""
  #  end
  #
  #  defp b2kib(bytes), do: Float.round(bytes/1024, 2)

  defp run_bench({{mod, func}}, {total_time, i, count}, follow, config) do
    if follow do
      log "[#{format_now()}] #{i}/#{count}: #{bench_name(mod, func)}"
    end
    {elapsed, _} = :timer.tc(fn ->
      {n, elapsed, mem_stats} = measure_func(mod, func, config)
      :ets.insert(@results_tab, {{mod, func}, n, elapsed, mem_stats})
    end)
    {total_time+elapsed, i+1, count}
  end

  defp format_now() do
    {_, {h,m,s}} = :erlang.localtime()
    :io_lib.format('~2.10.0B:~2.10.0B:~2.10.0B', [h, m, s])
    |> List.to_string()
  end

  defp collect_results({{mod, f}, n, elapsed, mem_stats}, list) do
    result = {{mod, f}, n, elapsed, mem_stats}
    [result|list]
  end

  defp bench_name(mod, f) do
    "#{inspect mod}.#{f}"
  end


  defp measure_func(mod, f, {_, collect_mem_stats}=config) do
    {elapsed, result, n, mem_stats} = measure_n(mod, f, 1, collect_mem_stats)
    measure_func(mod, f, {n, elapsed, result, mem_stats}, config)
  end

  defp measure_func(mod, f, {n, elapsed, result, _}, {bench_time, collect_mem_stats}=config)
    when elapsed < bench_time
  do
    n = predict_n(n, elapsed, bench_time)
    case measure_n(mod, f, n, collect_mem_stats) do
      {elapsed, ^result, n, mem_stats} ->
        measure_func(mod, f, {n, elapsed, result, mem_stats}, config)
      _ ->
        raise "Got different result between iterations"
    end
  end

  defp measure_func(_, _, {n, elapsed, _, mem_stats}, _) do
    {n, elapsed, mem_stats}
  end

  defp predict_n(n, elapsed, bench_time) do
    last = n
    quot = div(elapsed, n)
    n = if quot == 0 do
      1_000_000_000
    else
      div(bench_time, quot)
    end
    # Run more iterations than we think we'll need for a second (1.5x).
    # Don't grow too fast in case we had timing errors previously.
    # Be sure to run at least one more than last time.
    max(min(1.5*n, 10*last), last+1) |> round_up()
  end

  # round n up to an easy to read number; one of 1eX, 2eX, 5eX
  defp round_up(n) do
    base = round_down(trunc(n), 10)
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

  defp measure_n(mod, f, n, collect_mem_stats) do
    parent = self()
    pid = spawn_link(fn ->
      pid = self()
      if collect_mem_stats do
        {:memory, mem_before} = :erlang.process_info(pid, :memory)
        sys_mem_before = :erlang.memory()
      end

      result = measure_once(mod, f, n)

      mem_stats = if collect_mem_stats do
        {:memory, mem_after} = :erlang.process_info(pid, :memory)
        :erlang.garbage_collect()
        {:memory, mem_after_gc} = :erlang.process_info(pid, :memory)
        sys_mem_after = :erlang.memory()

        {
          mem_before, mem_after, mem_after_gc,
          sys_mem_before[:binary], sys_mem_before[:atom],
          sys_mem_after[:binary], sys_mem_after[:atom]
        }
      end
      send(parent, {pid, result, mem_stats})
    end)
    receive do
      {^pid, {elapsed, result}, mem_stats} -> {elapsed, result, n, mem_stats}
    end
  end

  defp measure_once(mod, f, n) do
    inputs = apply(mod, f, [])
    :timer.tc(mod, f, [n, nil | inputs])
  end

  def add_bench(mod, func_name) do
    try do
      :ets.insert(@bench_tab, {{mod, func_name}})
    catch
      :error, :badarg -> raise "Benchfella is not started"
    end
  end

  defmacro bench(name, [do: body]) do
    gen_bench_funcs(name, [], body)
  end

  defmacro bench(name, inputs, [do: body]) do
    gen_bench_funcs(name, inputs, body)
  end

  defp gen_bench_funcs(name, inputs, body) do
    {vars, assigns} = Enum.reduce(inputs, {[], []}, fn {name, {func, meta, _}}, {vars, assigns} ->
      var = Macro.var(name, nil)
      val = {func, meta, []}
      {[var|vars], [quote(do: unquote(var) = unquote(val))|assigns]}
    end)
    ignored_vars = Enum.map(vars, fn _ -> quote do _ end end)

    quote bind_quoted: [
      fella: __MODULE__, name: name, body: Macro.escape(body),
      assigns: Macro.escape(assigns),
      vars: Macro.escape(vars),
      ignored_vars: Macro.escape(ignored_vars)]
    do
      name = String.to_atom(name)
      fella.add_bench(__MODULE__, name)

      def unquote(name)() do
        [unquote_splicing(assigns)]
      end

      def unquote(name)(0, result, unquote_splicing(ignored_vars)) do
        result
      end

      def unquote(name)(n, _, unquote_splicing(vars)) do
        unquote(name)(n-1, unquote(body), unquote_splicing(vars))
      end
    end
  end
end
