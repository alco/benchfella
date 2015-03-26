Benchfella
==========

Benchmarking tool for Elixir.


## Installation

Choose how you'd like to install the custom Mix tasks:

  1. As an archive:

     ```
     mix archive.install https://github.com/alco/benchfella/releases/download/v0.1.0/benchfella-0.1.0.ez
     ```

     This will make the custom tasks available to `mix` regardless of where it is invoked, just like
     the builtin tasks are.

     **Caveat**: the archive may be outdated when there is development happening on the master
     branch.

  2. Add `benchfella` as a dependency to your project:

     ```elixir
     # in your mix.exs

     defp deps do
       [{:benchfella, github: "alco/benchfella"}]
     end
     ```

     This will make the new tasks available only in the root directory of your Mix project.

## Usage

Add a directory called `bench` and put files called `*_bench.exs` into it. Then
run `mix bench`.

Example:

```elixir
defmodule BasicBench do
  use Benchfella

  @list Enum.to_list(1..1000)

  bench "hello list" do
    Enum.reverse @list
  end
end
```

When you need to generate inputs for tests at runtime without affecting the run
time of the tests, use the following trick:

```elixir
defmodule BasicBench do
  use Benchfella

  bench "reverse string", [str: gen_string()] do
    Enum.reverse(str)
  end

  defp gen_string() do
    String.duplicate("abc", 10000)
  end
end
```

Benchfella provides `setup_all` and `teardown_all` macros that let you perform some setup
before the first test in a module is run and do some cleanup after the last test within
the same module has finished running:

```elixir
defmodule BasicBench do
  use Benchfella

  setup_all do
    Process.flag(:trap_exit, true)
  end

  teardown_all do
    Process.flag(:trap_exit, false)
  end

  bench "process kill" do
    pid = spawn_link(fn -> receive do end end)
    Process.exit(pid, :kill)
    receive do
      {:EXIT, ^pid, :killed} -> :ok
    end
  end
end
```


### `mix bench`

Sample output:

```sh
$ mix bench
Settings:
  duration:      1.0 s
  mem stats:     false
  sys mem stats: false

## StringBench
[01:17:08] 1/3: reverse string
[01:17:11] 2/3: reverse string dynamic
## ListBench
[01:17:14] 3/3: reverse list

Finished in 9.23 seconds

## ListBench
reverse list                 50000   50.29 µs/op

## StringBench
reverse string                1000   2749.31 µs/op
reverse string dynamic        1000   2773.01 µs/op
```


### `mix bench.cmp`

To compare results between multiple runs, use `mix bench.cmp`.

```sh
# Run 'mix bench' one more time.
# Each run automatically saves a snapshot in bench/snapshots.
$ mix bench
...

# 'mix bench.cmp' will read the two latest snapshots by default.
# You could also pass the snapshot files to compare as arguments.
$ mix bench.cmp -f percent
bench/snapshots/2015-03-26T01:17:17.snapshot vs
bench/snapshots/2015-03-26T01:19:30.snapshot

## ListBench
reverse list              -10.32%

## StringBench
reverse string dynamic    +2.26%
reverse string            +3.33%
```


### `mix bench.graph`

Benchfella can produce an HTML page with graphs providing various insights into
the raw data obtained from running `mix bench`.

```sh
# run the benchmarks twice
$ mix bench
...
$ mix bench
...

# 'mix bench.graph' works similarly to 'mix bench.cmp' except it can display
# all given snapshots on one graph.
$ mix bench.graph
Wrote bench/graphs/index.html

$ open bench/graphs/index.html
```

![Graph example](bench_graph.png "Graph example")


## License

This software is licensed under [the MIT license](LICENSE).
