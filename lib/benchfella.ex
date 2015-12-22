defmodule Benchfella do
  @bench_tab :"#{__MODULE__}:tests"
  @bench_sec 1
  @default_outdir "bench/snapshots"

  @setup_func :setup_all
  @teardown_func :teardown_all

  @before_each_func :before_each_bench
  @after_each_func :after_each_bench

  alias Benchfella.Snapshot
  alias Benchfella.Counter

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: :macros

      def unquote(@before_each_func)(mod_context) do
        {:ok, mod_context}
      end

      defoverridable [{unquote(@before_each_func), 1}]
    end
  end

  def start(opts \\ []) do
    cli_opts = Process.get(:benchfella_cli_options, [])
    opts = Keyword.merge(opts, cli_opts)

    # spawn a zombie process to keep the table alive
    pid = spawn(fn ->
      receive do end
    end)
    :ets.new(@bench_tab, [:public, :named_table, :ordered_set, {:heir, pid, nil}])

    {collect_mem_stats, sys_mem_stats} =
      case Keyword.fetch(opts, :mem_stats) do
        {:ok, :include_sys} -> {true, true}
        {:ok, true}         -> {true, false}
        {:ok, false}        -> {false, false}
        :error              -> {false, false}
      end

    format = Keyword.get(opts, :format, :plain)
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
      #log "  mem stats:     #{mem_stats}"
      #log "  sys mem stats: #{sys_mem_stats}"
      log ""
    end

    bench_count = :ets.info(@bench_tab, :size)
    bench_config = {bench_time, mem_stats}
    {total_time, results} = :timer.tc(fn ->
      prepare_tests_for_running(@bench_tab)
      |> run_grouped_tests(bench_count, verbose, bench_config)
    end)

    if verbose do
      sec = Float.round(total_time / 1_000_000, 2)
      log ""
      log "Finished in #{sec} seconds"
    end

    print_results(results, bench_time, format, outdir, mem_stats, sys_mem_stats)
  end

  defp prepare_tests_for_running(table) do
    :ets.tab2list(table) |> Enum.group_by(fn {{mod, _test}} -> mod end)
  end

  # TODO: extract logging from this function and number running tests externally
  defp run_grouped_tests(groups, count, follow, bench_config) do
    {:ok, counter} = Counter.start_link(1)

    # for each group we return the list of its results
    Enum.flat_map(groups, fn {mod, tests} ->
      if follow, do: log ["## ", inspect(mod)]

      log_msg_func = fn func -> if follow do
        "[#{format_now()}] #{Counter.next(counter)}/#{count}: #{func}" end
      end
      spawn_with_exit(fn ->
        result = case run_setup_hook(mod) do
          {:ok, mod_context} ->
            results = run_individual_tests(tests, log_msg_func, bench_config, mod_context)
            run_teardown_hook(mod, mod_context)
            results
          _ ->
            log "Skipping all tests in #{inspect mod}\n"
            [nil]
        end
        exit({:normal, result})
      end)
    end)
  end

  defp run_individual_tests(tests, log_msg_func, bench_config, mod_context) do
    Enum.map(tests, fn {test} ->
      {test, run_bench(test, log_msg_func, bench_config, mod_context)}
    end)
  end

  defp run_bench({mod, func}, log_msg_func, config, mod_context) do
    func_name = bench_func_name(func)
    run_bench_with_context(mod, func_name, mod_context, log_msg_func.(func), fn context ->
      inputs = apply(mod, func_name, [context])
      measure_func(mod, func_name, context, inputs, config)
    end)
  end

  defp run_bench_with_context(mod, func_name, mod_context, log_msg, func) do
    spawn_with_exit(fn ->
      result = case run_before_each_hook(mod, mod_context) do
        {:ok, bench_context} ->
          if log_msg, do: log log_msg
          result = func.(bench_context)
          run_after_each_hook(mod, bench_context)
          result
        _ ->
          log "Skipping #{inspect mod}.#{func_name}\n"
          nil
      end
      exit({:normal, result})
    end)
  end

  defp print_results(results, bench_time, format, outdir, mem_stats?, sys_mem_stats?) do
    musec2sec(bench_time)
    |> Snapshot.prepare(mem_stats?, sys_mem_stats?, results)
    |> write_snapshot(outdir)
    |> print_formatted_data(format)
  end

  defp print_formatted_data(iodata, :raw) do
    IO.write(iodata)
  end

  defp print_formatted_data(iodata, format) do
    IO.write "\n"
    IO.iodata_to_binary(iodata)
    |> Snapshot.parse
    |> Snapshot.print(format)
  end

  defp write_snapshot(iodata, "") do
    iodata
  end

  defp write_snapshot(iodata, dir) do
    filename = gen_snapshot_name()
    File.write!(Path.join(dir, filename), iodata)
    iodata
  end

  defp gen_snapshot_name() do
    # FIXME: think about including additional info in the filename, like
    # indication of which tests were run or test settings
    {{year, month, day}, {hour, min, sec}} = :calendar.local_time()
    :io_lib.format('~B-~2..0B-~2..0B_~2..0B-~2..0B-~2..0B.snapshot',
                   [year, month, day, hour, min, sec])
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

  defp format_now() do
    {_, {h,m,s}} = :erlang.localtime()
    :io_lib.format('~2.10.0B:~2.10.0B:~2.10.0B', [h, m, s])
    |> List.to_string()
  end

  defp measure_func(mod, f, context, inputs, {_, collect_mem_stats}=config) do
    {elapsed, result, n, mem_stats} = measure_n(mod, f, context, inputs, 1, collect_mem_stats)
    measure_func(mod, f, context, inputs, {n, elapsed, result, mem_stats}, config)
  end

  defp measure_func(mod, f, context, inputs, {n, elapsed, result, _}, {bench_time, collect_mem_stats}=config)
    when elapsed < bench_time
  do
    n = predict_n(n, elapsed, bench_time)
    case measure_n(mod, f, context, inputs, n, collect_mem_stats) do
      {elapsed, ^result, n, mem_stats} ->
        measure_func(mod, f, context, inputs, {n, elapsed, result, mem_stats}, config)
      {_, other, _, _} ->
        fatal """
        Different return values between iterations.
         Expected: #{inspect result}
              Got: #{inspect other}
        """
    end
  end

  defp measure_func(_, _, _, _, {n, elapsed, _, mem_stats}, _) do
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

  defp measure_n(mod, f, context, inputs, n, collect_mem_stats) do
    parent = self()
    pid = spawn_link(fn ->
      pid = self()
      {mem_before, sys_mem_before} = if collect_mem_stats do
        {:memory, mem_before} = :erlang.process_info(pid, :memory)
        sys_mem_before = :erlang.memory()
        {mem_before, sys_mem_before}
      else
        {nil, nil}
      end

      result = measure_once(mod, f, n, context, inputs)

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

  defp measure_once(mod, f, n, context, inputs) do
    :timer.tc(mod, f, [n, nil, context | inputs])
  end

  def add_bench(mod, func_name) do
    validate_name!(inspect(mod))
    validate_name!(mod, Atom.to_string(func_name))
    try do
      :ets.insert(@bench_tab, {{mod, func_name}})
    catch
      :error, :badarg -> raise "Benchfella is not started"
    end
  end

  @doc false
  def bench_func_name(bench_name) do
    :"bench: #{bench_name}"
  end

  defp validate_name!(name) do
    validate_name!(nil, name)
  end

  defp validate_name!(mod, name) do
    if not String.printable?(name) or Regex.match?(~r/\n|\t/, name) do
      module = if mod, do: "#{inspect(mod)}."
      fatal """
      Invalid characters in the name #{module}#{inspect name}.
         Only printable characters are allowed except for \\t and \\n.
      """
    end
  end

  defmacro bench(name, [do: body]) do
    gen_bench_funcs(name, [], body)
  end

  defmacro bench(name, inputs, [do: body]) do
    gen_bench_funcs(name, inputs, body)
  end

  defmacro setup_all([do: body]) do
    quote do
      def unquote(@setup_func)() do
        unquote(body)
      end
    end
  end

  defmacro teardown_all(mod_context, [do: body]) do
    quote do
      def unquote(@teardown_func)(unquote(mod_context)) do
        unquote(body)
      end
    end
  end

  defmacro before_each_bench(mod_context, [do: body]) do
    quote do
      def unquote(@before_each_func)(unquote(mod_context)) do
        unquote(body)
      end
    end
  end

  defmacro after_each_bench(bench_context, [do: body]) do
    quote do
      def unquote(@after_each_func)(unquote(bench_context)) do
        unquote(body)
      end
    end
  end

  defp gen_bench_funcs(name, inputs, body) do
    {vars, values} = Enum.reduce(inputs, {[], []}, fn {name, {func, meta, args}}, {vars, values} ->
      var = Macro.var(name, nil)
      val = {func, meta, args}
      {[var|vars], [val|values]}
    end)
    ignored_vars = Enum.map(vars, fn _ -> quote do _ end end)

    quote bind_quoted: [
      fella: __MODULE__,
      bench_name: name,
      body: Macro.escape(body),
      values: Macro.escape(values),
      vars: Macro.escape(vars),
      ignored_vars: Macro.escape(ignored_vars)
    ] do
      fella.add_bench(__MODULE__, String.to_atom(bench_name))

      func_name = fella.bench_func_name(bench_name)

      def unquote(func_name)(var!(bench_context)) do
        _ = var!(bench_context)
        [unquote_splicing(values)]
      end

      def unquote(func_name)(0, result, _, unquote_splicing(ignored_vars)) do
        result
      end

      def unquote(func_name)(n, _, var!(bench_context), unquote_splicing(vars)) do
        unquote(func_name)(n-1, unquote(body), var!(bench_context), unquote_splicing(vars))
      end
    end
  end

  defp run_setup_hook(mod) do
    if function_exported?(mod, @setup_func, 0) do
      try do
        case apply(mod, @setup_func, []) do
          {:ok, context} -> {:ok, context}
          other -> raise "Expected #{inspect mod}.#{@setup_func}/0 to return {:ok, <term>}. "
                      <> "Got #{inspect other}"
        end
      catch
        kind, error ->
          IO.puts :stderr, Exception.format(kind, error, pruned_stacktrace) |> String.rstrip
      end
    else
      {:ok, nil}
    end
  end

  defp run_teardown_hook(mod, mod_context) do
    if function_exported?(mod, @teardown_func, 1) do
      try do
        apply(mod, @teardown_func, [mod_context])
      catch
        kind, error -> IO.puts :stderr, Exception.format(kind, error, pruned_stacktrace)
      end
    end
  end

  defp run_before_each_hook(mod, mod_context) do
    if function_exported?(mod, @before_each_func, 1) do
      try do
        case apply(mod, @before_each_func, [mod_context]) do
          {:ok, bench_context} -> {:ok, bench_context}
          other -> raise "Expected #{inspect mod}.#{@before_each_func}/1 to return {:ok, <term>}. "
                      <> "Got #{inspect other}"
        end
      catch
        kind, error ->
          IO.puts :stderr, Exception.format(kind, error, pruned_stacktrace) |> String.rstrip
      end
    end
  end

  defp run_after_each_hook(mod, bench_context) do
    if function_exported?(mod, @after_each_func, 1) do
      try do
        apply(mod, @after_each_func, [bench_context])
      catch
        kind, error -> IO.puts :stderr, Exception.format(kind, error, pruned_stacktrace)
      end
    end
  end

  defp spawn_with_exit(func) do
    Process.flag(:trap_exit, true)
    pid = spawn_link(func)
    receive do
      {:EXIT, ^pid, {:normal, result}} -> result
      {:EXIT, ^pid, error} ->
        IO.puts :stderr, Exception.format(:exit, Exception.normalize(:exit, error))
        nil
    end
  end

  defp pruned_stacktrace do
    System.stacktrace
    |> Enum.take_while(fn {mod, _, _, _} -> mod != __MODULE__ end)
  end

  defp fatal(msg) do
    IO.puts :stderr, ["** (Error) ", msg]
    System.halt(1)
  end
end
