defmodule RedstoneServer.Filesystem do
  @moduledoc """
  Functions for gathering info and manipulating the filesystem
  """
  @base_backups_path Path.expand("priv/backups/")
  @base_temporary_backups_path Path.expand("priv/temporary_backups/")

  def get_base_backups_path, do: @base_backups_path
  def get_base_temporary_backups_path, do: @base_temporary_backups_path

  def get_backup_entrypoint(backup_name), do: Path.join(@base_backups_path, backup_name)

  def get_temporary_backup_entrypoint(backup_name),
    do: Path.join(@base_temporary_backups_path, backup_name)

  def move_files_to_definitive_folder(files) do
    Enum.map(files, fn file ->
      definitive_path =
        file.path |> String.replace(@base_temporary_backups_path, @base_backups_path)

      File.rename(file.path, definitive_path)
      RedstoneServer.Backup.File.update_path_changeset(file, definitive_path)
    end)
  end
end
