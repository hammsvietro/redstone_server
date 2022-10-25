defmodule RedstoneServerWeb.Json.UploadView do
  use RedstoneServerWeb, :view

  def render("show.json", %{backup: backup, update_token: token}) do
    %{backup: backup, update_token: token}
  end

  def render("show.json", %{backup: backup}) do
    %{backup: backup}
  end
end
