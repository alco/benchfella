defmodule StringBench do
  use Benchfella

  @size 10000
  @str String.duplicate("a", @size)

  bench "reverse string" do
    String.reverse @str
  end

  bench "reverse string dynamic", [str: make_string] do
    String.reverse(str)
  end

  defp make_string() do
    String.duplicate("a", @size)
  end
end
