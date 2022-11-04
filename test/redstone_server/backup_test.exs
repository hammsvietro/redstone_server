defmodule RedstoneServer.BackupTest do
  use RedstoneServer.DataCase

  alias RedstoneServer.Backup

  describe "update_tokens" do
    alias RedstoneServer.Backup.UploadToken

    import RedstoneServer.BackupFixtures

    @invalid_attrs %{token: nil}

    test "list_update_tokens/0 returns all update_tokens" do
      update_token = update_token_fixture()
      assert Backup.list_update_tokens() == [update_token]
    end

    test "get_update_token!/1 returns the update_token with given id" do
      update_token = update_token_fixture()
      assert Backup.get_update_token!(update_token.id) == update_token
    end

    test "create_update_token/1 with valid data creates a update_token" do
      valid_attrs = %{token: "some token"}

      assert {:ok, %UploadToken{} = update_token} = Backup.create_update_token(valid_attrs)
      assert update_token.token == "some token"
    end

    test "create_update_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Backup.create_update_token(@invalid_attrs)
    end

    test "update_update_token/2 with valid data updates the update_token" do
      update_token = update_token_fixture()
      update_attrs = %{token: "some updated token"}

      assert {:ok, %UploadToken{} = update_token} =
               Backup.update_update_token(update_token, update_attrs)

      assert update_token.token == "some updated token"
    end

    test "update_update_token/2 with invalid data returns error changeset" do
      update_token = update_token_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Backup.update_update_token(update_token, @invalid_attrs)

      assert update_token == Backup.get_update_token!(update_token.id)
    end

    test "delete_update_token/1 deletes the update_token" do
      update_token = update_token_fixture()
      assert {:ok, %UploadToken{}} = Backup.delete_update_token(update_token)
      assert_raise Ecto.NoResultsError, fn -> Backup.get_update_token!(update_token.id) end
    end

    test "change_update_token/1 returns a update_token changeset" do
      update_token = update_token_fixture()
      assert %Ecto.Changeset{} = Backup.change_update_token(update_token)
    end
  end
end
