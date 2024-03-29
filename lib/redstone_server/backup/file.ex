defmodule RedstoneServer.Backup.File do
  @moduledoc """
  File schema module.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias RedstoneServer.Filesystem

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "files" do
    field :path, :string
    field :sha256_checksum, :string
    field :last_update, :any, virtual: true
    belongs_to :backup, RedstoneServer.Backup.Backup, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:path, :sha256_checksum, :backup_id])
    |> validate_required([:path, :sha256_checksum])
  end

  def update_path_changeset(file, path) do
    file
    |> change(path: path)
    |> validate_required([:path, :sha256_checksum])
  end

  def with_temporary_backup_path(%__MODULE__{} = file),
    do: %__MODULE__{
      file
      | path:
          String.replace(
            file.path,
            Filesystem.get_base_backups_path(),
            Filesystem.get_base_temporary_backups_path()
          )
    }
end
