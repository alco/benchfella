defmodule Mix.Tasks.Bench do
  use Mix.Task

  @shortdoc "Microbenchmarking tool for Elixir."

  @moduledoc """
  ## Usage

      mix bench [options] [<path>...]

  When one or more arguments are supplied, each of them will be treated as a
  wildcard pattern and only those bench tests that match the pattern will be
  selected.

  By default, all files matching `bench/**/*_bench.exs` are executed. Each test will run for as many
  iterations as necessary so that the total running time is at least the specified duration.

  In the end, the number of iterations and the average time of a single iteration are printed to the
  standard output. Additionally, the output in machine format is written to a snapshot file in
  `bench/snapshots/`.

  ## Options

      -f, --format
          Print it in the specific format.

          One of: raw, plain (default) and markdown.

      -q, --quiet
          Don't print progress report while the tests are running.

          Reports are printed to stderr so as not to interfere with output
          redirection.

      -d <duration>, --duration=<duration>
          Minimum duration of each test in seconds. Default: 1.

      -o <path>, --output=<path>
          Path to the directory in which to store snapshots. The directory will
          be created if necessary.

          Setting it to an empty value will prevent benchfella from creating
          any files or directories.

          Default: bench/snapshots.

      --no-compile
          Do not compile the target project before running benchmarks.

          NOTE: as of Elixir 1.0.4, this option only works when using the archive.
          If you include Benchfella as a dependency, your project will always be
          recompiled prior to running any 'bench.*' task.

  """

  def run(args) do
    {paths, options, no_compile} =
      parse_options(args)
      |> normalize_options()

    prepare_mix_project(no_compile)

    Process.put(:benchfella_cli_options, options)
    load_bench_files(paths)
  end

  @switches [format: :string, quiet: :boolean,
             duration: :float, output: :string,
             no_compile: :boolean]

  @aliases [f: :format, q: :quiet,
            d: :duration, o: :output]

  defp parse_options(args) do
    case OptionParser.parse(args, strict: @switches, aliases: @aliases) do
      {opts, paths, []} -> {paths, opts}
      {_, _, [{opt, nil} | _]} ->
        Mix.raise "Invalid option: #{opt}"
      {_, _, [{opt, val} | _]} ->
        Mix.raise "Invalid option: #{opt}=#{val}"
    end
  end

  defp prepare_mix_project(no_compile) do
    # Set up the target project's paths
    Mix.Project.get!
    args = ["--no-start"]
    args = case no_compile do
      true -> args ++ ["--no-compile"]
      _    -> args
    end
    Mix.Task.run("app.start", args)
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

  defp normalize_options({paths, opts}) do
    {no_compile, opts} =
      Enum.reduce(opts, %{}, &normalize_option/2)
      |> Map.pop(:no_compile)
    {paths, Map.to_list(opts), no_compile}
  end

  def normalize_option({:format, fmt}, acc) do
    Map.put(acc, :format, parse_format(fmt))
  end

  def normalize_option({:quiet, flag}, acc) do
    Map.put(acc, :verbose, not flag)
  end

  def normalize_option({key, value}, acc) do
    Map.put(acc, key, value)
  end

  defp parse_format(fmt)
    when fmt in ["raw", "plain", "markdown"] do
    String.to_atom(fmt)
  end

  defp parse_format(fmt) do
    Mix.raise "Unknown format: #{fmt}"
  end
end
