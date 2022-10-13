defmodule RedstoneServer.Backup do
  @moduledoc """
  Data access layer for the backup context
  """
  alias Ecto.Multi

  alias RedstoneServer.Repo
  alias RedstoneServer.Backup.{Backup, File, Folder}

  def create_backup(name, user_id, files) do
    Multi.new()
    |> Multi.insert(
      :backup,
      RedstoneServer.Backup.Backup.changeset(%Backup{}, %{
        "name" => name,
        "created_by_id" => user_id
      })
    )
    |> store_file_tree(files)
    |> Repo.transaction()
  end

  def store_file_tree(multi, files, parent_path \\ nil) do
    Enum.reduce(files, multi, fn
      %{"File" => file}, multi ->
        multi
        |> Multi.insert(file["path"], fn
          %{^parent_path => folder, backup: backup} ->
            File.insert_changeset(
              %File{},
              %{
                "path" => file["path"],
                "sha1_checksum" => file["sha_256_digest"],
                "folder_id" => folder.id,
                "backup_id" => backup.id
              }
            )
        end)

      %{"Folder" => folder}, multi ->
        multi
        |> Multi.insert(folder["path"], fn
          %{^parent_path => parent, backup: backup} ->
            Folder.insert_changeset(
              %Folder{},
              %{"backup_id" => backup.id, "parent_id" => parent.id, "path" => folder["path"]}
            )

          %{backup: backup} ->
            Folder.insert_changeset(%Folder{}, %{
              "backup_id" => backup.id,
              "path" => folder["path"]
            })
        end)
        |> store_file_tree(folder["items"], folder["path"])
    end)
  end
end
