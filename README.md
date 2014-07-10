Benchfella
==========

Benchmarking tool for Elixir.

Sample output:

```
$ mix run test/benchfella_bench.exs
[06:50:05] 1/8: BenchfellaBench.binary test 10
[06:50:06] 2/8: BenchfellaBench.range test 10
[06:50:09] 3/8: BenchfellaBench.range test
[06:50:12] 4/8: BenchfellaBench.binary test 100
[06:50:14] 5/8: BenchfellaBench.binary test 1000
[06:50:15] 6/8: BenchfellaBench.range test 1000
[06:50:17] 7/8: BenchfellaBench.binary test
[06:50:19] 8/8: BenchfellaBench.range test 100
---
BenchfellaBench.binary test 1000:   10000000   0.13 µs/op
BenchfellaBench.binary test 10:     10000000   0.13 µs/op
BenchfellaBench.binary test:        10000000   0.13 µs/op
BenchfellaBench.binary test 100:    10000000   0.13 µs/op
BenchfellaBench.range test:           100000   27.26 µs/op
BenchfellaBench.range test 10:         10000   297.64 µs/op
BenchfellaBench.range test 100:          500   3314.17 µs/op
BenchfellaBench.range test 1000:          50   32567.24 µs/op
---
Total running time: 16.29 s
```
