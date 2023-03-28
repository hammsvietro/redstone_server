defmodule RedstoneServer.Backup do
  @moduledoc """
  Service layer for the backup context.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias RedstoneServer.Repo
  alias RedstoneServer.Filesystem
  alias RedstoneServer.Backup.{Backup, File, Update, UploadToken, DownloadToken, FileUpdate}

  @two_minutes 120_000

  def create_backup(name, user_id, files) do
    entrypoint = Filesystem.get_temporary_backup_entrypoint(name)

    transaction =
      Multi.new()
      |> _create_backup_multi(name, user_id, entrypoint)
      |> _store_file_tree(files)
      |> Repo.transaction(timeout: @two_minutes)

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

  def update_files(backup, files, user_id) do
    transaction =
      Multi.new()
      |> _create_update(backup, user_id)
      |> _update_file_tree(files, backup)
      |> Repo.transaction()

    case transaction do
      {:ok, schemas} -> {:ok, schemas}
      {:error, _, changeset, _} -> {:error, changeset}
    end
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

  def get_latest_update(backup_id) do
    from(u in Update,
      where: u.backup_id == ^backup_id and u.transaction_status == :completed,
      order_by: [desc: u.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @spec get_file(binary(), binary()) :: RedstoneServer.Backup.File.__struct__()
  def get_file(file_id, backup_id) do
    from(f in RedstoneServer.Backup.File, where: f.id == ^file_id and f.backup_id == ^backup_id)
    |> Repo.one()
  end

  def get_files_by_backup(backup_id) do
    changed_file_ids_subquery =
      RedstoneServer.Backup.FileUpdate
      |> where([fu], fu.backup_id == ^backup_id)
      |> group_by([fu], fu.file_id)
      |> select([fu], fu.file_id)

    _build_files_changed_query(changed_file_ids_subquery,
      with_transaction_status: :completed,
      only_operations: [:add, :update]
    )
    |> Repo.all()
  end

  def get_files_changed_in_update(update_id, opts \\ []) do
    query =
      RedstoneServer.Backup.FileUpdate
      |> where([fu], fu.update_id == ^update_id)
      |> join(:inner, [fu], f in assoc(fu, :file))
      |> select([_, file], file)
      |> select_merge([fu], %{last_update: fu})

    Enum.reduce(opts, query, fn
      {:operations, operations}, query -> where(query, [fu], fu.operation in ^operations)
      _, query -> query
    end)
    |> Repo.all()
  end

  @doc """
  Gets a Update by a given id.
  """
  def get_update(update_id) do
    from(u in RedstoneServer.Backup.Update, where: u.id == ^update_id)
    |> Repo.one()
  end

  @doc """
  Returns all files that has been changed since the last update with last_update field loaded
  """
  def get_files_changed_since_update(%Update{} = update) do
    changed_file_ids_subquery =
      RedstoneServer.Backup.FileUpdate
      |> where([fu], fu.inserted_at > ^update.inserted_at and fu.backup_id == ^update.backup_id)
      |> group_by([fu], fu.file_id)
      |> select([fu], fu.file_id)

    _build_files_changed_query(changed_file_ids_subquery, with_transaction_status: :completed)
    |> Repo.all()
  end

  def update_update_status(%Update{} = update, status) do
    update
    |> RedstoneServer.Backup.Update.update_status_changeset(status)
    |> Repo.update()
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

  @doc """
  Gets a single download_token.

  Raises `Ecto.NoResultsError` if the Downdate token does not exist.

  ## Examples

      iex> get_download_token!(123)
      %DownloadToken{}

      iex> get_download_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_download_token!(id), do: Repo.get!(DownloadToken, id)

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
        operation = file["operation"]

        multi
        |> Multi.insert(file_path, fn
          %{backup: backup} ->
            File.changeset(
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
          fn %{^file_path => db_file, update: update, backup: backup} ->
            FileUpdate.changeset(
              %FileUpdate{},
              %{
                "file_id" => db_file.id,
                "update_id" => update.id,
                "backup_id" => backup.id,
                "operation" => operation
              }
            )
          end
        )
    end)
  end

  defp _create_update(multi, backup, user_id) do
    Multi.insert(
      multi,
      :update,
      RedstoneServer.Backup.Update.insert_changeset(%Update{}, %{
        "backup_id" => backup.id,
        "made_by_id" => user_id,
        "message" => "Push",
        "hash" => RedstoneServer.Crypto.generate_hash()
      })
    )
  end

  defp _update_file_tree(multi, files, backup) do
    Enum.reduce(files, multi, fn
      file, multi ->
        file_path = file["path"]
        operation = file["operation"]

        multi
        |> _handle_file_for_operation(file, operation)
        |> Multi.insert(
          file_path <> "-update",
          fn
            %{^file_path => file, update: update} ->
              FileUpdate.changeset(
                %FileUpdate{},
                %{
                  "file_id" => file.id,
                  "update_id" => update.id,
                  "backup_id" => backup.id,
                  "operation" => operation
                }
              )

            %{update: update} ->
              file =
                from(f in RedstoneServer.Backup.File,
                  where: f.path == ^file_path and f.backup_id == ^backup.id
                )
                |> Repo.one!()

              FileUpdate.changeset(
                %FileUpdate{},
                %{
                  "file_id" => file.id,
                  "update_id" => update.id,
                  "backup_id" => backup.id,
                  "operation" => operation
                }
              )
          end
        )
    end)
  end

  defp _handle_file_for_operation(multi, _file, "remove"), do: multi

  defp _handle_file_for_operation(multi, file, "update") do
    file_path = file["path"]

    Multi.update(multi, file_path, fn %{update: update} ->
      db_file =
        from(f in File, where: f.path == ^file_path and f.backup_id == ^update.backup_id)
        |> Repo.one!()

      File.changeset(
        db_file,
        %{
          "sha256_checksum" => file["sha_256_digest"]
        }
      )
    end)
  end

  defp _handle_file_for_operation(multi, file, "add") do
    file_path = file["path"]

    Multi.insert(multi, file_path, fn
      %{update: update} ->
        File.changeset(
          %File{},
          %{
            "path" => file_path,
            "sha256_checksum" => file["sha_256_digest"],
            "backup_id" => update.backup_id
          }
        )
    end)
  end

  defp _build_files_changed_query(files_changed_subquery, opts) do
    query =
      RedstoneServer.Backup.FileUpdate
      |> join(:left, [fu1], fu2 in RedstoneServer.Backup.FileUpdate,
        on: fu1.file_id == fu2.file_id and fu1.inserted_at < fu2.inserted_at
      )
      |> join(:inner, [fu1], file in assoc(fu1, :file))
      |> join(:inner, [fu1], update in assoc(fu1, :update))
      |> where(
        [fu1, fu2],
        is_nil(fu2) and
          fu1.file_id in subquery(files_changed_subquery)
      )
      |> select([_, _, file], file)
      |> select_merge([f1], %{last_update: f1})

    Enum.reduce(opts, query, fn
      {:only_operations, operations}, query ->
        where(query, [fu, _, _, _], fu.operation in ^operations)

      {:with_transaction_status, status}, query ->
        where(query, [_, _, _, update], update.transaction_status == ^status)

      _, query ->
        query
    end)
  end
end
