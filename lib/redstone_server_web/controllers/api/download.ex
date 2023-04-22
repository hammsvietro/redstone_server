defmodule RedstoneServerWeb.Api.Download do
  @moduledoc """
  Download API controller
  """

  use RedstoneServerWeb, :controller

  alias RedstoneServer.Backup.{Backup, Update, DownloadToken}
  alias RedstoneServer.Filesystem, as: FS
  alias RedstoneServerWeb.Utils

  def clone(conn, params) do
    # TODO: create schema
    backup_name = params["backup_name"]
    user_id = conn.assigns.current_user.id

    with %Backup{} = backup <- RedstoneServer.Backup.get_backup_by_name(backup_name),
         :ok <- RedstoneServer.Lock.lock(%{backup_name: backup.name, kind: :read}) do
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
        Utils.to_json(%{
          backup: backup,
          update: update,
          download_token: token,
          files: files,
          total_bytes: total_bytes
        })
      )
    else
      error ->
        RedstoneServer.Lock.unlock(backup_name)

        case error do
          {:error, reason} ->
            conn
            |> put_status(400)
            |> put_view(RedstoneServerWeb.ErrorView)
            |> render("error.json", %{reason: reason})

          nil ->
            conn
            |> put_status(400)
            |> put_view(RedstoneServerWeb.ErrorView)
            |> render("404.json", entity: "backup", name: backup_name)
        end
    end
  end

  def pull(conn, %{"backup_id" => backup_id, "update_id" => update_id}) do
    user_id = conn.assigns.current_user.id
    %Backup{} = backup = RedstoneServer.Backup.get_backup(backup_id)

    with %Update{} = update <- RedstoneServer.Backup.get_update(update_id),
         [_ | _] = files <- RedstoneServer.Backup.get_files_changed_since_update(update),
         %RedstoneServer.Backup.Update{} = latest_update <-
           RedstoneServer.Backup.get_last_update_of_backup(backup_id),
         :ok <- RedstoneServer.Lock.lock(%{backup_name: backup.name, kind: :read}) do
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
        Utils.to_json(%{
          backup: backup,
          update: latest_update,
          download_token: token,
          files: files,
          total_bytes: total_bytes
        })
      )
    else
      error ->
        RedstoneServer.Lock.unlock(backup.name)

        case error do
          {:error, reason} ->
            conn
            |> put_status(400)
            |> put_view(RedstoneServerWeb.ErrorView)
            |> render("error.json", %{reason: reason})

          nil ->
            conn
            |> put_status(400)
            |> put_view(RedstoneServerWeb.ErrorView)
            |> render("404.json", entity: "backup", name: backup_id)
        end
    end
  end
end
