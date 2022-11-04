defmodule RedstoneServer.Backup.Backup do
  use Ecto.Schema
  import Ecto.Changeset

  defimpl Jason.Encoder, for: RedstoneServer.Backup.Backup do
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
  end
end
