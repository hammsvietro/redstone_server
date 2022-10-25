defmodule RedstoneServer.BackupFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RedstoneServer.Backup` context.
  """

  @doc """
  Generate a update_token.
  """
  def update_token_fixture(attrs \\ %{}) do
    {:ok, update_token} =
      attrs
      |> Enum.into(%{
        token: "some token"
      })
      |> RedstoneServer.Backup.create_update_token()

    update_token
  end
end
