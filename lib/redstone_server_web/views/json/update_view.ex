defmodule RedstoneServerWeb.Json.UpdateView do
  def render("show.json", %{latest_update: latest_update}) do
    latest_update
  end
end
