defmodule RedstoneServerWeb.Json.DownloadView do
  def render("show.json", %{
        backup: backup,
        download_token: token,
        update: update,
        files: files,
        total_bytes: total_bytes
      }) do
    %{
      backup: backup,
      download_token: token,
      update: update,
      files: files,
      total_bytes: total_bytes
    }
  end
end
