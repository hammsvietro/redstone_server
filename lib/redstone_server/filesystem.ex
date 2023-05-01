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

  def remove_file(backup_name, file_path) do
    backup_name
    |> get_backup_entrypoint()
    |> Path.join(file_path)
    |> File.rm!()
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

  def apply_update_to_backup_folder(backup_name, files) do
    Enum.each(files, &_handle_file_move(&1, backup_name))

    remove_temporary_files(backup_name)
  end

  def remove_temporary_files(backup_name) do
    backup_name
    |> get_temporary_backup_entrypoint()
    |> File.rm_rf!()
  end

  def verify_checksum(checksum, file_path), do: checksum == _calculate_sha256(file_path)

  def get_file_size(backup_name, %RedstoneServer.Backup.File{} = file) do
    backup_name
    |> get_file_path(file.path)
    |> File.stat!()
    |> Map.get(:size)
  end

  defp _calculate_sha256(file_path) do
    File.stream!(file_path, [], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end

  defp _handle_file_move(
         %RedstoneServer.Backup.File{
           last_update: %RedstoneServer.Backup.FileUpdate{operation: :remove}
         } = file,
         backup_name
       ) do
    :ok =
      backup_name
      |> get_backup_entrypoint()
      |> Path.join(file.path)
      |> File.rm!()
  end

  defp _handle_file_move(
         %RedstoneServer.Backup.File{
           last_update: %RedstoneServer.Backup.FileUpdate{operation: :add}
         } = file,
         backup_name
       ) do
    temporary_path =
      backup_name
      |> get_temporary_backup_entrypoint()
      |> Path.join(file.path)

    definitive_path =
      backup_name
      |> get_backup_entrypoint()
      |> Path.join(file.path)

    :ok = create_folders_if_needed(definitive_path)

    # simply moving the file results in exdev error when using a mapped volume in docker
    # there might be a better solution to this

    :ok = File.cp(temporary_path, definitive_path)
    :ok = File.rm(temporary_path)
  end

  defp _handle_file_move(
         %RedstoneServer.Backup.File{
           last_update: %RedstoneServer.Backup.FileUpdate{operation: :update}
         } = file,
         backup_name
       ) do
    temporary_path =
      backup_name
      |> get_temporary_backup_entrypoint()
      |> Path.join(file.path)

    definitive_path =
      backup_name
      |> get_backup_entrypoint()
      |> Path.join(file.path)

    :ok = create_folders_if_needed(definitive_path)
    :ok = File.rm!(definitive_path)
    :ok = File.rename(temporary_path, definitive_path)
  end
end
