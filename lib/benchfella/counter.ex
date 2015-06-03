defmodule Benchfella.Counter do
  def start_link(initial) do
    Agent.start_link(fn -> initial end)
  end

  def next(counter) do
    Agent.get_and_update(counter, fn count -> {count, count+1} end)
  end
end
