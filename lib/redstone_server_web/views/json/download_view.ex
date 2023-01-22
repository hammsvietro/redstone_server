defmodule RedstoneServerWeb.Json.DownloadView do
  def render("show.json", %{backup: backup, upload_token: token, update: update}) do
    %{backup: backup, upload_token: token, update: update}
  end
end
