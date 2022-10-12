defmodule RedstoneServer.Backup.Update do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "updates" do
    field :hash, :string
    field :message, :string
    belongs_to :made_by, RedstoneServer.Accounts.User
    belongs_to :backup, RedstoneServer.Backup.Backup

    timestamps()
  end

  @doc false
  def changeset(update, attrs) do
    update
    |> cast(attrs, [:message, :hash])
    |> validate_required([:message, :hash])
  end
end
