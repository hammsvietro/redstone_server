defmodule RedstoneServer.BackupTest do
  use RedstoneServer.DataCase

  alias RedstoneServer.Backup

  describe "upload_tokens" do
    alias RedstoneServer.Backup.UploadToken

    import RedstoneServer.BackupFixtures

    test "get_upload_token!/1 returns the upload_token with given id" do
      upload_token = upload_token_fixture()
      assert Backup.get_upload_token!(upload_token.id) == upload_token
    end

    test "delete_upload_token/1 deletes the upload_token" do
      upload_token = upload_token_fixture()
      assert {:ok, %UploadToken{}} = Backup.delete_upload_token(upload_token.token)
      assert_raise Ecto.NoResultsError, fn -> Backup.get_upload_token!(upload_token.id) end
    end

    test "get_update_by_upload_token/1 returns a update" do
      %UploadToken{} = upload_token = upload_token_fixture()
      %Backup.Update{} = Backup.get_update_by_upload_token(upload_token.token)
    end

    test "get_backup_by_upload_token/1 returns a backup" do
      %UploadToken{} = upload_token = upload_token_fixture()
      %Backup.Backup{} = Backup.get_backup_by_upload_token(upload_token.token)
    end
  end

  describe "download_tokens" do
    alias RedstoneServer.Backup.DownloadToken

    import RedstoneServer.BackupFixtures

    test "get_backup_by_download_token/1 returns a backup" do
      %DownloadToken{} = download_token = download_token_fixture()
      %Backup.Backup{} = Backup.get_backup_by_download_token(download_token.token)
    end

    test "delete_download_token/1 deletes the download_token" do
      download_token = download_token_fixture()
      assert {:ok, %DownloadToken{}} = Backup.delete_download_token(download_token.token)
      assert_raise Ecto.NoResultsError, fn -> Backup.get_download_token!(download_token.id) end
    end
  end

  describe "backup_lock" do
    alias RedstoneServer.Lock

    test "lock/1 can be used multiple times for :read locks" do
      Lock.start_link(%{})
      assert :ok = Lock.lock(%{backup_name: "leprous_discography", kind: :read})
      assert :ok = Lock.lock(%{backup_name: "leprous_discography", kind: :read})
      assert :ok = Lock.lock(%{backup_name: "leprous_discography", kind: :read})

      assert %{users: 3} = GenServer.call(Lock, {:get, "leprous_discography"})
      assert :ok = Lock.unlock("leprous_discography")
      assert :ok = Lock.unlock("leprous_discography")
      assert %{users: 1} = GenServer.call(Lock, {:get, "leprous_discography"})
      assert :ok = Lock.unlock("leprous_discography")
      assert is_nil(GenServer.call(Lock, {:get, "leprous_discography"}))
      assert {:error, _} = Lock.unlock("leprous_discography")
    end

    test "lock/1 with a :write lock returns an error when there's a read lock and vice-versa" do
      Lock.start_link(%{})
      assert :ok = Lock.lock(%{backup_name: "leprous_discography", kind: :read})
      assert {:error, _} = Lock.lock(%{backup_name: "leprous_discography", kind: :write})
      assert :ok = Lock.unlock("leprous_discography")

      assert :ok = Lock.lock(%{backup_name: "leprous_discography", kind: :write})
      assert {:error, _} = Lock.lock(%{backup_name: "leprous_discography", kind: :read})
      assert :ok = Lock.unlock("leprous_discography")
    end

    test "lock/1 with a :write lock returns an error if the backup already has a write lock" do
      Lock.start_link(%{})
      assert :ok = Lock.lock(%{backup_name: "leprous_discography", kind: :write})
      assert {:error, _} = Lock.lock(%{backup_name: "leprous_discography", kind: :write})
      assert :ok = Lock.unlock("leprous_discography")
    end
  end
end
