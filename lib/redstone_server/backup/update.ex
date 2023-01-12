defmodule RedstoneServer.Backup.Update do
  use RedstoneServer.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "updates" do
    field :hash, :string
    field :message, :string
    field :transaction_status, Ecto.Enum, values: [:in_progress, :completed, :aborted, :failed]
    field :error_message, :string
    belongs_to :made_by, RedstoneServer.Accounts.User
    belongs_to :backup, RedstoneServer.Backup.Backup

    timestamps()
  end

  @doc false
  def insert_changeset(%__schema__{} = update, attrs) do
    update
    |> cast(attrs, [:message, :hash, :made_by_id, :backup_id])
    |> foreign_key_constraint(:made_by_id)
    |> foreign_key_constraint(:backup_id)
    |> put_change(:transaction_status, :in_progress)
    |> validate_required([:message, :hash])
  end

  def update_status_changeset(%__schema__{} = update, status) do
    change(update, transaction_status: status)
  end
end
