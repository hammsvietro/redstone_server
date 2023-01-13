defmodule RedstoneServer.BackupFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RedstoneServer.Backup` context.
  """

  @doc """
  Generate a upload_token.
  """
  def upload_token_fixture(attrs \\ %{backup_name: "test"}) do
    {:ok, user} =
      RedstoneServer.Accounts.register_user(%{email: "admin@admin.com", password: "123123123123"})

    {:ok, %{backup: %{id: backup_id}, update: %{id: update_id}}} =
      RedstoneServer.Backup.create_backup(attrs.backup_name, user.id, [])

    attrs = %{
      backup_id: backup_id,
      update_id: update_id,
      user_id: user.id
    }

    {:ok, upload_token} = attrs |> RedstoneServer.Backup.create_upload_token()

    upload_token
  end
end
