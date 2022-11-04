defmodule RedstoneServer.Repo.Migrations.CreateUploadTokens do
  use Ecto.Migration

  def change do
    create table(:upload_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :backup_id, references(:backups, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:upload_tokens, [:token], unique: true)
    create index(:upload_tokens, [:user_id])
    create index(:upload_tokens, [:backup_id])
  end
end
