defmodule RedstoneServerWeb.Api.Download do
  use RedstoneServerWeb, :controller

  alias RedstoneServer.Backup.{Backup, Update, DownloadToken}
  alias RedstoneServer.Filesystem, as: FS

  def clone(conn, params) do
    backup_name = params["backup_name"]
    user_id = conn.assigns.current_user.id
    %Backup{} = backup = RedstoneServer.Backup.get_backup_by_name(backup_name)
    files = RedstoneServer.Backup.get_files_by_backup(backup.id)
    %Update{} = update = RedstoneServer.Backup.get_last_update_of_backup(backup.id)

    total_bytes = Enum.reduce(files, 0, &(FS.get_file_size(backup_name, &1) + &2))

    {:ok, %DownloadToken{token: token}} =
      RedstoneServer.Backup.create_download_token(%{
        user_id: user_id,
        backup_id: backup.id
      })

    conn
    |> put_view(RedstoneServerWeb.Json.DownloadView)
    |> render(
      "show.json",
      %{
        backup: backup,
        update: update,
        download_token: token,
        files_to_download: files,
        total_bytes: total_bytes
      }
    )
  end
end
