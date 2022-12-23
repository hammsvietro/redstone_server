defmodule RedstoneServer.Repo.Migrations.CreateUpdates do
  use Ecto.Migration

  def change do
    create table(:updates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :message, :string
      add :hash, :string, null: false
      add :transaction_status, :string, default: "in_progress"
      add :error_message, :string
      add :made_by_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :backup_id, references(:backups, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:updates, [:made_by_id])
    create index(:updates, [:backup_id])
  end
end
