defmodule ListBench do
  use Benchfella

  Enum.each([1, 10, 100, 1000, 10000], fn n ->
    @list Enum.to_list(1..n)

    bench "reverse list #{n}" do
      Enum.reverse @list
    end
  end)
end
