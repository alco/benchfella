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
end
