defmodule RedstoneServer.Backup.Update do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "updates" do
    field :hash, :string
    field :message, :string
    field :transaction_completed, :boolean
    belongs_to :made_by, RedstoneServer.Accounts.User
    belongs_to :backup, RedstoneServer.Backup.Backup

    timestamps()
  end

  @doc false
  def insert_changeset(%__schema__{} = update, attrs) do
    update
    |> cast(attrs, [:message, :hash, :made_by_id, :backup_id])
    |> foreign_key_constraint(:made_by_id)
    |> foreign_key_constraint(:backup_id)
    |> put_change(:transaction_completed, false)
    |> validate_required([:message, :hash])
  end
end
