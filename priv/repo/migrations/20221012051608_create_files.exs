defmodule RedstoneServer.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string
      add :sha1_checksum, :string
      add :backup_id, references(:backups, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:files, [:backup_id])
  end
end
