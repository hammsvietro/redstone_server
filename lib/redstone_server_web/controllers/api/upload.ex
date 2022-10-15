defmodule RedstoneServerWeb.Api.Upload do
  use RedstoneServerWeb, :controller
  alias RedstoneServerWeb.Api.Schemas.Upload, as: UploadValidators

  def declare(conn, params) do
    case UploadValidators.validate_backup(params) do
      %{
        valid?: true,
        changes: %{name: name, files: files}
      } ->
        RedstoneServer.Backup.create_backup(name, conn.assigns.current_user.id, files)

        files
        |> IO.inspect()
        |> get_total_size()
        |> IO.inspect()

        conn |> send_resp(200, "")

      changeset ->
        conn
        |> put_status(400)
        |> render(RedstoneServerWeb.ErrorView, "error.json", changeset: changeset)
    end
  end

  defp get_total_size(files) do
    files
    |> Enum.map(fn file -> file["size"] end)
    |> Enum.sum()
  end
end
