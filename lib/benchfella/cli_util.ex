defmodule Benchfella.CLI.Util do
  def read_all_input(lines \\ []) do
    case IO.binread(:line) do
      :eof ->
        lines |> Enum.reverse |> Enum.join("")
      {:error, reason} ->
        Mix.raise "Error reading from input: #{inspect reason}"
      line ->
        read_all_input([line|lines])
    end
  end

  def locate_snapshots(count \\ 2) do
    dir = "bench/snapshots"
    snapshots =
      Path.join(dir, "*.snapshot")
      |> Path.wildcard
      |> Enum.sort(& &1 > &2)
      |> Enum.take(count)
      |> Enum.reverse

    if snapshots == [] do
      Mix.raise "No snapshots found. Pass - to read from stdin"
    end
    snapshots
  end
end
