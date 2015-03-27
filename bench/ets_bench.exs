defmodule ETSBench do
  use Benchfella

  before_each_bench(_) do
    tid = :ets.new(:my_table, [:public])
    {:ok, tid}
  end

  after_each_bench(tid) do
    IO.inspect length(:ets.tab2list(tid))
    :ets.delete(tid)
  end

  bench "ets insert", [_unused: inspect_table(bench_context)] do
    tid = bench_context
    :ets.insert(tid, {:random.uniform(1000), :x})
    :ok
  end

  defp inspect_table(tid) do
    IO.inspect :ets.info(tid)
  end
end
