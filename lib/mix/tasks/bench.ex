defmodule Mix.Tasks.Bench do
  use Mix.Task

  @shortdoc "Benchmark your code"

  @moduledoc """
  ## Usage

      mix bench [options] [<path>...]

  When one or more arguments are supplied, each of them will be treated as a
  wildcard pattern and only those bench tests that match the pattern will be
  selected.

  By default, all files matching `bench/**/*_bench.exs` are run.

  The results of a test run are pretty-printed to the standard output.
  Additionally, the output in machine format is written to a snapshot file.

  ## Options

      -n, --no-pretty
          Instead of pretty-printing the output, print it in the format that
          can be parsed by bench.cmp and bench.graph.

      -q, --quiet
          Don't print progress report while the tests are running.

          Reports are printed to stderr so as not to interfere with output
          redirection.

      -d <duration>, --duration=<duration>
          Minimum duration of each test in seconds.

      -o <path>, --output=<path>
          Path to the directory in which to store snapshots. The directory will
          be created if necessary.

          Setting it to an empty value will prevent benchfella from creating
          any files or directories.

          Default: bench/snapshots.

      -m, --mem-stats
          Gather memory usage statistics.

      --sys-mem-stats
          Gather system memory stats. Implies --mem-stats.

  """

  def run(args) do
    switches = [no_pretty: :boolean, quiet: :boolean, duration: :float,
                mem_stats: :boolean, sys_mem_stats: :boolean, output: :string]
    aliases = [n: :no_pretty, q: :quiet, d: :duration, m: :mem_stats, o: :output]
    {paths, options} =
      case OptionParser.parse(args, strict: switches, aliases: aliases) do
        {opts, paths, []} -> {paths, opts}
        {_, _, [{opt, val}|_]} ->
          valstr = if val do "=#{val}" end
          Mix.raise "Invalid option: #{opt}#{valstr}"
      end
      |> normalize_options()
    Process.put(:"benchfella cli options", options)
    load_bench_files(paths)
  end

  defp load_bench_files([]) do
    Path.wildcard("bench/**/*_bench.exs")
    |> do_load_bench_files
  end

  defp load_bench_files(paths) do
    Enum.flat_map(paths, &Path.wildcard/1)
    |> do_load_bench_files
  end

  defp do_load_bench_files([]), do: nil
  defp do_load_bench_files(files) do
    load_bench_helper()
    Kernel.ParallelRequire.files(files)
  end

  @helper_path "bench/bench_helper.exs"

  defp load_bench_helper() do
    if File.exists?(@helper_path) do
      Code.require_file(@helper_path)
    else
      Benchfella.start()
    end
  end

  defp normalize_options({paths, options}) do
    options =
      Enum.reduce(options, %{}, fn
        {:no_pretty, flag}, map -> Map.put(map, :format, pretty_to_format(!flag))
        {:quiet, flag}, map -> Map.put(map, :verbose, not flag)
        {:mem_stats, flag}, map -> Map.update(map, :mem_stats, flag, & &1)
        {:sys_mem_stats, true}, map -> Map.put(map, :mem_stats, :include_sys)
        {:sys_mem_stats, _}, map -> map
        {k, v}, map -> Map.put(map, k, v)
      end)
      |> Enum.to_list()
    {paths, options}
  end

  defp pretty_to_format(true), do: :pretty
  defp pretty_to_format(false), do: :machine
end
