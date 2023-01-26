defmodule RedstoneServer.Backup.DownloadToken do
  @moduledoc """
  Download token schema module.

  This is used as a validation token when the client is downloading data.
  """

  use RedstoneServer.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "download_tokens" do
    field :token, :string
    belongs_to :user, RedstoneServer.Accounts.User
    belongs_to :backup, RedstoneServer.Backup.Backup

    timestamps()
  end

  @doc false
  def insert_changeset(%__MODULE__{} = download_token, attrs) do
    download_token
    |> cast(attrs, [:user_id, :backup_id])
    |> put_change(:token, RedstoneServer.Crypto.generate_hash())
    |> unsafe_validate_unique(:token, RedstoneServer.Repo)
    |> unique_constraint(:user_id)
    |> unique_constraint(:backup_id)
  end
end
