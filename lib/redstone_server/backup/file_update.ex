defmodule RedstoneServer.Backup.FileUpdate do
  @moduledoc """
  File update schema module
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "file_updates" do
    field :operation, Ecto.Enum, values: [:add, :update, :remove]
    belongs_to :file, RedstoneServer.Backup.File, type: :binary_id
    belongs_to :update, RedstoneServer.Backup.Update, type: :binary_id
    belongs_to :backup, RedstoneServer.Backup.Backup, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(file_update, attrs) do
    file_update
    |> cast(attrs, [:operation, :file_id, :update_id, :backup_id])
    |> validate_required([:operation])
  end
end
