defmodule RedstoneServer.Backup.File do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "files" do
    field :path, :string
    field :sha1_checksum, :string
    belongs_to :folder, RedstoneServer.Backup.Folder

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:path, :sha1_checksum])
    |> validate_required([:path, :sha1_checksum])
  end
end
