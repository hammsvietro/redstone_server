defmodule RedstoneServer.Repo.Migrations.CreateFolders do
  use Ecto.Migration

  def change do
    create table(:folders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string
      add :backup_id, references(:backups, on_delete: :nothing, type: :binary_id)
      add :parent_id, references(:folders, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:folders, [:backup_id])
    create index(:folders, [:parent_id])
  end
end
