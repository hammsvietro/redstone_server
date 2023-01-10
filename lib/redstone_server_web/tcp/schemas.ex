defmodule RedstoneServerWeb.Tcp.Schemas do
  @moduledoc """
  Schemas for validating tcp messages
  """
  
  use Ecto.Schema
  import Ecto.Changeset

  def validate_upload_chunk(params) do
    upload_chunk = %{}
    types = %{upload_token: :string, file_id: :binary_id, data: :any}

    {upload_chunk, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end
end
