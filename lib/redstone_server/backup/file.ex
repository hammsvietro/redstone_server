defmodule RedstoneServer.Backup.File do
  use Ecto.Schema
  import Ecto.Changeset

  defimpl Jason.Encoder, for: RedstoneServer.Backup.File do
    def encode(struct, opts) do
      Enum.reduce(Map.from_struct(struct), %{}, fn
        {_k, %Ecto.Association.NotLoaded{}}, acc -> acc
        {:__meta__, _}, acc -> acc
        {:__struct__, _}, acc -> acc
        {k, v}, acc -> Map.put(acc, k, v)
      end)
      |> Jason.Encode.map(opts)
    end
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "files" do
    field :path, :string
    field :sha1_checksum, :string
    belongs_to :backup, RedstoneServer.Backup.Backup, type: :binary_id

    timestamps()
  end

  @doc false
  def insert_changeset(file, attrs) do
    file
    |> cast(attrs, [:path, :sha1_checksum, :backup_id])
    |> foreign_key_constraint(:folder_id)
    |> validate_required([:path, :sha1_checksum])
  end
end
