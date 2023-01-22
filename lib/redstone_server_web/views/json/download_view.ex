defmodule RedstoneServerWeb.Json.DownloadView do
  def render("show.json", %{backup: backup, download_token: token, update: update}) do
    %{backup: backup, download_token: token, update: update}
  end
end
