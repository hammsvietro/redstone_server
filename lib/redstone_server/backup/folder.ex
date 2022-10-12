defmodule RedstoneServer.Backup.Folder do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "folders" do
    field :path, :string
    field :backup_id, :binary_id
    field :parent_id, :binary_id
    belongs_to :parent, RedstoneServer.Backup.Folder
    has_many :files, RedstoneServer.Backup.Files

    timestamps()
  end

  @doc false
  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:path])
    |> validate_required([:path])
  end
end
