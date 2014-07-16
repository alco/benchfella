defmodule StringBench do
  use Benchfella

  @str String.duplicate("a", 10000)

  bench "reverse string" do
    String.reverse @str
  end
end
