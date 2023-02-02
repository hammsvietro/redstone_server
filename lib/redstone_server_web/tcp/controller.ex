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
    with %{valid?: true} <- Schemas.validate_upload_chunk_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"], backup.id) do
      temporary_path = Filesystem.get_temporary_file_path(backup.name, file.path)

      file_chunk = payload["data"] |> elem(1)

      Filesystem.create_folders_if_needed(temporary_path)
      Filesystem.write_data(temporary_path, file_chunk)
      :ok
    else
      %{valid?: false} = changeset ->
        {:error, RedstoneServerWeb.ErrorHelpers.changeset_error_to_string(changeset)}

      {:error, _} = error ->
        error

      error ->
        {:error, error}
    end
  end

  def process(%{"operation" => "commit"} = payload) do
    with %{valid?: true} <- Schemas.validate_commit_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %Update{} = update <-
           RedstoneServer.Backup.get_update_by_upload_token(payload["upload_token"]),
         files <-
           RedstoneServer.Backup.get_files_changed_in_update(update.id,
             operations: [:add, :update]
           ) do
      {:ok, _} = RedstoneServer.Backup.update_update_status(update, :completed)
      Filesystem.move_files_to_definitive_folder(backup.name, files)
      RedstoneServer.Backup.delete_upload_token(payload["upload_token"])
      :ok
    else
      %{valid?: false} = changeset ->
        {:error, RedstoneServerWeb.ErrorHelpers.changeset_error_to_string(changeset)}

      {:error, _} = error ->
        error

      error ->
        {:error, error}
    end
  end

  def process(%{"operation" => "check_file"} = payload) do
    with %{valid?: true} <- Schemas.validate_check_file_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %RedstoneServer.Backup.File{} = file <-
           RedstoneServer.Backup.get_file(payload["file_id"], backup.id),
         true <-
           Filesystem.verify_checksum(
             file.sha256_checksum,
             Filesystem.get_temporary_file_path(backup.name, file.path)
           ) do
      :ok
    else
      false ->
        {:error, "Checksum error"}

      %{valid?: false} = changeset ->
        {:error, RedstoneServerWeb.ErrorHelpers.changeset_error_to_string(changeset)}

      {:error, _} = error ->
        error

      error ->
        error
    end
  end

  def process(%{"operation" => "download_chunk"} = payload) do
    with %{valid?: true} <- Schemas.validate_download_chunk_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_download_token(payload["download_token"]),
         %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"], backup.id) do
      path = Filesystem.get_file_path(backup.name, file.path)
      byte_limit = payload["byte_limit"]
      skip = payload["offset"] * byte_limit

      {:ok, file} = :file.open(path, [:read, :raw])
      :file.position(file, skip)

      case :file.read(file, byte_limit) do
        :eof -> {:ok, nil}
        {:ok, data} -> {:ok, data}
        error -> error
      end
    end
  end

  def process(%{"operation" => "finish_download"} = payload) do
    RedstoneServer.Backup.delete_download_token(payload["download_token"])
    :ok
  end

  def process(%{"operation" => "abort"} = _payload) do
    # TODO: implement it
  end
end
