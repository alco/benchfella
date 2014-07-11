defmodule BenchBench do
  use Benchfella

  @str String.duplicate("abc", 1000)

  bench "hello string" do
    String.reverse @str
  end
end
