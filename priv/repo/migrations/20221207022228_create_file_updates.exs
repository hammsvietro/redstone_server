defmodule RedstoneServer.Repo.Migrations.CreateFileUpdates do
  use Ecto.Migration

  def change do
    create table(:file_updates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :operation, :string
      add :file_id, references(:files, on_delete: :delete_all, type: :binary_id)
      add :update_id, references(:updates, on_delete: :delete_all, type: :binary_id)
      add :backup_id, references(:backups, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:file_updates, [:file_id])
    create index(:file_updates, [:update_id])
    create index(:file_updates, [:backup_id])
  end
end
