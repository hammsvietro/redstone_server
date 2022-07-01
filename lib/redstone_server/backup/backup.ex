defmodule RedstoneServer.Backup.Backup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backups" do
    field :name, :string
    field :relative_path, :string
    field :sync_every, :string
    field :watch, :boolean, default: false
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(backup, attrs) do
    backup
    |> cast(attrs, [:name, :watch, :sync_every, :relative_path])
    |> validate_required([:name, :watch, :sync_every, :relative_path])
  end
end
