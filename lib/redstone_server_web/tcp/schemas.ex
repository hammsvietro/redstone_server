defmodule RedstoneServerWeb.Tcp.Schemas do
  @moduledoc """
  Schemas for validating tcp messages
  """

  use Ecto.Schema
  import Ecto.Changeset

  def validate_upload_chunk_message(params) do
    upload_chunk = %{}
    types = %{upload_token: :string, file_id: :binary_id, data: :any}

    {upload_chunk, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end

  def validate_download_chunk_message(params) do
    download_chunk = %{}

    types = %{
      download_token: :string,
      file_id: :binary_id,
      byte_limit: :integer,
      offset: :integer
    }

    {download_chunk, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end

  def validate_finish_download_message(params) do
    download_chunk = %{}

    types = %{
      download_token: :string
    }

    {download_chunk, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end

  def validate_commit_message(params) do
    upload_chunk = %{}
    types = %{upload_token: :string}

    {upload_chunk, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end

  def validate_check_file_message(params) do
    upload_chunk = %{}
    types = %{upload_token: :string, file_id: :binary_id}

    {upload_chunk, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end
end
