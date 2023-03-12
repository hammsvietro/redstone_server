defmodule RedstoneServerWeb.Api.Download do
  @moduledoc """
  Download API controller
  """

  use RedstoneServerWeb, :controller

  alias RedstoneServer.Backup.{Backup, Update, DownloadToken}
  alias RedstoneServer.Filesystem, as: FS

  def clone(conn, params) do
    # TODO: create schema
    backup_name = params["backup_name"]
    user_id = conn.assigns.current_user.id

    case RedstoneServer.Backup.get_backup_by_name(backup_name) do
      %Backup{} = backup ->
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
            files: files,
            total_bytes: total_bytes
          }
        )

      nil ->
        conn
        |> put_status(400)
        |> put_view(RedstoneServerWeb.ErrorView)
        |> render("404.json", entity: "backup", name: backup_name)
    end
  end

  def pull(conn, %{"backup_id" => backup_id, "update_id" => update_id}) do
    user_id = conn.assigns.current_user.id

    with %Update{} = update <- RedstoneServer.Backup.get_update(update_id),
         [_ | _] = files <- RedstoneServer.Backup.get_files_changed_since_update(update),
         backup <- RedstoneServer.Backup.get_backup(backup_id),
         %RedstoneServer.Backup.Update{} = latest_update <-
           RedstoneServer.Backup.get_last_update_of_backup(backup_id) do
      {:ok, %DownloadToken{token: token}} =
        RedstoneServer.Backup.create_download_token(%{
          user_id: user_id,
          backup_id: backup.id
        })

      total_bytes =
        files
        |> Enum.filter(&(&1.last_update.operation != :remove))
        |> Enum.reduce(0, &(FS.get_file_size(backup.name, &1) + &2))

      conn
      |> put_view(RedstoneServerWeb.Json.DownloadView)
      |> render(
        "show.json",
        %{
          backup: backup,
          update: latest_update,
          download_token: token,
          files: files,
          total_bytes: total_bytes
        }
      )
    else
      nil ->
        conn
        |> put_status(400)
        |> put_view(RedstoneServerWeb.ErrorView)
        |> render("404.json", entity: "backup", name: backup_id)
    end
  end
end
