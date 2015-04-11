defmodule SysBench do
  use Benchfella

  setup_all do
    depth = :erlang.system_flag(:backtrace_depth, 100)
    {:ok, depth}
  end

  teardown_all depth do
    :erlang.system_flag(:backtrace_depth, depth)
  end

  @list Enum.to_list(1..10000)

  bench "list reverse" do
    Enum.reverse(@list)
  end
end
