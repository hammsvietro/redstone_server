defmodule RedstoneServerWeb.Websocket.Controller do
  @moduledoc """
  Controller layer for websocket interactions.
  """

  alias RedstoneServer.Backup.Update
  alias RedstoneServer.Backup.Backup
  alias RedstoneServer.Filesystem
  alias RedstoneServerWeb.Tcp.Schemas
  alias RedstoneServer.Backup.File, as: RSFile

  def process?(%{"operation" => operation}) do
    Enum.member?(["commit", "check_file", "download_chunk", "finish_download"], operation)
  end

  def update_state?(%{"operation" => operation}), do: operation == "prepare_file_upload"

  # TODO: Change to a specific funcion
  def process(%{"operation" => "upload_chunk"} = payload) do
    with %{valid?: true} <- Schemas.validate_upload_chunk_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         {_, true} <- {:has_write_lock, RedstoneServer.Lock.has_write_lock(backup.name)},
         %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"], backup.id) do
      temporary_path = Filesystem.get_temporary_file_path(backup.name, file.path)

      file_chunk = payload["data"] |> elem(1)

      Filesystem.create_folders_if_needed(temporary_path)
      Filesystem.write_data(temporary_path, file_chunk)
      :ok
    else
      error -> handle_upload_error(error, payload)
    end
  end

  def process(%{"operation" => "commit"} = payload) do
    with %{valid?: true} <- Schemas.validate_commit_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         {_, true} <- {:has_write_lock, RedstoneServer.Lock.has_write_lock(backup.name)},
         %Update{} = update <-
           RedstoneServer.Backup.get_update_by_upload_token(payload["upload_token"]),
         files <-
           RedstoneServer.Backup.get_files_changed_in_update(update.id) do
      {:ok, _} = RedstoneServer.Backup.update_update_status(update, :completed)
      Filesystem.apply_update_to_backup_folder(backup.name, files)
      RedstoneServer.Lock.unlock(backup.name)
      RedstoneServer.Backup.delete_upload_token(payload["upload_token"])
      :ok
    else
      error -> handle_upload_error(error, payload)
    end
  end

  def process(%{"operation" => "check_file"} = payload) do
    with %{valid?: true} <- Schemas.validate_check_file_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         {_, true} <- {:has_write_lock, RedstoneServer.Lock.has_write_lock(backup.name)},
         %RedstoneServer.Backup.File{} = file <-
           RedstoneServer.Backup.get_file(payload["file_id"], backup.id) do
      case Filesystem.verify_checksum(
             file.sha256_checksum,
             Filesystem.get_temporary_file_path(backup.name, file.path)
           ) do
        true -> :ok
        false -> :retry
      end
    else
      error -> handle_upload_error(error, payload)
    end
  end

  def process(%{"operation" => "download_chunk"} = payload) do
    with %{valid?: true} <- Schemas.validate_download_chunk_message(payload),
         %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_download_token(payload["download_token"]),
         {_, true} <- {:has_read_lock, RedstoneServer.Lock.has_read_lock(backup.name)},
         %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"], backup.id) do
      path = Filesystem.get_file_path(backup.name, file.path)
      byte_limit = payload["byte_limit"]
      skip = payload["offset"] * byte_limit

      {:ok, file} = :file.open(path, [:read, :raw])
      read_result = :file.pread(file, skip, byte_limit)
      :file.close(file)

      case read_result do
        :eof -> ""
        {:ok, data} -> data
        error -> error
      end
    else
      {:has_read_lock, false} ->
        RedstoneServer.Backup.delete_download_token(payload["download_token"])
        {:error, "No backup write lock found."}
    end
  end

  def process(%{"operation" => "finish_download"} = payload) do
    %Backup{name: backup_name} =
      RedstoneServer.Backup.get_backup_by_download_token(payload["download_token"])

    RedstoneServer.Lock.unlock(backup_name)

    RedstoneServer.Backup.delete_download_token(payload["download_token"])
    :ok
  end

  defp handle_upload_error(error, payload) do
    error_message =
      case error do
        {:has_write_lock, false} ->
          "No backup write lock found."

        %{valid?: false} = changeset ->
          RedstoneServerWeb.ErrorHelpers.changeset_error_to_string(changeset)

        {:error, error_message} ->
          error_message

        error when is_binary(error) ->
          error
      end

    abort_upload(payload["upload_token"], error_message)
    {:error, error_message}
  end

  defp abort_upload(upload_token, error) do
    %Backup{name: backup_name} = RedstoneServer.Backup.get_backup_by_upload_token(upload_token)
    RedstoneServer.Lock.unlock(backup_name)
    %Update{} = update = RedstoneServer.Backup.get_update_by_upload_token(upload_token)
    RedstoneServer.Backup.fail_update(update, error)
    Filesystem.remove_temporary_files(backup_name)
  end
end
