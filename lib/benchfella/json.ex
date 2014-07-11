defmodule Benchfella.Json do
  @moduledoc false

  def encode(true), do: "true"
  def encode(false), do: "false"
  def encode(num) when is_number(num), do: "#{num}"
  def encode(%{}=map), do: encode_map(map)
  def encode(list) when is_list(list), do: encode_list(list)
  def encode(bin) when is_binary(bin), do: ~s("#{bin}")

  defp encode_map(map) do
    kvstring =
      Enum.map(map, fn {k, v} ->
        ~s("#{k}":#{encode(v)})
      end)
      |> Enum.join(",")
    "{" <> kvstring <> "}"
  end

  defp encode_list(list) do
    liststr =
      Enum.map(list, &encode/1)
      |> Enum.join(",")
    "[" <> liststr <> "]"
  end
end
