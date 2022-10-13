defmodule RedstoneServer.Backup.Backup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backups" do
    field :name, :string
    belongs_to :created_by, RedstoneServer.Accounts.User
    has_many :updates, RedstoneServer.Backup.Update
    has_many :folders, RedstoneServer.Backup.Folder
    has_many :files, RedstoneServer.Backup.File

    timestamps()
  end

  @doc false
  def changeset(backup, attrs) do
    backup
    |> cast(attrs, [:name, :created_by_id])
    |> foreign_key_constraint(:created_by_id)
    |> validate_required([:name])
  end
end
