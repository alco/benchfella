defmodule ListBench do
  use Benchfella

  @list Enum.to_list(1..10000)

  bench "reverse list" do
    Enum.reverse @list
  end
end
