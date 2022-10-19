defmodule RedstoneServer.Backup do
  @moduledoc """
  Data access layer for the backup context
  """
  import Ecto.Query

  alias Ecto.Multi
  alias RedstoneServer.Repo
  alias RedstoneServer.Backup.{Backup, File, Update}

  def create_backup(name, user_id, files) do
    Multi.new()
    |> Multi.insert(
      :backup,
      RedstoneServer.Backup.Backup.changeset(%Backup{}, %{
        "name" => name,
        "created_by_id" => user_id,
        "entrypoint" => "CHANGEME"
      })
    )
    |> Multi.insert(:update, fn %{backup: backup} ->
      RedstoneServer.Backup.Update.insert_changeset(%Update{}, %{
        "backup_id" => backup.id,
        "made_by_id" => user_id,
        "message" => "Bootstrap",
        "hash" => generate_hash()
      })
    end)
    |> store_file_tree(files)
    |> Repo.transaction()
  end

  def get_backup(backup_id) do
    (from b in RedstoneServer.Backup.Backup,
      where: b.id == ^backup_id,
      preload: :files)
    |> Repo.one
  end

  defp store_file_tree(multi, files) do
    Enum.reduce(files, multi, fn
      file, multi ->
        multi
        |> Multi.insert(file["path"], fn
          %{backup: backup} ->
            File.insert_changeset(
              %File{},
              %{
                "path" => file["path"],
                "sha1_checksum" => file["sha_256_digest"],
                "backup_id" => backup.id
              }
            )
        end)
    end)
  end

  defp generate_hash() do
    :crypto.hash(:sha, [:crypto.strong_rand_bytes(4)]) |> Base.encode16() |> String.downcase()
  end
end
