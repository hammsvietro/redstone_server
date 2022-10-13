defmodule RedstoneServer.Backup.Folder do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "folders" do
    field :path, :string
    belongs_to :backup, RedstoneServer.Backup.Backup
    belongs_to :parent, RedstoneServer.Backup.Folder
    has_many :files, RedstoneServer.Backup.File

    timestamps()
  end

  @doc false
  def insert_changeset(folder, attrs) do
    folder
    |> cast(attrs, [:path, :backup_id, :parent_id])
    |> foreign_key_constraint(:backup_id)
    |> validate_required([:path])
  end
end
