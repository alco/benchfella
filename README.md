Benchfella
==========

Benchmarking tool for Elixir.

Sample output:

```
$ mix run test/benchfella_bench.exs
Settings:
  duration:      1.0 s
  mem stats:     true
  sys mem stats: false

[21:13:27] 1/8: BenchfellaBench.binary test 10
[21:13:29] 2/8: BenchfellaBench.binary test 1
[21:13:30] 3/8: BenchfellaBench.range test 10
[21:13:34] 4/8: BenchfellaBench.binary test 100
[21:13:35] 5/8: BenchfellaBench.binary test 1000
[21:13:36] 6/8: BenchfellaBench.range test 1000
[21:13:38] 7/8: BenchfellaBench.range test 1
[21:13:41] 8/8: BenchfellaBench.range test 100
Finished in 15.72 seconds

BenchfellaBench.binary test 10:     10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     136.7 KiB

BenchfellaBench.binary test 1:      10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     136.7 KiB

BenchfellaBench.binary test 100:    10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     136.7 KiB

BenchfellaBench.binary test 1000:   10000000   0.13 µs/op
  mem initial:  2680
  mem after:    142656
  mem diff:     136.7 KiB

BenchfellaBench.range test 1:         100000   24.88 µs/op
  mem initial:  2680
  mem after:    109168
  mem diff:     103.99 KiB

BenchfellaBench.range test 10:         10000   290.28 µs/op
  mem initial:  2680
  mem after:    13592
  mem diff:     10.66 KiB

BenchfellaBench.range test 100:          500   3330.80 µs/op
  mem initial:  2680
  mem after:    7560
  mem diff:     4.77 KiB

BenchfellaBench.range test 1000:          50   32453.02 µs/op
  mem initial:  2680
  mem after:    7560
  mem diff:     4.77 KiB

```
