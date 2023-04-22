defmodule RedstoneServerWeb.Api.Upload do
  @moduledoc """
  Upload API controller
  """

  use RedstoneServerWeb, :controller
  alias RedstoneServer.Backup.UploadToken
  alias RedstoneServerWeb.Utils
  alias RedstoneServerWeb.Api.Schemas.Upload, as: UploadValidators

  def declare_backup(conn, params) do
    user_id = conn.assigns.current_user.id

    with %{
           valid?: true,
           changes: %{name: name, files: files}
         } <- UploadValidators.validate_backup(params),
         {:ok, %{backup: %{id: backup_id}, update: update}} <-
           RedstoneServer.Backup.create_backup(name, user_id, files) do
      backup = RedstoneServer.Backup.get_backup(backup_id)
      RedstoneServer.Lock.lock(%{backup_name: backup.name, kind: :write})

      files = RedstoneServer.Backup.get_files_changed_in_update(update.id)

      {:ok, %UploadToken{token: token}} =
        RedstoneServer.Backup.create_upload_token(%{
          backup_id: backup.id,
          user_id: user_id,
          update_id: update.id
        })

      conn
      |> put_view(RedstoneServerWeb.Json.UploadView)
      |> render(
        "show.json",
        Utils.to_json(%{
          backup: backup,
          upload_token: token,
          update: update,
          files: files
        })
      )
    else
      %{valid?: false} = changeset -> _render_changeset_error(conn, changeset)
      {:error, changeset} -> _render_changeset_error(conn, changeset)
    end
  end

  def push(conn, %{"backup_id" => backup_id, "files" => files}) do
    user_id = conn.assigns.current_user.id
    %RedstoneServer.Backup.Backup{} = backup = RedstoneServer.Backup.get_backup(backup_id)

    with {:ok, %{update: update}} <- RedstoneServer.Backup.update_files(backup, files, user_id),
         files <- RedstoneServer.Backup.get_files_changed_in_update(update.id),
         :ok <- RedstoneServer.Lock.lock(%{backup_name: backup.name, kind: :write}),
         {:ok, %UploadToken{token: token}} <-
           RedstoneServer.Backup.create_upload_token(%{
             backup_id: backup.id,
             user_id: user_id,
             update_id: update.id
           }) do
      conn
      |> put_view(RedstoneServerWeb.Json.UploadView)
      |> render(
        "show.json",
        Utils.to_json(%{
          backup: backup,
          upload_token: token,
          update: update,
          files: files
        })
      )
    else
      error ->
        RedstoneServer.Lock.unlock(backup.name)

        case error do
          %{valid?: false} = changeset ->
            _render_changeset_error(conn, changeset)

          {:error, %Ecto.Changeset{} = changeset} ->
            _render_changeset_error(conn, changeset)

          {:error, reason} ->
            conn
            |> put_status(400)
            |> put_view(RedstoneServerWeb.ErrorView)
            |> render("error.json", %{reason: reason})
        end
    end
  end

  # defp get_total_size(files) do
  #   files
  #   |> Enum.map(fn file -> file["size"] end)
  #   |> Enum.sum()
  # end

  defp _render_changeset_error(conn, changeset) do
    conn
    |> put_status(400)
    |> put_view(RedstoneServerWeb.ErrorView)
    |> render("error.json", changeset: changeset)
  end
end
