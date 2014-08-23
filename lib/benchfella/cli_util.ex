defmodule Benchfella.CLI.Util do
  def read_all_input() do
    read_all_input([])
  end

  def read_all_input(lines) do
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
      case File.ls(dir) do
        {:error, _}  -> []
        {:ok, files} ->
          files |> Enum.sort |> Enum.reverse |> Enum.take(count) |> Enum.reverse
      end
      |> Enum.map(&Path.join(dir, &1))
    if snapshots == [] do
      Mix.raise "No snapshots found. Pass - to read from stdin"
    end
    snapshots
  end
end
