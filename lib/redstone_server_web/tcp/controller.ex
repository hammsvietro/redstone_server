defmodule RedstoneServerWeb.Tcp.Controller do
  @moduledoc """
  Controller layer for tcp messages.
  """

  alias RedstoneServer.Backup.Backup
  alias RedstoneServer.Backup.File, as: RSFile

  def process(%{"operation" => "UploadChunk"} = payload) do
    with %Backup{} = _backup <-
           RedstoneServer.Backup.get_backup_by_upload_token(payload["upload_token"]),
         %RSFile{} = file <- RedstoneServer.Backup.get_file(payload["file_id"]) do
      # TODO calculate sha_256 checksum and see if it matches
      path = Path.join(System.user_home!(), "backup_test/#{file.path}")

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

  def process("Abort", payload) do
  end
end
