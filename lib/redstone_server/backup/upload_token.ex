defmodule RedstoneServer.Backup.UploadToken do
  @moduledoc """
  Upload token schema module.

  This is used as a validation token when the client is uploading data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "upload_tokens" do
    field :token, :string
    belongs_to :user, RedstoneServer.Accounts.User
    belongs_to :backup, RedstoneServer.Backup.Backup
    belongs_to :update, RedstoneServer.Backup.Update

    timestamps()
  end

  def insert_changeset(%__MODULE__{} = upload_token, attrs) do
    upload_token
    |> cast(attrs, [:user_id, :backup_id, :update_id])
    |> put_change(:token, RedstoneServer.Crypto.generate_hash())
    |> unsafe_validate_unique(:token, RedstoneServer.Repo)
    |> unique_constraint(:user_id)
    |> unique_constraint(:backup_id)
    |> unique_constraint(:update_id)
  end
end
