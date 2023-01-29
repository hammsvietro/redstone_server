defmodule RedstoneServer.BackupFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RedstoneServer.Backup` context.
  """

  @doc """
  Generate a backup and update

  Returns a {%Backup{}, %Update{}} tuple
  """
  def backup_fixture(attrs \\ %{}) do
    backup_name = Map.get(attrs, :backup_name, "test")

    user_id =
      case Map.get(attrs, :user_id) do
        nil ->
          {:ok, user} =
            RedstoneServer.Accounts.register_user(%{
              email: "admin@admin.com",
              password: "123123123123"
            })

          user.id

        user_id ->
          user_id
      end

    files = Map.get(attrs, :files, [])

    {:ok, %{backup: backup, update: update}} =
      RedstoneServer.Backup.create_backup(backup_name, user_id, files)

    {backup, update}
  end

  @doc """
  Generate a upload_token.
  """
  def upload_token_fixture(attrs \\ %{backup_name: "test"}) do
    {:ok, user} =
      RedstoneServer.Accounts.register_user(%{email: "admin@admin.com", password: "123123123123"})

    {backup, update} =
      attrs
      |> Map.merge(%{user_id: user.id})
      |> backup_fixture()

    attrs = %{
      backup_id: backup.id,
      update_id: update.id,
      user_id: user.id
    }

    {:ok, upload_token} = RedstoneServer.Backup.create_upload_token(attrs)

    upload_token
  end

  @doc """
  Generate a download_token.
  """
  def download_token_fixture(attrs \\ %{backup_name: "test"}) do
    {:ok, user} =
      RedstoneServer.Accounts.register_user(%{email: "admin@admin.com", password: "123123123123"})

    {:ok, %{backup: %{id: backup_id}}} =
      RedstoneServer.Backup.create_backup(attrs.backup_name, user.id, [])

    attrs = %{
      backup_id: backup_id,
      user_id: user.id
    }

    {:ok, upload_token} = attrs |> RedstoneServer.Backup.create_download_token()

    upload_token
  end
end
