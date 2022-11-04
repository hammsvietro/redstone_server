defmodule RedstoneServer.Backup.UploadToken do
  use Ecto.Schema
  import Ecto.Changeset

  defimpl Jason.Encoder, for: RedstoneServer.Backup.UploadToken do
    def encode(struct, opts) do
      Enum.reduce(Map.from_struct(struct), %{}, fn
        {_k, %Ecto.Association.NotLoaded{}}, acc -> acc
        {:__meta__, _}, acc -> acc
        {:__struct__, _}, acc -> acc
        {k, v}, acc -> Map.put(acc, k, v)
      end)
      |> Jason.Encode.map(opts)
    end
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "upload_tokens" do
    field :token, :string
    belongs_to :user, RedstoneServer.Accounts.User
    belongs_to :backup, RedstoneServer.Backup.Backup

    timestamps()
  end

  def insert_changeset(%__MODULE__{} = update_token, attrs) do
    update_token
    |> cast(attrs, [:user_id, :backup_id])
    |> put_change(:token, RedstoneServer.Crypto.generate_hash())
    |> unsafe_validate_unique(:token, RedstoneServer.Repo)
    |> unique_constraint(:user_id)
    |> unique_constraint(:backup_id)
  end
end
