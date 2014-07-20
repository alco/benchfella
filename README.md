Benchfella
==========

The benchmarking tool for Elixir.


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


### `mix bench`

Sample output:

```
$ mix bench -p
Settings:
  duration:      1.0 s
  mem stats:     false
  sys mem stats: false

[02:53:15] 1/4: StringBench.reverse string
[02:53:18] 2/4: BinBench.binary_part
[02:53:19] 3/4: BinBench.matching
[02:53:25] 4/4: ListBench.reverse list
Finished in 12.2 seconds

BinBench.binary_part:        100000000   0.01 µs/op
BinBench.matching:           100000000   0.05 µs/op
ListBench.reverse list:          50000   41.33 µs/op
StringBench.reverse string:       1000   2474.14 µs/op
```


### `mix bench.cmp`

To compare results between multiple runs, omit the `-p` flag from `mix bench`
and feed the output to `mix bench.cmp`:

```
$ mix bench bench/benchfella/* >snapshot1.txt
Settings:
  duration:      1.0 s
  mem stats:     false
  sys mem stats: false

[02:55:43] 1/3: BinBench.binary_part
[02:55:45] 2/3: BinBench.matching
[02:55:50] 3/3: ListBench.reverse list
Finished in 9.57 seconds

$ mix bench -q bench/benchfella/* >snapshot2.txt

$ mix bench.cmp -f percent snapshot1.txt snapshot2.txt
BinBench.matching:      -6.44%
ListBench.reverse list: -1.28%
BinBench.binary_part:   -0.83%
```


### `mix bench.graph`

The ability to draw pretty graphs is still a few commits away...
