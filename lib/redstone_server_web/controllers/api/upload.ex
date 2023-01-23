defmodule RedstoneServerWeb.Api.Upload do
  use RedstoneServerWeb, :controller
  alias RedstoneServer.Backup.UploadToken
  alias RedstoneServerWeb.Api.Schemas.Upload, as: UploadValidators

  def declare(conn, params) do
    user_id = conn.assigns.current_user.id

    with %{
           valid?: true,
           changes: %{name: name, files: files}
         } <- UploadValidators.validate_backup(params),
         {:ok, %{backup: %{id: backup_id}, update: update}} <-
           RedstoneServer.Backup.create_backup(name, user_id, files) do
      backup = RedstoneServer.Backup.get_backup(backup_id)
      files = RedstoneServer.Backup.get_files_by_backup(backup.id)

      {:ok, %UploadToken{token: token}} =
        RedstoneServer.Backup.create_upload_token(%{
          backup_id: backup.id,
          user_id: user_id,
          update_id: update.id
        })

      conn
      |> put_view(RedstoneServerWeb.Json.UploadView)
      |> render("show.json", %{backup: backup, upload_token: token, update: update, files: files})
    else
      %{valid?: false} = changeset -> _render_changeset_error(conn, changeset)
      {:error, changeset} -> _render_changeset_error(conn, changeset)
    end
  end

  defp get_total_size(files) do
    files
    |> Enum.map(fn file -> file["size"] end)
    |> Enum.sum()
  end

  defp _render_changeset_error(conn, changeset) do
    conn
    |> put_status(400)
    |> put_view(RedstoneServerWeb.ErrorView)
    |> render("error.json", changeset: changeset)
  end
end
