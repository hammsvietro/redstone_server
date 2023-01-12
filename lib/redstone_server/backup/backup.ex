defmodule RedstoneServer.Backup.Backup do
  use RedstoneServer.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backups" do
    field :name, :string
    field :entrypoint, :string
    belongs_to :created_by, RedstoneServer.Accounts.User
    has_many :updates, RedstoneServer.Backup.Update
    has_many :files, RedstoneServer.Backup.File

    timestamps()
  end

  @doc false
  def changeset(backup, attrs) do
    backup
    |> cast(attrs, [:name, :created_by_id, :entrypoint])
    |> foreign_key_constraint(:created_by_id)
    |> validate_required([:name, :entrypoint])
    |> unique_constraint(:name)
  end
end
