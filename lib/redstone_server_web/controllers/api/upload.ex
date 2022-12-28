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
         {:ok, %{backup: backup, update: update}} <-
           RedstoneServer.Backup.create_backup(name, user_id, files) do
      backup = RedstoneServer.Backup.get_backup(backup.id)

      # TODO: also create update token durring the backup
      {:ok, %UploadToken{token: token}} =
        RedstoneServer.Backup.create_update_token(%{
          backup_id: backup.id,
          user_id: user_id,
          update_id: update.id
        })

      conn
      |> put_view(RedstoneServerWeb.Json.UploadView)
      |> render("show.json", %{backup: backup, update_token: token})
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
