defmodule BinBench do
  use Benchfella

  @str String.duplicate("hello world", 1000)

  bench "binary_part" do
    binary_part(@str, 113, 600)
  end

  bench "matching" do
    <<_::binary-size(113), core::binary-size(600), _::binary>> = @str
    core
  end
end
