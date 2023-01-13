defmodule RedstoneServerWeb.Json.UploadView do
  use RedstoneServerWeb, :view

  def render("show.json", %{backup: backup, upload_token: token, update: update}) do
    %{backup: backup, upload_token: token, update: update}
  end

  def render("show.json", %{backup: backup}) do
    %{backup: backup}
  end
end
