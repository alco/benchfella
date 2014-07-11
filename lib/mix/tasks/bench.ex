defmodule Mix.Tasks.Bench do
  use Mix.Task

  @shortdoc "Benchmark your code"

  @moduledoc """
  ## Usage

      mix bench [options]

  ## Options

      -d <duration>, --duration=<duration>
          Minimum duration of each bench in seconds.

      -m, --mem-stats
          Gather memory usage statistics.

      --sys-mem-stats
          Gather system memory stats. Implies --mem-stats.

      -v, --verbose
          Print progress report while the benches are running.

          Reports are printed to stderr so as not to interfere with output
          redirection.

      -f=<fmt>, --format=<fmt>
          Output format. One of: default, machine.
  """

  def run(args) do
    switches = [format: :string, verbose: :boolean, duration: :float,
                mem_stats: :boolean, sys_mem_stats: :boolean]
    aliases = [f: :format, v: :verbose, d: :duration, m: :mem_stats]
    options =
      case OptionParser.parse(args, strict: switches, aliases: aliases) do
        {opts, [], []} -> opts
        {_, [arg|_], []} ->
          Mix.raise "Extraneous argument: #{arg}"
        {_, _, [{opt, val}|_]} ->
          valstr = if val do "=#{val}" end
          Mix.raise "Invalid option: #{opt}#{valstr}"
      end
      |> normalize_options()
    Process.put(:"benchfella cli options", options)
    load_bench_files()
  end

  defp load_bench_files() do
    files = Path.wildcard("bench/**/*_bench.exs")
    unless files == [] do
      load_bench_helper()
      Kernel.ParallelRequire.files(files)
    end
  end

  @helper_path "bench/bench_helper.exs"

  defp load_bench_helper() do
    if File.exists?(@helper_path) do
      Code.require_file(@helper_path)
    else
      Benchfella.start()
    end
  end

  defp normalize_options(options) do
    Enum.reduce(options, %{}, fn
      {:format, fmt}, map -> Map.put(map, :format, parse_format(fmt))
      {:mem_stats, flag}, map -> Map.update(map, :mem_stats, flag, & &1)
      {:sys_mem_stats, true}, map -> Map.put(map, :mem_stats, :include_sys)
      {:sys_mem_stats, _}, map -> map
      {k, v}, map -> Map.put(map, k, v)
    end)
    |> Enum.to_list()
  end

  defp parse_format("default"), do: :default
  defp parse_format("machine"), do: :machine
  defp parse_format(other), do: Mix.raise "Undefined format: #{other}"
end
