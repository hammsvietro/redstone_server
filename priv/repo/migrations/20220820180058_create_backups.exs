defmodule RedstoneServer.Repo.Migrations.CreateBackups do
  use Ecto.Migration

  def change do
    create table(:backups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :watch, :boolean, default: false, null: false
      add :sync_every, :string
      add :relative_path, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:backups, [:user_id])
  end
end
