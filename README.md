Benchfella
==========

Benchmarking tool for Elixir.

Sample output:

```
$ mix run test/benchfella_bench.exs
[07:04:14] 1/8: BenchfellaBench.binary test 10
[07:04:16] 2/8: BenchfellaBench.range test 10
[07:04:19] 3/8: BenchfellaBench.range test
[07:04:22] 4/8: BenchfellaBench.binary test 100
[07:04:23] 5/8: BenchfellaBench.binary test 1000
[07:04:25] 6/8: BenchfellaBench.range test 1000
[07:04:27] 7/8: BenchfellaBench.binary test
[07:04:28] 8/8: BenchfellaBench.range test 100

BenchfellaBench.binary test:        10000000   0.13 µs/op
BenchfellaBench.binary test 10:     10000000   0.13 µs/op
BenchfellaBench.binary test 100:    10000000   0.13 µs/op
BenchfellaBench.binary test 1000:   10000000   0.14 µs/op
BenchfellaBench.range test:           100000   27.19 µs/op
BenchfellaBench.range test 10:         10000   294.17 µs/op
BenchfellaBench.range test 100:          500   3311.92 µs/op
BenchfellaBench.range test 1000:          50   32624.56 µs/op

Finished in 16.27 seconds
```
