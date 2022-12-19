defmodule RedstoneServer.Backup do
  @moduledoc """
  Service layer for the backup context
  """
  import Ecto.Query

  alias Ecto.Multi
  alias RedstoneServer.Repo
  alias RedstoneServer.Filesystem
  alias RedstoneServer.Backup.{Backup, File, Update, UploadToken, FileUpdate}

  def create_backup(name, user_id, files) do
    entrypoint = Filesystem.get_backup_entrypoint(name)

    transaction =
      Multi.new()
      |> _create_backup_multi(name, user_id, entrypoint)
      |> _store_file_tree(files)
      |> Repo.transaction()

    case transaction do
      {:ok, schemas} -> {:ok, schemas}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def get_backup(backup_id) do
    from(b in RedstoneServer.Backup.Backup,
      where: b.id == ^backup_id,
      preload: :files
    )
    |> Repo.one()
  end

  def get_backup_by_upload_token(token) do
    from(u in RedstoneServer.Backup.UploadToken,
      where: u.token == ^token,
      left_join: b in assoc(u, :backup),
      select: b
    )
    |> Repo.one()
  end

  @spec get_file(binary()) :: RedstoneServer.Backup.File.__struct__()
  def get_file(file_id) do
    from(f in RedstoneServer.Backup.File, where: f.id == ^file_id)
    |> Repo.one()
  end

  @doc """
  Returns the list of update_tokens.

  ## Examples

      iex> list_update_tokens()
      [%UploadToken{}, ...]

  """
  def list_update_tokens do
    Repo.all(UploadToken)
  end

  @doc """
  Gets a single update_token.

  Raises `Ecto.NoResultsError` if the Update token does not exist.

  ## Examples

      iex> get_update_token!(123)
      %UploadToken{}

      iex> get_update_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_update_token!(id), do: Repo.get!(UploadToken, id)

  @doc """
  Creates a update_token.
  ## Examples

      iex> create_update_token(%{field: value})
      {:ok, %UploadToken{}}

      iex> create_update_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_update_token(attrs \\ %{}) do
    %UploadToken{}
    |> UploadToken.insert_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a update_token.

  ## Examples

      iex> delete_update_token(update_token)
      {:ok, %UploadToken{}}

      iex> delete_update_token(update_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_update_token(%UploadToken{} = update_token) do
    Repo.delete(update_token)
  end

  defp _create_backup_multi(multi, name, user_id, path) do
    multi
    |> Multi.insert(
      :backup,
      RedstoneServer.Backup.Backup.changeset(%Backup{}, %{
        "name" => name,
        "created_by_id" => user_id,
        "entrypoint" => path
      })
    )
    |> Multi.insert(:update, fn %{backup: backup} ->
      RedstoneServer.Backup.Update.insert_changeset(%Update{}, %{
        "backup_id" => backup.id,
        "made_by_id" => user_id,
        "message" => "Bootstrap",
        "hash" => RedstoneServer.Crypto.generate_hash()
      })
    end)
  end

  defp _store_file_tree(multi, files) do
    Enum.reduce(files, multi, fn
      file, multi ->
        file_path = file["path"]

        multi
        |> Multi.insert(file_path, fn
          %{backup: backup} ->
            File.insert_changeset(
              %File{},
              %{
                "path" => file_path,
                "sha1_checksum" => file["sha_256_digest"],
                "backup_id" => backup.id
              }
            )
        end)
        |> Multi.insert(
          file_path <> "-update",
          fn %{^file_path => file, update: update} ->
            IO.inspect(file)

            FileUpdate.changeset(
              %FileUpdate{},
              %{
                "file_id" => file.id,
                "update_id" => update.id,
                "operation" => :add
              }
            )
          end
        )
    end)
  end
end
