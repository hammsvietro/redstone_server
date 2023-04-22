defmodule RedstoneServerWeb.Utils do
  @moduledoc """
  Collection of helper functions of the presentation layer of the app. 
  """

  def to_json(data) do
    data
    |> to_map()
    |> Enum.map(fn
      {key, %Ecto.Association.NotLoaded{}} -> {key, nil}
      {key, %Ecto.Schema.Metadata{}} -> {key, nil}
      {key, %NaiveDateTime{} = date} -> {key, date}
      {key, list} when is_list(list) -> {key, Enum.map(list, &to_json/1)}
      {key, %{} = map} -> {key, to_json(map)}
      otherwise -> otherwise
    end)
    |> Map.new()
  end

  def to_map(data) when is_struct(data), do: Map.from_struct(data)
  def to_map(data) when is_map(data), do: data
end
