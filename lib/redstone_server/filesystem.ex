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

  def get_temporary_file_path(backup_name, relative_file_path) do
    backup_name
    |> get_temporary_backup_entrypoint()
    |> Path.join(relative_file_path)
  end

  def get_file_path(backup_name, relative_file_path) do
    backup_name
    |> get_backup_entrypoint()
    |> Path.join(relative_file_path)
  end

  def create_folders_if_needed(file_name) do
    {_file_name, folders} =
      file_name
      |> String.split("/", trim: true)
      |> List.pop_at(-1)

    File.mkdir_p("/#{Enum.join(folders, "/")}/")
  end

  def write_data(path, data), do: File.write(path, data, [:append, :binary])

  def move_files_to_definitive_folder(backup_name, files) do
    Enum.each(files, fn file ->
      temporary_path =
        backup_name
        |> get_temporary_backup_entrypoint()
        |> Path.join(file.path)

      definitive_path =
        backup_name
        |> get_backup_entrypoint()
        |> Path.join(file.path)

      :ok = create_folders_if_needed(definitive_path)
      :ok = File.rename(temporary_path, definitive_path)
    end)
  end

  def verify_checksum(checksum, file_path), do: checksum == _calculate_sha256(file_path)

  defp _calculate_sha256(file_path) do
    File.stream!(file_path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end

  def get_file_size(backup_name, %RedstoneServer.Backup.File{} = file) do
    backup_name
    |> get_file_path(file.path)
    |> File.stat!()
    |> Map.get(:size)
  end
end
