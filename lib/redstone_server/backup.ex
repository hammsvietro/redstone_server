defmodule RedstoneServer.Backup do
  @moduledoc """
  Data access layer for the backup context
  """
  import Ecto.Query

  alias Ecto.Multi
  alias RedstoneServer.Repo
  alias RedstoneServer.Backup.{Backup, File, Update, UploadToken}

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
        "hash" => RedstoneServer.Crypto.generate_hash()
      })
    end)
    |> store_file_tree(files)
    |> Repo.transaction()
  end

  def get_backup(backup_id) do
    from(b in RedstoneServer.Backup.Backup,
      where: b.id == ^backup_id,
      preload: :files
    )
    |> Repo.one()
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
end
