defmodule RedstoneServer.Backup do
  @moduledoc """
  Service layer for the backup context.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias RedstoneServer.Repo
  alias RedstoneServer.Filesystem
  alias RedstoneServer.Backup.{Backup, File, Update, UploadToken, DownloadToken, FileUpdate}

  def create_backup(name, user_id, files) do
    entrypoint = Filesystem.get_temporary_backup_entrypoint(name)

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
      where: b.id == ^backup_id
    )
    |> Repo.one()
    |> Repo.preload([:created_by])
  end

  def get_backup_by_name(backup_name) do
    from(b in RedstoneServer.Backup.Backup,
      where: b.name == ^backup_name
    )
    |> Repo.one()
  end

  def get_last_update_of_backup(backup_id) do
    from(u in RedstoneServer.Backup.Update,
      where: u.backup_id == ^backup_id,
      limit: 1,
      order_by: [desc: :inserted_at]
    )
    |> Repo.one()
  end

  def get_backup_by_download_token(token) do
    from(u in RedstoneServer.Backup.DownloadToken,
      where: u.token == ^token,
      left_join: b in assoc(u, :backup),
      select: b
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

  def get_update_by_upload_token(token) do
    from(ut in UploadToken,
      where: ut.token == ^token,
      left_join: up in assoc(ut, :update),
      select: up
    )
    |> Repo.one()
  end

  @spec get_file(binary(), binary()) :: RedstoneServer.Backup.File.__struct__()
  def get_file(file_id, backup_id) do
    from(f in RedstoneServer.Backup.File, where: f.id == ^file_id and f.backup_id == ^backup_id)
    |> Repo.one()
  end

  def get_files_by_backup(backup_id) do
    from(f in RedstoneServer.Backup.File, where: f.backup_id == ^backup_id)
    |> Repo.all()
  end

  def get_files_changed_in_update(update_id, opts \\ []) do
    query =
      RedstoneServer.Backup.FileUpdate
      |> where([fu], fu.update_id == ^update_id)
      |> join(:left, [fu], f in assoc(fu, :file))
      |> select([_, f], f)

    Enum.reduce(opts, query, fn
      {:operations, operations}, query -> where(query, [fu], fu.operation in ^operations)
      _, query -> query
    end)
    |> Repo.all()
  end

  # def get_files_changed_in_update(update_id, opts) do
  #   Enum.reduce 
  # end

  def update_update_status(%Update{} = update, status) do
    update
    |> RedstoneServer.Backup.Update.update_status_changeset(status)
    |> Repo.update()
  end

  @doc """
  Returns the list of upload_tokens.

  ## Examples

      iex> list_upload_tokens()
      [%UploadToken{}, ...]

  """
  def list_upload_tokens do
    Repo.all(UploadToken)
  end

  @doc """
  Gets a single upload_token.

  Raises `Ecto.NoResultsError` if the Update token does not exist.

  ## Examples

      iex> get_upload_token!(123)
      %UploadToken{}

      iex> get_upload_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_upload_token!(id), do: Repo.get!(UploadToken, id)

  @doc """
  Creates a upload_token.
  ## Examples

      iex> create_upload_token(%{user_id: user.id, backup_id: backup.id, update_id: update.id})
      {:ok, %UploadToken{}}

      iex> create_upload_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_upload_token(attrs \\ %{}) do
    %UploadToken{}
    |> UploadToken.insert_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a upload_token.

  ## Examples

      iex> delete_upload_token(upload_token)
      {:ok, %UploadToken{}}

      iex> delete_upload_token(upload_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_upload_token(token) do
    from(ut in UploadToken, where: ut.token == ^token)
    |> Repo.one!()
    |> Repo.delete()
  end

  @doc """
  Creates a download_token.
  ## Examples

      iex> create_download_token(%{user_id: user.id, backup_id: backup.id})
      {:ok, %DownloadToken{}}

      iex> create_download_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_download_token(attrs \\ %{}) do
    %DownloadToken{}
    |> DownloadToken.insert_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a download_token.

  ## Examples

    iex> delete_download_token(download_token)
      {:ok, %DownloadToken{}}

      iex> delete_download_token(download_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_download_token(token) do
    from(ut in DownloadToken, where: ut.token == ^token)
    |> Repo.one!()
    |> Repo.delete()
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
                "sha256_checksum" => file["sha_256_digest"],
                "backup_id" => backup.id
              }
            )
        end)
        |> Multi.insert(
          file_path <> "-update",
          fn %{^file_path => file, update: update} ->
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
