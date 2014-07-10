Benchfella.start

defmodule BenchfellaBench do
  use Benchfella

  @str "Some long string here. It should be much longer than this."

  Enum.each([1, 10, 100, 1000], fn n ->
    @bench_str String.duplicate("Some long string here. It should be much longer than this.", n)

    bench "range test #{n}" do
      String.slice(@bench_str, 10..-10)
    end

    bench "binary test #{n}" do
      binary_part(@bench_str, 10, -10)
    end
  end)
end
