defmodule RedstoneServerWeb.Tcp.Controller do
  @moduledoc """
  Controller layer for tcp messages.
  """

  alias RedstoneServer.Backup.Update
  alias RedstoneServer.Backup.Backup
  alias RedstoneServer.Backup.File, as: RSFile

  def process(%{"operation" => "UploadChunk"} = payload) do
    with %Backup{} = backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"]) do
      # TODO calculate sha_256 checksum and see if it matches
      path = Path.join(backup.entrypoint, file.path)

      {_file_name, folders} =
        path
        |> String.split("/", trim: true)
        |> List.pop_at(-1)

      file_chunk = payload["data"] |> elem(1)
      File.mkdir_p("/#{Enum.join(folders, "/")}/")
      File.write(path, file_chunk, [:append, :binary])
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
      files
      |> RedstoneServer.Filesystem.move_files_to_definitive_folder()
      |> RedstoneServer.Backup.update_paths_and_commit(update)
    end
  end

  def process(%{"operation" => "Abort"} = payload) do
  end
end
