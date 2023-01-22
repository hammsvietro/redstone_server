defmodule RedstoneServer.Repo.Migrations.CreateDownloadTokens do
  use Ecto.Migration

  def change do
    create table(:download_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string
      add :backup_id, references(:backups, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:download_tokens, [:backup_id])
    create index(:download_tokens, [:user_id])
  end
end
