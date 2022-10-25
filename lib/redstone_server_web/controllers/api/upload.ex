defmodule RedstoneServerWeb.Api.Upload do
  use RedstoneServerWeb, :controller
  alias RedstoneServer.Backup.UpdateToken
  alias RedstoneServerWeb.Api.Schemas.Upload, as: UploadValidators

  def declare(conn, params) do
    case UploadValidators.validate_backup(params) do
      %{
        valid?: true,
        changes: %{name: name, files: files}
      } ->
        user_id = conn.assigns.current_user.id
        {:ok, %{backup: backup}} = RedstoneServer.Backup.create_backup(name, user_id, files)
        backup = RedstoneServer.Backup.get_backup(backup.id)
        {:ok, %UpdateToken{token: token}} = RedstoneServer.Backup.create_update_token(%{backup_id: backup.id, user_id: user_id})

        conn
        |> put_view(RedstoneServerWeb.Json.UploadView)
        |> render("show.json", %{backup: backup, update_token: token})

      changeset ->
        conn
        |> put_status(400)
        |> put_view(RedstoneServerWeb.ErrorView)
        |> render("error.json", changeset: changeset)
    end
  end

  defp get_total_size(files) do
    files
    |> Enum.map(fn file -> file["size"] end)
    |> Enum.sum()
  end
end
