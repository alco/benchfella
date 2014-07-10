Benchfella.start

defmodule BenchfellaBench do
  use Benchfella

  @str "Some long string here. It should be much longer than this."
  @str_10 String.duplicate("Some long string here. It should be much longer than this.", 10)
  @str_100 String.duplicate("Some long string here. It should be much longer than this.", 100)
  @str_1000 String.duplicate("Some long string here. It should be much longer than this.", 1000)

  bench "range test" do
    String.slice(@str, 10..-10)
  end

  bench "binary test" do
    binary_part(@str, 10, -10)
  end

  bench "range test 10" do
    String.slice(@str_10, 10..-10)
  end

  bench "binary test 10" do
    binary_part(@str_10, 10, -10)
  end

  bench "range test 100" do
    String.slice(@str_100, 10..-10)
  end

  bench "binary test 100" do
    binary_part(@str_100, 10, -10)
  end

  bench "range test 1000" do
    String.slice(@str_1000, 10..-10)
  end

  bench "binary test 1000" do
    binary_part(@str_1000, 10, -10)
  end
end
