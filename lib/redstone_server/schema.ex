defmodule RedstoneServer.Schema do
  @moduledoc """
  Schema definition.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(struct, opts) do
          Enum.reduce(Map.from_struct(struct), %{}, fn
            {_k, %Ecto.Association.NotLoaded{}}, acc -> acc
            {:__meta__, _}, acc -> acc
            {:__struct__, _}, acc -> acc
            {k, v}, acc -> Map.put(acc, k, v)
          end)
          |> Jason.Encode.map(opts)
        end
      end
    end
  end
end
