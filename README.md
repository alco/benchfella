Benchfella
==========

Benchmark tool for Elixir.

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
$ mix bench --mem-stats
Settings:
  duration:      1.0 s
  mem stats:     true
  sys mem stats: false

[21:36:11] 1/8: BenchfellaBench.binary test 10
[21:36:12] 2/8: BenchfellaBench.binary test 1
[21:36:14] 3/8: BenchfellaBench.range test 10
[21:36:17] 4/8: BenchfellaBench.binary test 100
[21:36:18] 5/8: BenchfellaBench.binary test 1000
[21:36:20] 6/8: BenchfellaBench.range test 1000
[21:36:22] 7/8: BenchfellaBench.range test 1
[21:36:25] 8/8: BenchfellaBench.range test 100
Finished in 15.69 seconds

BenchfellaBench.binary test 10:     10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     0.01 bytes/op

BenchfellaBench.binary test 100:    10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     0.01 bytes/op

BenchfellaBench.binary test 1:      10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     0.01 bytes/op

BenchfellaBench.binary test 1000:   10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     0.01 bytes/op

BenchfellaBench.range test 1:         100000   25.16 µs/op
  mem initial:  2680
  mem after:    109168
  mem diff:     1.06 bytes/op

BenchfellaBench.range test 10:         10000   289.00 µs/op
  mem initial:  2680
  mem after:    13592
  mem diff:     1.09 bytes/op

BenchfellaBench.range test 100:          500   3278.40 µs/op
  mem initial:  2680
  mem after:    7560
  mem diff:     9.76 bytes/op

BenchfellaBench.range test 1000:          50   32240.40 µs/op
  mem initial:  2680
  mem after:    7560
  mem diff:     97.6 bytes/op

```

### `mix bench.cmp`

To compare results between multiple runs, use machine output format:

```
$ mix bench --verbose -f machine >snapshot_old.txt
[05:14:51] 1/2: BasicBench.hello list
[05:14:54] 2/2: BenchBench.hello string
Finished in 7.18 seconds

$ mix bench --verbose -f machine >snapshot_new.txt
[05:15:03] 1/2: BasicBench.hello list
[05:15:05] 2/2: BenchBench.hello string
Finished in 4.94 seconds

$ mix bench.cmp snapshot_old.txt snapshot_new.txt -f percent
BasicBench.hello list:   -2.04%
BenchBench.hello string: -0.08%
```
