defmodule RedstoneServer.Crypto do
  @moduledoc """
  Crypto functions for general
  """

  def generate_hash() do
    :crypto.hash(:sha, [:crypto.strong_rand_bytes(4)]) |> Base.encode16() |> String.downcase()
  end
end
