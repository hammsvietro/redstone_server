defmodule RedstoneServerWeb.Tcp.Controller do
  @moduledoc """
  Controller layer for tcp messages.
  """

  alias RedstoneServer.Backup.Update
  alias RedstoneServer.Backup.Backup
  alias RedstoneServer.Filesystem
  alias RedstoneServer.Backup.File, as: RSFile

  def process(%{"operation" => "UploadChunk"} = payload) do
    with %Backup{} = backup <-
        RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
        %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"]) do

      temporary_path = 
        backup.name
        |> Filesystem.get_temporary_backup_entrypoint()
        |> Path.join(file.path)

      file_chunk = payload["data"] |> elem(1)
        
      Filesystem.create_folders_if_needed(temporary_path)
      Filesystem.write_data(temporary_path, file_chunk)
    else
      {:error, _} = err -> err
    end
  end

  def process(%{"operation" => "Commit"} = payload) do
    # TODO: move files to definitive folder and change update status to completed
    with %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %Update{} = update <-
           RedstoneServer.Backup.get_update_by_upload_token(payload["upload_token"]),
         files <- RedstoneServer.Backup.get_files_by_backup(backup.id) do
      
      Filesystem.move_files_to_definitive_folder(backup.name, files)
      RedstoneServer.Backup.update_update_status(update, :completed)
    end
    
  end

  def process(%{"operation" => "Abort"} = payload) do
  end
end
