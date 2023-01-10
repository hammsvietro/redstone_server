defmodule RedstoneServerWeb.Tcp.Controller do
  @moduledoc """
  Controller layer for tcp messages.
  """

  alias RedstoneServer.Backup.Update
  alias RedstoneServer.Backup.Backup
  alias RedstoneServer.Filesystem
  alias RedstoneServerWeb.Tcp.Schemas
  alias RedstoneServer.Backup.File, as: RSFile

  def process(%{"operation" => "upload_chunk"} = payload) do
    IO.inspect("####")
    IO.inspect(Schemas.validate_upload_chunk(payload))
    IO.inspect("####")
    with %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"], backup.id) do
      temporary_path = Filesystem.get_temporary_file_path(backup.name, file.path)

      file_chunk = payload["data"] |> elem(1)

      Filesystem.create_folders_if_needed(temporary_path)
      Filesystem.write_data(temporary_path, file_chunk)
      wrap_response(:ok)
    else
      {:error, _} = error -> wrap_response(error)
      error -> wrap_response({:error, error})
    end
  end

  def process(%{"operation" => "commit"} = payload) do
    with %Backup{} = backup <-
      RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %Update{} = update <-
      RedstoneServer.Backup.get_update_by_upload_token(payload["upload_token"]),
         files <- RedstoneServer.Backup.get_files_changed_in_update(backup.id, operations: [:add, :update]) do
      {:ok, _} = RedstoneServer.Backup.update_update_status(update, :completed)
      Filesystem.move_files_to_definitive_folder(backup.name, files)
      wrap_response(:ok)
    end
  end

  def process(%{"operation" => "check_file"} = payload) do
    with %Backup{} = backup <-
      RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
      %RedstoneServer.Backup.File{} = file <- RedstoneServer.Backup.get_file(payload["file_id"], backup.id),
      true <- RedstoneServer.Filesystem.verify_checksum(file.sha256_checksum, Filesystem.get_temporary_file_path(backup.name, file.path)) do
      wrap_response(:ok)
    else
      error -> wrap_response(error)
    end
  end

  def process(%{"operation" => "abort"} = payload) do
  end

  defp wrap_response(response) do
    case response do
      {:error, error} -> %{status: "error", reason: error}
      :ok -> %{status: "ok"}
    end
  end
end
