defmodule RedstoneServerWeb.Api.Update do
  @moduledoc """
  Update API controller
  """
  use RedstoneServerWeb, :controller

  def fetch(conn, %{"backup_id" => backup_id}) do
    latest_update = RedstoneServer.Backup.get_latest_update(backup_id)

    conn
    |> put_view(RedstoneServerWeb.Json.UpdateView)
    |> render("show.json", %{latest_update: latest_update})
  end
end
