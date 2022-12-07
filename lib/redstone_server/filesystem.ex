defmodule RedstoneServer.Filesystem do
  @moduledoc """
  Functions for gathering info and manipulating the filesystem
  """
  @base_backups_path Path.expand("priv/backups/")
  @base_temporary_backups_path Path.expand("priv/backups/")

  def get_backup_entrypoint(backup_name), do: Path.join(@base_backups_path, backup_name)
  def get_temporary_backup_entrypoint(backup_name), do: Path.join(@base_temporary_backups_path, backup_name)
end
