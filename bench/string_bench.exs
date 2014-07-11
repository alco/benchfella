defmodule StringBench do
  use Benchfella

  Enum.each([1, 10, 100, 1000, 10000], fn n ->
    @str String.duplicate("abc", n)

    bench "reverse string #{n}" do
      String.reverse @str
    end
  end)
end
