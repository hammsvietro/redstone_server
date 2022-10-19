defmodule RedstoneServerWeb.Api.Upload do
  use RedstoneServerWeb, :controller
  alias RedstoneServerWeb.Api.Schemas.Upload, as: UploadValidators

  def declare(conn, params) do
    case UploadValidators.validate_backup(params) do
      %{
        valid?: true,
        changes: %{name: name, files: files}
      } ->
        {:ok, %{backup: backup}} = RedstoneServer.Backup.create_backup(name, conn.assigns.current_user.id, files)
        backup = RedstoneServer.Backup.get_backup(backup.id)
        # files
        # |> get_total_size()

        conn
        |> put_view(RedstoneServerWeb.Json.UploadView)
        |> render("show.json", %{backup: backup})

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
