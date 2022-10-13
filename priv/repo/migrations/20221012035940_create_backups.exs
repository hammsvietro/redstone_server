defmodule RedstoneServer.Repo.Migrations.CreateBackups do
  use Ecto.Migration

  def change do
    create table(:backups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :created_by_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:backups, [:created_by_id])
  end
end
