defmodule RedstoneServerWeb.Jason do
  @moduledoc """
  Implementations for Jason.Encoder 
  """

  defimpl Jason.Encoder, for: [Ecto.Association.NotLoaded] do
    def encode(struct, opts) do
      Jason.Encode.value(nil, opts)
    end
  end
end
