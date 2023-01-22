defmodule RedstoneServerWeb.Api.Download do
  use RedstoneServerWeb, :controller

  alias RedstoneServer.Backup.{Backup, Update, UploadToken}
  def clone(conn, params) do
    backup_name = params["backup_name"]
    %Backup{} = backup = RedstoneServer.Backup.get_backup_by_name(backup_name)
    %Update{} = update = RedstoneServer.Backup.get_last_update_of_backup(backup.id)
    %Update{} = update = RedstoneServer.Backup.get_last_update_of_backup(backup.id)
    conn
    |> put_view(RedstoneServerWeb.Json.DownloadView)
    |> render("show.json", %{backup: backup, update: update})
  end
  
end
