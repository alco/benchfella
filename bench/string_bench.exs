defmodule StringBench do
  use Benchfella

  bench "reverse string", [str: gen_string()] do
    String.reverse(str)
  end

  defp gen_string() do
    String.duplicate("abc", 10000)
  end
end
